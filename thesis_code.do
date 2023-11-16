

***** STATA code for master thesis: The Importance of Colleagues as a Reference Group in Income Comparison
***** Author: Xinyue Wang



*** install package if need
ssc install schemepack, replace
ssc install slideplot, replace
ssc install tabplot, replace
ssc install floatplot, replace
ssc install coefplot, replace
net install pr0046, from(http://www.stata-journal.com/software/sj9-1)
ssc install omodel, replace


*** set environment
set scheme white_cividis
global infile = "C:\Users\11967\Desktop\SC"
use "$infile\SOEP_IS_Modul_20230420\soep-is-2022-i_dohmen.dta", clear
label language EN



*** for each "pid", if "lb0266_v2" == -2, gross work earnings is "plc0013_v2"; if "lb0266_v2" == 2020/2021/2022, gross income last employment is "doh22_01".
merge 1:1 pid using "$infile\SOEP_IS_Modul_20230420\SOEP-IS-Data\soep-is-2022-pe2.dta", keep(match) keepusing(plc0013_v2) nogenerate
generate SC0 = plc0013_v2
replace SC0 = doh22_01 if plc0013_v2 == -2
recast long SC0
label variable SC0 "Merged Gross Wage"
order plc0013_v2 SC0, after(doh22_01)

*** for each "pid", add "Geburtsjahr" and "Geschlecht" informations from "pbrutto.dta", calculate their age.
merge 1:1 pid using "$infile\SOEP_IS_Modul_20230420\SOEP-IS-Data\soep-is-2022-pbrutto.dta", keep(match) keepusing(geburt sex) nogenerate
order geburt sex, after(pid)
label values sex doh22_31a_EN

generate age = ., after(sex)
replace age = 1 if syear-geburt >= 16 & syear-geburt <= 24
replace age = 2 if syear-geburt >= 25 & syear-geburt <= 35
replace age = 3 if syear-geburt >= 36 & syear-geburt <= 45
replace age = 4 if syear-geburt >= 46 & syear-geburt <= 55
replace age = 5 if syear-geburt > 55
label variable age "Age"
label values age doh22_32a_EN

*** for each "pid", add "occupational status" information from "pe2.dta"
merge 1:1 pid using "$infile\SOEP_IS_Modul_20230420\SOEP-IS-Data\soep-is-2022-pe2.dta", keep(match) keepusing(plb0568_v1) nogenerate
generate status = ., after(age)
replace status = lb1272_v1
replace status = 1 if lb1272_v1 == -2 & plb0568_v1 == 2
replace status = 2 if lb1272_v1 == -2 & plb0568_v1 == 1
replace status = 3 if lb1272_v1 == -2 & plb0568_v1 == 4
replace status = 4 if lb1272_v1 == -2 & plb0568_v1 == 5
replace status = 5 if lb1272_v1 == -2 & plb0568_v1 == 3
replace status = -1 if status == -2
label variable status "Occupational Position"
label values status lb1272_v1_EN

*** for peer module question, compare their own income to the estimated peer income
generate sc0verda = ., after(doh22_verda)
generate sc0verdb = ., after(doh22_verdb)
foreach v in verda verdb{
	replace sc0`v' = 1 if SC0!=-1 & (doh22_`v'!=-1 & doh22_`v'!=-2) & SC0 < doh22_`v'
	replace sc0`v' = 2 if SC0!=-1 & (doh22_`v'!=-1 & doh22_`v'!=-2) & SC0 == doh22_`v'
	replace sc0`v' = 3 if SC0!=-1 & (doh22_`v'!=-1 & doh22_`v'!=-2) & SC0 > doh22_`v'
}



********** SC1 question, the general importance of comparison **********

*** individual rank
rowranks doh22_02 doh22_03 doh22_04 doh22_07 doh22_08, generate(rank_02 rank_03 rank_04 rank_07 rank_08) descending method(low)
order rank_02 rank_03 rank_04 rank_07 rank_08, after(doh22_08)
foreach i in 02 03 04 07 08{
	replace rank_`i' = -1 if doh22_`i' == -1 | doh22_`i' == -2
	replace rank_`i' = 5 if doh22_`i' == 1
}
foreach i in 02 03 04 07 08{
	 replace rank_`i' = 6 - rank_`i' if rank_`i' != -1
}

label variable rank_02 "Rank of Importance Income Comparison - Neighbors"
label variable rank_03 "Rank of Importance Income Comparison - Friends"
label variable rank_04 "Rank of Importance Income Comparison - Colleagues"
label variable rank_07 "Rank of Importance Income Comparison - Parents"
label variable rank_08 "Rank of Importance Income Comparison - Partner"

gen absrank = ., after(rank_08)
replace absrank = -1 if (doh22_02==1 | doh22_02==-1) & (doh22_03==1 | doh22_03==-1) & (doh22_04==1 | doh22_04==-1 | doh22_04==-2) & (doh22_07==1 | doh22_07==-1) & (doh22_08==1 | doh22_08==-1)
replace absrank = 2 if (rank_02 == 5) & (rank_03 != 5 & rank_04 != 5 & rank_07 != 5 & rank_08 != 5)
replace absrank = 3 if (rank_03 == 5) & (rank_02 != 5 & rank_04 != 5 & rank_07 != 5 & rank_08 != 5)
replace absrank = 4 if (rank_04 == 5) & (rank_02 != 5 & rank_03 != 5 & rank_07 != 5 & rank_08 != 5)
replace absrank = 7 if (rank_07 == 5) & (rank_02 != 5 & rank_03 != 5 & rank_04 != 5 & rank_08 != 5)
replace absrank = 8 if (rank_08 == 5) & (rank_02 != 5 & rank_03 != 5 & rank_04 != 5 & rank_07 != 5)
replace absrank = 9 if absrank != 2 & absrank != 3 & absrank != 4 & absrank != 7 & absrank != 8 & absrank != -1
label define absranklabel 2 "Neighbors" 3 "Friends" 4 "Colleagues" 7 "Parents" 8 "Partner" 9 "Multi" -1 "None"
label values absrank absranklabel

foreach i in 2 3 4 7 8{
	 replace rank_0`i' = 6 if absrank == `i'
}

label define ranklabel -1 "No Answer" 1 "Least Important" 2 "Fourth Important" 3 "Third Important" 4 "Second Important" 5 "Most Important-Simultaneous" 6 "Most Important-Absolute", replace
label values rank_02 rank_03 rank_04 rank_07 rank_08 ranklabel





********************* save the adjusted data





*** importance rank figure
preserve
keep pid rank_02 rank_03 rank_04 rank_07 rank_08
reshape long rank_, i(pid) j(group) string

gen int order_group = .
replace order_group = 1 if group == "04"
replace order_group = 2 if group == "08"
replace order_group = 3 if group == "03"
replace order_group = 4 if group == "02"
replace order_group = 5 if group == "07"
quietly count if order_group == 1
local obs = r(N)

graph hbar (count), over(rank_) over(order_group, gap(70) relabel(1"Colleagues" 2"Partner" 3"Friends" 4"Neighbors" 5"Parents")) asyvars stack bar(1, fcolor("225 223 208 %90") fintensity(100) lcolor(none)) bar(2, fcolor("46 69 184 %90") fintensity(90) lcolor(none)) bar(3, fcolor("46 69 184 %90") fintensity(70) lcolor(none)) bar(4, fcolor("46 69 184 %90") fintensity(50) lcolor(none)) bar(5, fcolor("46 69 184 %90") fintensity(30) lcolor(none)) bar(6, fcolor("251 152 81 %90") fintensity(50) lcolor("251 152 81 %80") lalign(center)) bar(7, fcolor("251 152 81 %90") fintensity(90) lcolor("251 152 81 %100") lalign(center)) blabel(bar, format(%5.3g) size(small) position(center)) ytitle(, size(zero)) ylabel(0(110)770,noticks nolabels) note("Obs. = `obs'" "Source: SOEP-IS 2022", size(vsmall)) legend(position(12) rows(1) stack keygap(.5) symxsize(6pt) symysize(2pt) size(vsmall)) xsize(2) ysize(1) name(SC1_rank_importance, replace)

restore





*** average gross income
eststo clear
tabstat SC0 if SC0 != -1, by(sex) statistics(mean sd count) columns(statistics) save
forvalue i = 1/2 {
	local p`i': display r(Stat`i')[3,1]/r(StatTotal)[3,1]
	matrix r`i' = (r(Stat`i')[1,1],r(Stat`i')[2,1],r(Stat`i')[3,1], `p`i'')
}
matrix G = (r1\r2)
tabstat SC0 if SC0 != -1, by(age) statistics(mean sd count) columns(statistics) save
forvalue i = 1/5 {
	local p`i': display r(Stat`i')[3,1]/r(StatTotal)[3,1]
	matrix r`i' = (r(Stat`i')[1,1],r(Stat`i')[2,1],r(Stat`i')[3,1], `p`i'')
}
matrix A = (r1\r2\r3\r4\r5) 
tabstat SC0 if SC0 != -1, by(status) statistics(mean sd count) columns(statistics) save
forvalue i = 1/6 {
	local p`i': display r(Stat`i')[3,1]/r(StatTotal)[3,1]
	matrix r`i' = (r(Stat`i')[1,1],r(Stat`i')[2,1],r(Stat`i')[3,1], `p`i'')
}
matrix S = (r1\r2\r3\r4\r5\r6) 
tabstat SC0 if SC0 != -1, by(absrank) statistics(mean sd count) columns(statistics) save
forvalue i = 1/7 {
	local p`i': display r(Stat`i')[3,1]/r(StatTotal)[3,1]
	matrix r`i' = (r(Stat`i')[1,1],r(Stat`i')[2,1],r(Stat`i')[3,1], `p`i'')
}
matrix R = (r1\r2\r3\r4\r5\r6\r7)
matrix rt= (r(StatTotal)[1,1],r(StatTotal)[2,1],r(StatTotal)[3,1],100)
matrix M = (G\A\S\R\rt)
matrix rownames M =  Male Female 16-24 25-35 36-45 46-55 55+ No-answer Blue-collar Self-employed Apprentices White-collar Civil-servant No-SC Neighbors Friends Colleagues Parents Partner Multi Total
matrix colnames M = Mean SD N Percent
esttab matrix(M, fmt(0 0 0 3)), title("Statistics of Respondents' Gross Income\label{tsc0}") addnotes("Note: 65 respondents with No Answer for gross income question are not included in table" "Source: SOEP-IS 2022") width(\linewidth)
* using "$infile\analysis\table\SC_0.tex", replace booktabs 

ranksum SC0 if SC0 != -1, by(sex)
kwallis SC0 if SC0 != -1, by(age)
kwallis SC0 if SC0 != -1, by(absrank)
kwallis SC0 if SC0 != -1, by(status)



*** association in demographics of respondents
eststo clear
foreach v in sex age status{
	quietly tabulate `v' sex, chi2
	local rg = r(p)
	quietly tabulate `v' age, chi2
	local ra = r(p)
	quietly tabulate `v' status if status!=-1, chi2
	local rs = r(p)
	matrix r`v' = (`rg',`ra',`rs')
}
matrix R = (rsex\rage\rstatus)
matrix rownames R =  Gender Age Occupational-Position
matrix colnames R =  Gender Age Occupational-Position
esttab matrix(R, fmt(3 3 3)), title("Association of Respondents' Demographics\label{tsc0demo}") width(\linewidth)
* using "$infile\analysis\table\SC_0_demo.tex", replace booktabs

preserve
clonevar status_order = status
replace status_order = 1 if status == 3
replace status_order = 2 if status == 5
replace status_order = 3 if status == 2
replace status_order = 4 if status == 1
replace status_order = 5 if status == 4
slideplot hbar sex if status_order != -1, by(age status_order) neg(1) pos(2) bar(1, color("46 69 184"*.8)) bar(2, color("251 152 81"*.8)) blabel(bar) ylabel(-80(40)80, noticks nolabels) legend(order(2 1) position(10) ring(0)) title("Gender and Age of Respondents' Occupational Position") name(SC1_status, replace)
restore



*** heterogeneity on importance rank and absolute rank group

eststo clear
local i=1
foreach v in rank_02 rank_03 rank_04 rank_07 rank_08{
	quietly kwallis `v', by(sex)
	local p1: display chi2tail(r(df), r(chi2_adj))
	quietly kwallis `v', by(age)
	local p2: display chi2tail(r(df), r(chi2_adj))
	quietly kwallis `v' if status!=-1, by(status)
	local p3: display chi2tail(r(df), r(chi2_adj))
	matrix r`i' = (`p1',`p2',`p3')
	local ++i
} 
foreach v in sex age status{
	quietly tabulate `v' absrank, chi2
	local r`v' = r(p)
}
quietly tabulate status absrank if status!=-1, chi2
local rstatus = r(p)
matrix r6 = (`rsex',`rage',`rstatus')
quietly count
local n = r(N)
matrix r7 = (`n',`n',`n')
matrix R = (r1\r2\r3\r4\r5\r6\r7)
matrix rownames R = Neighbors Friends Colleagues Parents Partner Absolute-Rank-Group Obs
matrix colnames R = Gender Age Status
esttab matrix(R, fmt("3 3 3 3 3 3 0")), nomtitle title("Kruskal-Wallis and Chi-square Test on Respondents' Importance Rank\label{tsc1}") addnotes("Source: SOEP-IS 2022") width(\linewidth)
* using "$infile\analysis\table\SC_1.tex", replace booktabs 





*** plot on demographics for importance rank
tabstat rank_02 rank_03 rank_04 rank_07 rank_08, by(sex) stats(mean p50 n)
tabstat rank_02 rank_03 rank_04 rank_07 rank_08, by(age) stats(mean p50 n)
tabstat rank_02 rank_03 rank_04 rank_07 rank_08, by(status) stats(mean p50 n)

preserve
keep pid sex age status SC0 rank_02 rank_03 rank_04 rank_07 rank_08 absrank
reshape long rank_, i(pid) j(group) string

gen int group_order = .
replace group_order = 1 if group == "04"
replace group_order = 2 if group == "08"
replace group_order = 3 if group == "03"
replace group_order = 4 if group == "02"
replace group_order = 5 if group == "07"

graph hbar (count), over(rank_) over(sex, gap(0)) over(group_order, relabel(1 Colleagues 2 Partner 3 Friends 4 Neighbors 5 Parents) label(labsize(small))) asyvars percentages stack bar(1, fcolor("225 223 208 %80") fintensity(100) lcolor(none)) bar(2, fcolor("46 69 184 %80") fintensity(80) lcolor(none)) bar(3, fcolor("46 69 184 %80") fintensity(60) lcolor(none)) bar(4, fcolor("46 69 184 %80") fintensity(40) lcolor(none)) bar(5, fcolor("46 69 184 %80") fintensity(20) lcolor(none)) bar(6, fcolor("251 152 81 %80") fintensity(40) lcolor(none)) bar(7, fcolor("251 152 81 %80") fintensity(80) lcolor(none)) ylabel(0(25)100, nolabels noticks) ytitle(, size(zero)) legend(stack rows(1) size(small) position(12)) title("The Importance Rank Distribution - by Gender", size(medsmall) position(6)) note("Source: SOEP-IS 2022", size(vsmall) position(1)) legend(stack rows(1) size(small) region(fcolor(none)) position(12)) xsize(2) ysize(1) name(SC1_rankgender, replace)

graph hbar (count), over(rank_) over(age,gap(0)) over(group_order, relabel(1 Colleagues 2 Partner 3 Friends 4 Neighbors 5 Parents) label(labsize(small))) asyvars percentages stack bar(1, fcolor("225 223 208 %80") fintensity(100) lcolor(none)) bar(2, fcolor("46 69 184 %80") fintensity(80) lcolor(none)) bar(3, fcolor("46 69 184 %80") fintensity(60) lcolor(none)) bar(4, fcolor("46 69 184 %80") fintensity(40) lcolor(none)) bar(5, fcolor("46 69 184 %80") fintensity(20) lcolor(none)) bar(6, fcolor("251 152 81 %80") fintensity(40) lcolor(none)) bar(7, fcolor("251 152 81 %80") fintensity(80) lcolor(none)) ylabel(0(25)100, nolabels noticks) ytitle(, size(zero)) legend(off) title("The Importance Rank Distribution - by Age", size(medsmall) position(6)) name(SC1_rankage, replace)

gen int status_order = .
replace status_order = 1 if status == 3
replace status_order = 2 if status == 5
replace status_order = 3 if status == 4
replace status_order = 4 if status == 1
replace status_order = 5 if status == 2

graph hbar (count), over(rank_) over(status_order, gap(0) relabel(1 "Apprentices" 2 "Civil servant" 3 "White-collar" 4 "Blue-collar" 5 "Self-employed") label(labsize(small))) over(group_order, relabel(1 Colleagues 2 Partner 3 Friends 4 Neighbors 5 Parents) label(labsize(small))) asyvars percentages stack bar(1, fcolor("225 223 208 %80") fintensity(100) lcolor(none)) bar(2, fcolor("46 69 184 %80") fintensity(80) lcolor(none)) bar(3, fcolor("46 69 184 %80") fintensity(60) lcolor(none)) bar(4, fcolor("46 69 184 %80") fintensity(40) lcolor(none)) bar(5, fcolor("46 69 184 %80") fintensity(20) lcolor(none)) bar(6, fcolor("251 152 81 %80") fintensity(40) lcolor(none)) bar(7, fcolor("251 152 81 %80") fintensity(80) lcolor(none)) ylabel(0(25)100, nolabels noticks) ytitle(, size(zero)) legend(off) title("The Importance Rank Distribution - by Occupational Position", size(medsmall) position(6)) name(SC1_rankstatus, replace)

restore





*** plot on demographics for absolute rank group
foreach v in sex age status{
	tabulate `v' absrank, chi2 cchi2
}

preserve
gen int group_order = .
replace group_order = 1 if absrank == 4
replace group_order = 2 if absrank == 8
replace group_order = 3 if absrank == 3
replace group_order = 4 if absrank == 2
replace group_order = 5 if absrank == 7
replace group_order = 6 if absrank == 9
replace group_order = 7 if absrank == -1
forvalue i = 1/7{
	count if group_order == `i'
	local n`i' = r(N)
}

gen int status_order = .
replace status_order = 1 if status == 3
replace status_order = 2 if status == 5
replace status_order = 3 if status == 4
replace status_order = 4 if status == 2
replace status_order = 5 if status == 1

forvalue i = 1/2{
	count if sex == `i'
	local ng`i' = r(N)
}
tabplot sex group_order, percent(sex) horizontal separate(sex) bar1(barwidth(0.3) color("46 69 184 %70") fintensity(70) lwidth(0)) bar2(barwidth(0.3) color("251 152 81 %70") fintensity(70) lwidth(0)) showval(offset(0.05) format(%2.1f)) subtitle("% by Absolute Rank Group, given Gender") ytitle("") ylabel(2 `" "Male" "(n=`ng1')" "' 1 `" "Female" "(n=`ng2')" "', labgap(midsmall)) xtitle("") xlabel(1 `" "Colleagues" "(n=`n1')" "' 2 `" "Partner" "(n=`n2')" "' 3 `" "Friends" "(n=`n3')" "' 4 `" "Neighbors" "(n=`n4')" "' 5 `" "Parents" "(n=`n5')" "' 6 `" "Multiple" "(n=`n6')" "' 7 `" "No-IC" "(n=`n7')" "') xsize(2.5) ysize(1) aspect(0.15) name(SC1_absrankgender, replace)

forvalue i = 1/5{
	count if age == `i'
	local na`i' = r(N)
}
tabplot age group_order, percent(age) horizontal separate(age) bar1(barwidth(0.6) color("46 69 184 %70") fintensity(20) lwidth(0)) bar2(barwidth(0.6) color("46 69 184 %70") fintensity(40) lwidth(0)) bar3(barwidth(0.6) color("46 69 184 %70") fintensity(60) lwidth(0)) bar4(barwidth(0.6) color("46 69 184 %70") fintensity(80) lwidth(0)) bar5(barwidth(0.6) color("46 69 184 %70") fintensity(100) lwidth(0)) showval(offset(0.05) format(%2.1f)) subtitle("% by Absolute Rank Group, given Age") ytitle("") ylabel(5 `" "16-24" "(n=`na1')" "' 4 `" "25-35" "(n=`na2')" "' 3 `" "36-45" "(n=`na3')" "' 2 `" "46-55" "(n=`na4')" "' 1 `" "55+" "(n=`na5')" "', labgap(midsmall)) xtitle("") xlabel(1 `" "Colleagues" "(n=`n1')" "' 2 `" "Partner" "(n=`n2')" "' 3 `" "Friends" "(n=`n3')" "' 4 `" "Neighbors" "(n=`n4')" "' 5 `" "Parents" "(n=`n5')" "' 6 `" "Multiple" "(n=`n6')" "' 7 `" "No-IC" "(n=`n7')" "') xsize(2.5) ysize(1) aspect(0.3) name(SC1_absrankage, replace)

forvalue i = 1/5{
	count if status_order == `i'
	local ns`i' = r(N)
}
tabplot status_order group_order, percent(status_order) horizontal separate(status_order) bar1(barwidth(0.6) color("249 122 31 %70") fintensity(20) lwidth(0)) bar2(barwidth(0.6) color("249 122 31 %70") fintensity(40) lwidth(0)) bar3(barwidth(0.6) color("249 122 31 %70") fintensity(60) lwidth(0)) bar4(barwidth(0.6) color("249 122 31 %70") fintensity(80) lwidth(0)) bar5(barwidth(0.6) color("249 122 31 %70") fintensity(100) lwidth(0)) showval(offset(0.05) format(%2.1f)) subtitle("% by Absolute Rank Group, given Occupational Position") ytitle("") ylabel(5 `" "Apprentices" "(n=`ns1')" "' 4 `" "Civil servant" "(n=`ns2')" "' 3 `" "White-collar" "(n=`ns3')" "' 2 `" "Self-employed" "(n=`ns4')" "' 1 `" "Blue-collar" "(n=`ns5')" "', labgap(midsmall)) xtitle("") xlabel(1 `" "Colleagues" "(n=`n1')" "' 2 `" "Partner" "(n=`n2')" "' 3 `" "Friends" "(n=`n3')" "' 4 `" "Neighbors" "(n=`n4')" "' 5 `" "Parents" "(n=`n5')" "' 6 `" "Multiple" "(n=`n6')" "' 7 `" "No-IC" "(n=`n7')" "') xsize(2.5) ysize(1) aspect(0.3) name(SC1_absrankstatus, replace)

restore






********** the gross income adequacy perceptions **********
*** use "income adequacy" variables with seven-scale Likert data
foreach v in doh22_21 doh22_22 doh22_23 doh22_24 doh22_26 doh22_27{
	kwallis `v' if doh22_20 != -1 & `v' != -1 & `v' != -2, by(doh22_20)
}

*** plot for income adequacy distribution
preserve
keep pid sex age SC0 rank_02 rank_03 rank_04 rank_07 rank_08 absrank doh22_20 doh22_21 doh22_22 doh22_23 doh22_24 doh22_26 doh22_27
reshape long doh22_, i(pid) j(group) string
gen int order_group = .
replace order_group = 1 if group == "20"
replace order_group = 2 if group == "24"
replace order_group = 3 if group == "21"
replace order_group = 4 if group == "23"
replace order_group = 5 if group == "22"
replace order_group = 6 if group == "27"
replace order_group = 7 if group == "26"

tabstat doh22_ if doh22_ != -1 & doh22_ != -2, by(order_group) stat(n) save
forvalue i = 1/7{
	local n`i': display r(Stat`i')[1,1]
}

graph hbar (count) if doh22_ != -1 & doh22_ != -2, over(doh22_) over(order_group, gap(100) relabel(1 `" "Self-income Adequacy" "( n=`n1' )" "' 2 `" "Same Occupation" "Colleagues  ( n=`n2' )" "' 3 `" "Neighbors  ( n=`n3' )" "'  4 `" "Workplace Colleagues" "( n=`n4' )" "' 5 `" "Friends  ( n=`n5' )" "' 6`" "Partner  ( n=`n6' )" "' 7 `" "Parents  ( n=`n7' )" "') label(labsize(small))) asyvars percentages stack bar(1, fcolor("46 69 184 %90") fintensity(90) lcolor(none)) bar(2, fcolor("46 69 184 %90") fintensity(70) lcolor(none)) bar(3, fcolor("46 69 184 %90") fintensity(50) lcolor(none)) bar(4, fcolor("225 223 208 %90") fintensity(110) lcolor(none)) bar(5, fcolor("251 152 81 %90") fintensity(50) lcolor(none)) bar(6, fcolor("251 152 81 %90") fintensity(70) lcolor(none)) bar(7, fcolor("251 152 81 %90") fintensity(90) lcolor(none)) blabel(bar, size(small) position(center) format(%5.3g)) ytitle(, size(zero)) ylabel(, nolabels noticks) note("Source: SOEP-IS 2022", size(vsmall) position(7)) legend(stack rows(1) size(small) region(fcolor(none)) position(12)) xsize(2) ysize(1) name(SC3_adequacy, replace)

restore



*** table for heterogeneity
eststo clear
local i=1
foreach v in doh22_20 doh22_21 doh22_22 doh22_23 doh22_24 doh22_26 doh22_27{
	quietly kwallis `v' if `v' != -1 & `v' != -2, by(sex)
	local p1: display chi2tail(r(df), r(chi2_adj))
	quietly kwallis `v' if `v' != -1 & `v' != -2, by(age)
	local p2: display chi2tail(r(df), r(chi2_adj))	
	quietly kwallis `v' if `v' != -1 & `v' != -2 & status!= -1, by(status)
	local p3: display chi2tail(r(df), r(chi2_adj))	
	quietly kwallis `v' if `v' != -1 & `v' != -2, by(absrank)
	local p4: display chi2tail(r(df), r(chi2_adj))
	quietly count if `v' != -1 & `v' != -2
	local p5 = r(N)
	matrix r`i' = (`p1',`p2',`p3',`p4',`p5')
	local ++i
} 

matrix R = (r1\r2\r3\r4\r5\r6\r7)
matrix rownames R = Self Neighbors Friends Colleagues SameOccupation Parents Partner
matrix colnames R = Gender Age Occupational-Position Absolute-Rank-Group N
esttab matrix(R, fmt(3 3 3 3 0)) 



*** plot on heterogeneity for income adequacy
preserve
foreach v in doh22_20 doh22_21 doh22_22 doh22_23 doh22_24 doh22_26 doh22_27{
	replace `v' = . if `v' == -2 | `v' == -1
}
tabstat doh22_20 doh22_21 doh22_22 doh22_23 doh22_24 doh22_26 doh22_27, by(sex) stats(mean p50 n)
tabstat doh22_20 doh22_21 doh22_22 doh22_23 doh22_24 doh22_26 doh22_27, by(age) stats(mean p50 n)
tabstat doh22_20 doh22_21 doh22_22 doh22_23 doh22_24 doh22_26 doh22_27 if status!=-1, by(status) stats(mean p50 n)
tabstat doh22_20 doh22_21 doh22_22 doh22_23 doh22_24 doh22_26 doh22_27, by(absrank) stats(mean p50 n)

keep pid sex age status absrank doh22_20 doh22_21 doh22_22 doh22_23 doh22_24 doh22_26 doh22_27
reshape long doh22_, i(pid) j(group) string
gen int order_group = .
replace order_group = 1 if group == "20"
replace order_group = 2 if group == "24"
replace order_group = 3 if group == "21"
replace order_group = 4 if group == "23"
replace order_group = 5 if group == "22"
replace order_group = 6 if group == "27"
replace order_group = 7 if group == "26"
tabstat doh22_, by(order_group) stat(n) save

graph hbar (count), over(doh22_) over(order_group, gap(0) relabel(1 "Self-income Adequacy" 2 "Same Occupation Colleagues" 3 "Neighbors" 4 "Workplace Colleagues" 5 "Friends" 6 "Partner" 7 "Parents") label(labsize(small))) over(sex) asyvars percentages stack bar(1, fcolor("46 69 184 %80") fintensity(80) lcolor(none)) bar(2, fcolor("46 69 184 %80") fintensity(60) lcolor(none)) bar(3, fcolor("46 69 184 %80") fintensity(40) lcolor(none)) bar(4, fcolor("225 223 208 %80") fintensity(100) lcolor(none)) bar(5, fcolor("251 152 81 %80") fintensity(40) lcolor(none)) bar(6, fcolor("251 152 81 %80") fintensity(60) lcolor(none)) bar(7, fcolor("251 152 81 %80") fintensity(80) lcolor(none)) blabel(bar, position(center) format(%5.2g)) ytitle(, size(zero)) ylabel(0(25)100, nolabels noticks) title("The Income Adequacy Comparison Distribution - by Gender", size(medsmall) position(6)) note("Source: SOEP-IS 2022", size(vsmall) position(1)) legend(stack rows(1) size(small) region(fcolor(none)) position(12)) xsize(2) ysize(1) name(SC3_adequacygender, replace) 

gen int status_order = .
replace status_order = 1 if status == 3
replace status_order = 2 if status == 5
replace status_order = 3 if status == 4
replace status_order = 4 if status == 1
replace status_order = 5 if status == 2

graph hbar (count), over(doh22_) over(order_group, gap(0) relabel(1 "Self-income Adequacy" 2 "Same Occupation Colleagues" 3 "Neighbors" 4 "Workplace Colleagues" 5 "Friends" 6 "Partner" 7 "Parents") label(labsize(vsmall))) over(status_order, relabel(1 "Apprentices" 2 "Civil servant" 3 "White-collar" 4 "Blue-collar" 5 "Self-employed") label(labsize(small))) asyvars percentages stack bar(1, fcolor("46 69 184 %80") fintensity(80) lcolor(none)) bar(2, fcolor("46 69 184 %80") fintensity(60) lcolor(none)) bar(3, fcolor("46 69 184 %80") fintensity(40) lcolor(none)) bar(4, fcolor("225 223 208 %80") fintensity(100) lcolor(none)) bar(5, fcolor("251 152 81 %80") fintensity(40) lcolor(none)) bar(6, fcolor("251 152 81 %80") fintensity(60) lcolor(none)) bar(7, fcolor("251 152 81 %80") fintensity(80) lcolor(none)) ylabel(0(25)100, nolabels noticks) ytitle(, size(zero)) legend(off) title("The Income Adequacy Comparison Distribution - by Occupational Position", size(medsmall) position(6)) xsize(2) ysize(1) name(SC3_adequacystatus, replace)

restore





*** non-parametric regression on all groups: table and figure
preserve

count if doh22_21 != -1 & doh22_22 != -1 & (doh22_23 != -2 & doh22_23 != -1) & doh22_24 != -1 & doh22_26 != -1 & doh22_27 != -1
foreach v in doh22_20 doh22_21 doh22_22 doh22_23 doh22_24 doh22_26 doh22_27{
	replace `v' = . if `v' == -2 | `v' == -1
}
count if doh22_21 != -1 & doh22_22 != -1 & (doh22_23 != -2 & doh22_23 != -1) & doh22_24 != -1 & doh22_26 != -1 & doh22_27 != -1

eststo clear
eststo ologit1: quietly ologit doh22_20 doh22_21 doh22_22 doh22_23 doh22_24 doh22_26 doh22_27
eststo ologit2: quietly ologit doh22_20 doh22_21 doh22_22 doh22_23 doh22_24 doh22_26 doh22_27, or
estadd brant

forvalue i = 1/2{
	eststo ologit_g`i': quietly ologit doh22_20 doh22_21 doh22_22 doh22_23 doh22_24 doh22_26 doh22_27 if sex == `i' 
}

*** table
esttab ologit1 ologit2, cell("b(star fmt(2) label({Coefficients}) pattern(1 0)) b(star fmt(2) label({Odds Ratios}) pattern(0 1)) se(par fmt(2) label( )) brant[p>chi2](fmt(2) label(\small Brant-test p-value) pattern(0 1))") eform(0 1) stats(N r2_p chi2 p, fmt(0 2 2 2) labels("Obs." "Pseudo R-squared" "Chi2" "P-value")) drop(cut*) eqlabels(none) varlabels(doh22_21 "Neighbors" doh22_22 "Friends" doh22_23 "Colleagues" doh22_24 "Same Occupation" doh22_26 "Parents" doh22_27 "Partner") nonumber nomtitle mgroups("Dependent variable: Self-income adequacy perception" pattern(1 0)) title("Ordered Logistic Regression on Income Adequacy Comparison\label{tsc3oreg}") legend addnotes("Standard errors are in parentheses. Significant level:" "Brant-test \(p < 0.05 \) provides significant evidence that the parallel regression assumption has been violated" "Independent variables: Relative-income adequacy perceptions towards the six different groups" "Brant-test p-value: provides significant evidence that the parallel regression assumption has been violated" "Source: SOEP-IS 2022") gaps compress width(\linewidth)
* using "$infile\analysis\table\SC_3_oreg.tex", replace booktabs 



*** plot
coefplot (ologit1, label(All) ciopts(recast(rcap) lwidth(.2) lcolor("89 89 89 %50")) recast(connected) msymbol(o) mcolor("89 89 89 %100") msize(5pt) lcolor("89 89 89 %50") lwidth(0.5)) (ologit_g1, label(Male) ciopts(recast(rcap) lwidth(.2) lcolor("46 69 184 %50")) recast(bar) barwidth(0.2) color("46 69 184 %70") fintensity(70) lwidth(0)) (ologit_g2, label(Female) ciopts(recast(rcap) lwidth(.2) lcolor("251 152 81 %50")) recast(bar) barwidth(0.2) color("251 152 81 %70") fintensity(70) lwidth(0)), vertical sort(, descending) subtitle("Log Odds of Regression") note("Obs.= 479" "Source: SOEP-IS 2022") ylabel(,labsize(small) format("%03.1f")) mlabel(cond(@pval<.001, string(@b, "%4.2f") + "***", cond(@pval<.01, string(@b,"%4.2f") + "**", cond(@pval<.05, string(@b,"%4.2f") + "*", " ")))) msize(vsmall) mcolor("89 89 89 %70") mlabposition(0) coeflabels(doh22_21="Neighbors" doh22_22="Friends" doh22_23="Workplace Colleagues" doh22_24="Same Occupation Colleagues" doh22_26="Parents" doh22_27="Partner", wrap(15) nobreak labsize(small)) legend(rows(1) stack position(12) ring(0)) xsize(2) ysize(1) name(SC3_oreg, replace)
* saving("$infile\analysis\fig\SC3_oreg", replace)





*** non-parametric regress on specific group: table and figure
*** tabel
foreach v in doh22_21 doh22_22 doh22_23 doh22_24 doh22_26 doh22_27{
	local i = substr("`v'", 7, .)
	rename `v' adequacy`i'
}
reshape long adequacy, i(pid) j(group)

eststo clear
eststo all05: quietly ologit doh22_20 adequacy if group==24
estadd brant
eststo imp05: quietly ologit doh22_20 adequacy if group==24 & (rank_04==5|rank_04==6)
estadd brant
eststo nim05: quietly ologit doh22_20 adequacy if group==24 & (rank_04==-1|rank_04==1|rank_04==2|rank_04==3|rank_04==4)
estadd brant
forvalue i = 1/2{
	eststo imp05_g`i': quietly ologit doh22_20 adequacy if group==24 & (rank_04==5|rank_04==6) & sex == `i' 
}
forvalue i = 1/5{
	eststo imp05_s`i': quietly ologit doh22_20 adequacy if group==24 & (rank_04==5|rank_04==6) & status == `i' 
}
foreach v in 02 03 04 07 08{
	local i = `v'+19
	rename adequacy doh22_`i'
	eststo all`v': quietly ologit doh22_20 doh22_`i' if group==`i'
	estadd brant
	eststo imp`v': quietly ologit doh22_20 doh22_`i' if group==`i' & (rank_`v'==5|rank_`v'==6)
	estadd brant
	forvalue t = 1/2{
		eststo imp`v'_g`t': quietly ologit doh22_20 doh22_`i' if group==`i' & (rank_`v'==5|rank_`v'==6) & sex==`t'
	}
	eststo nim`v': quietly ologit doh22_20 doh22_`i' if group==`i' & (rank_`v'==-1|rank_`v'==1|rank_`v'==2|rank_`v'==3|rank_`v'==4)
	estadd brant
	rename doh22_`i' adequacy
}

do "$infile\analysis\repository\appendmodels.do"
eststo all: appendmodels all02 all03 all04 all05 all07 all08
eststo imp: appendmodels imp02 imp03 imp04 imp05 imp07 imp08
eststo nim: appendmodels nim02 nim03 nim04 nim05 nim07 nim08

esttab all imp nim, cells("b(star fmt(2) label(Odds Ratios)) N" "se(par) brant[p>chi2](fmt(2) label(Brant-p))") eqlabels(none) mtitles("Logistic on: All" "Most Important" "Not Most Important") varlabels(doh22_21 "Neighbors" doh22_22 "Friends" doh22_23 "Colleagues" adequacy "Same Occupation" doh22_26 "Parents" doh22_27 "Partner") title("Ordered Logistic Regression on Adequacy Comparison with Importance Rank\label{tsc3oreg2}") mgroups("Dependent variable: Self-income adequacy perception" pattern(1 0 0)) legend addnotes("Standard errors are in parentheses. Significant level:" "Independent variable: Relative-income adequacy perceptions towards the six different groups separately" "Source: SOEP-IS 2022") nonumber noobs gaps compress width(\linewidth)
* using "$infile\analysis\table\SC_3_oreg2.tex", replace booktabs 



*** plot
coefplot (nim05) (all05) (imp05, mlabel(cond(@pval<.001, string(@b, "%4.2f") + "***", cond(@pval<.01, string(@b,"%4.2f") + "**", cond(@pval<.05, string(@b,"%4.2f") + "*", " "))))) (imp05_g1) (imp05_g2), bylabel("Same Occupation Colleagues") || (nim02) (all02) (imp02, mlabel(cond(@pval<.001, string(@b, "%4.2f") + "***", cond(@pval<.01, string(@b,"%4.2f") + "**", cond(@pval<.05, string(@b,"%4.2f") + "*", " "))))) (imp02_g1) (imp02_g2), bylabel("Neighbors") || (nim04) (all04) (imp04, mlabel(cond(@pval<.001, string(@b, "%4.2f") + "***", cond(@pval<.01, string(@b,"%4.2f") + "**", cond(@pval<.05, string(@b,"%4.2f") + "*", " "))))) (imp04_g1) (imp04_g2), bylabel("Workplace Colleagues") || (nim07) (all07) (imp07) (imp07_g1) (imp07_g2), bylabel("Parents") || (nim03) (all03) (imp03, mlabel(cond(@pval<.001, string(@b, "%4.2f") + "***", cond(@pval<.01, string(@b,"%4.2f") + "**", cond(@pval<.05, string(@b,"%4.2f") + "*", " "))))) (imp03_g1) (imp03_g2), bylabel("Friends") || (nim08) (all08) (imp08, mlabel(cond(@pval<.001, string(@b, "%4.2f") + "***", cond(@pval<.01, string(@b,"%4.2f") + "**", cond(@pval<.05, string(@b,"%4.2f") + "*", " "))))) (imp08_g1) (imp08_g2), bylabel("Partner") ||, vertical sort(, descending) byopts(row(2) yrescale imargin(medium) note("Source: SOEP-IS 2022", size(vsmall))) rename(doh22_21="" doh22_22="" doh22_23="" adequacy="" doh22_26="" doh22_27="") p1(label("Not Most Important") ciopts(recast(rcap) lwidth(.2) lcolor("89 89 89 %70")) recast(bar) barwidth(0.1) color("89 89 89 %50") fintensity(50) lwidth(0)) p2(label("All") ciopts(recast(rcap) lwidth(.2) lcolor("89 89 89 %100")) recast(bar) barwidth(0.1) color("89 89 89 %75") fintensity(75) lwidth(0)) p3(label("Most Important") ciopts(recast(rcap) lwidth(.2) lcolor("227 18 11 %70")) recast(bar) barwidth(0.1) color("227 18 11 %70") fintensity(70) lwidth(0)) p4(label("Male") ciopts(recast(rcap) lwidth(.2) lcolor("46 69 184 %50")) recast(scatter) msymbol(o) mcolor("46 69 184 %50") msize(3pt)) p5(label("Female") ciopts(recast(rcap) lwidth(.2) lcolor("251 152 81 %50")) recast(scatter) msymbol(o) mcolor("251 152 81 %50") msize(3pt)) subtitle(, size(medsmall) margin(vsmall) justification(left) bcolor(none)) legend(rows(1)) xsize(2) ysize(1) name(SC3_oreg2, replace) 
* saving("$infile\analysis\fig\SC3_oreg2", replace)

restore





********** Peer Module of two closest colleagues **********

count if doh22_ste != 0
count if doh22_ste != 0 & doh22_ste != 1

*** tabel for the association between demographics and two peers

preserve

keep if doh22_ste != 0
foreach v in doh22_31a doh22_32a doh22_42a doh22_stella1 doh22_bila2 doh22_colla doh22_verda doh22_einscha doh22_31b doh22_32b doh22_42b doh22_stellb1 doh22_bilb2 doh22_collb doh22_verdb doh22_einschb{
	replace `v' = . if `v' == -2 | `v' == -1
}

foreach v in doh22_colla doh22_collb{
	clonevar order`v' = `v' if `v' != -2 & `v' != -1
	replace order`v' = 1 if `v' == 1
	replace order`v' = 2 if `v' == 2
	replace order`v' = 3 if `v' == 5 
	replace order`v' = 4 if `v' == 4
	replace order`v' = 5 if `v' == 3
	local i = substr("`v'", 6, .)
	rename order`v' peer`i'
}

eststo clear
local i=1
foreach v in doh22_31a doh22_32a doh22_42a doh22_stella1 doh22_bila2 peer_colla doh22_verda doh22_31b doh22_32b doh22_42b doh22_stellb1 doh22_bilb2 peer_collb doh22_verdb{
	quietly tabulate `v' sex, chi2
	local p1 = r(p)
	quietly tabulate `v' age, chi2
	local p2 = r(p)
	quietly tabulate `v' status if status!=-1, chi2
	local p3 = r(p)
	quietly tabulate `v' absrank, chi2
	local p4 = r(p)
	quietly count if `v' != .
	local p5 = r(N)
	matrix r`i' = (`p1',`p2',`p3',`p4',`p5')
	local ++i
}

matrix R = (r1\r8\r2\r9\r3\r10\r4\r11\r5\r12\r6\r13\r7\r14)
matrix rownames R = "Gender - A" " - B" "Age - A" " - B" "Seniority - A" " - B" "Professional Position - A " " - B" "Educational Background - A" " - B" "Professional Relationship - A" " - B" "Evaluation Earnings - A" " - B"
matrix colnames R = Gender Age status absrank N

esttab matrix(R, fmt(3 3 3 3 0))

restore





*** plot for gender
preserve
foreach v in doh22_31a doh22_31b{
	replace `v' = . if `v' == -2 | `v' == -1
	local i = substr("`v'", 7, .)
	rename `v' peer`i'
}
reshape long peer, i(pid) j(group) string
catplot peer group sex, asyvar stack percentages blabel(bar, size(small) position(center)) var1opts(relabel(3 "Other gender")) var2opts(relabel(1 "Peer A" 2 "Peer B")) var3opts(label(labsize(small))) bar(1, color(gold*.6) lcolor(none)) bar(2, color(khaki*1.3) lcolor(none)) bar(3, color(gs4) lcolor(none)) ytitle("Two Colleagues' Gender Distribution - by Respondents' Gender", size(medsmall)) ylabel(,noticks nolabels) note("Y-axis: respondents' gender" "Source: SOEP-IS 2022", size(small) position(7)) legend(row(1) stack forcesize keygap(.7) symxsize(13) size(small) position(11) note("the peer's gender is:", size(small) position(11))) name(SC4_gender1, replace)
restore

preserve
foreach v in doh22_colla doh22_collb{
	clonevar order`v' = `v' if `v' != -2 & `v' != -1
	replace order`v' = 1 if `v' == 1
	replace order`v' = 2 if `v' == 2
	replace order`v' = 3 if `v' == 5 
	replace order`v' = 4 if `v' == 4
	replace order`v' = 5 if `v' == 3
	local i = substr("`v'", 6, .)
	rename order`v' peer`i'
}
reshape long peer, i(pid) j(group) string
catplot peer group sex, asyvar stack percentages blabel(bar, size(small) position(center)) var1opts(relabel(1 `""supervised by" "respondent""' 2 `""at lower level" "but not supervised""' 3 `""at the" "same level""' 4 `""at higher level" "but not supervisor""' 5 `""supervisor of" "respondent""')) var2opts(relabel(1 "Peer A" 2 "Peer B")) var3opts(label(labsize(small))) bar(1,lcolor(none)) bar(2,lcolor(none)) bar(3,lcolor(none)) bar(4,lcolor(none)) bar(5,lcolor(none)) ytitle("Two Colleagues' Professional Relationship Distribution - by Respondents' Gender", size(medsmall)) ylabel(,noticks nolabels) note("Y-axis: respondents' gender" "Source: SOEP-IS 2022", size(small) position(7)) legend(row(1) stack forcesize keygap(.7) symxsize(13) size(small) position(11) note("the peer's relationship to respondent is:", size(small) position(11))) name(SC4_gender2, replace)
restore



*** plot for age
preserve
foreach v in doh22_32a doh22_32b{
	replace `v' = . if `v' == -2 | `v' == -1
	local i = substr("`v'", 7, .)
	rename `v' peer`i'
}
reshape long peer, i(pid) j(group) string
catplot peer group age, asyvar stack percentages blabel(bar, size(small) position(center)) var2opts(relabel(1 "Peer A" 2 "Peer B")) var3opts(label(labsize(small))) bar(1,lcolor(none)) bar(2,lcolor(none)) bar(3,lcolor(none)) bar(4,lcolor(none)) bar(5,lcolor(none)) ytitle("Two Colleagues' Age Distribution - by Respondents' Age", size(medsmall)) ylabel(,noticks nolabels) note("Y-axis: respondents' age" "Source: SOEP-IS 2022", size(small) position(7)) legend(row(1) stack forcesize keygap(.7) symxsize(13) size(small) position(11) note("the peer's age is:", size(small) position(11))) name(SC4_age1, replace)
restore

preserve
foreach v in doh22_42a doh22_42b{
	replace `v' = . if `v' == -2 | `v' == -1
	local i = substr("`v'", 7, .)
	rename `v' peer`i'
}
reshape long peer, i(pid) j(group) string
catplot peer group age, asyvar stack percentages blabel(bar, size(small) position(center)) var2opts(relabel(1 "Peer A" 2 "Peer B")) var3opts(label(labsize(small))) bar(1,lcolor(none)) bar(2,lcolor(none)) bar(3,lcolor(none)) bar(4,lcolor(none)) bar(5,lcolor(none)) ytitle("Two Colleagues' Seniority Distribution - by Respondents' Age", size(medsmall)) ylabel(,noticks nolabels) note("Y-axis: respondents' age" "Source: SOEP-IS 2022", size(small) position(7)) legend(row(1) stack forcesize keygap(.7) symxsize(13) size(small) position(11) note("the peer has been employed:", size(small) position(11))) name(SC4_age2, replace)
restore



*** plot for status
preserve
foreach v in doh22_bila2 doh22_bilb2{
	replace `v' = . if `v' == -2 | `v' == -1
	local i = substr("`v'", 7, .)
	rename `v' peer`i'
}
gen int status_order = .
replace status_order = 1 if status == 3
replace status_order = 2 if status == 5
replace status_order = 3 if status == 4
replace status_order = 4 if status == 1
replace status_order = 5 if status == 2
reshape long peer, i(pid) j(group) string
graph dot (median) peer, over(group, relabel(1 " A" 2 " B") label(labsize(vsmall))) over(status_order, relabel(1 "Apprentices" 2 "Civil servant" 3 "White-collar" 4 "Blue-collar" 5 "Self-employed") label(labsize(small))) marker(1, mcolor("251 152 81") msize(3-pt) msymbol(circle)) marker(2, mcolor("251 152 81") msize(3-pt)) linetype(line) lines(lcolor(gs7) lwidth(vthin) lpattern(vshortdash)) ytitle(, size(zero) margin(medsmall) justification(left) alignment(middle)) ylabel(1(1)14, labels labsize(vsmall) valuelabel noticks) name(SC4_status1, replace) xsize(2) ysize(1)
restore



*** regression on the income comparison of two colleagues
*** tabel
eststo clear
foreach v in doh22_23 doh22_einscha doh22_einschb{
	eststo all`v': quietly ologit doh22_20 `v' if (doh22_20!=-1 & doh22_20!=-2) & (`v'!=-1 & `v'!=-2)
	eststo imp`v': quietly ologit doh22_20 `v' if (doh22_20!=-1 & doh22_20!=-2) & (`v'!=-1 & `v'!=-2) & (rank_04==5|rank_04==6)
	eststo nim`v': quietly ologit doh22_20 `v' if (doh22_20!=-1 & doh22_20!=-2) & (`v'!=-1 & `v'!=-2) & (rank_04==-1|rank_04==1|rank_04==2|rank_04==3|rank_04==4)
}

do "$infile\analysis\repository\appendmodels.do"
eststo all: appendmodels alldoh22_23 alldoh22_einscha alldoh22_einschb 
eststo imp: appendmodels impdoh22_23 impdoh22_einscha impdoh22_einschb 
eststo nim: appendmodels nimdoh22_23 nimdoh22_einscha nimdoh22_einschb 

esttab all imp nim, cells("b(star fmt(2) label(Log Odds)) N" "se(par)") eqlabels(none) mtitles("Logistic on: All" "Most Important" "Not Most Important") varlabels(doh22_23 "Workplace Colleagues" doh22_einscha "Closest Colleague A" doh22_einschb "Closest Colleague B") title("Ordered Logistic Regression on Adequacy Comparison with Importance Rank\label{tsc4oreg}") mgroups("Dependent variable: Self-income adequacy perception" pattern(1 0 0)) legend addnotes("Standard errors are in parentheses. Significant level:" "Independent variable: Relative-income comparison to the different workplace colleagues separately" "Source: SOEP-IS 2022") nonumber noobs gaps compress width(\linewidth)
* using "$infile\analysis\table\SC_4_oreg.tex", replace booktabs



*** plot
coefplot (nimdoh22_23) (alldoh22_23) (impdoh22_23), bylabel("Workplace Colleagues") || (nimdoh22_einscha) (alldoh22_einscha) (impdoh22_einscha), bylabel("Closest Colleague A") || (nimdoh22_einschb) (alldoh22_einschb) (impdoh22_einschb), bylabel("Closest Colleague B") ||, vertical sort(, descending) mlabel(cond(@pval<.001, string(@b, "%4.2f") + "***", cond(@pval<.01, string(@b,"%4.2f") + "**", cond(@pval<.05, string(@b,"%4.2f") + "*", " ")))) byopts(row(1) yrescale imargin(medium) note("Log Odds of Regression" "Source: SOEP-IS 2022", size(vsmall))) rename(doh22_23="" doh22_einscha="" doh22_einschb="") p1(label("Not Most Important") ciopts(recast(rcap) lwidth(.3) lcolor("89 89 89 %70")) recast(bar) barwidth(0.15) color("89 89 89 %50") fintensity(50) lwidth(0)) p2(label("All") ciopts(recast(rcap) lwidth(.3) lcolor("89 89 89 %100")) recast(bar) barwidth(0.15) color("89 89 89 %75") fintensity(75) lwidth(0)) p3(label("Most Important") ciopts(recast(rcap) lwidth(.3) lcolor("227 18 11 %70")) recast(bar) barwidth(0.15) color("227 18 11 %70") fintensity(70) lwidth(0)) subtitle(, size(medsmall) margin(vsmall) justification(left) bcolor(none)) legend(rows(1)) xsize(2.5) ysize(1) name(SC4_oreg, replace)



*** plot for income comparison of two colleagues
preserve
keep pid sex age rank_04 doh22_20 doh22_23 doh22_24 doh22_einscha doh22_einschb
reshape long doh22_, i(pid) j(group) string

gen int order_group = .
replace order_group = 1 if group == "20"
replace order_group = 2 if group == "24"
replace order_group = 3 if group == "23"
replace order_group = 4 if group == "einscha"
replace order_group = 5 if group == "einschb"

tabstat doh22_ if doh22_ != -1 & doh22_ != -2, by(order_group) stat(n) save
forvalue i = 1/5{
	local n`i': display r(Stat`i')[1,1]
}

graph hbar (count) if doh22_ != -1 & doh22_ != -2 & order_group != 1, over(doh22_) over(order_group, relabel(1 `" "Same Occupation Colleagues" "(n=`n2')" "' 2 `" "Workplace Colleagues" "(n=`n3')" "' 3 `" "Closest Colleagues A" "(n=`n4')" "' 4 `" "Closest Colleagues B" "(n=`n5')" "') label(labsize(small))) asyvars percentages stack bar(1, fcolor("46 69 184 %90") fintensity(80) lcolor(none)) bar(2, fcolor("46 69 184 %90") fintensity(60) lcolor(none)) bar(3, fcolor("46 69 184 %90") fintensity(40) lcolor(none)) bar(4, fcolor("225 223 208 %90") fintensity(100) lcolor(none)) bar(5, fcolor("251 152 81 %90") fintensity(40) lcolor(none)) bar(6, fcolor("251 152 81 %90") fintensity(60) lcolor(none)) bar(7, fcolor("251 152 81 %90") fintensity(80) lcolor(none)) outergap(30) blabel(bar, size(small) position(center) format(%5.3g)) ytitle("% Distribution of Respondents' Income Comparision to Different Colleagues", size(medsmall) justification(left)) note("Source: SOEP-IS 2022", size(vsmall) position(1) justification(right)) legend(stack rows(1) size(small) region(fcolor(none)) position(12)) xsize(2.5) ysize(1) name(SC4_adequacy, replace)

restore




preserve
foreach v in doh22_colla doh22_collb{
	clonevar order`v' = `v' if `v' != -2 & `v' != -1
	replace order`v' = 1 if `v' == 5
	replace order`v' = 2 if `v' == 3
	replace order`v' = 3 if `v' == 4 
	replace order`v' = 4 if `v' == 1
	replace order`v' = 5 if `v' == 2
	local i = substr("`v'", 6, .)
	rename order`v' peer`i'
}
keep pid sex age doh22_einscha doh22_einschb peer_colla peer_collb
reshape long doh22_, i(pid) j(group) string
generate coll = .
replace coll = peer_colla if group == "einscha"
replace coll = peer_collb if group == "einschb"

graph hbar (count) if doh22_ != -1 & doh22_ != -2, over(doh22_) over(coll, gap(5) relabel(1 "Same lever" 2 "Be Supervised" 3 "Lower lever" 4 "Supervisor of" 5 "Higher level") label(labsize(vsmall))) over(group, relabel(1 "A" 2 "B") label(labsize(small))) asyvars percentages stack bar(1, fcolor("46 69 184 %90") fintensity(80) lcolor(none)) bar(2, fcolor("46 69 184 %90") fintensity(60) lcolor(none)) bar(3, fcolor("46 69 184 %90") fintensity(40) lcolor(none)) bar(4, fcolor("225 223 208 %90") fintensity(100) lcolor(none)) bar(5, fcolor("251 152 81 %90") fintensity(40) lcolor(none)) bar(6, fcolor("251 152 81 %90") fintensity(60) lcolor(none)) bar(7, fcolor("251 152 81 %90") fintensity(80) lcolor(none)) blabel(bar, size(small) position(center) format(%5.3g)) ytitle("% Distribution of Respondents' Income Comparision to Closest Colleagues - by Professional Relationship", size(medsmall) justification(left)) legend(off) xsize(2) ysize(1) name(SC4_adequacyrelation, replace)

restore







