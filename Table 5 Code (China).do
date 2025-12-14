clear
cd "/Users/kyuyeonhwang/Desktop/Dissertation/Data/ShortandLongregression"
use "merged_dataset.dta"

set obs 304  // (1949Y 1Q ~ 2024Y 4Q, Total 304 Q)

gen quarter_time = tq(1949q1) + _n - 1  // 1949년 1분기부터 증가
format quarter_time %tq  // STATA 분기 형식 적용
tsset quarter_time  // 시계열 데이터로 설정


gen crisis_dummy = 0
replace crisis_dummy = 1 if (quarter_time >= tq(2008q4) & quarter_time <= tq(2009q4)) | (quarter_time >= tq(2020q1) & quarter_time <= tq(2023q1))


gen d_gfc = log(PGCF_Q_SA) - log(L.PGCF_Q_SA)
// Capital data used by RGCF_Q_SA /////
gen d_exp = log(RExport_Q_SA) - log(L.RExport_Q_SA)
gen HDR = (TotalLoans / NominalGDP)
gen hd = log(ShorttermHouseholdLoans) - log(L.ShorttermHouseholdLoans)
gen d_gdp= log(PGDP_exp_Q_SA) - log(L.PGDP_exp_Q_SA)
//gdp data used by RGDP_exp_Q_SA ///
gen d_pop = log(pop) - log(L.pop)
//중요! pop 대신에 Employment 써도 결과는 비슷.

//////////////////////////////////////
gen d_gfc = log(RGCF_Q_SA) - log(L.RGCF_Q_SA)
gen d_exp = log(RExport_Q_SA) - log(L.RExport_Q_SA)
gen HDR = (TotalLoans / NominalGDP)
gen hd = log(ShorttermHouseholdLoans) - log(L.ShorttermHouseholdLoans)
gen d_gdp= log(RGDP_exp_Q_SA) - log(L.RGDP_exp_Q_SA)
gen d_pop = log(Employment) - log(L.Employment)
//////////////////////////////////////

//Calculate HDR_hat.
reg HDR quarter_time hd
predict HDR_hat
sum hd
scalar mean_hd = r(mean)  

// Generate HDR_tilde
gen HDR_tilde = HDR - _b[hd] * (hd - mean_hd)

gen d_HDR = log(HDR_tilde) - log(L.HDR_tilde)

summarize d_gdp hd d_HDR overseagr d_exp d_gfc d_pop cb crisis_dummy

//All data are included in merged_dataset.

clear
cd "/Users/kyuyeonhwang/Desktop/Dissertation/Data/ShortandLongregression"
use "merged_dataset.dta"


// Unit roots test for all variables
dfuller d_gfc, lags(1) trend
dfuller overseagr, lags(1) trend
dfuller d_exp, lags(1) trend
dfuller HDR_tilde, lags(1) trend
dfuller d_HDR, lags(1) trend
dfuller hd, lags(1) trend
dfuller d_gdp, lags(1) trend
dfuller d_pop, lags(1) trend
dfuller cb, lags(1) trend


// OLS Regression
reg d_gdp hd d_HDR, robust
reg d_gdp hd d_HDR overseagr d_exp d_gfc d_pop, robust
reg d_gdp hd d_HDR overseagr d_exp d_gfc d_pop crisis_dummy L.d_gdp L2.d_gdp, robust
estout, cells(b(star fmt(3)) se(fmt(3))) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01)

ivreg2 d_gdp (hd d_HDR overseagr d_exp d_pop d_gfc = L(1/4).hd L(1/4).d_HDR L(1/4).overseagr L(1/4).d_exp L(1/4).d_pop L(1/4).d_gfc), liml first

// GMM (4laged variables)
gmm (d_gdp - {b0} - {b1}*hd - {b2}*d_HDR - {b3}*overseagr - {b4}*d_exp - {b5}*d_pop  - {b6}*d_gfc - {b7}*crisis_dummy - {b8}*L.d_gdp - {b9}*L2.d_gdp), ///
    instruments(L(1/4).hd L(1/4).d_HDR L(1/4).overseagr L(1/4).d_exp L(1/4).d_pop L(1/4).d_gfc L(1/4).d_gdp) vce(robust)
estout, cells(b(star fmt(3)) se(fmt(3))) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01)

gmm (d_gdp - {b0} - {b1}*hd - {b2}*d_HDR - {b3}*overseagr - {b4}*d_exp - {b5}*d_pop  - {b6}*d_gfc - {b7}*crisis_dummy - {b8}*L.d_gdp - {b9}*L2.d_gdp), ///
    instruments(L(0/4).hd L(0/4).d_HDR L(0/4).overseagr L(0/4).d_exp L(0/4).d_pop L(0/4).d_gfc L(0/4).d_gdp) vce(robust)
estout, cells(b(star fmt(3)) se(fmt(3))) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01)


//Hanse J-test p=0.33, p>0.05
estat overid

// Generate CB variables
gen cb = log(LendingRatePBC1year) - log(L.LendingRatePBC1year)

// OLS
reg d_gdp hd d_HDR, robust
reg d_gdp hd d_HDR overseagr d_exp d_gfc d_pop cb, robust
reg d_gdp hd d_HDR overseagr d_exp d_gfc d_pop cb crisis_dummy L.d_gdp L2.d_gdp, robust
estout, cells(b(star fmt(3)) se(fmt(3))) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01)

vif

// GMM
gmm (d_gdp - {b0} - {b1}*hd - {b2}*d_HDR), ///
    instruments(L(1/4).hd L(1/4).d_HDR) vce(robust)
estout, cells(b(star fmt(3)) se(fmt(3))) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01)

gmm (d_gdp - {b0} - {b1}*hd - {b2}*d_HDR - {b3}*d_exp - {b4}*d_pop  - {b5}*d_gfc - {b6}*cb), ///
    instruments(L(1/4).hd L(1/4).d_HDR L(1/4).d_exp L(1/4).d_pop L(1/4).d_gfc L(1/4).cb) vce(robust)
estout, cells(b(star fmt(3)) se(fmt(3))) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01)

gmm (d_gdp - {b0} - {b1}*hd - {b2}*d_HDR - {b3}*overseagr - {b4}*d_exp - {b5}*d_pop  - {b6}*d_gfc - {b7}*cb), ///
    instruments(L(1/4).hd L(1/4).d_HDR L(1/4).overseagr L(1/4).d_exp L(1/4).d_pop L(1/4).d_gfc L(1/4).cb) vce(robust)
estout, cells(b(star fmt(3)) se(fmt(3))) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01)

gmm (d_gdp - {b0} - {b1}*hd - {b2}*d_HDR - {b3}*overseagr - {b4}*d_exp - {b5}*d_pop  - {b6}*d_gfc - {b7}*cb - {b8}*crisis_dummy - {b9}*L.d_gdp - {b10}*L2.d_gdp), ///
    instruments(L(1/4).hd L(1/4).d_HDR L(1/4).overseagr L(1/4).d_exp L(1/4).d_pop L(1/4).d_gfc L(1/4).cb L(1/4).d_gdp) vce(robust)
estout, cells(b(star fmt(3)) se(fmt(3))) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01)

// 2SLS
ivreg2 d_gdp (hd d_HDR = L(1/4).hd L(1/4).d_HDR), robust
ivregress 2sls d_gdp (hd d_HDR = L(1/4).hd L(1/4).d_HDR), robust
estat firststage

ivreg2 d_gdp (hd d_HDR overseagr d_exp d_pop d_gfc cb = L(1/4).hd L(1/4).d_HDR L(1/4).overseagr L(1/4).d_exp L(1/4).d_pop L(1/4).d_gfc L(1/4).cb), robust
ivregress 2sls d_gdp (hd d_HDR overseagr d_exp d_pop d_gfc cb = L(1/4).hd L(1/4).d_HDR L(1/4).overseagr L(1/4).d_exp L(1/4).d_pop L(1/4).d_gfc L(1/4).cb), robust
estat firststage

ivreg2 d_gdp (hd d_HDR overseagr d_exp d_pop d_gfc cb crisis_dummy= L(1/4).hd L(1/4).d_HDR L(1/4).overseagr L(1/4).d_exp L(1/4).d_pop L(1/4).d_gfc L(1/4).cb), robust
ivregress 2sls d_gdp (hd d_HDR overseagr d_exp d_pop d_gfc cb crisis_dummy= L(1/4).hd L(1/4).d_HDR L(1/4).overseagr L(1/4).d_exp L(1/4).d_pop L(1/4).d_gfc L(1/4).cb), robust
estat firststage


// 2SLS
reg hd d_HDR overseagr d_exp d_pop d_gfc cb crisis_dummy L(1/2).d_gdp
predict hd_hat, xb

reg d_HDR hd overseagr d_exp d_gfc d_pop cb crisis_dummy L.d_gdp L2.d_gdp
predict d_HDR_hat, xb

reg d_gdp hd_hat d_HDR_hat overseagr d_exp d_gfc d_pop cb crisis_dummy L.d_gdp L2.d_gdp, robust

ivreg2 d_gdp hd d_HDR overseagr d_exp d_gfc d_pop cb crisis_dummy L.d_gdp L2.d_gdp ///
   ( hd d_HDR = hd_hat d_HDR_hat), ///
   gmm2s robust
   
   
   

// Consumption

gen d_c = log(NominalRetailGoodsC) - log(L.NominalRetailGoodsC)


// OLS 
reg c hd d_HDR, robust
reg c hd d_HDR d_pop overseagr cb, robust
reg c hd d_HDR d_pop overseagr cb crisis_dummy L.c L2.c, robust
estout, cells(b(star fmt(3)) se(fmt(3))) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01)

// GMM 
gmm (c - {b0} - {b1}*hd - {b2}*d_HDR), ///
    instruments(L(1/4).hd L(1/4).d_HDR) vce(robust)
estout, cells(b(star fmt(3)) se(fmt(3))) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01)

gmm (c - {b0} - {b1}*hd - {b2}*d_HDR - {b3}*d_pop - {b4}*overseagr  - {b5}*cb), ///
    instruments(L(1/4).hd L(1/4).d_HDR L(1/4).overseagr L(1/4).d_exp L(1/4).d_pop L(1/4).d_gfc L(1/4).cb) vce(robust)
estout, cells(b(star fmt(3)) se(fmt(3))) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01)

gmm (c - {b0} - {b1}*hd - {b2}*d_HDR - {b3}*d_pop - {b4}*overseagr  - {b5}*cb - {b6}*crisis_dummy - {b7}*L.c - {b8}*L2.c), ///
    instruments(L(1/4).hd L(1/4).d_HDR L(1/4).overseagr L(1/4).d_exp L(1/4).d_pop L(1/4).d_gfc L(1/4).cb L(1/4).d_gdp) vce(robust)
estout, cells(b(star fmt(3)) se(fmt(3))) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01)

// OLS 
reg c hd d_HDR, robust
reg c hd d_HDR d_pop overseagr cb dpi, robust
reg c hd d_HDR d_pop overseagr cb dpi crisis_dummy L.c L2.c, robust
estout, cells(b(star fmt(3)) se(fmt(3))) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01)

// GMM (c와 dpi 사용, 성공)
gmm (c - {b0} - {b1}*hd - {b2}*d_HDR), ///
    instruments(L(1/4).hd L(1/4).d_HDR) vce(robust)
estout, cells(b(star fmt(3)) se(fmt(3))) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01)
//Hanse J-test p=0.33, p>0.05
estat overid


gmm (c - {b0} - {b1}*hd - {b2}*d_HDR - {b3}*d_pop - {b4}*overseagr  - {b5}*cb - {b6}*dpi), ///
    instruments(L(1/4).hd L(1/4).d_HDR L(1/4).overseagr L(1/4).d_exp L(1/4).d_pop L(1/4).d_gfc L(1/4).cb) vce(robust)
estout, cells(b(star fmt(3)) se(fmt(3))) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01)
//Hanse J-test p=0.33, p>0.05
estat overid


gmm (c - {b0} - {b1}*hd - {b2}*d_HDR - {b3}*d_pop - {b4}*overseagr  - {b5}*cb - {b6}*dpi - {b7}*crisis_dummy - {b8}*L.c - {b9}*L2.c), ///
    instruments(L(1/4).hd L(1/4).d_HDR L(1/4).overseagr L(1/4).d_exp L(1/4).d_pop L(1/4).d_gfc L(1/4).cb L(1/4).d_gdp) vce(robust)
estout, cells(b(star fmt(3)) se(fmt(3))) stats(N r2) starlevels(* 0.10 ** 0.05 *** 0.01)
//Hanse J-test p=0.33, p>0.05
estat overid




