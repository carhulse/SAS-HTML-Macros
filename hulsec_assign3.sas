/*Question 1*/
*1. Temporary datasets & removal of duplicates;

DATA clients;
	SET '/folders/myfolders/STAT466/Assignment 3/clients.sas7bdat';

PROC SORT DUPOUT=clientsremoved NODUPRECS;
	by lastname;
RUN;

/*2 observations with duplicate key values were found & deleted: Hariette and Nicole.*/
DATA projects;
	SET '/folders/myfolders/STAT466/Assignment 3/projects.sas7bdat';

PROC SORT NODUPKEY;
	BY ProjectID;
RUN;

/*0 observations with duplicate key values were found, none deleted.*/
*2. First date, last date, total hours. Merge.;

data totals (rename=(_s=startdate _e=enddate _h=hours));
	do until(last.ProjectID);
		set '/folders/myfolders/STAT466/Assignment 3/time.sas7bdat';
		by ProjectID;
		_s=min(_s, date);
		_e=max(_e, date);
		_h=sum(_h, hours);
	end;
	drop date hours;
	format _s _e date9.;
run;

data merged;
	merge projects totals;
	by ProjectID;
run;

data time;
	do until(last.ProjectID);
		SET '/folders/myfolders/STAT466/Assignment 3/time.sas7bdat';
		by ProjectID;
		hourstotal=sum(hourstotal, hours);
	end;
run;

proc compare base=time compare=merged;
	ID ProjectID;
	var hourstotal;
	with hours;
run;

/*No unequal values were found. All values compared are exactly equal. We can keep them all!*/
*3. Total number of projects, total hours across all projects for each client, merge.;

data merged2;
	MERGE projects merged;
	by ProjectID;
run;

proc sort data=merged2;
	by lastname;
run;

proc summary data=merged2;
	var hours;
	by lastname;
	output out=hoursperclient (drop=_:) sum=HoursPerClient;
run;

data merged3;
	merge hoursperclient merged2;
	by lastname;
run;

data clientprojs;
	set merged3;
	by lastname;

	if last.lastname;
	NumberOfProjects=_n_-sum(lag(_n_), 0);
	keep lastname NumberOfProjects;
run;

data merged4;
	merge merged3 clientprojs;
	by lastname;
run;

*4;
*Getting data we need for Clients.html;

data clients_final;
	merge clients merged4;
	by lastname;
	keep firstname lastname HoursPerClient NumberOfProjects;

proc sort nodupkey;
	by lastname;
run;

data Clients;
	set clients_final;
	array days[1] DaysPerClient;
	array HPC[1] HoursPerClient;

	do i=1 to dim(HPC);

		if HPC[i]=. then
			delete;
		days[i]=round(Hpc[i]/7.5, .1);
	end;
	drop i;
run;

*Getting data we need for Projects.html;

data Projects;
	set merged4;
	by lastname;
	drop grant projectID publication NumberOfProjects HoursPerClient;
run;

data Projects;
	set projects;
	array HPP[1] hours;
	array days[1] DaysPerProject;

	do i=1 to dim(HPP);

		if HPP[i]=. then
			delete;
		days[i]=round(HPP[i]/7.5, .1);
	end;
	drop i hours;
run;

*Now time to set up HTML;

data _null_;
	set Projects end=eof;
	by lastname;
	file "/folders/myfolders/STAT466/Assignment 3/CarlyOut/Projects.html";

	if _n_=1 then
		do;
			put'<html><center><h1> Projects by Client </h1></center>';
		end;

	if first.lastname then
		put '<a name=' lastname firstname'</a><h2>' lastname+(-1)', ' 
			firstname'</h2>';
	put '<b>' Title +(-1) ": " '</b>' DaysPerProject 9.1 " days between" startdate 
		worddate20. ' and' enddate worddate20. '.' '<br><br>';

	if eof then
		put '</html>';
run;

data _null_;
	set Clients end=eof;
	by lastname;
	file "/folders/myfolders/STAT466/Assignment 3/CarlyOut/Clients.html";

	if _n_=1 then
		do;
			put'<html><center><h1> Client Report </h1></center>';
		end;

	if first.lastname then
		put '<a href=' "projects.html#"lastname '>' lastname+(-1)', ' firstname 
			'</a>' NumberofProjects " project(s) totaling" DaysPerClient 9.1 " days." 
			'<br>';

	if eof then
		put '</html>';
run;

/*Question 2*/
options MLOGIC MPRINT SYMBOLGEN;
%let n = 100;
%let sims = 1;
%let outdata = binorm;
%let plot = y;
run;

%macro binorm(mux=0, muy=0, stdx=1, stdy=1, rho=0);
	data simdat;
		call streaminit(0);

		do i=1 to &sims;
			A(=X)=randnorm(&n, mux, muy);
			B(=X’)=randnorm(&n, mux, muy);
			simnum=1;

			do j=1 to &n;
				Y=rho*A+sqrt(1-rho**2)*B;
				output;
			end;
		end;
	%mend binorm;

	%macro analyze;
	proc reg data=simdat noprint outest=results tableout;
		model Y=rho*A+sqrt(1-rho**2)*B;
		by simnum;
		run;
	%mend analyze;

	%macro simulate;
		%if %upcase(%substr(&plot, 1, 1))=Y %then
			%do;

			proc sgscatter data=&outdata;
				PLOT X * Y;
				Title "Plot of y vs. x";
				Title2 "n=100, X~N(&mux, &stdx), Y~N(&muy, &stdy), corr(x, y)";
				Title3 "&sims";
			run;

		%end;

	proc print;
	run;

%mend simulate;

%simulate(100, 0, 0);
%simulate(100, 0, 0.2);
%simulate(100, 0, 0.5);
%simulate(100, 0, 0.9);
run;