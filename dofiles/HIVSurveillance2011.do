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

** Now we want to see if there is any HIV negatives < 2012
gen YearNeg = year(HIVNegative)
gen YearPos = year(HIVPositive)
bysort IIntID: egen AnyHIVNegPre_2012 = max(YearNeg < 2012)
bysort IIntID: egen AnyHIVNegPost_2011 = max(inrange(YearNeg, 2012, 2015))
bysort IIntID: egen AnyHIVPosPost_2010 = max(inrange(YearPos, 2011, 2015))
bysort IIntID: egen AnyHIVPosPre_2011 = max(YearPos < 2011)

** Now identify Repeat tester if has two tests and one pre prior to 2010. 
gen RepeatTester = (AnyHIVNegPre_2012 & AnyHIVNegPost_2011) | (AnyHIVNegPre_2012 & AnyHIVPosPost_2010)
** However, if this individual seroconverted prior to 2011 then exclude from analysis. EG IIntID=45344
replace RepeatTester = 0 if AnyHIVPosPre_2011==1

keep if RepeatTester==1
distinct IIntID 
gen SeroConvertEvent = AnyHIVPosPost_2010
distinct IIntID if SeroConvertEvent==1

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

** To draw a random seroconversion date between latest HIV negative and Earliest HIV positive. 
gen SeroConvertEvent = !missing(EarliestHIVPositive)
set seed 200
gen DateSeroConvert = (EarliestHIVPositive - LatestHIVNegative)*runiform() + LatestHIVNegative if SeroConvertEvent==1 
replace DateSeroConvert = int(DateSeroConvert)  
assert inrange(DateSeroConvert, LatestHIVNegative, EarliestHIVPositive) if SeroConvertEvent==1

** Now get a date for right censoring or event failure ** Which End date to us?
if "$enddate"=="impute" {
  gen EndDate = cond(SeroConvertEvent==1, DateSeroConvert, LatestHIVNegative)
  ** It is likely that random imputation may put enddate before 2011
  gen ImputePos = year(DateSeroConvert)
  bysort IIntID: egen AnyHIVPosImpPre_2011 = max(ImputePos < 2011)
  drop if AnyHIVPosImpPre_2011==1
  drop AnyHIVPosImpPre_2011
  distinct IIntID if SeroConvertEvent == 1
}
else {
  gen EndDate = cond(SeroConvertEvent==1, EarliestHIVPositive, LatestHIVNegative)
}
distinct IIntID if SeroConvertEvent == 1
format DateSeroConvert EndDate Earliest* %td


order IIntID
save "$derived/ac-HIV_Dates_2011", replace

***********************************************************************************************************
****************************************Episodes data *****************************************************
***********************************************************************************************************
use "$derived/ac-HIV_Dates_2011", clear
distinct IIntID 
distinct IIntID if SeroConvertEvent 
local RTcheck = r(ndistinct)

gen ObservationEnd = EndDate
gen ObservationStart = EarliestHIVNegative
format Observation* %td
assert ObservationStart < ObservationEnd 

** To create the correct episodes we must stset first
stset ObservationEnd, id(IIntID) failure(SeroConvertEvent==1) entry(ObservationStart) time0(ObservationStart) // scale(365.25) 

** Show which days corrsepond to cut-off year
forvalue yr = 2011/2015 {
	local y = d(01jan`yr')
	dis `yr' ":" `y'
	}

** Now split into episodes
stsplit _Year, at(18628(365.25)20089)

** Make sure first episode start begins with entry into surveillance
gen ExpDays = ObservationEnd - ObservationStart 
gen ExpYear = year(ObservationStart)

stset, clear

** Now expand the event var across all new episodes
bysort IIntID : replace SeroConvertEvent = 0 if _n < _N

distinct IIntID if SeroConvertEvent==1
local Epicheck = r(ndistinct)
assert `RTcheck'==`Epicheck'
tab SeroConvertEvent

drop _*
save "$derived/HIV_Episodes", replace
