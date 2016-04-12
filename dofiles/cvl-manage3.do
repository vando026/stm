//  program:    cvl-manage3.do
//  task:	Bring in demographic vars
//  project:	CVL
//  author:     AV / Created: 11Apr2016 


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
merge m:1 IIntID using "$derived/cvl-main2", keep(2 3)
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
append using "$source\WGH_Contacts2004to12"
rename IIntId IIntID
merge m:1 IIntID using "$derived/cvl-main2", keep(2 3)

tab _merge
keep IIntID VisitDate CurrentMaritalStatusName  

fdate VisitDate 
gen ExpYear = year(VisitDate)

tab CurrentMaritalStatusName , nolab
encode CurrentMaritalStatusName, gen(MaritalStatus)
** tab MaritalStatus ,nolab
recode MaritalStatus (1/2 4 6/8 11 13 15 16 = 2 "Married") ///
  (3 12 14 = 3 "Polygamous") (9/10 5 17 = 1 "Single") (nonmiss = .), gen(MaritalStatus1)

bysort IIntID (ExpYear): carryforward MaritalStatus1, replace
bysort IIntID: gen m1 = MaritalStatus1 if ExpYear==2012
** Give preference to marital status 2012
bysort IIntID: egen Marital = min(m1)
** If not  in 2012 get last recent Marital
bysort IIntID (VisitDate): egen LastMarital = max(ExpYear) if !missing(MaritalStatus1)
bysort IIntID: gen LM1 =  MaritalStatus1  if LastMarital == ExpYear
bysort IIntID: egen LM2 = max(LM1)
replace Marital = LM2 if missing(Marital)
duplicates drop IIntID, force
label define LblMarital 2 "Marital" 3 "Polygamous" 1 "Single"
label values Marital LblMarital
** Ok randomly replace with 1-3
gen Replace = 1+int((3-1+1)*runiform())
replace Marital = Replace if missing(Marital)
tab Marital , miss
keep IIntID Marital

** Now bring in partners
merge 1:1 IIntID using "`Partners'", nogen
replace Partners = 1 if inlist(Marital, 2, 3) & missing(Partners)
replace Partners = 0 if Marital==1 & missing(Partners)
egen PartnerCat = cut(Partners), at(0, 1, 2, 100)
tab Partners PartnerCat, miss
tab PartnerCat 

drop Partners
tempfile Marital
save "`Marital'" 

***********************************************************************************************************
************************************* Merge All ***********************************************************
***********************************************************************************************************
use "$derived/cvl-main2", clear
merge m:1 BSIntID using "`HSE2011'" , keep(1 3) nogen
gen Replace = 1+int((5-1+1)*runiform())
replace AIQ = Replace if missing(AIQ)
drop Replace
merge 1:1 IIntID using "`Marital'", nogen
saveold "$derived/cvl-analysis2", replace
