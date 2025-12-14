clear
cd "/Users/kyuyeonhwang/Desktop/Dissertation/Data/한국데이터"
import excel "한국데이터.xlsx", sheet("Sheet1") firstrow 

set obs 85  // (2003Y 4Q ~ 2024Y 3Q, Total 84 Q)

gen quarter_time = tq(2003q4) + _n - 1  //
format quarter_time %tq  // 
tsset quarter_time  //


gen d_con = log(con) - log(L.con)
gen d_dpi = log(rdpi) - log(L.rdpi)
replace USEUJPCHGR = USEUJPCHGR/4
replace USEUJPGR = USEUJPGR/3

// from 2007
drop if quarter_time < tq(2006q1)
tsset quarter_time
drop if quarter_time < tq(2007q1)
tsset quarter_time


reg RGDPQOQ FLIBRGDP_SA SLIBRGDPHPX12 CB3GB3G EXPQOQ INVQOQ POP USEUJPCHGR L.FINDUMMY L.RGDPQOQ L2.RGDPQOQ, robust
reg d_con FLIBRGDP_SA SLIBRGDPHPX12 CB3GB3G d_dpi POP USEUJPCHGR FINDUMMY L.d_con L2.d_con, robust

gen L1_d_con = L.d_con
gen L2_d_con = L2.d_con
gen L1_RGDPQOQ = L.RGDPQOQ
gen L2_RGDPQOQ = L2.RGDPQOQ
gen L1_FINDUMMY = L.FINDUMMY

sem ///
  (d_con <- FLIBRGDP_SA SLIBRGDPHPX12 CB3GB3G d_dpi POP USEUJPCHGR FINDUMMY L1_d_con L2_d_con) ///
  (RGDPQOQ <- d_con FLIBRGDP_SA SLIBRGDPHPX12 CB3GB3G EXPQOQ INVQOQ POP USEUJPCHGR L1_FINDUMMY L1_RGDPQOQ L2_RGDPQOQ) ///
  , nocapslatent
estat teffects
