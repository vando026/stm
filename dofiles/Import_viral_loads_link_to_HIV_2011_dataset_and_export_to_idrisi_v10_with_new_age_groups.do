clear

use "C:\research\africa_C\ACDIS datasets\ACDIS_A20130701\HIV\HIV_Contacts_2003to12.dta" 


*******Create Year of first eligibility
replace VisitDate = dofc(VisitDate)
gen Year = year(VisitDate)
keep IIntId Year
collapse (min) Year, by (IIntId)

sort IIntId
rename IIntId IIntID 
save "C:\research\africa_C\Community viral load\All community viral loads\HIVYearFirstEligible.dta", replace

/******************Import viral loads
clear
insheet using "C:\research\africa_C\Community viral load\All community viral loads\CommunityViralLoadWithARtemisData29jun2013.csv", comma

*** The version of the Biocentric Generic HIV Charge Virale (ed.2012-10-02/GB)
***The lowest detectible limit has been calculated at 1550 copies/ml for this batch of specimens (as determined from our previous work).
***Total number of specimens on the list was 2456, with 36 specimens excluded due to being insufficient for testing, thus 2420 were tested.
***Of these, 30% (726) were below the detectable limit.

summ vlresultcopiesml

summ vlresultcopiesml, detail
summ vlresultcopiesml if vlbelowldl != "Yes", detail
means  vlresultcopiesml
summ vlresultcopiesml if vlbelowldl != "Yes"

set seed 339487731
gen RandomUndetectable =int(1500*runiform()) if vlbelowldl == "Yes"
replace vlresultcopiesml=RandomUndetectable if  vlbelowldl=="Yes"


gen Lnvlresultcopiesml = ln(vlresultcopiesml)
gen Logvlresultcopiesml = log(vlresultcopiesml)
ren iintid  IIntID
sort IIntID
save "C:\research\africa_C\Community viral load\All community viral loads\CommunityViralLoadWithIIntId10dec2012.dta", replace
*/


***Link to 2011 HIV surveillance dataset
use "C:\research\africa_C\ACDIS datasets\ACDIS_A20130110\HIV\HIV_2011.dta" 
duplicates drop IIntID, force
merge 1:1 IIntID using "C:\research\africa_C\Community viral load\All community viral loads\CommunityViralLoadWithIIntId10dec2012.dta"

drop if _merge ==2
drop _merge
sort BSIntID
rename BSIntID BSIntId
merge BSIntId using "C:\research\africa_C\ACDIS datasets\LiveACDIS\RegisteredPointLocations_UTM_30-01-2013", keep(Latitude Longitude)

*****Link to ARTEMIS
drop _merge
duplicates drop IIntID, force
merge 1:1 IIntID using "C:\research\africa_C\ACDIS datasets\ACDIS_A20140101\RD10-01 All Artemis Persons_Valid IIntID.dta", keepusing (DateOfInitiation DateLastFollowedUp) 
drop if _merge ==2

gen temp = date(DateOfInitiation, "YMD")
drop  DateOfInitiation
rename temp DateOfInitiation
format DateOfInitiation %td


gen temp = date(DateLastFollowedUp, "YMD")
drop  DateLastFollowedUp
rename temp DateLastFollowedUp
format DateLastFollowedUp %td



****transform vlbelowldl an create OnTreatment variablereplace vlbelowldl ="No" if vlresultcopiesml!=. & vlbelowldl!="Yes"
gen OnTreatment=1 if (DateOfInitiation <  dofc(VisitDate)) 
replace OnTreatment=0 if vlresultcopiesml!=. & OnTreatment==.

gen OnTreatment12Months=1 if (dofc(VisitDate)-DateOfInitiation)>365 & DateOfInitiation!=.
replace OnTreatment12Months=0 if vlresultcopiesml!=. & OnTreatment12Months==.

gen OnTreatment12MonthsActive=1 if (dofc(VisitDate)-DateOfInitiation)>365 & DateLastFollowedUp>dofc(VisitDate)& DateOfInitiation!=.
replace OnTreatment12MonthsActive=0 if vlresultcopiesml!=. & OnTreatment12MonthsActive==.

gen VLBbelowldlYesNo = 1 if vlbelowldl == "Yes"
replace VLBbelowldlYesNo = 0 if vlbelowldl != "Yes" & vlresultcopiesml!=.

gen OnTreatmentOrSupressed= OnTreatment
replace OnTreatmentOrSupressed= 1 if VLBbelowldlYesNo==1


tab OnTreatment VLBbelowldlYesNo
tab OnTreatment12Months VLBbelowldlYesNo
tab OnTreatment12MonthsActive VLBbelowldlYesNo


**********Create Age groups
generate Age = (dofc(VisitDate)-dofc(DateOfBirth))/365.25

generate agegrp=.
replace agegrp=1 if Age>=12& Age<25
replace agegrp=2 if Age>=25& Age<35
replace agegrp=3 if Age>=35& Age<45
replace agegrp=4 if Age>=45& Age<55
replace agegrp=5 if Age>=55& Age<200



label define agegrp_lab 1 "15-24" 2 "25-34" 3"35-44" 4"45-54" 5">=55" 
label values agegrp agegrp_lab


****Merge year fist eligible data
drop _merge
merge 1:1 IIntID using "C:\research\africa_C\Community viral load\All community viral loads\HIVYearFirstEligible.dta"
drop if _merge ==2
rename Year YearFirstEligible


****Summarize by age and sex
bysort agegrp: centile vlresultcopiesml if Latitude!=. & Lnvlresultcopiesml!=. & Sex=="MAL"
bysort agegrp: centile vlresultcopiesml if Latitude!=. & Lnvlresultcopiesml!=. & Sex=="FEM"


bysort agegrp: centile vlresultcopiesml if Latitude!=. & Lnvlresultcopiesml!=. & OnTreatment!=1 & Sex=="MAL"
bysort agegrp: centile vlresultcopiesml if Latitude!=. & Lnvlresultcopiesml!=. & OnTreatment!=1 & Sex=="FEM"


bysort agegrp: centile vlresultcopiesml if Latitude!=. & Lnvlresultcopiesml!=. & OnTreatment==1 & Sex=="MAL"
bysort agegrp: centile vlresultcopiesml if Latitude!=. & Lnvlresultcopiesml!=. & OnTreatment==1 & Sex=="FEM"

bysort agegrp: centile vlresultcopiesml if Latitude!=. & Lnvlresultcopiesml!=. & OnTreatmentOrSupressed!=1 & Sex=="MAL"
bysort agegrp: centile vlresultcopiesml if Latitude!=. & Lnvlresultcopiesml!=. & OnTreatmentOrSupressed!=1 & Sex=="FEM"

bysort agegrp: centile vlresultcopiesml if Latitude!=. & Lnvlresultcopiesml!=. & OnTreatmentOrSupressed==1 & Sex=="MAL"
bysort agegrp: centile vlresultcopiesml if Latitude!=. & Lnvlresultcopiesml!=. & OnTreatmentOrSupressed==1 & Sex=="FEM"





gen vlresult_10000=1 if vlresultcopiesml>=10000
replace vlresult_10000=0 if vlresultcopiesml<10000|VLBbelowldlYesNo == 1
mean vlresult_10000 if Latitude!=. & Lnvlresultcopiesml!=. & Sex=="MAL", over (agegrp)
mean vlresult_10000 if Latitude!=. & Lnvlresultcopiesml!=. & Sex=="FEM", over (agegrp)
graph bar (mean) vlresult_10000 if Latitude!=. & Lnvlresultcopiesml!=., over(Sex) over(agegrp)


gen vlresult_50000=1 if vlresultcopiesml>=50000
replace vlresult_50000=0 if vlresultcopiesml<50000|VLBbelowldlYesNo == 1
mean vlresult_50000 if Latitude!=. & Lnvlresultcopiesml!=. & Sex=="MAL", over (agegrp)
mean vlresult_50000 if Latitude!=. & Lnvlresultcopiesml!=. & Sex=="FEM", over (agegrp)
graph bar (mean) vlresult_50000 if Latitude!=. & Lnvlresultcopiesml!=., over(Sex) over(agegrp)


gen vlresult_100000=1 if vlresultcopiesml>=100000
replace vlresult_100000=0 if vlresultcopiesml<100000|VLBbelowldlYesNo == 1
mean vlresult_100000 if Latitude!=. & Lnvlresultcopiesml!=. & Sex=="MAL", over (agegrp)
mean vlresult_100000 if Latitude!=. & Lnvlresultcopiesml!=. & Sex=="FEM", over (agegrp)
graph bar (mean) vlresult_100000 if Latitude!=. & Lnvlresultcopiesml!=., over(Sex) over(agegrp)

bysort YearFirstEligible: centile vlresultcopiesml if Latitude!=. & Lnvlresultcopiesml!=. & OnTreatment==1 & Sex=="MAL"
bysort YearFirstEligible: centile vlresultcopiesml if Latitude!=. & Lnvlresultcopiesml!=. & OnTreatment==1 & Sex=="FEM"

regress Lnvlresultcopiesml i.YearFirstEligible
char YearFirstEligible [omit]"2011"
logistic vlresult_50000 i.YearFirstEligible if YearFirstEligible<2012 & YearFirstEligible>2004

xi:logistic vlresult_50000 i.agegrp i.Sex i.YearFirstEligible if YearFirstEligible<2012 & YearFirstEligible>2004


**Proportion test Males vs Females >50,000 copies
gen SexNum = 1 if Sex=="MAL"
replace SexNum = 2 if Sex=="FEM"
bysort agegrp:prtest vlresult_50000 if Latitude!=. & Lnvlresultcopiesml!=., by(SexNum)



****Histogram by sex
histogram Lnvlresultcopiesml if vlresultcopiesml>0 & OnTreatment==0, by(Sex) normal


****Export viral loads random viral load for <1500 (idrisi)
outsheet Longitude Latitude Lnvlresultcopiesml using "C:\research\africa_C\Community viral load\All community viral loads\AllLnvlresultcopiesml.txt" if Latitude!=. & Lnvlresultcopiesml!=., replace nonames noquote
outsheet Longitude Latitude vlresultcopiesml using "C:\research\africa_C\Community viral load\All community viral loads\Allvlresultcopiesml.txt" if Latitude!=. & vlresultcopiesml!=., replace nonames noquote

outsheet Longitude Latitude Logvlresultcopiesml using "C:\research\africa_C\Community viral load\All community viral loads\AllLoglresultcopiesml.txt" if Latitude!=. & Lnvlresultcopiesml!=., replace nonames noquote





****Export viral loads random viral load for <1500 (Satscan)
gen temp=1
gen temp1=2000
outsheet BSIntID temp temp1 Lnvlresultcopiesml using "C:\research\africa_C\Community viral load\All community viral loads\Lnvlresultcopiesml.cas" if Latitude!=. & Lnvlresultcopiesml!=., replace nonames
outsheet BSIntID Latitude Longitude using "C:\research\africa_C\Community viral load\All community viral loads\AllBS.geo" if Latitude!=., replace nonames

****For comparison set all undetectable viral loads to one (idrisi)
gen temp = vlresultcopiesml
replace temp = 1 if  vlbelowldl=="Yes"
gen temp1= ln(temp)

outsheet Longitude Latitude temp1 using "C:\research\africa_C\Community viral load\All community viral loads\AllLnvlresultcopiesml_undecSetToOne.txt" if Latitude!=. & Lnvlresultcopiesml!=., replace nonames noquote
outsheet Longitude Latitude temp using "C:\research\africa_C\Community viral load\All community viral loads\Allvlresultcopiesml_undecSetToOne.txt" if Latitude!=. & vlresultcopiesml!=., replace nonames noquote

****Export viral loads for all individuals in the cohort including negatives
gen vlresultcopiesmlIncNeg = vlresultcopiesml + 1
replace vlresultcopiesmlIncNeg = 1 if HIVResult=="N"
gen LnvlresultcopiesmlIncNeg = ln(vlresultcopiesmlIncNeg)

outsheet BSIntID temp temp1 LnvlresultcopiesmlIncNeg using "C:\research\africa_C\Community viral load\All community viral loads\LnvlresultcopiesmlIncNeg.cas" if Latitude!=. & LnvlresultcopiesmlIncNeg!=., replace nonames
outsheet Longitude Latitude LnvlresultcopiesmlIncNeg  using "C:\research\africa_C\Community viral load\All community viral loads\LnvlresultcopiesmlIncNeg.txt" if Latitude!=. & LnvlresultcopiesmlIncNeg !=., replace nonames noquote

****To calculate % suppressed 
outsheet BSIntID temp temp1 using "C:\research\africa_C\Community viral load\All community viral loads\VLBbelowldlYesNo.ctl" if Latitude!=. & VLBbelowldlYesNo==1, replace nonames
outsheet BSIntID temp temp1 using "C:\research\africa_C\Community viral load\All community viral loads\VLBbelowldlYesNo.cas" if Latitude!=. & VLBbelowldlYesNo==0, replace nonames



outsheet Longitude Latitude VLBbelowldlYesNo using "C:\research\africa_C\Community viral load\All community viral loads\VLBbelowldlYesNo.txt" if Latitude!=. & Lnvlresultcopiesml!=., replace nonames noquote


****To calculate % suppressed including negatives
gen VLBbelowldlYesNoIncNeg = VLBbelowldlYesNo
replace VLBbelowldlYesNoIncNeg = 1 if HIVResult=="N"

outsheet BSIntID temp temp1 using "C:\research\africa_C\Community viral load\All community viral loads\VLBbelowldlYesNoIncNeg.ctl" if Latitude!=. & VLBbelowldlYesNoIncNeg==1, replace nonames
outsheet BSIntID temp temp1 using "C:\research\africa_C\Community viral load\All community viral loads\VLBbelowldlYesNoIncNeg.cas" if Latitude!=. & VLBbelowldlYesNoIncNeg==0, replace nonames

outsheet Longitude Latitude VLBbelowldlYesNoIncNeg using "C:\research\africa_C\Community viral load\All community viral loads\VLBbelowldlYesNoIncNeg.txt" if Latitude!=. & VLBbelowldlYesNoIncNeg!=., replace nonames noquote





*********************Create Prevalence maps for 2011 (idrisi)
replace HIVResult="1" if HIVResult=="P"
replace HIVResult="0" if HIVResult=="N" 
replace HIVResult="1" if HIVResult=="p"
replace HIVResult="0" if HIVResult=="n"


outsheet Longitude Latitude IIntID using "C:\research\africa_C\Community viral load\All community viral loads\HIV8_2011_TotalEligible.txt" if Resident=="Y", replace nonames noquote
outsheet Longitude Latitude HIVResult using "C:\research\africa_C\Community viral load\All community viral loads\HIV8_2011_status.txt" ///
if  (HIVResult=="1"|HIVResult=="0") & Resident=="Y", replace nonames noquote

