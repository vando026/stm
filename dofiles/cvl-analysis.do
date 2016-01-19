//  program:    analysis.do
//  task:	
//  project:	Name
//  author:     AV / Created: 19Jan2016

***********************************************************************************************************
**************************************** Analyze **********************************************************
***********************************************************************************************************
** Prop over VL 50000
gen Over50k = cond(ViralLoad>=50000, 1, 0)

** Plot
foreach year in 2011 2012 {
  ciplot ViralLoad if TestYear==`year' & Sex==2, by(Age) title("`year': Females") name(F`year')
  ciplot ViralLoad if TestYear==`year' & Sex==1, by(Age) title("`year': Males") name(M`year')
}
graph combine F2011 M2011 F2012 M2012, col(2) iscale(0.5) saving("$derived/VLplot")

foreach year in 2011 2012 {
  ciplot Over50k if TestYear==`year' & Sex==2, by(Age) title("`year': Females") name(F`year'_)
  ciplot Over50k if TestYear==`year' & Sex==1, by(Age) title("`year': Males") name(M`year'_)
}
graph combine F2011_ M2011_ F2012_ M2012_, col(2) iscale(0.5) saving("$derived/Prop50k", replace)


statsby mean50k=r(mean) sd50k=r(sd), ///
    by(TestYear Sex Age) saving("$derived/Over50k", replace): sum Over50k, d

statsby mean=r(mean) sd=r(sd) median=r(p50) q1=r(p25) q3=r(p75), ///
    by(TestYear Sex Age) clear: sum ViralLoad, d

merge 1:1 TestYear Sex Age using "$derived/Over50k", nogen
list *, clean
rename ViralLoad VLClinic

