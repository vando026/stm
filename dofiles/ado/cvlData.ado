program cvlData
version 12.1
syntax varlist , year(string) data(string)  
tokenize `varlist'
local var `1'
local var50k `2'

** Set the data to be used
if "`data'"=="FVL" {
  ** use "$derived/FVL2011", clear 
  local Data = 1
  local VLname "Facility-based viral load"
}
else {
  ** use "$derived/CVL2011", clear 
  local Data = 2
  local VLname "Population-based viral load"
}


dis as text _n "==========>Using `VLname' data for Year `year'" _n

** Plot
forvalue i = 1/2 {

  if  `i'==1  { 
    local sex "Male" 
    } 
  else { 
    local sex "Female" 
  }

  local gname "`data'`year'`sex'"
  dis as text _n "------------> Computing estimates for `sex's..." _n

  statsby mean=r(mean_g) lb=r(lb_g) ub=r(ub_g) Data=`Data', by(Age) saving("$derived/`gname'_gmn", replace): /// 
    ameans `var' if TestYear==`year' & Sex==`i'

  statsby mean=r(mean) lb=r(lb) ub=r(ub) Data=`Data', by(Age) saving("$derived/`gname'_mn", replace): /// 
    ci `var' if TestYear==`year' & Sex==`i'

  statsby mean=r(p50) lb=r(p25) ub=r(p75) Data=`Data', by(Age) saving("$derived/`gname'_med", replace): /// 
    sum `var' if TestYear==`year' & Sex==`i', detail

  statsby mean=r(mean) lb=r(lb) ub=r(ub) Data=`Data', by(Age) saving("$derived/`gname'_50", replace): /// 
    ci `var50k' if TestYear==`year' & Sex==`i'

}

foreach dat in gmn mn med 50  {
  qui use "$derived/`gname'_`dat'", clear
  dis as text _n "--------> Showing results for  dataset: `gname'_`dat'" 
  qui replace lb = 0 if lb<0 
  list *, sep(0)
  qui saveold "$derived/`gname'_`dat'", replace
}

exit
end

