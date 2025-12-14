clear
cd "/Users/kyuyeonhwang/Desktop/Dissertation/Data/한국데이터"
import excel "한국데이터.xlsx", sheet("Sheet1") firstrow 

set obs 85  // (2003년 4분기 ~ 2024년 3분기, 총 84개 분기)

gen quarter_time = tq(2003q4) + _n - 1  // 2003년 4분기부터 증가
format quarter_time %tq  // STATA 분기 형식 적용
tsset quarter_time  // 시계열 데이터로 설정


gen d_con = (log(con) - log(L.con))*100
gen d_dpi = (log(rdpi) - log(L.rdpi))*100
replace USEUJPCHGR = USEUJPCHGR/4
replace USEUJPGR = USEUJPGR/3

// Generate Consumption variables
replace USEUJPCHGR = USEUJPCHGR/4
replace USEUJPGR = USEUJPGR/3
gen hd_dpi = FLIBRGDP_SA * d_dpi
gen HDR_dpi = SLIBRGDPHPX12 * d_dpi


// 2007년도 1Q - 2024년 2Q

drop if quarter_time < tq(2007q1)
tsset quarter_time



// Investment variables

reg FLIBRGDP_SA creditgr dfgdp CB3GB3G EXPQOQ INVQOQ POP USEUJPCHGR L.FINDUMMY L.RGDPQOQ L2.RGDPQOQ, robust

reg SLIBRGDPHPX12 dfgdp FLIBRGDP_SA CB3GB3G EXPQOQ INVQOQ POP USEUJPCHGR L.FINDUMMY L.RGDPQOQ L2.RGDPQOQ, robust



// 2SLS Analysis
// Growth
ivreg2 RGDPQOQ CB3GB3G EXPQOQ INVQOQ POP USEUJPCHGR FINDUMMY L.RGDPQOQ L2.RGDPQOQ ///
   ( FLIBRGDP_SA SLIBRGDPHPX12 = creditgr dfgdp), ///
   gmm2s robust

// Consumption
ivreg2 d_con d_dpi hd_dpi CB3GB3G POP USEUJPCHGR FINDUMMY L.d_con L2.d_con ///
   ( FLIBRGDP_SA SLIBRGDPHPX12 = creditgr dfgdp), ///
   gmm2s robust
   
