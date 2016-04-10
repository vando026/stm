//  program:    cvl-manage2.do
//  task:	Prep cvl data for analysis
//  project:	Name
//  author:     AV / Created: 30Jan2016 

***********************************************************************************************************
**************************************** Bring in Datasets*************************************************
***********************************************************************************************************
insheet using "$source/RegisteredPointLocationsMI_CVL+ARTEMIS.csv", clear
rename bsintid BSIntID

** lets rename these vars, too long
rename pvl_prev_vlbaboveldlyesnoincneg ppvl // population prev of detectable viremia. 
rename pvl_prev_vlbaboveyesno_gauss199 ppvlg //proportion  of pos suppressed
rename pvl_geo_mean_lnvlresultcopiesml pgm
rename art_prev_vlbaboveldlyesnoincneg apvl
rename art_geo_mean_lnvlresultcopiesml agm
rename art_prev_vlaboveldlyesno2011    apvlg //??
rename hiv8_2011_prev_trim_1 HIV_prev

foreach var of varlist ppvl-apvl {
  sum `var'
}

** Recode vars for analysis
gen ppvl_pc = ppvl*100
gen apvl_pc = apvl*100
gen ppvlg_pc = ppvlg*100
gen apvlg_pc = apvlg*100

sum ppvlg_pc
egen ppvl_pcat = cut(ppvl_pc), at(0, 15, 20, 110) icode label
tab ppvl_pcat
capture drop ppvlg_pcat
egen ppvlg_pcat = cut(ppvlg_pc), at(0, 65, 75, 110) icode label
tab ppvlg_pcat

replace pgm = 17000 if pgm > 17000
gen pgm1000 = pgm/1000
gen agm1000 = agm/1000
egen pgm1000_cat = cut(pgm1000), at(0, 5, 10,  17)
tab pgm1000_cat 

capture drop pgm_cat
egen pgm_cat = cut(pgm), at(0, 7000, 10000,  18000) icode
tab1 pgm1000_cat pgm_cat
sum pgm1000

gen HIVpc = HIV_prev * 100

capture drop HIV_pcat
egen HIV_pcat = cut(HIVpc), at(0, 12.5, 25, 100) icode label
tab HIV_pcat

tempfile Point
save "`Point'"

use "$source/RD01-01_ACDIS_Individuals", clear
keep IIntID DateOfBirth 
duplicates drop IIntID, force
tempfile Individuals
save "`Individuals'"

use "$source/ART Coverage and HIV prevalence by BS_final_v12", clear
keep BSIntID X_2011artcoverage_1
rename X_2011artcoverage_1 ARTCov2011
gen ARTCov2011_10 = ARTCov2011*10
tempfile ARTCov
save "`ARTCov'" 

insheet using "$source/logvl.csv", clear 
rename bsintid BSIntID
rename mean_log* mnLogVL 

summarize mnLogVL, meanonly
gen cmnLogVL =  mnLogVL - r(mean)

tempfile BS_CVL
save "`BS_CVL'" 

***********************************************************************************************************
**************************************** Demography *******************************************************
***********************************************************************************************************
** Bring in linked Demography data
use "$source/RD02-002_Demography", clear

** Dont need any obs other than 2011
keep if ExpYear == 2011

keep IIntID BSIntID Sex ExpDays
drop if missing(BSIntID)

** Drop duplicates as same BS per 1+ episode in 2011
** duplicates drop IIntID BSIntID, force
bysort IIntID  : gen Count = _N
tab Count

** Identify BS that ID spent most time in in 2011
bysort IIntID : egen MaxBS = max(ExpDays)
bysort IIntID: gen MaxBSID = BSIntID if (MaxBS==ExpDays)
collapse (firstnm) MaxBSID Sex, by(IIntID)
rename MaxBSID BSIntID

** Bring in CVL, no match for BSIntId 17887
merge m:1 BSIntID using "`Point'", keep(match) nogen 
merge m:1 BSIntID using "`BS_CVL'", keep(match) nogen

** Bring in ART cov
** merge m:1 BSIntID using "`ARTCov'", keep(1 3) nogen
** replace ARTCov2011 = runiform() if missing(ARTCov2011)
** drop if missing(ARTCov2011)

encode(isurbanorrural) if isurbanorrural != "DFT", gen(urban)
drop isurbanorrural
tempfile BS_dat
save "`BS_dat'" 

***********************************************************************************************************
**************************************** Single Rec HIV data***********************************************
***********************************************************************************************************
***********************************************************************************************************
use "$derived/ac-HIV_Dates_2011", clear

** Bring in CVL data
merge 1:m IIntID using "`BS_dat'", keep(match) nogen
distinct IIntID 

** Bring in ages. 
merge m:1 IIntID using "`Individuals'" , keepusing(DateOfBirth) keep(match) nogen

gen Age = round((date("01-01-2011", "DMY")-DateOfBirth)/365.25, 1)
global ad = 12
drop if Age < $ad

** Make Age Category 
egen AgeGrp = cut(Age), at($ad, 20(5)90, 110) label icode
** Make this for AgeSex var
egen AgeGrp1 = cut(Age), at($ad, 20(5)45, 110) label icode
tab AgeGrp1

** Make new AgeSex Var
gen Female = (Sex==2)
gen SexLab = cond(Sex==2, "F", "M")
generate AgeSex=SexLab + string(AgeGrp1)
encode AgeSex, gen(AgeSexCat)

** Cannot use i.var stata formate for stpm
tab AgeSexCat, gen(AF)
tab urban, gen(U)

save "$derived/cvl-analysis2", replace

