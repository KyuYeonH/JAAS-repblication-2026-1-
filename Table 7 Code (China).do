* Mediation effect

clear
cd "/Users/kyuyeonhwang/Desktop/Dissertation/Data/ShortandLongregression"
use "merged_dataset.dta"


sem (c <- hd d_HDR d_pop cb dpi overseagr L.c L2.c) ///
    (d_gdp <- c hd d_HDR overseagr d_exp d_pop cb crisis_dummy L.d_gdp L2.d_gdp)
	estat teffects
	
