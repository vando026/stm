//  program:    VL2011_12.do
//  task:		Produce VL for 2011 and 2012
//  project:	Misc
//  author:     AV / Created: 15Aug2015 

clear all
version 12.1
capture ssc install ciplot

global AC_Path "$dropbox/AfricaCentre/Projects/CommunityVL"
global dofile "$AC_Path/dofiles"

global source "$AC_Path/source"
global derived "$AC_Path/derived"
global output "$AC_Path/output"

adopath+ "$AC_Path/dofiles/ado"


** Impute VL values for undetectable in ARTemis dataset to correspond with Pop VL method
global VLImpute "Yes"

** Use random imputation for censored intervals
global method "random"

***********************************************************************************************************
**************************************** Run do files *****************************************************
***********************************************************************************************************
** The dofiles are to be run in the following sequence

** This dofile prepares the repeat-tester seroconverion dates
do "$dofile/HIVSurveillance2011"

** This dofile prepares all the CVL and FVL data for analysis
do "$dofile/cvl-manage"

** This dofile prepares the graphs (note it relies on an adofile)
do "$dofile/cvl-analysis"

** This dofile prepares the data for Cox analysis
do "$dofile/cvl-manage2"

** This dofile does Cox models
do "$dofile/cvl-analysis2"



