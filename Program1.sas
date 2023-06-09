data Laptops;
set '/home/u62064900/Projects/laptops.sas7bdat';
run; 

data Pos1;
set '/home/u62064900/Projects/pos_q1.sas7bdat';

run;
data Pos2;
set '/home/u62064900/Projects/pos_q2.sas7bdat';
run;
data Pos3;
set '/home/u62064900/Projects/pos_q3.sas7bdat';
run;
data Pos4;
set '/home/u62064900/Projects/pos_q4.sas7bdat';
run;



data Pos_Complete ;
set Pos1 Pos2 Pos3 Pos4;
drop month Date;
run;
/* proc print data=Pos_Complete(obs=100); */
/*  */
/* run; */

libname Data '/home/u62064900/Projects';

Data want;
Merge Pos_Complete Data.postalcodes;
Run;
/* proc print data=want (obs=100); */
/* run; */

proc sql noprint;
create table Customer_Final as
select b.Customer_Postcode ,a.postcode,a.latitude,a.longitude from work.want a ,work.want b
where a.postcode = b.Customer_Postcode;

quit;

proc sql noprint ;
create table Store_Final as
select b.Store_Postcode ,a.postcode,a.latitude,a.longitude from work.want a ,work.want b
where a.postcode = b.Store_Postcode;

quit;
 
data Store_Final;
set work.Store_Final;
rename postcode=S_postcode
latitude=S_latitude
longitude=S_longitude;
drop Store_Postcode	;
run;
/* proc print data=Store_Final(obs=100); */
/* run; */
proc sort data=Store_Final out=no_dups_store nodupkey;
    by _all_;
run;

data Customer_Final;
set work.customer_final;
rename postcode=C_postcode
latitude=C_latitude
longitude=C_longitude;
drop Customer_Postcode;
run;

/* proc print data=Customer_Final(obs=100); */
/* run; */

proc sort data=Customer_Final out=no_dups_customer nodupkey;
    by _all_;
run;

data Store_Locations;
set '/home/u62064900/Projects/store_locations.sas7bdat';
run ;

proc sql;
create table Store as
select  b.Store_Postcode, a.Postcode ,  a.Lat, a.Long  from Store_Locations a ,Pos_Complete b
where a.Postcode=b.Store_Postcode; 

data Locations;
set '/home/u62064900/Projects/london_postal_codes.sas7bdat';
run ;

proc sql;
create table Customer as
select  b.Customer_Postcode, a.C_postcode,  C_latitude ,C_longitude from no_dups_customer a ,Pos_Complete b
where a.C_postcode=b.Customer_Postcode 
; 

data Customer_P;
set customer;
rename Postcode=C_Postcode ;

run;

data Store_P;
set Store;
rename Postcode=S_Postcode;
run;

data SC_Final;
set Pos1 Pos2 Pos3 Pos4;
merge Customer_P Store_P;
drop Date Configuration month;
distance=geodist(C_latitude, C_longitude,Lat,Long
);
run;
proc print data=SC_Final(obs=100) ;
run;

proc sql;
create table total_sales as
   
   select Store_Postcode, sum(Retail_Price) format=comma14. as Total_Sales
      from Pos_Complete
      where Store_Postcode is not missing
      group by Store_Postcode;
      
      
/*  proc sql; */
/*    title 'Total sales for each Customer'; */
/*    select Customer_Postcode, sum(Retail_Price) format=comma14. as Total_Sales */
/*       from Pos_Complete */
/*       where Customer_Postcode is not missing */
/*       group by Customer_Postcode; */
      
data Sales ;
set total_sales;
rename Store_Postcode=StoreSales_Postcode;
run;

ods excel file="/home/u62064900/Projects/Report.xlsx";
ods graphics on;

 proc sgplot data=Sales;
  title 'Total sales for each store';
  yaxis label="Sales" ;
  vbar StoreSales_Postcode/ response=Total_Sales
   datalabel dataskin=matte
           baselineattrs=(thickness=0)
           fillattrs=(color=lightblue);
  run;
  
  

 proc sgplot data=SC_Final;
  title 'AVG Distance Travelled By Customers To Diffrent Stores';
  yaxis label="AVG Distance Between Customers and Stores";
  vbar Store_Postcode/ response=distance 
  datalabel dataskin=matte
           baselineattrs=(thickness=0)
           fillattrs=(color=lightblue);
  run;




data plot;
merge SC_Final Sales;
run;


 proc sgplot data=plot;
  title 'AVG Distance VS Sales';
  vbar Store_Postcode /response=Total_Sales
     datalabel dataskin=matte;
  
  vline Store_Postcode/ response=distance y2axis;
           
           run;
 
 ods excel close;


