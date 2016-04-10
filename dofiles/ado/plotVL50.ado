program plotVL50
version 12.1
syntax varlist , year(string) data(string) [comp]
tokenize `varlist'
local var `1'

** Set the data to be used
if "`data'"=="FVL" {
  local prefix "FVL"
  local VLname "Facility-based viral load"
}
else {
  local prefix "CVL"
  local VLname "Population-based viral load"
}


local gtitle "l1title("Prop. >50,000 copies/ml", size(small)) b1title("Age", size(small))"
local gopts "col(2) iscale(0.6) ycommon  ysize(10) xsize(16)"
local gexp "replace width(6000) height(4000)" 

dis as text _n "==========>Using `VLname' data for Year `year'"

** Plot
forvalue i = 1/2 {

  if  `i'==1  { 
    local sex "Male" 
    } 
  else { 
    local sex "Female" 
  }

  local gname "`prefix'`year'`sex'50"
  ** dis as text "`gname'"
  statsby mean=r(mean) lb=r(lb) ub=r(ub), by(Age) saving("$derived/`gname'", replace): /// 
    ci `var' if TestYear==`year' & Sex==`i'
  preserve
    qui use "$derived/`gname'", clear
    qui replace lb = 0 if lb<0 
    list *, sep(0)
    twoway (scatter mean Age) (rcap lb ub Age), ///
      ytitle("") xtitle("") xlabel(, val) legend(off) title("`VLname': `sex'") name("`gname'", replace)
  restore
}

graph combine `prefix'`year'Female50 `prefix'`year'Male50, `gtitle' `gopts'
graph export "$output/`prefix'`year'_50.png", `gexp'

if "`comp'"!="" {
  graph combine  CVL`year'Male50 FVL`year'Male50 CVL`year'Female50 FVL`year'Female50, ///
         `gtitle' `gopts'
  graph export "$output/Comp`year'_50.png",  `gexp'
  }

exit
end

