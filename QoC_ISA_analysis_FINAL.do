* Set working directory using cd command
	cd
	
******************************************************Open facility level dataset 
	use xxxx.dta, clear 
	count
		
* Check for missing data 
	tab a91,miss
	tab a129,m 
	misstable summarize a18aa a18bb 
	tab a18aa,m
	
* Set svy design 
	svyset facility_code [pw=nwt], strata(strata) singleunit(centered)
	
* Power source with 24 hours backup 
	label define yn 0"No" 1"Yes", replace
	numlabel, add  //includes the numeric code along with the label 
	for var a20 a22 a27: tab X
	
	gen power = 0 
		replace power = 1 if a20==1 & a27==1 
		label values power yn
		label var power "Connect to grid with a functional backup" 
		tab power,m  
		
* Emergency transport 	
	for var a158 a161 a158a a158b a158c a158d a158e a160 a159: tab X
	
	gen transport = 0 
		replace transport = 1 if (a160==1 | a158d==1) & a159==1
		label values transport yn 
		label var transport "Access to emergency transport"
		tab transport, m

	for var a133 a134 a134a a135 a135_other: tab X,m 	
	gen anticov = 0 
		replace anticov=1 if a133==1 | a134==1 | a134a==1 | (a135==1 & a135_other~="Hydralazine")
		label values anticov yn 
		label var anticov "Avail of anticonvulsants"
		tab anticov, m
		
******************************************************Open provider level dataset 
	use xxxx.dta, clear 
	count 
	numlabel, add
	
	* Provider supervision 
		for var b42 b43 b44 b45 b46: tab X,m
		
		*Convert string labels to dates 
			gen date_interview=date(today,"DMY", 2020)
			format date_interview %td
			label var date_interview "Date of Interview"
			
			gen date_super=date(b43,"DMY", 2020)
			format date_super %td
			label var date_super "Date of supervision"

			gen super_mn = month(date_interview - date_super)
			list date_super date_interview super_mn if super_mn~=.
			label var super_mn "Months ago supervision"
		
		gen supervision = 0 
			replace supervision = 1 if super_mn<3 & (b44==1 | b45==1 | b46==1)
			label values supervision yn 
			label var supervision "Supervision"
			tab supervision, m 
			
		for var b44 b45 b46: replace X=0 if X==2 | X==. | X==8  	

		gen super_score = b44 + b45 + b46
			label var super_score "Supervision score 0-3"
			tab super_score
			
		gen super_score1 = (b44 + b45 + b46)/3
			label var super_score1 "Supervision score, weighted"	
			tab super_score1
		
******************************************************Open assessment level dataset 
	use xxxx.dta, clear 
	count 
	numlabel, add
	
* Check for duplicates 
	duplicates report
	isid facility_code
	duplicates report facility_code
	duplicates tag facility_code, gen(dup_tag)
	isid provider_code	
	
	* Account for clustering of providers at the facility level (no sampling weights)
		*c5 = unique facility code 
			svyset facility_code 
	
	* Correct cord clamping 
		for var q2_22 q2_23 q2_24 q2_25: tab X,m
		
	* Cord clamping compound indicator 
		gen cord_care = 0 
			replace cord_care = 1 if q2_22==1 & q2_23==1 & q2_24==1 & q2_25==1 
			label values cord_care yn 
			label var cord_care "Correct cord care"
			tab cord_care, m
			
	* Immediate newborn care 
		for var q2_43 q2_44 q2_45 q2_46 q2_47 q2_41 q2_41a: tab X
		for var q2_43 q2_44 q2_45 q2_46 q2_47 q2_41 q2_41a: replace X=0 if X==2
		
		gen immed_new = (q2_43 + q2_44 + q2_45 + q2_46 + q2_47 + q2_41 + q2_41a)/7
			label var immed_new "Immediate newborn care, weighted score"
			mean immed_new
			svy: mean immed_new	
	
	* Analysis with svy design 
		proportion cord_care		
		svy: proportion cord_care		
	
	* Stratification 
		svy: proportion cord_care, over(facil_type)
		lincom  1.cord_care@1.facil_type - 1.cord_care@2.facil_type
			
