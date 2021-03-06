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
global output "$AC_Path/output1"

** This reads my personal ado files created for this project
adopath+ "$AC_Path/dofiles/ado"

** Impute VL values for undetectable in ARTemis dataset to correspond with Pop VL method
global VLImpute "Yes"

** date created
global today = subinstr("`=c(current_date)'"," ", "",.)
dis as text "$today"

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
do "$dofile/cvl-analysis1" 

