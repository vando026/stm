program plotVL
version 12.1
syntax anything , name(string) title(string)  

use `anything' , clear


global mcol1 "green"
global mcol2 "red"
global lopts "lwidth(medium)"
twoway  ///
  (scatter mean Age if Data==1, mcolor("maroon") ///
  xtitle("Age") ytitle("Viral load copies/ml") ) ///
  (scatter mean Age if Data==2, mcolor("navy")) ///
  (rcap lb ub Age if Data==1, lcolor("maroon") $lopts) ///
  (rcap lb ub Age if Data==2, lcolor("navy") $lopts), ///
   ylabel(#4) xlabel(#7, val) legend(off) ///
  name(gr1, replace) legend(off)
  
bysort Age (Data): gen byCount = _n
reshape wide mean lb ub Data, i(Age) j(byCount)
gen Ratio = mean2/mean1
** reshape long

twoway (line Ratio Age, xtitle("Age") xlabel(#7, val) ///
  ytitle("Ratio of Community to Facility VL")), ///
  name(gr2, replace) legend(off)

graph combine gr1 gr2, cols(2) name("`name'", replace) ///
  title("`title'") 

exit
end

