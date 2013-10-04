--------------------------------------------------------------------------------
--
-- Loading
--
--------------------------------------------------------------------------------

create database bmwdb on /local2/db2/@
connect to bmwdb@
update db cfg using LOGFILSIZ 1000000@

--
--
--

drop table ml_cars_list@
create table ml_cars_list (
    vin   varchar(32)
   ,class integer
)@   


load from /local2/bjr_biadmin/iter2/ml_data/ml_cars_list.del of del warningcount 1 replace into ml_cars_list@
create index ml_cars_list_pk on ml_cars_list( vin)@
runstats on table ml_cars_list@


--
--
--

drop table ml_cars@
create table ml_cars (
     class           integer
    ,vin             varchar(32)
    ,production_date date
    ,line            varchar(3)
    ,model	     varchar(10)
    ,engine_model    char(4)
    ,model_year      integer
)@

load from /local2/bjr_biadmin/iter2/ml_data/ml_cars.del of del warningcount 1 replace into ml_cars@
create index ml_cars_pk on ml_cars( vin)@
runstats on table ml_cars@


--
--
--

drop table ml_readouts@
create table ml_readouts (
    key              integer
   ,vin              varchar(32)
   ,repair_case      bigint 
   ,readout_index    bigint   
   ,readout_date     date   
   ,mileage          integer
   ,dealerId         character(5)
   ,zipcode          varchar(30)
)@

load from /local2/bjr_biadmin/iter2/ml_data/ml_readouts.del of del warningcount 1 replace into ml_readouts@
create index ml_readouts_pk  on ml_readouts(key)@
create index ml_readouts_idx on ml_readouts(vin)@
runstats on table ml_readouts@

--
--
--

drop table ml_readoutDTCs@
create table ml_readoutDTCs (
    key   INTEGER
   ,dtc   VARCHAR(22)
   ,value INTEGER
)@

load from /local2/bjr_biadmin/iter2/ml_data/ml_readoutDTCs.del of del warningcount 1 replace into ml_readoutDTCs@
create index ml_readoutdtcs_pk   on ml_readoutDTCs(key)@
create index ml_readoutdtcs_idx  on ml_readoutDTCs(dtc)@
runstats on table ml_readoutDTCs@


--
--
--

drop table ml_warr_rep_diag@
create table ml_warr_rep_diag (
    vin          varchar (32)
   ,wid          integer     
   ,wrepdate     date   
   ,line_nr      integer 
   ,diag_finding varchar (10)
)@

load from /local2/bjr_biadmin/iter2/ml_data/ml_warr_rep_diag.del of del warningcount 1 replace into ml_warr_rep_diag@
create index ml_warr_rep_diag_pk on ml_warr_rep_diag(wid)@
create index ml_warr_rep_diag_idx on ml_warr_rep_diag(vin)@
runstats on table ml_warr_rep_diag@


--
--
--

drop table ml_warr_rep_exchgparts@
create table ml_warr_rep_exchgparts (
    vin         varchar(32)
   ,wid         integer     
   ,line_nr     integer     
   ,item_nummer integer     
   ,partid      varchar(255)
)@

load from /local2/bjr_biadmin/iter2/ml_data/ml_warr_rep_exchgparts.del of del warningcount 1 replace into ml_warr_rep_exchgparts@
create index ml_warr_rep_exchgparts_idx1 on ml_warr_rep_exchgparts(wid)@
create index ml_warr_rep_exchgparts_idx2 on ml_warr_rep_exchgparts(vin)@
create index ml_warr_rep_exchgparts_idx3 on ml_warr_rep_exchgparts(partid)@
runstats on table ml_warr_rep_exchgparts@


--
--
--

drop table ml_car_options@
create table ml_car_options (
    vin    varchar(32)
   ,option VARCHAR(6)
   ,values INTEGER 
)@

load from /local2/bjr_biadmin/iter2/ml_data/ml_car_options.del of del warningcount 1 replace into ml_car_options@
create index ml_car_options_idx1 on ml_car_options (vin)@
create index ml_car_options_idx2 on ml_car_options (option)@
runstats on table ml_car_options@


--
--
--

create table tmpspecificDTCs (dtc varchar(22) not null, primary key(DTC))@
load from /local2/bjr_biadmin/iter2/ml_data/specificDTCs.del of del warningcount 1 replace into tmpspecificDTCs@
drop table map_specificDTCs@
create table map_specificDTCs (dtc varchar(22) not null, idx integer, idy integer, primary key(DTC))@

insert into map_specificDTCs 
   with t  as (select dtc, rownumber() over (order by dtc) as id from tmpspecificDTCs t),
        v  as (select count(*) as cnt from tmpspecificDTCs),
        t1 as (select dtc, id as idx, id + (select cnt from v) as idy from t)
   select dtc,  idx, idy from t1@

drop table tmpspecificDTCs@
runstats on table map_specificDTCs@


--------------------------------------------------------------------------------
--
-- Construct Features Vectors
--
--------------------------------------------------------------------------------

-- 
-- Readout features
--

drop view f_readouts@
create view f_readouts as 

   with r as (
   select  r.*
          ,days(readout_date) - lag(days(readout_date), 1) over (partition by r.vin order by r.repair_case, r.readout_index, r.readout_date asc) as readoutdatelag
          ,mileage - lag(mileage, 1) over (partition by r.vin order by r.repair_case, r.readout_index, r.readout_date asc) as mileagelag
   from  ml_readouts r)

   select 
   	  r.vin
          ,min(days(r.readout_date) - days(c.production_date))                 as minlivedays
          ,avg(days(r.readout_date) - days(c.production_date))                 as avglivedays
          ,stddev(days(r.readout_date) - days(c.production_date))              as devlivedays
          ,max(days(r.readout_date) - days(c.production_date))                 as maxlivedays

	  ,count(*)                                                            as allcnt
	  ,count(distinct r.readout_date)                                      as distreaddatecnt

          ,(max(days(r.readout_date)) - min (days(r.readout_date)))/count(key) as avgvisitdaygap

	  ,min(readout_index)                                                  as minreadoutidx
	  ,avg(readout_index)                                                  as avgreadoutidx
	  ,stddev(readout_index)                                               as devreadoutidx
	  ,max(readout_index)                                                  as maxreadoutidx

	  ,min(repair_case)                                                    as minrepaircase
	  ,avg(repair_case)                                                    as avgrepaircase
	  ,stddev(repair_case)                                                 as devrepaircase
 	  ,max(repair_case)                                                    as maxrepaircase

	  ,min(mileage)                                                        as minmileage
	  ,avg(mileage)                                                        as avgmileage
	  ,stddev(mileage)                                                     as devmileage
 	  ,max(mileage)                                                        as maxmileage

          ,min(readoutdatelag)                                                 as minreadoutdatelag
          ,avg(readoutdatelag)                                                 as avgreadoutdatelag
          ,stddev(readoutdatelag)                                              as devreadoutdatelag
          ,max(readoutdatelag)                                                 as maxreadoutdatelag
   
          ,min(mileagelag)                                                     as minmileagelag
          ,avg(mileagelag)                                                     as avgmileagelag
          ,stddev(mileagelag)                                                  as devmileagelag
          ,max(mileagelag)                                                     as maxmileagelag

   from r, ml_cars c
   where r.vin = c.vin
   group by r.vin
@


--
-- Feature Car Options features
--

create table map_car_options(option varchar(6) not null, id integer, primary key(option))@
insert into map_car_options
   select  option 
          ,rownumber() over (order by option) 
   from ml_car_options 
   group by option @
runstats on table map_car_options@


drop view f_car_options@
create view f_car_options as 
   with t as (
   select  vin as ovin 
          ,xmlserialize(xmlagg(xmltext(m.id || ';' || '1' || ':')) as varchar(600)) as options
   from  ml_car_options o
        ,map_car_options m 
   where o.option = m.option	
   group by vin
   )
   select c.vin as ovin, t.options 
   from ml_cars c left outer join t on c.vin = t.ovin
@

drop table t_f_car_options@
update command options using c off@
create table t_f_car_options like f_car_options@
alter table t_f_car_options activate not logged initially@
insert into t_f_car_options select * from f_car_options@
commit@
create index t_f_car_options_idx on t_f_car_options (ovin)@
runstats on table t_f_car_options@



--
-- Feature ReadOut Dealers
--

create table map_readout_dealerids(dealerId character(5) not null, id integer, primary key(dealerId))@
insert into map_readout_dealerids
   select  dealerId 
          ,rownumber() over (order by dealerId) 
   from ml_readouts
   group by dealerid@
runstats on table map_readout_dealerids@


drop view f_readout_dealers@
create view f_readout_dealers as 
   with r as (
     select r.vin, r.dealerid, count(*) as count
     from ml_readouts r
     group by r.vin, r.dealerid       
   ), t as (
   select  vin as rdvin 
          ,xmlserialize(xmlagg(xmltext(m.id || ';' || r.count || ':')) as varchar(100)) as dealers
   from  r
        ,map_readout_dealerids m 
   where r.dealerid = m.dealerid	
   group by vin
   )
  select c.vin as rdvin, dealers
  from ml_cars c left outer join t on c.vin = t.rdvin
@

drop table t_f_readout_dealers@
update command options using c off@
create table t_f_readout_dealers like f_readout_dealers@
alter table t_f_readout_dealers activate not logged initially@
insert into t_f_readout_dealers select * from f_readout_dealers@
commit@
create index t_f_readout_dealers_idx on t_f_readout_dealers (rdvin)@
runstats on table t_f_readout_dealers@




--
-- Feature Warranty Diagnostic Findings
--

create table map_warr_rep_diag(diag_finding varchar(10) not null, id integer, primary key(diag_finding))@
insert into map_warr_rep_diag
   select  diag_finding 
          ,rownumber() over (order by diag_finding) 
   from ml_warr_rep_diag
   group by diag_finding @
runstats on table map_warr_rep_diag@

 
drop view f_warr_rep_diag@
create view f_warr_rep_diag as 
   with d as (
     select d.vin, d.diag_finding, count(*) as count
     from ml_warr_rep_diag d
     group by d.vin, d.diag_finding       
   ), t as (
   select  vin as dvin 
          ,xmlserialize(xmlagg(xmltext(m.id || ';' || d.count || ':')) as varchar(500)) as warr_diag
   from  d
        ,map_warr_rep_diag m 
   where d.diag_finding = m.diag_finding	
   group by vin
   )
   select c.vin as dvin, t.warr_diag
   from ml_cars c left outer join t on c.vin = t.dvin 
@


drop table t_f_warr_rep_diag@
update command options using c off@
create table t_f_warr_rep_diag like f_warr_rep_diag@
alter table t_f_warr_rep_diag activate not logged initially@
insert into t_f_warr_rep_diag select * from f_warr_rep_diag@
commit@
create index t_f_warr_rep_diag_idx on t_f_warr_rep_diag (dvin)@
runstats on table t_f_warr_rep_diag@


--
-- Feature Warranty Exchange Parts
--

create table map_warr_rep_exchgparts(partid varchar(7) not null, id integer, primary key(partid))@
insert into map_warr_rep_exchgparts
   select  partid 
          ,rownumber() over (order by partid) 
   from ml_warr_rep_exchgparts
   group by partid @
runstats on table map_warr_rep_exchgparts@

 
drop view f_warr_rep_exchgparts@
create view f_warr_rep_exchgparts as 
   with p as (
     select p.vin, p.partid, count(*) as count
     from ml_warr_rep_exchgparts p
     group by p.vin, p.partid       
   ), t as (
   select  vin as pvin 
          ,xmlserialize(xmlagg(xmltext(m.id || ';' || p.count || ':')) as varchar(800)) as warr_exchgparts
   from  p
        ,map_warr_rep_exchgparts m 
   where p.partid = m.partid	
   group by vin
   ) 
   select c.vin as pvin, t.warr_exchgparts
   from ml_cars c left outer join t on c.vin = t.pvin
@


drop table t_f_warr_rep_exchgparts@
update command options using c off@
create table t_f_warr_rep_exchgparts like f_warr_rep_exchgparts@
alter table t_f_warr_rep_exchgparts activate not logged initially@
insert into t_f_warr_rep_exchgparts select * from f_warr_rep_exchgparts@
commit@
create index t_f_warr_rep_exchgparts_idx on t_f_warr_rep_exchgparts (pvin)@
runstats on table t_f_warr_rep_exchgparts@


-- 
-- Feature SpecificDTCs
--

drop view f_specificDTCS@
create view f_specificDTCS as 
with t as (
select  d.key, m.dtc, m.idx, m.idy
from  map_specificdtcs m
     ,ml_readoutDTCs d
where m.dtc = d.dtc
), t1 as (
select r.vin, t.dtc, t.idx, t.idy, count(*) as absfreq
from t, ml_readouts r
where t.key = r.key
group by r.vin, t.dtc, t.idx, t.idy
), t2 as(
--select t1.vin, sum (absfreq) as totalCnt
--from t1
--group by vin
select vin, count(*) as totalCnt
from ml_readouts r
group by vin
), t3 as (
select  t1.vin as svin 
       ,xmlserialize(xmlagg(xmltext(t1.idx || ';' || t1.absfreq || ':')) as varchar(100))                              as specDTCsx
       ,xmlserialize(xmlagg(xmltext(t1.idy || ';' || varchar(double(t1.absfreq)/t2.totalCnt) || ':')) as varchar(450)) as specDTCsy
from t1, t2
where t1.vin = t2.vin
group by t1.vin
)
select c.vin as svin, t3.specDTCsx, t3.specDTCsy
from ml_cars c left outer join t3 on c.vin = t3.svin
@

drop table t_f_specificDTCs@
update command options using c off@
create table t_f_specificDTCs like f_specificDTCs@
alter table t_f_specificDTCs activate not logged initially@
insert into t_f_specificDTCs select * from f_specificDTCs@
commit@
create index t_f_specificDTCs_idx on t_f_specificDTCs (svin)@
runstats on table t_f_specificDTCs@


--
-- Features DTC Summaries
--

drop view f_dtcs@
create view f_dtcs as
with t as (
  select r.vin, r.repair_case, r.readout_index, count(*) as dtc_cnt
  from  ml_readouts r
       ,ml_readoutDTCs d
  where r.key = d.key
  group by r.vin, r.repair_case, r.readout_index
), t1 as (
select  
        vin                as fdvin
       ,min(t.dtc_cnt)     as minnumdtc
       ,avg(t.dtc_cnt)     as avgnumdtc
       ,stddev(t.dtc_cnt)  as devnumdtc
       ,max(t.dtc_cnt)     as maxnumdtc
       ,sum(t.dtc_cnt)     as sumnumdtc
from t
group by t.vin
), t2 as (
select c.vin, t1.*
from ml_cars c left outer join t1 on c.vin = t1.fdvin
)
select 
        t2.vin   as fdvin
--       ,minnumdtc
--       ,avgnumdtc
--       ,devnumdtc
--       ,maxnumdtc
--       ,sumnumdtc
       ,f."minnumdtc"
       ,f."avgnumdtc"
       ,f."mednumdtc"
       ,f."devnumdtc"
       ,f."maxnumdtc"
       ,f."sumnumdtc"
       ,f."mindeltadtc"
       ,f."avgdeltadtc"
       ,f."meddeltadtc"
       ,f."devdeltadtc"
       ,f."maxdeltadtc"
       ,f."minnumcommondtcprev"
       ,f."avgnumcommondtcprev"
       ,f."mednumcommondtcprev"
       ,f."devnumcommondtcprev"
       ,f."maxnumcommondtcprev"
       ,f."minnumcommondtcprev2"
       ,f."avgnumcommondtcprev2"
       ,f."mednumcommondtcprev2"
       ,f."devnumcommondtcprev2"
       ,f."maxnumcommondtcprev2"
       ,f."minnumcommondtcprev3"
       ,f."avgnumcommondtcprev3"
       ,f."mednumcommondtcprev3"
       ,f."devnumcommondtcprev3"
       ,f."maxnumcommondtcprev3"
       from t2 left outer join "features2.csv" f on t2.vin = f."vin"
@


drop table t_f_dtcs@
create table t_f_dtcs like f_dtcs@
update command options using c off@
alter table t_f_DTCS activate not logged initially@
insert into t_f_DTCS select * from f_dtcs@
commit@
create index t_f_DTCS_idx on t_f_DTCs (fdvin)@
runstats on table t_f_DTCs@


--------------------------------------------------------------------------------
-- 
-- Maps for categorical attributes
--
--------------------------------------------------------------------------------

drop table map_line@
create table map_line(line varchar(3) not null, id integer, primary key(line))@
insert into map_line 
  with t  as (select distinct line from ml_cars),
       t1 as (select line, rownumber() over (order by line) as id from t)
  select * from t1@
runstats on table map_line@      


drop table map_model@
create table map_model(model varchar(10) not null, id integer, primary key(model))@
insert into map_model 
  with t  as (select distinct model from ml_cars),
       t1 as (select model, rownumber() over (order by model) as id from t)
  select * from t1@
runstats on table map_model@      


drop table map_engine_model@
create table map_engine_model(engine_model varchar(4) not null, id integer, primary key(engine_model))@
insert into map_engine_model 
  with t  as (select distinct engine_model from ml_cars),
       t1 as (select engine_model, rownumber() over (order by engine_model) as id from t)
  select * from t1@
runstats on table map_engine_model@      


drop table map_prod_ym@
create table map_prod_ym(prod_ym varchar(6) not null, id integer, primary key(prod_ym))@
insert into map_prod_ym 
  with t  as (select distinct (year(production_date) || month(production_date)) as prod_ym from ml_cars),
       t1 as (select prod_ym, rownumber() over (order by prod_ym) as id from t)
  select * from t1@
runstats on table map_engine_model@      



-- 
-- OVERALL FEATURE VECTOR
--


drop view features@
create view features as 
select  
	c.vin,
        c.class   
       -- READOUT SUMMARIES                                     -- ... scale features
       ,fr.minlivedays
       ,fr.avglivedays
       ,fr.devlivedays
       ,fr.maxlivedays

       ,fr.allcnt
       ,fr.distreaddatecnt

       ,fr.avgvisitdaygap

       ,fr.minreadoutidx
       ,fr.avgreadoutidx
       ,fr.devreadoutidx
       ,fr.maxreadoutidx

       ,fr.minrepaircase
       ,fr.avgrepaircase
       ,fr.devrepaircase
       ,fr.maxrepaircase

       ,fr.minmileage
       ,fr.avgmileage
       ,fr.devmileage
       ,fr.maxmileage

       ,fr.minreadoutdatelag
       ,fr.avgreadoutdatelag
       ,fr.devreadoutdatelag
       ,fr.maxreadoutdatelag

       ,fr.minmileagelag
       ,fr.avgmileagelag
       ,fr.devmileagelag
       ,fr.maxmileagelag

       -- DTC summaries
       ,fd."minnumdtc"
       ,fd."avgnumdtc"
       ,fd."mednumdtc"
       ,fd."devnumdtc"
       ,fd."maxnumdtc"
       ,fd."sumnumdtc"
       ,fd."mindeltadtc"
       ,fd."avgdeltadtc"
       ,fd."meddeltadtc"
       ,fd."devdeltadtc"
       ,fd."maxdeltadtc"
       ,fd."minnumcommondtcprev"
       ,fd."avgnumcommondtcprev"
       ,fd."mednumcommondtcprev"
       ,fd."devnumcommondtcprev"
       ,fd."maxnumcommondtcprev"
       ,fd."minnumcommondtcprev2"
       ,fd."avgnumcommondtcprev2"
       ,fd."mednumcommondtcprev2"
       ,fd."devnumcommondtcprev2"
       ,fd."maxnumcommondtcprev2"
       ,fd."minnumcommondtcprev3"
       ,fd."avgnumcommondtcprev3"
       ,fd."mednumcommondtcprev3"
       ,fd."devnumcommondtcprev3"
       ,fd."maxnumcommondtcprev3"

	-- CAR
       ,(select id||';'||1||':' from map_line  
         where line = c.line)   as line                         -- 58 0/1 dummy features	
       ,(select id||';'||1||':' from map_model 
         where model = c.model) as model                        -- 91 0/1 dummy features	
       ,(select id||';'||1||':' from map_engine_model 
         where engine_model = c.engine_model) as engine_model   -- 38 0/1 dummy features	
       ,(select id||';'||1||':' from map_prod_ym 
         where prod_ym = (year(c.production_date) || month(c.production_date))) as prod_ym   -- 78 0/1 dummy features	

       -- SPECIFIC DTCS
       ,fsd.specdtcsx                                          -- 55 specific DTCs with absolute frequencies
       ,fsd.specdtcsy                                          -- 55 specific DTCs with relative frequencies

       -- CAR OPTIONS                        
       ,fo.options                                             -- 1220 0/1 dummy features including VIN

       -- READOUT DEALERS
       ,frd.dealers                                            -- 3228 dealer features with counts
 
       -- WARR DIAGNOSTICS
       ,fwd.warr_diag                                          -- 3738 warranty repair diagnositcs with counts

       -- WARR EXCHANGE PARTS
       ,fwp.warr_exchgparts                                    -- 13270 warranty exchange parts with counts

from  ml_cars c
     ,f_readouts fr
     ,t_f_dtcs fd
     ,t_f_specificDTCS fsd
     ,t_f_car_options fo
     ,t_f_readout_dealers frd
     ,t_f_warr_rep_diag fwd
     ,t_f_warr_rep_exchgparts fwp
where c.vin = fr.vin 
  and c.vin = fd.fdvin
  and c.vin = fsd.svin
  and c.vin = fo.ovin
  and c.vin = frd.rdvin
  and c.vin = fwd.dvin
  and c.vin = fwp.pvin
@

export to /local2/bjr_biadmin/iter2/ml_data/features64.del of del select * from features 
@


-- materialize w/ VIN

drop table tv_features@
create table tv_features like features not logged initially@
insert into tv_features select * from features@
commit@



--------------------------------------------------------------------------------
--
-- Monday (reacquired) cars
-- 
--------------------------------------------------------------------------------

with t as (
  select dayofweek_iso(c.production_date) as DayOfWeek, class, count(*) as count 
  from ml_cars c 
  group by rollup (dayofweek_iso(c.production_date), class) 
),
t1 as (
  select dayofweek
        ,case when class is null then count end as all 
        ,case when class = 1 then count end as p1
        ,case when class = -1 then count end as m1
from t)
select dayofweek
      ,max(all) as All
      ,max(p1) as "Reacquired Cars"
      ,max(m1) as "Regular Cars"
from t1 
group by dayofweek 
order by t1.dayofweek@


DAYOFWEEK   ALL         Reacquired Cars Regular Cars
----------- ----------- --------------- ------------
          1      313367            1577       311790
          2      341161            1667       339494
          3      341168            1654       339514
          4      331316            1629       329687
          5      305564            1383       304181
          6       81014             361        80653
          7       13196              48        13148
          -     1726786               -            -

  8 record(s) selected.


--------------------------------------------------------------------------------
--
-- Lemon Dealers?
--    Get last readout of cars and analyze by dealer 
--
--------------------------------------------------------------------------------

with t as (
  select key, vin, 
         dealerId, 
         readout_date, 
         first_value(key) 
           over (partition by vin 
                 order by repair_case desc, readout_index desc) as last_key
  from ml_readouts r
), t1 as (
  select t.dealerId, c.class
  from t, ml_cars c
  where t.key = t.last_key
    and t.vin = c.vin
), t2 as (
  select dealerid, class, count(*) as count
  from  t1
  group by rollup (dealerid, class)
), t3 as (
  select dealerid
        ,case when class is null then count end as all 
        ,case when class = 1 then count end as p1
        ,case when class = -1 then count end as m1
  from t2
), t4 as (
  select dealerid
        ,max(all) as All
        ,max(p1) as Reacquired
        ,max(m1) as Regular
  from t3 
  group by dealerid 
), t5 as (
  select t4.*, round((100*reacquired/all),3) as PctReacquired, round((100*regular/all),3) as pctRegular 
  from t4)
select * 
from t5 
where reacquired > 0 order by pctreacquired desc
fetch first 100 rows only
@

DEALERID ALL         REACQUIRED  REGULAR     PCTREACQUIRED PCTREGULAR 
-------- ----------- ----------- ----------- ------------- -----------
96530              1           1           -           100           -
06760            374          42         332            11          88
06580             25           2          23             8          92
29855             23           2          21             8          91
06837           2258         163        2095             7          92
06299           1843         104        1739             5          94
28999             36           2          34             5          94
96296           1225          70        1155             5          94
06292           2166         106        2060             4          95
31776           1426          68        1358             4          95
06274           1371          42        1329             3          96
17966           3509         124        3385             3          96
26336             32           1          31             3          96
31044            136           5         131             3          96
06363             87           2          85             2          97
06713            932          21         911             2          97
06561            235           7         228             2          97
09578             83           2          81             2          97
17990           1156          24        1132             2          97
20268           6196         140        6056             2          97
25769             44           1          43             2          97
56292           1947          42        1905             2          97
65256           2700          79        2621             2          97
76350            519          11         508             2          97
76837           6194         137        6057             2          97
86262          11118         266       10852             2          97
86287             43           1          42             2          97
86846            375           9         366             2          97



-- CLASS   VIN      LAST DEALERID+ZIP        2ND LAST DEALERID+ZIP        3RD LAST DEALERID+ZIP
-- +1 only

--------------------------------------------------------------------------------
--
-- lemon models ??

--------------------------------------------------------------------------------
--
-- Other queries
--
--------------------------------------------------------------------------------

-- PartId count for lemon, non-lemon with pivot

export to /local2/bjr_biadmin/iter2/ml_data/partIdCntLnL.del of del
with t as (
select substr(p.partid, 1, 10) as partid, c.class class, count(*) cnt
from ml_warr_rep_exchgparts p, ml_cars c 
where p.vin = c.vin 
group by p.partid, c.class
), 
t2 as (
select  t.partid 
       ,case when t.class = -1 then cnt end as nonlemon
       ,case when t.class =  1 then cnt end as lemon
from t
),
t3 as (
select partid, max(nonlemon) as nonlemon, max (lemon) as lemon
from t2
group by partid
)
select partid, lemon, nonlemon from t3 order by partid asc
@


-- Warranty Repair Diagnostic count for lemon, non-lemon

export to /local2/bjr_biadmin/iter2/ml_data/warrRepDiagCntLnL.del of del
with t as (
select substr(d.diag_finding, 1, 10) as diag_finding, c.class class, count(*) cnt
from ml_warr_rep_diag d, ml_cars c 
where d.vin = c.vin 
group by d.diag_finding, c.class
), 
t2 as (
select  t.diag_finding 
       ,case when t.class = -1 then cnt end as nonlemon
       ,case when t.class =  1 then cnt end as lemon
from t
),
t3 as (
select diag_finding, max(nonlemon) as nonlemon, max (lemon) as lemon
from t2
group by diag_finding
)
select diag_finding, lemon, nonlemon from t3 order by diag_finding asc
@

 
-- Dealer count for lemon, non-lemon

export to /local2/bjr_biadmin/iter2/ml_data/dealerCntLnL.del of del
with t as (
select r.dealerId, c.class class, count(*) cnt
from ml_readouts r, ml_cars c 
where r.vin = c.vin 
group by r.dealerId, c.class
), 
t2 as (
select  t.dealerId 
       ,case when t.class = -1 then cnt end as nonlemon
       ,case when t.class =  1 then cnt end as lemon
from t
),
t3 as (
select dealerId, max(nonlemon) as nonlemon, max (lemon) as lemon
from t2
group by dealerId
)
select dealerId, lemon, nonlemon from t3 order by dealerId asc
@


-- Car Options count for lemon, non-lemon

export to /local2/bjr_biadmin/iter2/ml_data/carOptionsCntLnL.del of del
with t as (
select o.option, c.class class, count(*) cnt
from ml_car_options o, ml_cars c 
where o.vin = c.vin 
group by o.option, c.class
), 
t2 as (
select  t.option 
       ,case when t.class = -1 then cnt end as nonlemon
       ,case when t.class =  1 then cnt end as lemon
from t
),
t3 as (
select option, max(nonlemon) as nonlemon, max (lemon) as lemon
from t2
group by option
)
select option, lemon, nonlemon from t3 order by option asc
@


-- Car line count for lemon, non-lemon

export to /local2/bjr_biadmin/iter2/ml_data/carLineCntLnL.del of del
with t as (
select c.line, c.class class, count(*) cnt
from ml_cars c 
group by c.line, c.class
), 
t2 as (
select  t.line 
       ,case when t.class = -1 then cnt end as nonlemon
       ,case when t.class =  1 then cnt end as lemon
from t
),
t3 as (
select line, max(nonlemon) as nonlemon, max (lemon) as lemon
from t2
group by line
)
select line, lemon, nonlemon from t3 order by line asc
@


-- Car model count for lemon, non-lemon

export to /local2/bjr_biadmin/iter2/ml_data/carModelCntLnL.del of del
with t as (
select c.model, c.class class, count(*) cnt
from ml_cars c 
group by c.model, c.class
), 
t2 as (
select  t.model 
       ,case when t.class = -1 then cnt end as nonlemon
       ,case when t.class =  1 then cnt end as lemon
from t
),
t3 as (
select model, max(nonlemon) as nonlemon, max (lemon) as lemon
from t2
group by model
)
select model, lemon, nonlemon from t3 order by model asc
@


-- Car engine model count for lemon, non-lemon

export to /local2/bjr_biadmin/iter2/ml_data/carEngineModelCntLnL.del of del
with t as (
select c.engine_model, c.class class, count(*) cnt
from ml_cars c 
group by c.engine_model, c.class
), 
t2 as (
select  t.engine_model 
       ,case when t.class = -1 then cnt end as nonlemon
       ,case when t.class =  1 then cnt end as lemon
from t
),
t3 as (
select engine_model, max(nonlemon) as nonlemon, max (lemon) as lemon
from t2
group by engine_model
)
select engine_model, lemon, nonlemon from t3 order by engine_model asc
@






--------------------------------------------------------------------------------
--
-- Load features2.csv
--
--------------------------------------------------------------------------------

drop table "features2.csv"@
create table "features2.csv" ("vin" varchar(32) not null,"class" char(3),"prodyear" integer,"minlivedays" integer,"avglivedays" double,"medlivedays" integer,"devlivedays" double,"maxlivedays" integer,"allcnt" integer,"distreaddatecnt" integer,"minreadoutidx" integer,"avgreadoutidx" double,"medreadoutidx" integer,"devreadoutidx" double,"maxreadoutidx" integer,"minrepaircase" integer,"avgrepaircase" double,"medrepaircase" integer,"devrepaircase" double,"maxrepaircase" integer,"minmileage" integer,"avgmileage" double,"medmileage" integer,"devmileage" double,"maxmileage" integer,"minreadoutdatelag" integer,"avgreadoutdatelag" double,"medreadoutdatelag" integer,"devreadoutdatelag" double,"maxreadoutdatelag" integer,"minmileagelag" integer,"avgmileagelag" double,"medmileagelag" integer,"devmileagelag" double,"maxmileagelag" integer,
"minnumdtc" integer,
"avgnumdtc" double,
"mednumdtc" integer,
"devnumdtc" double,
"maxnumdtc" integer,
"sumnumdtc" integer,
"mindeltadtc" integer,
"avgdeltadtc" double,
"meddeltadtc" integer,
"devdeltadtc" double,
"maxdeltadtc" integer,
"minnumcommondtcprev" integer,
"avgnumcommondtcprev" double,
"mednumcommondtcprev" integer,
"devnumcommondtcprev" double,
"maxnumcommondtcprev" integer,
"minnumcommondtcprev2" integer,
"avgnumcommondtcprev2" double,
"mednumcommondtcprev2" integer,
"devnumcommondtcprev2" double,
"maxnumcommondtcprev2" integer,
"minnumcommondtcprev3" integer,
"avgnumcommondtcprev3" double,
"mednumcommondtcprev3" integer,
"devnumcommondtcprev3" double,
"maxnumcommondtcprev3" integer,
"dtc2421.x" integer,"dtc3193.x" integer,"dtc3927.x" integer,"dtc4572.x" integer,"dtc5583.x" integer,"dtc7224.x" integer,"dtc8137.x" integer,"dtc10388.x" integer,"dtc10434.x" integer,"dtc11417.x" integer,"dtc12803.x" integer,"dtc13193.x" integer,"dtc13566.x" integer,"dtc14405.x" integer,"dtc14996.x" integer,"dtc15733.x" integer,"dtc17812.x" integer,"dtc18113.x" integer,"dtc20292.x" integer,"dtc22716.x" double,"dtc23082.x" integer,"dtc23232.x" integer,"dtc24141.x" integer,"dtc24628.x" integer,"dtc25025.x" integer,"dtc25276.x" integer,"dtc25406.x" integer,"dtc25889.x" integer,"dtc26141.x" integer,"dtc29951.x" integer,"dtc30074.x" integer,"dtc31027.x" integer,"dtc31272.x" integer,"dtc32768.x" integer,"dtc32791.x" integer,"dtc33071.x" integer,"dtc33402.x" integer,"dtc34490.x" integer,"dtc36604.x" integer,"dtc36682.x" integer,"dtc37018.x" integer,"dtc37145.x" integer,"dtc37604.x" integer,"dtc38622.x" integer,"dtc39062.x" integer,"dtc39557.x" integer,"dtc39719.x" integer,"dtc40635.x" integer,"dtc41047.x" integer,"dtc43538.x" integer,"dtc43958.x" integer,"dtc44904.x" integer,"dtc45344.x" integer,"dtc45731.x" integer,"dtc46189.x" integer,"dtc2421.y" double,"dtc3193.y" double,"dtc3927.y" double,"dtc4572.y" double,"dtc5583.y" double,"dtc7224.y" double,"dtc8137.y" double,"dtc10388.y" double,"dtc10434.y" double,"dtc11417.y" double,"dtc12803.y" double,"dtc13193.y" double,"dtc13566.y" double,"dtc14405.y" double,"dtc14996.y" double,"dtc15733.y" double,"dtc17812.y" double,"dtc18113.y" double,"dtc20292.y" double,"dtc22716.y" double,"dtc23082.y" double,"dtc23232.y" double,"dtc24141.y" double,"dtc24628.y" double,"dtc25025.y" double,"dtc25276.y" double,"dtc25406.y" double,"dtc25889.y" double,"dtc26141.y" double,"dtc29951.y" double,"dtc30074.y" double,"dtc31027.y" double,"dtc31272.y" double,"dtc32768.y" double,"dtc32791.y" double,"dtc33071.y" double,"dtc33402.y" double,"dtc34490.y" double,"dtc36604.y" double,"dtc36682.y" double,"dtc37018.y" double,"dtc37145.y" double,"dtc37604.y" double,"dtc38622.y" double,"dtc39062.y" double,"dtc39557.y" double,"dtc39719.y" double,"dtc40635.y" double,"dtc41047.y" double,"dtc43538.y" double,"dtc43958.y" double,"dtc44904.y" double,"dtc45344.y" double,"dtc45731.y" double,"dtc46189.y" double,"modelE46" integer,"modelE53" integer,"modelE60" integer,"modelE61" integer,"modelE63" integer,"modelE64" integer,"modelE65" integer,"modelE66" integer,"modelE70" integer,"modelE71" integer,"modelE72" integer,"modelE82" integer,"modelE83" integer,"modelE84" integer,"modelE85" integer,"modelE86" integer,"modelE88" integer,"modelE89" integer,"modelE90" integer,"modelE91" integer,"modelE92" integer,"modelE93" integer,"modelF01" integer,"modelF02" integer,"modelF04" integer,"modelF06" integer,"modelF07" integer,"modelF10" integer,"modelF12" integer,"modelF13" integer,"modelF25" integer,"modelF30" integer,"modelK25" integer,"modelK26" integer,"modelK27" integer,"modelK28" integer,"modelK29" integer,"modelK40" integer,"modelK43" integer,"modelK44" integer,"modelK46" integer,"modelK48" integer,"modelK71" integer,"modelK72" integer,"modelK73" integer,"modelR50" integer,"modelR52" integer,"modelR53" integer,"modelR55" integer,"modelR56" integer,"modelR57" integer,"modelR58" integer,"modelR59" integer,"modelR60" integer,"modelRR1" integer,"modelRR2" integer,"modelRR3" integer,"modelRR4" integer, primary key("vin"))@


load from /local2/yannis/features2.csv of del  insert into "features2.csv"

create index features2_idxon "features2.csv" ("vin")@
runstats on table "features2.csv"@
