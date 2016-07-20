//  program:    cvl-manage2.do
//  task:	Prep cvl data for analysis
//  project:	Name
//  author:     AV / Created: 30Jan2016 

***********************************************************************************************************
**************************************** Bring in Datasets*************************************************
***********************************************************************************************************
import excel using "$source/Viral load estimation July04.xls", clear firstrow 

** I have to format vars from Diego file
foreach var of varlist PVL_prev_v - FVL_Quinn_Transmission_rate  {
  ds `var', has(type string)
  if "`=r(varlist)'" != "." {
    replace `var' = "" if `var'=="NA"
    destring `var', replace
  }
}

** No observations
drop if BSIntID > 17884

** we want to make this a percentage
foreach var of varlist *_prev_v *PDV* {
  ds `var', v(20)
  replace `var' = `var' * 100
}

** Make HIV prev a percent
gen HIV_prev = hiv8_2011_ * 100
egen HIV_pcat = cut(HIV_prev), at(0, 12.5, 25, 100) icode label
tab HIV_pcat

** the geometric mean vars are large, divide by 1000
foreach var of varlist *geo* *5 ?VL_unadjusted ?VL_*males ?VL_age*  {
  qui replace `var' = `var'/1000
}

** recode the Quin index to catory
sum *Quinn*
foreach var of varlist *Quinn_Index {
  cap drop `var'_cat
  egen `var'_cat = cut(`var'), at(0, 2.5, 12, 13.5,  23, 100)
  tab `var'_cat
}


** recode the Quin index to catory
sum *Quinn_Transmission_rate
foreach var of varlist *Quinn_Transmission_rate {
  cap drop `var'_cat
  egen `var'_cat = cut(`var'), at(0, 3, 5, 100)
  tab `var'_cat
}

tempfile Point
save "`Point'"

***********************************************************************************************************
**************************************** HSE **************************************************************
***********************************************************************************************************
** I get the assets quintile index from the HSE datasets
foreach year in 2009 2010 2011 2012 {
use "$source\HSE`year'", clear
** for some reason the BSIntID var is named differently in some datasets
   if `year' <= 2005 {  
    rename BSIntId BSIntID
    display as text "`year'"  
    }
    else if  `year' > 2005 {
    rename ResidencyBSIntId BSIntID
    display as text "`year'"
    }
    fdate VisitDate 
    gen ExpYear = year(VisitDate)
    keep BSIntID ExpYear AssetIndexQuintile 
    tempfile HSE`year'
    save "`HSE`year''" 
}
** use a loop to append each dataset into one
use "`HSE2009'", clear
append using "`HSE2010'" 
append using "`HSE2011'" 
append using "`HSE2012'" 

duplicates drop BSIntID ExpYear AssetIndexQuintile , force
bysort BSIntID: egen HSE_mn = mean(AssetIndexQuintile)
replace AssetIndexQuintile = round(HSE_mn, 1) if missing(AssetIndexQuintile)
rename AssetIndexQuintile AIQ
keep if ExpYear==2011
duplicates drop BSIntID, force
keep BSIntID AIQ
tempfile HSE2011
save "`HSE2011'" 

***********************************************************************************************************
***********************************************************************************************************
***********************************************************************************************************
use "$source\MGH_Contacts2004to12", clear
append using "$source\WGH_Contacts2004to12"
rename IIntId IIntID
keep IIntID VisitDate PartnersInLastTwelveMonths 
fdate VisitDate
gen ExpYear = year(VisitDate)
keep if inrange(ExpYear, 2010, 2012)
drop if PartnersInLastTwelveMonths>11
bysort IIntID: gen P1 = PartnersInLastTwelveMonths if ExpYear==2011
bysort IIntID: egen Partners = max(P1)
bysort IIntID: gen P2010 = PartnersInLastTwelveMonths if ExpYear==2010
bysort IIntID: egen P2010m = max(P2010)
replace Partners = P2010m if missing(Partners)
bysort IIntID: gen P2012 = PartnersInLastTwelveMonths if ExpYear==2012
bysort IIntID: egen P2012m = max(P2012)
replace Partners = P2012m if missing(Partners)
tab Partners , miss
duplicates drop IIntID, force 
keep IIntID Partners
tempfile Partners
save "`Partners'" 

***********************************************************************************************************
**************************************** Mariatal *********************************************************
***********************************************************************************************************
use "$source\MGH_Contacts2004to12", clear
rename IIntId IIntID

keep IIntID VisitDate CurrentMaritalStatusName  

fdate VisitDate 
gen ExpYear = year(VisitDate)
drop if ExpYear > 2011

encode CurrentMaritalStatusName, gen(MaritalStatus1)
** tab MaritalStatus ,nolab
recode MaritalStatus1 (1/2 4 6/8 11 13 15 16 = 2 "Married") ///
  (3 12 14 = 3 "Polygamous") (9/10 5 17 = 1 "Single") (nonmiss = .), gen(Marital)

bysort IIntID (ExpYear): carryforward Marital, replace
keep if ExpYear==2011
duplicates drop IIntID, force

label define LblMarital 2 "Marital" 3 "Polygamous" 1 "Single"
label values Marital LblMarital
keep IIntID Marital

** Now bring in partners
merge 1:1 IIntID using "`Partners'", keep(1 3) nogen
replace Partners = 1 if inlist(Marital, 2, 3) & missing(Partners)
replace Partners = 0 if Marital==1 & missing(Partners)
egen PartnerCat = cut(Partners), at(0, 1, 2, 100)
tab Partners PartnerCat, miss
tab PartnerCat 

drop Partners
tempfile Marital
save "`Marital'" 

***********************************************************************************************************
**************************************** Individuals ******************************************************
***********************************************************************************************************
use "$source/RD01-01_ACDIS_Individuals", clear
keep IIntID DateOfBirth 
duplicates drop IIntID, force
tempfile Individuals
save "`Individuals'"

***********************************************************************************************************
**************************************** Demography *******************************************************
***********************************************************************************************************
** Bring in linked Demography data
use "$source/RD02-002_Demography", clear

** Dont need any obs other than 2011
keep if ExpYear == 2011

** Resident in BS in this year, drop if not
drop if missing(BSIntID)
keep IIntID BSIntID Sex ExpDays

** Drop duplicates as same BS per 1+ episode in 2011
duplicates drop IIntID BSIntID, force
bysort IIntID  : egen Count = count(BSIntID)
tab Count

/** Identify BS that ID spent most time in in 2011
bysort IIntID : egen MaxBS = max(ExpDays)
bysort IIntID: gen MaxBSID = BSIntID if (MaxBS==ExpDays)
collapse (firstnm) MaxBSID Sex, by(IIntID)
rename MaxBSID BSIntID
*/

** Bring in CVL, no match for BSIntId 17887
merge m:1 BSIntID using "`Point'", keep(match) nogen 

** Bring in surv dates
merge m:1 IIntID using "$derived/ac-HIV_Dates_2011", keep(match) nogen

** Bring in ages. 
merge m:1 IIntID using "`Individuals'" , keepusing(DateOfBirth) keep(match) nogen

gen Age = round((date("01-01-2011", "DMY")-DateOfBirth)/365.25, 1)
global ad = 12
drop if Age < $ad

** Make Age Category 
egen AgeGrp = cut(Age), at($ad, 20(5)90, 110) label icode
** Make this for AgeSex var
egen AgeGrp1 = cut(Age), at($ad, 20(5)45, 110) label icode

** Make new AgeSex Var
gen Female = (Sex==2)

encode(IsUrbanOrR) if IsUrbanOrR != "DFT", gen(urban)
drop IsUrbanOrR Sex ExpDays Count

merge m:1 BSIntID using "`HSE2011'" , keep(1 3) nogen
gen Replace = 1+int((5-1+1)*runiform())
replace AIQ = Replace if missing(AIQ)
drop Replace
merge m:1 IIntID using "`Marital'", keep(1 3) //nogen
replace Marital = 1 if missing(Marital) & Age < 18
** Ok randomly replace with 1-3
gen Replace = 1+int((3-1+1)*runiform())
replace Marital = Replace if missing(Marital)
tab Marital , miss
replace PartnerCat = 0 if missing(PartnerCat) & Age < 18
replace PartnerCat = rbinomial(2, 0.5) if missing(PartnerCat)
saveold "$derived/cvl-analysis2", replace

