//  program:    HIVSurveillance.do
//  task:		Description
//  project:	Name
//  author:     AV / Created: 13Apr2015 


use "$source/RD05-001_ACDIS_HIV", clear
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

** Sanity check

** We have LatestNegativeDate after EarliestHIVPositive. 02May2016:  101 individuals
gen _LateNegAfterEarlyPos =  (LatestHIVNegative > EarliestHIVPositive & !missing(EarliestHIVPositive, LatestHIVNegative))

** I just drop these individuals, irreconcilable
drop if _LateNegAfterEarlyPos 

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

** If any positives prior to 2011 drop
** IE The repeat tester is right censored before start of study
drop if year(EarliestHIVPositive) < 2011

***********************************************************************************************************
**************************************** Impute dates *****************************************************
***********************************************************************************************************
gen SeroConvertEvent = !missing(EarliestHIVPositive)

** To draw a random seroconversion date between latest HIV negative and Earliest HIV positive. 
set seed 200
gen DateSeroConvert = int((EarliestHIVPositive - LatestHIVNegative)*runiform() + LatestHIVNegative) if SeroConvertEvent==1
format DateSeroConvert %td
assert inrange(DateSeroConvert, LatestHIVNegative, EarliestHIVPositive) if SeroConvertEvent==1

** If you impute dates before 2011 drop
drop if year(DateSeroConvert) < 2011 & !missing(SeroConvertEvent)

gen EndDate = cond(SeroConvertEvent==1, DateSeroConvert, LatestHIVNegative)
format EndDate %td
replace EarliestHIVNegative = date("01-01-2011", "DMY")
drop LatestHIVNegative

drop if EarliestHIVNegative == EndDate 
assert EarliestHIVNegative < EndDate 
saveold "$derived/ac-HIV_Dates_2011", replace

** distinct IIntID 
** distinct IIntID if SeroConvertEvent ==1 

