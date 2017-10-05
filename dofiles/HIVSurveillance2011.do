//  program:    HIVSurveillance.do
//  task:		Description
//  project:	Name
//  author:     AV / Created: 13Apr2015 


use "$AC_Data/HIVSurveillance/2015/RD05-001_ACDIS_HIV", clear
keep IIntID VisitDate HIVResult Sex

***********************************************************************************************************
**************************************** Check Data *******************************************************
***********************************************************************************************************
** Associate dates with Test result
bysort IIntID (VisitDate): gen HIVNegative = cond(HIVResult==0, VisitDate, .)
bysort IIntID (VisitDate): gen HIVPositive = cond(HIVResult==1, VisitDate, .)

** Now make the dates
bysort IIntID   : egen EarliestHIVNegative = min(HIVNegative)
bysort IIntID   : egen LatestHIVNegative = max(HIVNegative)
bysort IIntID   : egen EarliestHIVPositive = min(HIVPositive)
bysort IIntID   : egen LatestHIVPositive = max(HIVPositive)
format *HIV* %td

** Now work with single obs per Indiv
collapse (firstnm) EarliestHIVNegative LatestHIVNegative EarliestHIVPositive LatestHIVPositive , by(IIntID)

** These indivs dont have any test info
egen MissCount = rowmiss(Earliest* Latest*)
drop if MissCount==4

** We have LatestNegativeDate after EarliestHIVPositive. 02May2016:  101 individuals
gen _LateNegAfterEarlyPos =  (LatestHIVNegative > EarliestHIVPositive & !missing(EarliestHIVPositive, LatestHIVNegative))

** I just drop these individuals, irreconcilable
drop if _LateNegAfterEarlyPos 

tempfile HIVDat0
save "`HIVDat0'"

** Drop any indiv that dont have a first neg date.
egen AnyNegHIV = rownonmiss(EarliestHIVNegative LatestHIVNegative)
drop if AnyNegHIV==0

** Must have two tests, if early neg date is equal to late neg date and missing pos date then drop
drop if  (EarliestHIVNegative==LatestHIVNegative) & missing(EarliestHIVPositive)

***********************************************************************************************************
****************************************Sanity Checks******************************************************
***********************************************************************************************************
assert EarliestHIVNegative < EarliestHIVPositive if !missing(EarliestHIVPositive, EarliestHIVNegative) 
assert LatestHIVNegative < EarliestHIVPositive if !missing(EarliestHIVPositive, LatestHIVNegative) 
assert EarliestHIVNegative <= LatestHIVNegative 
assert !missing(EarliestHIVPositive, LatestHIVNegative) if !missing(EarliestHIVPositive)
drop AnyNegHIV MissCount _LateNegAfterEarlyPos LatestHIVPositive

tempfile HIVDat
save "`HIVDat'"

***********************************************************************************************************
**************************************** Make data for 2011 - *********************************************
***********************************************************************************************************
use "`HIVDat'", clear

** We exclude any indiv whose latest neg was before 2011 and never positive
** IE The repeat tester is right censored before start of study
drop if year(LatestHIVNegative) < 2011 & missing(EarliestHIVPositive)
** Tolerence for latest HIV neg date if positive
** drop if year(LatestHIVNegative) < 2009 & !missing(EarliestHIVPositive)

** If any positives prior to 2011 drop
** IE The repeat tester is right censored before start of study
drop if year(EarliestHIVPositive) < 2011
gen FirstNegYear = year(EarliestHIVNegative)
tab FirstNegYear 

***********************************************************************************************************
**************************************** Impute dates *****************************************************
***********************************************************************************************************
gen SeroConvertEvent = !missing(EarliestHIVPositive)
scalar StartTime = date("01-01-2011", "DMY")
replace EarliestHIVNegative = StartTime 

** To draw a random seroconversion date between latest HIV negative and Earliest HIV positive. 
gen DateSeroConvert = int((EarliestHIVPositive - LatestHIVNegative)*runiform() + LatestHIVNegative) if SeroConvertEvent==1
format DateSeroConvert %td
drop if DateSeroConvert < StartTime & SeroConvertEvent==1
assert inrange(DateSeroConvert, LatestHIVNegative, EarliestHIVPositive) if SeroConvertEvent==1

gen EndDate = cond(SeroConvertEvent==1, DateSeroConvert, LatestHIVNegative)
format EndDate* %td

drop LatestHIVNegative EarliestHIVPositive

drop if EarliestHIVNegative == EndDate 
assert EarliestHIVNegative < EndDate 

distinct IIntID 
distinct IIntID if SeroConvertEvent==1

saveold "$derived/ac-HIV_Dates_2011", replace





***********************************************************************************************
***********************************************************************************************
***********************************************************************************************
** Look at some last things for Franl
use "$AC_Data/HIVSurveillance/2015/RD05-001_ACDIS_HIV", clear
keep IIntID VisitDate HIVResult Sex HIVRefused
drop if inrange(year(VisitDate), 2011, 2015)
bysort IIntID (VisitDate): gen byCount=_n
gen RefusedFirst = (HIVRefused==1 & byCount==1) 
distinct IIntID 
global Total = r(ndistinct)
distinct IIntID if RefusedFirst==1
global Refused = r(ndistinct)
dis 1 - ($Refused/$Total)

keep if inlist(HIVResult, 0, 1) 
bysort IIntID (VisitDate): gen Catch = 1 if  HIVResult[_n]==0 & (HIVResult[_n+1]==1 | HIVResult[_n+1]==0) 
bysort IIntID: egen FirstNegPlus = sum(Catch)
distinct IIntID 
global Total = r(ndistinct)
distinct IIntID if FirstNegPlus>0
global FirstNegPlus = r(ndistinct)
dis ($FirstNegPlus/$Total)


***********************************************************************************************************
**************************************** Check Data *******************************************************
***********************************************************************************************************
** Associate dates with Test result
bysort IIntID (VisitDate): gen HIVNegative = cond(HIVResult==0, VisitDate, .)
bysort IIntID (VisitDate): gen HIVPositive = cond(HIVResult==1, VisitDate, .)

** Now make the dates
bysort IIntID   : egen EarliestHIVNegative = min(HIVNegative)
bysort IIntID   : egen LatestHIVNegative = max(HIVNegative)
bysort IIntID   : egen EarliestHIVPositive = min(HIVPositive)
bysort IIntID   : egen LatestHIVPositive = max(HIVPositive)
format *HIV* %td

gen SeroConvertEvent = !missing(EarliestHIVPositive)
gen IntLength = (EarliestHIVPositive - LatestHIVNegative)/365.25 if SeroConvertEvent==1
sum IntLength,d

use "C:\Users\avandormael\Dropbox\AfricaCentre\Projects\CommunityVL\source\ART Coverage and HIV prevalence by BS_final_v12.dta", clear
tabstat X_2005* X_2006* X_2007* X_2011* , s(p50, p25, p75, min, max, sd, cv)

keep X_*
stack X_2004artcoverage_1-X_2011artcoverage_1, into(All) clear
tabstat All, s(cv, sd) 
