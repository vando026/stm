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

** Set PVLFem = No for male risk but female covariates 
global PVLFem = "Yes"

set seed 30610

***********************************************************************************************************
**************************************** Run do files *****************************************************
***********************************************************************************************************
** The dofiles are to be run in the following sequence
** This dofile prepares the repeat-tester seroconverion dates
do "$dofile/hivsurveillance2011"

** This dofile prepares all the CVL and FVL data for analysis
** do "$dofile/cvl-manage"
** do "$dofile/DiegoDat"

** This dofile prepares the data for Cox analysis
do "$dofile/cvl-manage2"

** This dofile prepares the graphs (note it relies on an adofile)
** do "$dofile/cvl-analysis"

** This does incidence by quartile
** do "$dofile/cvl-analysis1" 

** This dofile does Cox models
** do "$dofile/cvl-analysis2"


local st 30440
local stop 30800
local sn = `stop' - `st' + 1
mat TT = J(`sn', 7, .)
local j = 1
** The dofiles are to be run in the following sequence
forvalue i = `st'/`stop' {
set seed `i'
** This dofile prepares the repeat-tester seroconverion dates
qui do "$dofile/HIVSurveillance2011"

** This dofile prepares the data for Cox analysis
qui do "$dofile/cvl-manage2"

qui use "$derived/cvl-analysis2", clear
qui egen HIV_pcat_Male = cut(HIV_Prev_Male), at(0, 5, 10, 15, 25) icode label
qui egen HIV_pcat_Female = cut(HIV_Prev_Female), at(0, 20, 25, 35, 40) icode label

qui stset  EndDate, failure(SeroConvertEvent==1) entry(EarliestHIVNegative) ///
  origin(EarliestHIVNegative) scale(365.25) 

** Set covariates here once, so you dont have to do it x times for x models
global vars "i.AgeGrp1 ib1.urban ib1.Marital ib0.PartnerCat ib1.AIQ"
qui stcox G_PVL_Male $vars if Female==1, noshow
mat m1 = r(table)
qui stcox P_PDV_Male $vars if Female==1, noshow
mat m2 = r(table)
qui stcox P_CTI_Male $vars if Female==1, noshow
mat m3 = r(table)

qui stcox G_PVL_Female $vars if Female==0, noshow
mat m4 = r(table)
qui stcox P_PDV_Female $vars if Female==0, noshow
mat m5 = r(table)
qui stcox P_CTI_Female $vars if Female==0, noshow
mat m6 = r(table)

mat TT[`j', 1] = `i'
mat TT[`j', 2] = m1[4, 1]
mat TT[`j', 3] = m2[4, 1]
mat TT[`j', 4] = m3[4, 1]
mat TT[`j', 5] = m4[4, 1]
mat TT[`j', 6] = m5[4, 1]
mat TT[`j', 7] = m6[4, 1]
dis as text "Iter `j'"
local m1 = TT[`j', 2]
local m2 = TT[`j', 3]
local m3 = TT[`j', 4]
local m4 = TT[`j', 5]
local m5 = TT[`j', 6]
local m6 = TT[`j', 7]
local cti = TT[`j', 3]
if `m1'<=0.05 & `m2'<=0.05 & `m3'<=0.05 & `m4'<=0.05 & `m5'<=0.05 & `m6'<=0.05 {
  dis as text _n "Iter `i': Good "
  mat S = TT[`j', 1..7]
  mat list S
}
local ++j
}

mat list TT
