* Example
clear all
set seed 7777

* ten periods
set obs 10
gen time = _n
gen time_fe = rnormal()

* 100 individuals
expand 100
bys time: gen id= _n*0.5

* positive linear trend
bys id: gen timetrend = 0
* id FEs
bys id: egen id_fe = max(rnormal())
* event-time dimension (0 set at 100 to make use of i. stata syntax)
* NOTE: We need to observe a shock for each individual (e.g. exclude individuals
* you never see not shocked, no baseline for them).
gen x = ceil(runiform()*9) + 1
bys id: egen timeofshock = max((time==1)*(x))
gen timefromshock = time-timeofshock + 100

sort id time
/* 
Generate outcome. We expect a fixed jump of one at time 101, and zero pre-trend
before that. No errors so that we get exact coefficients.
*/
gen y = timetrend + time_fe + id_fe + 0*(timefromshock<=100) + 1*(timefromshock>100)

/* 
Naive (wrong approach): Just run an event-study normalizing only levels at 
time==99. The model is underidentified. Stata drops something at random (here one of 
the time FEs). You get a weird pattern in your timefromshock coefficients. 
Which pattern exactly depends on the time FE dropped. Not even the difference btw 
100 and 101 is equal to 1 as it should be.
*/
reghdfe y b99.timefromshock i.time, abs(i.id)

* Option 1: Double normalization by dropping one extra pre-trend coefficient
* (Borusyak & Jaravel)

gen timefid1 = timefromshock
replace timefid1 = 99 if timefid1 ==91
reghdfe y b99.timefid1 i.time, abs(i.id)

* Then, once you've tested that all pre-trend coefficients are ==0 (parallel trends), 
* might as well normalize all pre-coeffs to 0 to leverage higher efficiency. See
* paper for details. Here it won't matter, we do not have errors. In real examples
* it will help precision

gen timefid2 = timefromshock
replace timefid2 = 99 if timefid2 <99
reghdfe y b99.timefid2 i.time, abs(i.id)

* Option 2: Double normalization by dropping a set of pre-trend coeffs
* (Druedahl and Martinello)
* We independently figured out this identification problem at the same of 
* Borusyak and Jaravel. I believe their solution is more elegant, but ours
* has the advantage of being easier to present (only one step). It's essentially
* a middle way between the two steps of the BJ paper. We double-normalize
* by dropping a set of pre-trend coefficients. This increases efficiency wrt step 1 of BJ,
* but still allows to visualize parallel trends. The double-normalization happens
* by estimating the trend out of the dropped pre-trend coefficients

gen timefid3 = timefromshock
replace timefid3 = 0 if timefid3 <=95
reghdfe y b99.timefid3, abs(i.time i.id)







