********************************************************************************
* Author: Brian Lumumba
*Stata level - Advanced
* Project: PHD PROJECT: AWARENESS AND PERCEPTIONS
* Purpose: DATA Analysis for Journal Paper
*Journal Name: Journal of Integrated Pest Management
**Date of creation: October 5, 2023
**Modified last:  November 23, 2023 / April 20, 2026
**Paper Title: Farmers' perceptions of integrated desert locust management: A case study in Isiolo and Meru Counties of Kenya
*Version 15.1
********************************************************************************

*------------------------
	* BASIC SETUP
*------------------------
clear all
version 15
set more off
set seed 638254

** 1. Paths
global root "G:/My Drive/AWARENESS_TYPOLOGIES" //change this to local path
global data "$root/Data"
global out  "$root/Output"

** 2. Setting log
cap log close
log using "$out/Analysis_Log_`c(current_date)'.log", replace

** 3. Data setup
use "$root/Perceptions.dta", clear
keep if Q_data == 1  // Focus for the perceptions survey

********************************************************************************
* SECTION 1: DESCRIPTIVE ANALYSIS
********************************************************************************

global demographics Gender Age Education_years Farmer_group Social_group ///
                  Farming_experience TLU Formal_sources Informal_sources ///
                  Mobile_ownership Land_tenure_ownership no_of_invasions ///
                  Shocks_experienced Tarmac_distance Cost

** T-test for differences by Location
foreach var of global demographics {
    quietly ttest `var', by(Location)
    di "Variable: `var' | P-value: " r(p)
}

* Export results
asdoc sum $demographics, by(Location) dec(2) save($out/Table1_Descriptives.doc) replace

********************************************************************************
* SECTION 2: INFORMATION CHANNELS (FIGURE 1 & 2)
********************************************************************************

** Source channel analysis
foreach type in Source Channel {
    tab Information_`type', gen(info_`type')
}

** Classfying perception categories 
global des_info Desert_Attack_Information Desert_Attack_Rating ///
                Desert_Attack_Timeliness Desert_Attack_Affordability ///
                Effects_Information Effects_Rating Effects_Timeliness ///
                Effects_Affordability Control_Information Control_Rating ///
                Control_Timeliness Control_Affordability Spraying_Information ///
                Spraying_Rating Spraying_Timeliness Spraying_Affordability

preserve
    collapse (mean) $des_info
    xpose, clear varname
    rename v1 percent
    replace percent = round(percent * 100)
    graph bar percent, over(_varname) title("Information Perceptions")
    graph export "$out/Fig2_Perceptions.tif", replace
restore

********************************************************************************
* SECTION 3: PCA AND REGRESSION ANALYSIS
********************************************************************************

** Principal component analysis
global ylist q1_1-q15_1
factor $ylist, pcf mineigen(1)
rotate, varimax blanks(0.5)
predict pc1 pc2 pc3 pc4, bartlett

** Robustness checks
eststo clear
eststo: reg COMP $demographics if Location == 1, robust // Meru
eststo: reg COMP $demographics if Location == 0, robust // Isiolo
eststo: reg COMP $demographics, robust                 // Pooled

** Export results
esttab using "$out/Table2_Regressions.rtf", b(2) se(2) r2 label replace

********************************************************************************
* SECTION 4: INDEX DERIVATION
********************************************************************************

** Standardizing perceptions
winsor weighted_perception_index, p(.1) gen(w_index_10)

gen perc_cat = 0
replace perc_cat = 1 if w_index_10 < 0
replace perc_cat = 2 if w_index_10 >= 11.918 // Standard deviation threshold

label define l_perc 0 "Neutral" 1 "Negative" 2 "Positive"
label val perc_cat l_perc

log close
exit
