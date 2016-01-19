//  program:    cvl-communityVL.do
//  task:	Get community VL
//  project:	CVL
//  author:     AV / Created: 18Jan2016 


insheet using "$source/CommunityViralLoadWithARtemisData29jun2013.csv", clear 

fdate datereceivedatacvl datelastfollowedup, sfmt("YMD")
rename iintid IIntID

