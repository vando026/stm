//  program:    VL2011_12.do
//  task:		Produce VL for 2011 and 2012
//  project:	Misc
//  author:     AV / Created: 15Aug2015 

clear all
version 12.1
** capture ssc install ciplot

global root "C:\Users\\`c(username)'"
global AC_Data "$root\Documents\AC_Data"
global AC_Path "$dropbox/AfricaCentre/Projects/CommunityVL"
global dofile "$AC_Path/dofiles"

global source "$AC_Data\Source"
global derived "$AC_Data\Derived/CommunityVL"
global output "$AC_Path/output"

adopath+ "$AC_Path/dofiles/ado"


** Impute VL values for undetectable in ARTemis dataset to correspond with Pop VL method
global VLImpute "Yes"

** Use random imputation for censored intervals
global method "random"

** Which end date to use: imputed date or earliestHIVpos
global impute "no"


** run dofiles
do "$dofile/HIVSurveillance2011"
do "$dofile/cvl-manage2"
