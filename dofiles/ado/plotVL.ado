capture program drop plotVL
program plotVL
version 12.1
syntax anything [if], name(string) title(string)  

use `anything' , clear

keep `if'

global mcol1 "green"
global mcol2 "red"
global lopts "lwidth(medium)"
twoway  ///
  (scatter mean Age if Data=="CVL", mcolor("maroon") ///
  xtitle("Age") ytitle("Viral load copies/ml") ) ///
  (scatter mean Age if Data=="FVL", mcolor("navy")) ///
  (rcap lb ub Age if Data=="CVL", lcolor("maroon") $lopts) ///
  (rcap lb ub Age if Data=="FVL", lcolor("navy") $lopts), ///
   ylabel(#4) xlabel(#7, val) legend(off) ///
  name(gr1, replace) legend(off)

bysort Age (Data): gen byCount = _n
reshape wide mean lb ub Data Female, i(Age) j(byCount)
gen Ratio = mean1/mean2
gen Rlb = lb1/lb2
gen Rub = ub1/ub2
** reshape long

twoway (rarea Rlb Rub Age, sort xtitle("Age") xlabel(#7, val) ///
  ytitle("Ratio of Community to Facility VL")), ///
  name(gr2, replace) legend(off)

graph combine gr1 gr2, cols(2) name("`name'", replace) ///
  title("`title'") 
graph export "$output/ratio_`name'.png", replace

exit
end
