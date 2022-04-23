/*********************************************
 * OPL 20.1.0.0 Model
 * Authors: Daniel, Almog, Nir - Group 7
 * HW 2
 * Creation Date: Apr 16, 2022 at 10:47:36 PM
 *********************************************/
 
execute {cplex.tilim = 60}; //Running time limit

// ***** Parameters ***** 
int T = ...; // Number of hours in a shift
range hours = 1..T;

int D = 6; //Number of work days in a week
range days = 1..D; 
string DAYS_NAME[days] = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"] ;

int scenarios = ...; // Number of different scenarios the model needs to deal with
range S = 1..scenarios; 

range possible_duration = 1..3; // Number of possible duration of shifts
int J[possible_duration] = [4, 6, 8];// Possible duration of shifts

//Setting up the shifts - Preprocessing
int ubN = 15; //There are 15 possible shifts, more information in PDF file
{int} A[1..ubN];
int N = 0;

execute
{
  for (var pd in possible_duration)
  	for (var t in hours)
  	  if (t % 2 != 0) {
	  	  if (J[pd] + t - 1 <= T) {
	  	    N++;
	  	    for (var k = 1; k <= J[pd]; k++)
	  	      A[N].add(k + t - 1);
	  	  }	  	      
      }		  	
}

range type_shift = 1..N;
string SHIFTS_NAME[type_shift] = ["08:00-12:00", "10:00-14:00", "12:00-16:00", "14:00-18:00", "16:00-20:00", "18:00-22:00",
								  "08:00-14:00", "10:00-16:00", "12:00-18:00", "14:00-20:00", "16:00-22:00",
								  "08:00-16:00", "10:00-18:00", "12:00-20:00", "14:00-22:00"] ;


range proficiencies = 1..3; // Number of different subjects a rep can help with

float d[S][days][hours][proficiencies] = ...; //Imorting demand

//Definition of salaries matrix - Preprocessing
int salaries[proficiencies] = [35, 40, 43];

float P[proficiencies][hours];

float late_night_bonus = 1.15;

execute
{
  for(var i in proficiencies) 
    for(var t in hours)
      if(t<12) {
        P[i][t] = salaries[i];
      } else {
        P[i][t] = salaries[i] * late_night_bonus;
      }
}

int TE = 50; // Travel expenses for each worker on a shift

int PW = 7; // Number of possible shifts

range possible_workers = 1..PW;
string SKILLS_NAME[possible_workers] = ["TV", "Cell", "Internet",
										"TV-Cell", "TV-Internet", "Cell-Internet",
										"TV-Cell-Internet"] ;

range single = 1..3;
range dubble = 4..6;
//Will use later for the vars
{int} not_tv = {2,3,6};
{int} not_tel = {1,3,5};
{int} not_int = {1,2,4};

// ***** Variables *****
dvar int+ x[possible_workers][type_shift][days];
dvar float+ y[S][possible_workers][proficiencies][days][hours];
//Defining target function
dexpr float transportation_fee = TE * (sum (pw in possible_workers, j in type_shift, day in days) x[pw,j,day]);
dexpr float single_proficiency_fee =  sum (pw in single, j in type_shift, day in days, t in hours: t in A[j]) P[1][t]*x[pw,j,day]; 
dexpr float dubble_proficiency_fee =  sum (pw in dubble, j in type_shift, day in days, t in hours: t in A[j]) P[2][t]*x[pw,j,day]; 
dexpr float triple_proficiency_fee =  sum (j in type_shift, day in days, t in hours: t in A[j]) P[3][t]*x[7,j,day]; 
dexpr float total_costs = transportation_fee + single_proficiency_fee + dubble_proficiency_fee + triple_proficiency_fee ; 

// ***** Target function *****

minimize total_costs; 

// ***** Constraints *****
subject to {
  
  forall (s in S, pw in possible_workers, day in days, t in hours) 
  	sum (j in type_shift: t in A[j]) x[pw][j][day] >= sum (i in proficiencies) y[s][pw][i][day][t];
  		
  forall (s in S, day in days, t in hours, i in proficiencies)
    sum (pw in possible_workers) y[s][pw][i][day][t] >= d[s][day][t][i];
    
  forall (s in S, pw in not_tv, day in days, t in hours) y[s][pw][1][day][t] == 0;
  forall (s in S, pw in not_tel, day in days, t in hours) y[s][pw][2][day][t] == 0;
  forall (s in S, pw in not_int, day in days, t in hours) y[s][pw][3][day][t] == 0; 
   
}

// ***** Setting the answer output ***** 
int Q = 0;
int W = 0;

execute
{
  
  for (var day in days) 
  	for(var j in type_shift)
  		for (var pw in possible_workers)
    		if (x[pw][j][day] > 0) {
    		  if (day != Q) {
    		    Q++ ;
    		    W = 0 ;
    		    writeln ("");
    		    writeln (DAYS_NAME[day]);
    		  	writeln ("=============================================");
    		  }
    		  if (j != W) {
    		    W++ ;
    		    writeln ("  Shift ", SHIFTS_NAME[j]);
    		  }
    		  writeln ("    Skills: ", SKILLS_NAME[pw], " -- number of workers: ", x[pw][j][day]);
    		} 			
}
 