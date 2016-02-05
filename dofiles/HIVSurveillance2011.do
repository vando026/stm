//  program:    HIVSurveillance.do
//  task:		Description
//  project:	Name
//  author:     AV / Created: 13Apr2015 


***********************************************************************************************************
**************************************** De Anonymize Data ************************************************
***********************************************************************************************************
use "$source/HIVSurveillance/2015/RD05-99 ACDIS HIV All", clear 
rename IIntId id_anonymised

merge m:1 id_anonymised using "$source/HIVSurveillance/2015/RD05-001 HIV Anonymised Individuals", keep(match) nogen

rename IIntId IIntID 
keep IIntID id_anonymised VisitDate HIVResult AgeAtVisit Sex

***********************************************************************************************************
**************************************** Get the dates ****************************************************
***********************************************************************************************************
sort IIntID VisitDate 
tab HIVResult , nolab

** Associate dates with Test result
bysort IIntID (VisitDate): gen HIVNegative = cond(HIVResult==0, VisitDate, .)
bysort IIntID (VisitDate): gen HIVPositive = cond(HIVResult==1, VisitDate, .)
format HIV* %td

** Now we want to see if there is any HIV negatives < 2012
gen YearNeg = year(HIVNegative)
gen YearPos = year(HIVPositive)
bysort IIntID: egen AnyHIVNegPre_2012 = max(YearNeg < 2012)
bysort IIntID: egen AnyHIVNegPost_2011 = max(inrange(YearNeg, 2012, 2015))
bysort IIntID: egen AnyHIVPosPost_2011 = max(inrange(YearPos, 2011, 2015))
bysort IIntID: egen AnyHIVPosPre_2011 = max(YearPos < 2011)

** Now identify Repeat tester if has two tests and one pre prior to 2010. 
gen RepeatTester = (AnyHIVNegPre_2012 & AnyHIVNegPost_2011) | (AnyHIVNegPre_2012 & AnyHIVPosPost_2011)
** However, if this individual seroconverted prior to 2011 then exclude from analysis. EG IIntID=45344
replace RepeatTester = 0 if AnyHIVPosPre_2011==1
keep if RepeatTester==1
distinct IIntID 
gen SeroConverter = AnyHIVPosPost_2011
distinct IIntID if SeroConverter==1


***********************************************************************************************************
****************************************Age and Censoring**************************************************
***********************************************************************************************************
** This will keep all men between 15 and 54
** drop if !inrange(AgeAtVisit, 15, 55)
** Now keep all woman between 15 and 49
** drop if Sex==2 & AgeAtVisit>=50
** bysort Sex: sum AgeAtVisit 



** Now make the dates
bysort IIntID   : egen EarliestHIVNegative = min(HIVNegative)
bysort IIntID   : egen LatestHIVNegative = max(HIVNegative)
bysort IIntID   : egen EarliestHIVPositive = min(HIVPositive)
bysort IIntID   : egen LatestHIVPositive = max(HIVPositive)
format *HIV* %td

** Now work with single obs per Indiv
collapse (first) EarliestHIVNegative LatestHIVNegative EarliestHIVPositive LatestHIVPositive, by(IIntID)

** Sanity check
assert EarliestHIVNegative <= LatestHIVNegative if !missing(EarliestHIVNegative, LatestHIVNegative)

label data "HIV dates for all ACDIS individuals (see notes)"
save "$derived/ac-HIV_Dates_2011", replace

***************************************************************************************************************
**************************************** Get repeat testers **************************************************
***************************************************************************************************************
use "$derived/ac-HIV_Dates_2011", clear 

** We have LatestNegativeDate after EarliestHIVPositive. 13Apr2015 only 50 individuals
gen _LateNegAfterEarlyPos =  (LatestHIVNegative > EarliestHIVPositive & !missing(EarliestHIVPositive, LatestHIVNegative))
distinct IIntID if _LateNegAfterEarlyPos 

** Perhaps we need to see of their LatestHIVPositive comes after LatestHIVNegative \
gen _LatePosAfterLateNeg = (LatestHIVPositive >= LatestHIVNegative)

** Note 14Apr2015: so 9 repeat-testers have a LatestHIVPositive after LatestNegativeDate (but not an EarliestHIVPositive after LatestHIVNegative). So replace.
distinct _LatePosAfterLateNeg if _LateNegAfterEarlyPos 
replace EarliestHIVPositive = LatestHIVPositive if _LatePosAfterLateNeg==1 & _LateNegAfterEarlyPos==1

** Drop the remaining repeat-testers that cannot have dates resolved
drop if _LateNegAfterEarlyPos==1 & _LatePosAfterLateNeg==0

** Lets identify positive repeat-testers
gen HasLateNeg_EarPosTest = !missing(LatestHIVNegative) & !missing(EarliestHIVPositive) 
distinct IIntID if HasLateNeg_EarPosTest==1 

** Lets identify negative repeat-testers
gen HasEar_LateNegTest = !missing(EarliestHIVNegative) & !missing(LatestHIVNegative) & missing(EarliestHIVPositive) 
distinct IIntID if HasEar_LateNegTest 

** Now lets keep only these individuals as they will qualify for repeat tester status. 
keep if HasEar_LateNegTest | HasLateNeg_EarPosTest

** For those that have only negative HIV dates, drop if both equal to each other as really only one HIVNegDate
drop if (EarliestHIVNegative==LatestHIVNegative) & HasEar_LateNegTest==1 

***********************************************************************************************************
****************************************ARTemis data ******************************************************
***********************************************************************************************************
** Add the ARTemis data to use EarliestTreatmentDate to reduce the interval
if "$artemis"=="Yes" {
  ** Bring in Earliest ART dates from ARTemis_main.do file
  merge m:1 IIntID using "$temp/ART_Earliest", keepusing(IIntID EarliestTreatmentDate) 

  ** Only keep individuals that in current dataset or are matched from Artemis
  keep if inlist(_merge, 1, 3)

  ** Now, we need to move the EarliestHIVPositive left if EarliestTreatmentDate comes before this date
  replace EarliestHIVPositive = EarliestTreatmentDate if !missing(EarliestHIVPositive) & inrange(EarliestTreatmentDate, LatestHIVNegative, EarliestHIVPositive)
  ** Note 28Apr2015: only 175 changes made, not very substantial. We should really think about adding positives too
}

***********************************************************************************************************
****************************************Sanity Checks******************************************************
***********************************************************************************************************
assert EarliestHIVNegative < EarliestHIVPositive if !missing(EarliestHIVPositive, EarliestHIVNegative) 
assert LatestHIVNegative < EarliestHIVPositive if !missing(EarliestHIVPositive, LatestHIVNegative) 
assert !missing(EarliestHIVPositive, LatestHIVNegative) if !missing(EarliestHIVPositive)

** Now lets identify who seroconverted or not. Give a 1 to indiv who dont have miss values for EarliestHIVPositive
gen SeroConvertEvent = cond(!missing(EarliestHIVPositive), 1, 0)
distinct IIntID if SeroConvertEvent==1
drop _* Has*

***********************************************************************************************************
*************************************** Keep if 3 months***************************************************
***********************************************************************************************************
distinct IIntID 
capture drop Diff
gen Diff = (date("01-01-2011", "DMY") - EarliestHIVNegative)/30.4 if year(EarliestHIVNegative) < 2011
gen Keep = cond(missing(Diff) | inrange(Diff, 0, 3), 1, 0)
keep if Keep==1
distinct IIntID 


/**********************************************************************************************************************
**------------------------------------------------------------------------------------------------------------------**
**       The code below uses different methods to impute the end point
**       Enter the method to be computed: 1) midpoint 2) random 3) endpoint 4) intcens
**------------------------------------------------------------------------------------------------------------------**
**********************************************************************************************************************
dis as text "$method"
cap drop DateSeroConvert
if "$method" == "random" {
    ** To draw a random seroconversion date between latest HIV negative and Earliest HIV positive. 
    set seed 200
    gen DateSeroConvert = (EarliestHIVPositive - LatestHIVNegative)*runiform() + LatestHIVNegative if SeroConvertEvent==1 
    replace DateSeroConvert = int(DateSeroConvert)  
    assert inrange(DateSeroConvert, LatestHIVNegative, EarliestHIVPositive) if SeroConvertEvent==1
}
else if "$method" == "midpoint" {
    ** Define the seroconversion date as mid-point between the interval capturing seroconversion.  
    gen DateSeroConvert = int((LatestHIVNegative + EarliestHIVPositive)/2) if SeroConvertEvent==1
    assert inrange(DateSeroConvert, LatestHIVNegative, EarliestHIVPositive) if SeroConvertEvent==1
}
else if "$method"=="endpoint"{
    gen DateSeroConvert = EarliestHIVPositive if SeroConvertEvent==1
}
else if "$method"=="intcens" {
	gen DateSeroConvert = EarliestHIVPositive
}
format DateSeroConvert %td
gen Method = "$method"
**-----------------------------------------  x ---------------------------------------------------------------------**

** Now get left truncated date
gen EarliestObservationDate = EarliestHIVNegative if SeroConvertEvent==1
replace EarliestObservationDate = EarliestHIVNegative if SeroConvertEvent==0
format EarliestObservationDate %td

** Now get a date for right censoring or event failure
gen LatestObservationDate = DateSeroConvert if SeroConvertEvent==1
replace LatestObservationDate = LatestHIVNegative if SeroConvertEvent==0
format LatestObservationDate %td
sum LatestObservationDate if SeroConvertEvent == 1

** Sometimes random method will make seroconversion on LatestHIVNegative date
list if LatestObservationDate==EarliestObservationDate 
replace LatestObservationDate=LatestObservationDate + 0.125 if LatestObservationDate==EarliestObservationDate

drop LatestHIVPositive _* Has*

label data "HIV Dates for Repeat-Testers"
save "$derived/ac-HIV_Dates_RT_2011", replace


/***********************************************************************************************************
****************************************Episodes **********************************************************
***********************************************************************************************************
use "$derived/ac-HIV_Dates_RT", clear

distinct IIntID if SeroConvertEvent 
local RTcheck = r(ndistinct)

** Make new vars which will become the begin and end of all episodes
clonevar ObservationStart = EarliestObservationDate
clonevar ObservationEnd = LatestObservationDate

** To create the correct episodes we must stset first
stset ObservationEnd, id(IIntID) failure(SeroConvertEvent==1) entry(ObservationStart) time0(ObservationStart) //  scale(365.25) 
keep if 1/20

** Show which days corrsepond to cut-off year
forvalue yr = 2000/2015 {
	local y = d(01jan`yr')
	dis `yr' ":" `y'
	}

** Now split into episodes
stsplit _Year, at(14610 14976 15341 15706 16071 16437 16802 17167 17532 17898 18263 18628 18993 19359 19724 20089)

** Make sure first episode start begins with entry into surveillance
gen ExpDays = ObservationEnd - ObservationStart 
gen ExpYear = year(ObservationStart)

stset, clear

** Now expand the event var across all new episodes
bysort IIntID : replace SeroConvertEvent = 0 if _n < _N

distinct IIntID if SeroConvertEvent==1
local Epicheck = r(ndistinct)
assert `RTcheck'==`Epicheck'

drop _Year IntervalLength
order IIntID ObservationStart ObservationEnd EarliestHIVNegative LatestHIVNegative EarliestHIVPositive DateSeroConvert 
save "$derived/HIV_Episodes", replace


** Note 09Oct2015: Add year for Andrew
use "$source/Demography/2015/RD02-01 ACDIS Demography", clear
rename IIntId id_anonymised 

merge m:1 id_anonymised using "$source/Demography/2015/RD02-001 Demography Anonymised Individuals" , keep(match) nogen

rename IIntId IIntID 
rename BSIntId BSIntID 
keep IIntID ExpYear Age  ObservationStart ObservationEnd

merge m:1 IIntID ExpYear using "$derived/HIV_Episodes"
keep if inlist(_merge, 2, 3)

sav "$derived/Dem_HIV", replace



