//  program:    VL2011_12.do
//  task:		Produce VL for 2011 and 2012
//  project:	Misc
//  author:     AV / Created: 15Aug2015 

clear all
version 12.1

***********************************************************************************************************
**************************************** Set paths ********************************************************
***********************************************************************************************************
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

***********************************************************************************************************
**************************************** Run do files *****************************************************
***********************************************************************************************************
** The dofiles are to be run in the following sequence
** This dofile prepares the repeat-tester seroconverion dates
do "$dofile/HIVSurveillance2011"

** This dofile prepares all the CVL and FVL data for analysis
** do "$dofile/cvl-manage"
do "$dofile/DiegoDat"

** This dofile prepares the data for Cox analysis
do "$dofile/cvl-manage2"

** This dofile prepares the graphs (note it relies on an adofile)
** do "$dofile/cvl-analysis"

** This dofile does Cox models
do "$dofile/cvl-analysis2"



mat TT = J(20, 3, .)
local j = 1
** The dofiles are to be run in the following sequence
forvalue i = 2001/2020 {
set seed `i'
** This dofile prepares the repeat-tester seroconverion dates
qui do "$dofile/HIVSurveillance2011"

** This dofile prepares the data for Cox analysis
qui do "$dofile/cvl-manage2"

qui stset  EndDate, failure(SeroConvertEvent==1) entry(EarliestHIVNegative) ///
  origin(EarliestHIVNegative) scale(365.25) 

** Set covariates here once, so you dont have to do it x times for x models
qui stcox G_PVL i.AgeGrp1 Female b3.urban ib1.Marital ib0.PartnerCat ib1.AIQ
mat PMVL = r(table)
qui stcox P_TI i.AgeGrp1 Female b3.urban ib1.Marital ib0.PartnerCat ib1.AIQ
mat TI = r(table)
mat TT[`j', 1] = `i'
mat TT[`j', 2] = PMVL[4, 1]
mat TT[`j', 3] = TI[4, 1]
dis as text "Iter `j'"
local ++j
}
mat list TT
