//  program:    HIVSurveillance.do
//  task:		Description
//  project:	Name
//  author:     AV / Created: 13Apr2015 


use "$AC_Data/Derived/HIVSurveillance/2015/RD05-001_ACDIS_HIV", clear
keep IIntID VisitDate HIVResult AgeAtVisit Sex

***********************************************************************************************************
**************************************** Check Data *******************************************************
***********************************************************************************************************
** Associate dates with Test result
bysort IIntID (VisitDate): gen HIVNegative = cond(HIVResult==0, VisitDate, .)
bysort IIntID (VisitDate): gen HIVPositive = cond(HIVResult==1, VisitDate, .)
format HIVNegative HIVPositive %td
distinct IIntID if !missing(HIVNegative)
distinct IIntID if !missing(HIVPositive)

** Drop not applicable results
drop if missing(HIVNegative) & missing(HIVPositive)

drop AgeAtVisit 
tempfile HIVDat
save "`HIVDat'"

** Now make the dates
bysort IIntID   : egen EarliestHIVNegative = min(HIVNegative)
bysort IIntID   : egen LatestHIVNegative = max(HIVNegative)
bysort IIntID   : egen EarliestHIVPositive = min(HIVPositive)
bysort IIntID   : egen LatestHIVPositive = max(HIVPositive)
format *HIV* %td

** Now work with single obs per Indiv
collapse (firstnm) EarliestHIVNegative LatestHIVNegative EarliestHIVPositive LatestHIVPositive, by(IIntID)

** Sanity check
assert EarliestHIVNegative <= LatestHIVNegative if !missing(EarliestHIVNegative, LatestHIVNegative)

** We have LatestNegativeDate after EarliestHIVPositive. 13Apr2015 only 50 individuals
gen _LateNegAfterEarlyPos =  (LatestHIVNegative > EarliestHIVPositive & !missing(EarliestHIVPositive, LatestHIVNegative))
distinct IIntID if _LateNegAfterEarlyPos 

** SO these are the unresolved test dates, we drop approx 101
keep if _LateNegAfterEarlyPos==1
keep IIntID
tempfile DropID
save "`DropID'"


***********************************************************************************************************
**************************************** Bring In data ****************************************************
***********************************************************************************************************
use "`HIVDat'", clear
merge m:1 IIntID using "`DropID'", keep(1 2) nogen

sort IIntID VisitDate 
tab HIVResult 

** Get years of tests
gen YearNeg = year(HIVNegative)
gen YearPos = year(HIVPositive)

** We exclude any indiv who did not have a Neg test in 2011 and before
bysort IIntID: egen HIVNegStart_2011 = max(YearNeg <= 2011)
drop if HIVNegStart_2011==0 

** If any positives prior to 2011 drop
bysort IIntID: egen FirstPos = min(YearPos)
drop if FirstPos < 2011
drop FirstPos

** Get HIV pos in 2011 and after
bysort IIntID: egen HIVPos2011_End = max(inrange(YearPos, 2011, 2015))

** Use to identify Negative repeat-testers
bysort IIntID: egen HIVNeg2011_End = max(inrange(YearNeg, 2011, 2015))

** Now identify Repeat tester if has two tests and one pre prior to 2010. 
gen RepeatTester = (HIVNeg2011_End | HIVPos2011_End) 

keep if RepeatTester==1
distinct IIntID 

***********************************************************************************************************
**************************************** Censor Dates******************************************************
***********************************************************************************************************
bysort IIntID   : egen LatestHIVNegative = max(HIVNegative)
bysort IIntID   : egen EarliestHIVPositive = min(HIVPositive)
gen EarliestHIVNegative = date("01-01-2011", "DMY")
format LatestHIVNegative EarliestHIV* %td

duplicates drop IIntID, force
keep IIntID Sex Earliest* Latest*

** Sanity checks
assert !missing(EarliestHIVPositive) | !missing(LatestHIVNegative)
assert EarliestHIVNegative < EarliestHIVPositive if !missing(EarliestHIVPositive, EarliestHIVNegative) 
assert !missing(EarliestHIVPositive, LatestHIVNegative) if !missing(EarliestHIVPositive)
assert (LatestHIVNegative < EarliestHIVPositive) if !missing(EarliestHIVPositive, LatestHIVNegative) 

***********************************************************************************************************
**************************************** Impute dates or Not **********************************************
***********************************************************************************************************
** In the next step we can select two methods to deal with interval censoring. The first imputes a 
** random serodate between latestHIVneg and EarliestHIV pos, even if LatestHIVNegative is prior to 2011.
** The Second method drops any LatestHIVNegative prior to 2011, since we will not randomly impute a serodate.
gen SeroConvertEvent = !missing(EarliestHIVPositive)
** Now get a date for right censoring or event failure ** Which End date to use?
if "$impute"=="yes" {
  ** Some LatestHIVNegative dates may be very early on, not reasonable to draw between long interval
  drop if year(LatestHIVNegative) < 2008
  ** To draw a random seroconversion date between latest HIV negative and Earliest HIV positive. 
  set seed 200
  gen DateSeroConvert = int((EarliestHIVPositive - LatestHIVNegative)*runiform() + LatestHIVNegative) if SeroConvertEvent==1
  format DateSeroConvert %td
  assert inrange(DateSeroConvert, LatestHIVNegative, EarliestHIVPositive) if SeroConvertEvent==1
  gen EndDate = cond(SeroConvertEvent==1, DateSeroConvert, LatestHIVNegative)
  ** Now drop the obs if randomly selected prior to 2011
  gen ImputePos = year(DateSeroConvert)
  bysort IIntID: egen AnyHIVPosImpPre_2011 = max(ImputePos < 2011)
  drop if AnyHIVPosImpPre_2011==1
  drop AnyHIVPosImpPre_2011
  distinct IIntID if SeroConvertEvent == 1
}
else {
  ** Now for interval censoring, we can only work LatestHIVNeg dates in 2011 and after
  drop if year(LatestHIVNegative) < 2011
  gen EndDate = cond(!missing(EarliestHIVPositive), EarliestHIVPositive, LatestHIVNegative)
}
format EndDate Earliest* %td
distinct IIntID if SeroConvertEvent == 1

order IIntID
save "$derived/ac-HIV_Dates_2011", replace

