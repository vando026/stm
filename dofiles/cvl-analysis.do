//  program:    analysis.do
//  task:	
//  project:	Name
//  author:     AV / Created: 19Jan2016

** The plan is to produce graphs for CVL and FVL by year 2011 and gender

***********************************************************************************************************
**************************************** Generate the Estimates *******************************************
***********************************************************************************************************
** Get summary stats for tables
foreach dat in FVL CVL {
  use "$derived/`dat'2011", clear 
  tab Sex
  tab Age
  sum ViralLoad, d
  ameans ViralLoad
  gen VLSuppr = (ViralLoad<1550) 
  tab VLSuppr 
}

** Now get summary estimates by age and sex
foreach dat in FVL CVL {
  use "$derived/`dat'2011", clear 
  cvlData ViralLoad Over50k, data(`dat') year(2011) 
}

***********************************************************************************************************
**************************************** Merge Estimates **************************************************
***********************************************************************************************************
foreach dat in gmn mn med 50 {
  foreach Sex in Male Female {
    use "$derived/CVL2011`Sex'_`dat'", clear
    label define LblData 1 "FVL" 2 "CVL", replace
    append using "$derived/FVL2011`Sex'_`dat'"
    label values Data LblData
    saveold "$derived/All2011`Sex'_`dat'", replace
  }
}


plotVL "$derived/All2011Female_gmn", name(Female_gmn) title(Females)
plotVL "$derived/All2011Male_gmn", name(Male_gmn) title(Males)
graph combine Female_gmn Male_gmn, rows(2)

plotVL "$derived/All2011Female_50", name(Female_50) title(Females)
plotVL "$derived/All2011Male_50", name(Male_50) title(Males)
graph combine Female_50 Male_50, rows(2)
 
shell 

