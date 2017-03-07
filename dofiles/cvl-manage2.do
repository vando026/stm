//  program:    cvl-manage2.do
//  task:	Prep cvl data for analysis
//  project:	Name
//  author:     AV / Created: 30Jan2016 

***********************************************************************************************************
**************************************** Bring in Datasets*************************************************
***********************************************************************************************************
import excel using "$source/Viral_load_estimation_Dec02.xls", clear firstrow 
drop FID
tempfile PVL
save "`PVL'" 

** This brings in the FVL data
import excel using "$source/Viral_load_estimation_Oct12.xls", clear firstrow 
keep BSIntID IsUrbanOrR FVL_* 
tempfile FVL
save "`FVL'" 

import excel using "$source/Viral_load_estimation_Nov05.xls", clear firstrow 
keep BSIntID G_FVL
tempfile G_FVL
save "`G_FVL'" 


import excel using "$source/Viral_load_estimation_Oct22.xls", clear firstrow 
keep BSIntID G_MVL PDV TI
merge 1:1 BSIntID using "`PVL'" , nogen
merge 1:1 BSIntID using "`FVL'", nogen
merge 1:1 BSIntID using "`G_FVL'", nogen

** I have to format vars from Diego file
foreach var of varlist * {
  qui ds `var', has(type string)
  if "`=r(varlist)'" != "." {
    replace `var' = "" if `var'=="NA"
    destring `var', replace
  }
}

** Make HIV prev a percent
replace P_PDV = P_PDV * 100
gen HIV_Prev = HIV_Prevalence * 100
egen HIV_pcat = cut(HIV_Prev), at(0, 15, 25, 100) icode label
tab HIV_pcat


encode(IsUrbanOrR) , gen(urban_ec)
tab urban_ec 
gen Replace = 2+int((4-1)*runiform())
replace urban_ec = Replace if urban_ec==1
recode urban_ec (3=1) (1=2) (4=3), gen(urban)
tab urban urban_ec
label define LblRural 1 "Rural" 2 "Peri" 3 "Urban"
label values urban LblRural
drop urban_ec IsUrbanOrR Replace

tempfile Point
save "`Point'"


***********************************************************************************************************
****************************************  Get BS for 2011 *************************************************
***********************************************************************************************************
** Bring in linked Demography data
use "$AC_Data/Demography/2015/RD02-002_Demography", clear

** Dont need any obs other than 2011
keep if ExpYear == 2011

** Resident in BS in this year, drop if not
drop if missing(BSIntID)
collapse (sum) ExpDays , by(BSIntID IIntID)

** Identify BS that ID spent most time in in 2011
bysort IIntID : egen MaxBS = max(ExpDays)
bysort IIntID: gen MaxBSID = BSIntID if (MaxBS==ExpDays)
collapse (firstnm) MaxBSID , by(IIntID)
rename MaxBSID BSIntID

tempfile MaxBS
save "`MaxBS'" 

***********************************************************************************************************
**************************************** Now get matches **************************************************
***********************************************************************************************************
use "$derived/ac-HIV_Dates_2011", clear
merge 1:m IIntID using "`MaxBS'", keep(match) nogen
merge m:1 BSIntID using "`Point'", keep(match) nogen 
tempfile AllData
save "`AllData'" 
preserve
  duplicates drop BSIntID, force
  keep BSIntID
  tempfile AllBSIntID
  save "`AllBSIntID'" 
restore
preserve
  duplicates drop IIntID, force
  keep IIntID
  tempfile AllIIntID
  save "`AllIIntID'" 
restore

***********************************************************************************************************
**************************************** HSE **************************************************************
***********************************************************************************************************
** I get the assets quintile index from the HSE datasets
foreach year in 2009 2010 2011 2012 {
use "$AC_Data/HSE/HSE`year'", clear
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

***********************************************************************************************************
***********************************************************************************************************
***********************************************************************************************************
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

merge 1:1 BSIntID using "`AllBSIntID'", keep(2 3) nogen 
set seed 2000000
gen Replace = 1+int((5-1+1)*runiform())
replace AIQ = Replace if missing(AIQ)
drop Replace
tempfile HSE2011
save "`HSE2011'" 


***********************************************************************************************************
******************************************* Individuals ***************************************************
***********************************************************************************************************
use "$AC_Data/Individuals/2015/RD01-01_ACDIS_Individuals", clear
gen Age = round((date("01-01-2011", "DMY")-DateOfBirth)/365.25, 1)
duplicates drop IIntID, force
tempfile Individuals
gen Female = (Sex==2)
keep IIntID Age Female 
save "`Individuals'"

***********************************************************************************************************
************************************** Partners Marital ***************************************************
***********************************************************************************************************
use "$AC_Data/WGH_MGH/MGH_Contacts2004to12", clear
append using "$AC_Data/WGH_MGH\WGH_Contacts2004to12"
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
use "$AC_Data/WGH_MGH\MGH_Contacts2004to12", clear
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

merge m:1 IIntID using "`Individuals'", keep(2 3) nogen
merge m:1 IIntID using "`AllIIntID'", keep(2 3) nogen

replace Marital = 1 if missing(Marital) & Age < 18
** Ok randomly replace with 1-3
set seed 2000000
gen Replace = 1+int((3-1+1)*runiform())
replace Marital = Replace if missing(Marital)
tab Marital , miss
replace PartnerCat = 0 if missing(PartnerCat) & Age < 18
set seed 2000000
replace PartnerCat = rbinomial(2, 0.5) if missing(PartnerCat)
drop Replace Partners
tempfile Ind
save "`Ind'" 

***********************************************************************************************************
**************************************** Bring in Datasets*************************************************
***********************************************************************************************************
use "`AllData'", clear

merge m:1 IIntID using "`Ind'", keep(match) nogen 
merge m:1 BSIntID using "`HSE2011'", keep(match) nogen 

gen Keep = . 
replace Keep = 1 if inrange(Age, 15, 55) & Female == 0
replace Keep = 1 if inrange(Age, 15, 50) & Female == 1
keep if Keep == 1
drop Keep

** Make Age Category 
egen AgeGrp1 = cut(Age), at(15(5)45, 100) label icode

foreach var of varlist PDV - AgeGrp1 {
  qui keep if !missing(`var')
    ** dis as text `var' 
}

saveold "$derived/cvl-analysis2", replace

** Bring in surv dates
