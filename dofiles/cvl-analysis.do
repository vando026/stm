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
  sav "$derived/All2011`Sex'_`dat'", replace
  }
}


plotVL "$derived/All2011Female_gmn", name(Female_gmn)
plotVL "$derived/All2011Male_gmn", name(Male_gmn)


graph combine Male_gmn


  

  title("`VLname': `sex'") ///
  name("`gname'", replace) note(`gnote')

statsby mean=r(mean_g) lb=r(lb_g) ub=r(ub_g) Data=1, by(Age) saving("$derived/test", replace): /// 
      ameans ViralLoad if TestYear==2011 & Sex==1

/*
statsby mean50k=r(mean) sd50k=r(sd), ///
    by(TestYear Sex Age) saving("$derived/Over50k", replace): sum Over50k, d

statsby mean=r(mean) sd=r(sd) median=r(p50) q1=r(p25) q3=r(p75), ///
    by(TestYear Sex Age) clear: sum ViralLoad, d

merge 1:1 TestYear Sex Age using "$derived/Over50k", nogen
list *, clean
rename ViralLoad VLClinic

