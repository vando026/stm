//  program:    VL2011_12.do
//  task:		Produce VL for 2011 and 2012
//  project:	Misc
//  author:     AV / Created: 15Aug2015 

clear all
version 12.1

***********************************************************************************************************
**************************************** Set paths ********************************************************
***********************************************************************************************************
global AC_Data "$home/Documents/AC_Data/Derived/"
global AC_Source "$home/Documents/AC_Data/Source/"
global AC_Path "$dropbox/AfricaCentre/Projects/CommunityVL"
global dofile "$AC_Path/dofiles"

global source "$AC_Path/source"
global derived "$AC_Path/derived"
global output "$AC_Path/output"

** This reads my personal ado files created for this project
adopath+ "$AC_Path/dofiles/ado"

** Impute VL values for undetectable in ARTemis dataset to correspond with Pop VL method
global VLImpute "Yes"

** date created
global today = subinstr("`=c(current_date)'"," ", "",.)
dis as text "$today"

global PVLFem = "Yes"

if "$PVLFem" == "Yes" {
  set seed 2650
}
else {
  set seed 2013
}

***********************************************************************************************************
**************************************** Run do files *****************************************************
***********************************************************************************************************
** The dofiles are to be run in the following sequence
** This dofile prepares the repeat-tester seroconverion dates
do "$dofile/HIVSurveillance2011"

** This dofile prepares all the CVL and FVL data for analysis
** do "$dofile/cvl-manage"
** do "$dofile/DiegoDat"

** This dofile prepares the data for Cox analysis
do "$dofile/cvl-manage2"

** This dofile prepares the graphs (note it relies on an adofile)
** do "$dofile/cvl-analysis"

** This dofile does Cox models
if "$PVLFem" == "Yes" {
  do "$dofile/cvl-analysis2females"
}
else  {
  do "$dofile/cvl-analysis2"
}

** This does incidence by quartile
do "$dofile/cvl-analysis3" 


local st 2551
local stop 2750
local sn = `stop' - `st' + 1
mat TT = J(`sn', 3, .)
local j = 1
** The dofiles are to be run in the following sequence
forvalue i = `st'/`stop' {
set seed `i'
** This dofile prepares the repeat-tester seroconverion dates
qui do "$dofile/HIVSurveillance2011"

** This dofile prepares the data for Cox analysis
qui do "$dofile/cvl-manage2"

qui use "$derived/cvl-analysis2", clear
qui stset  EndDate, failure(SeroConvertEvent==1) entry(EarliestHIVNegative) ///
  origin(EarliestHIVNegative) scale(365.25) 

** Set covariates here once, so you dont have to do it x times for x models
qui stcox P_PDV  i.HIV_pcat i.AgeGrp1 ib1.urban ib1.Marital ib0.PartnerCat ib1.AIQ if Female==0
mat PMVL = r(table)
qui stcox P_CTI  i.HIV_pcat i.AgeGrp1 ib1.urban ib1.Marital ib0.PartnerCat ib1.AIQ if Female==0
mat TI = r(table)
mat TT[`j', 1] = `i'
mat TT[`j', 2] = PMVL[4, 1]
mat TT[`j', 3] = TI[4, 1]
dis as text "Iter `j'"
local pdv = TT[`j', 2]
local cti = TT[`j', 3]
if `cti'<=0.05 & `pdv'<=0.05 {
  dis as text _n "Iter `i': PPDV=`pdv' | CTI=`cti'" 
}
local ++j
}

mat list TT
