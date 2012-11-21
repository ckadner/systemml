--------------------------------------------------------------------------------
--
-- Run this SQL code on the warehouse data to EXPORT data for supervised learning
--
-- We extract the following data.
--
-- ML_CARS
-- ML_READOUTS and ML_READOUTDTCS
-- WARRANTY REPAIR DIAGNOSTIC FINDINGS
-- WARRANTY REPAIR EXCHANGE PARTS
-- VEHICLE OPTIONS
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--
-- HILFS-VIEW: RELEVANTE AUSLESUNGEN FÜR DTCs: NUR MINIMALE AUSLESUNGEN PRO WERKSTATTFALL MIT DATEITYP 'D'
-- have valid DTS that are not set through software programming.
--
--------------------------------------------------------------------------------

-- select count(*) from Helper_Fahrzeug_Auslesevorgang_Clean@
--  6,501,361

drop view HELPER_FAHRZEUG_AUSLESEVORGANG_CLEAN@
create view HELPER_FAHRZEUG_AUSLESEVORGANG_CLEAN as
select   ro.fahrzeug_auslese_vorg_id
       , ro.fahrgestellnr_7
       , ro.werkstattfall_id
       , ro.ausleseindex
       , ro.auslesedatum
       , ro.kmstand 
       , ro.haendlernummer
       , ro.fzg_produktionsdatum
from BMW.V_VM_FAHRZEUG_AUSLESEVORGANG ro
join (select
	AV2.FAHRGESTELLNR_7, AV2.WERKSTATTFALL_ID, MIN(AV2.AUSLESEINDEX) AS MININDEX 
	from BMW.V_VM_FAHRZEUG_AUSLESEVORGANG AV2 
	where AV2.DATEITYP='D' 
	group by AV2.FAHRGESTELLNR_7, AV2.WERKSTATTFALL_ID) AVR
on (
	ro.FAHRGESTELLNR_7=AVR.FAHRGESTELLNR_7 and
	ro.WERKSTATTFALL_ID=AVR.WERKSTATTFALL_ID and
	ro.AUSLESEINDEX=AVR.MININDEX)@


--------------------------------------------------------------------------------
--
-- ML_CARS: Machine Learning Cars 
--
--------------------------------------------------------------------------------

-- We received 8920 lemons.
-- For the 3,553,761 cars, we have 921995 (880589 US) cars w/o any readouts.
--     bmw.v_vm_bmw_fahrzeug  => 3,553,761
--      MINUS
--    distinct fahrgestellnr_7 from helper_fahrzeug_auslesevorgang_clean before lemon@ => 
--    And we have some lemons w/o readouts before they become lemons (93)
-- HENCE: WE CONSIDER THE ... CANDIDDATE CARS AS OUR STARTING POINT TO DEFINE CARS, READOUTS,
-- WARRANTY, ETC.

-- We consider only cars with a production date in 2006 or later. This is blessed by BMW. Reason:
-- very few lemons among cars produced before 2006 (0.03 % (471 out of 1637880) of all cars produced
-- before 2006 are lemons. 0.43 % (8449 out of 1957287) the cars with a production year of 2006 or
-- later are lemons

--  select count(*) from ml_cars_list@
--    1741632
--  select count(*) from ml_cars_list where class = 1@
--    8329

drop table ml_cars_list@
create table ml_cars_list (fahrgestellnr_7 varchar(32) not null, class integer, primary key (fahrgestellnr_7))@
insert into ml_cars_list 
  with t as (select r.fahrgestellnr_7, r.auslesedatum, r.haendlernummer, r.kmstand, fzg_produktionsdatum,
             l.pseudovin, l.reparaturdatum_min 
             from helper_fahrzeug_auslesevorgang_clean r left outer join bmw.us_dissatisfactionlist l
               on r.fahrgestellnr_7 = l.pseudovin
            ),
      -- only readouts before car became lemon
      t1 as (select fahrgestellnr_7, pseudovin, kmstand, haendlernummer, fzg_produktionsdatum
             from t
             where t.reparaturdatum_min is null or t.reparaturdatum_min >= t.auslesedatum),
      -- remove non lemon cars that have any readout mileage < 0
      t2 as (select fahrgestellnr_7, min(pseudovin) as goodcar, min (kmstand) as min_mileage
             from t1
             where year(t1.fzg_produktionsdatum) >= 2006
             group by fahrgestellnr_7)
      select fahrgestellnr_7, 
             case when goodcar is not null then 1 else -1 end as class 
      from t2 where min_mileage >=0 or goodcar is not null
@
-- Remove ~800 (7 lemons) cars because of missing dealer info
delete from ml_cars_list
where fahrgestellnr_7
      in (select distinct fahrgestellnr_7
          from helper_fahrzeug_auslesevorgang_clean
	  where haendlernummer in ('AG100','XXXXX') or haendlernummer is null)
@


--   select class, count(*) as cnt from ml_cars group by rollup(class)@
--      Note: total count is less then original list because we restrict to US 
--        CLASS       CNT        
--          1        8319
--         -1     1718467
--          -     1726786


drop view ml_cars@
create view ml_cars as 
  with c as (
     select 
          case when l.pseudovin is not null 
           then 1 else -1 
          end                               as class
   	 ,l.reparaturdatum_min              as ldate
   	 ,c.fahrgestellnr_7                 as vin
   	 ,c.produktionsdatum                as production_date
	 ,c.typschluessel                   as typschluessel
     from (select * 
           from bmw.v_vm_bmw_fahrzeug c 
           where fahrgestellnr_7 in (select fahrgestellnr_7 from ml_cars_list)
          ) c
          left outer join bmw.us_dissatisfactionlist l
       on c.fahrgestellnr_7 = l.pseudovin
     where c.orderland = 'US')
  select  c.*
         ,typ.baureihe                             as line
         ,typ.modell                               as model
	 ,substr(typ.motorbaureihe,1,4)            as engine_model
         ,case 
            when length (trim(typ.modelljahr)) = 0 
              then 0 
            else integer(modelljahr) 
          end                                      as model_year
  from c, bmw.v_vm_typ_denorm  typ
  where c.typschluessel = typ.typschluessel
@


--------------------------------------------------------------------------------
--
-- ML_READOUTs, ML_READOUTDTS
--
--------------------------------------------------------------------------------

-- select count(*), count(distinct vin) from ml_readouts@
--   4524725     1726786
-- select count(*) from ml_readouts where mileage < 0@
--   0

drop view ml_readouts@
create view ml_readouts as 
   with t as (
     select 
            r.fahrzeug_auslese_vorg_id   as key
           ,r.werkstattfall_id	         as repair_case
           ,r.ausleseindex               as readout_index 
           ,r.auslesedatum               as readout_date
           ,r.kmstand                    as mileage
	   ,r.haendlernummer             as haendlernummer
           ,car.vin                      as vin
     from ml_cars car left outer join helper_fahrzeug_auslesevorgang_clean r 
       on car.vin = r.fahrgestellnr_7 
     where car.ldate is null or car.ldate >= r.auslesedatum)
   select t.*
         ,d.plz            as zipcode
   from t, bmw.v_vm_haendler_denorm d
   where t.haendlernummer = d.haendlernummer
  @


--------------------------------------------------------------------------------
--
-- ReadOut DTCs
--
--------------------------------------------------------------------------------

-- select count(*), count (distinct DTC) from ml_readoutdtcs@
--      132487499       46293

drop view ml_readoutDTCS@
create view ml_readoutDTCS as (
   select r.key as key, 
          rtrim(steuergeraetbeschrdat_var) 
             || '@' || varchar(fehlerort_nr)  
             || '@' || varchar(fehlerspeicher_art) as DTC, 
	  1 as value
   from   ml_readouts r
         ,bmw.v_vm_fehler_in_fehlerspeicher dtcs
   where  r.key = dtcs.fahrzeug_auslese_vorg_id 
) @


--------------------------------------------------------------------------------
--
-- Warranty Repair Diagnosis
-- Warranty: ANTRAG_GUT (gewaehrleistungs antrag gutschrift)
--
--------------------------------------------------------------------------------

-- select count(*), count (distinct wid), count (distinct vin), count(distinct diag_finding) from ml_warr_rep_diag@
--         24383656    11565051                   1716271            3738

drop view ml_warr_rep_diag@
create view ml_warr_rep_diag as (
select  w.antrag_id       as wid
       ,r.line_nr
       ,w.fahrgestellnr_7 as vin
       ,w.reparaturdatum  as wrepdate
       ,substring(r.befund_bereinigt,1,6,CODEUNITS32) as diag_finding
from  
      ml_cars c
     ,bmw.v_vm_gw_antrag w 
     ,bmw.v_vm_gw_antrep r
where c.vin = w.fahrgestellnr_7
  and w.antrag_id = r.antrag_id
)@


--------------------------------------------------------------------------------
--
-- Warranty Repair Exchanged Parts: 
--    ANTTEIL_GUT (antrag teil gutschrift)
--
--------------------------------------------------------------------------------

--  select count(*), count (distinct vin), count(distinct wid), count(distinct partid) from ml_warr_rep_exchgparts@
--         26805284     1399888                  8485888               13270

drop view ml_warr_rep_exchgparts@
create view ml_warr_rep_exchgparts as (
select wr.vin, wr.wid,  wr.line_nr, wp.item_nummer, 
       p.benennungs_nr as partId
from  ml_warr_rep_diag wr
     ,bmw.v_vm_gw_antteil wp   
     ,bmw.v_vm_teil p
where wr.wid= wp.antrag_id
  and wr.line_nr = wp.line_nr
  and wp.teile_sachnummer = p.teile_sachnummer
)@


--------------------------------------------------------------------------------
--
-- Vehicle Options
--    car options from fahrzeug_sa: vertriebsschluessel and sa_bestelltyp (S=typical; B=color, ...)
--
--------------------------------------------------------------------------------

-- select count(*), count(distinct vin), count(distinct option) from ml_car_options@
--        77574991       1726719            1220

drop view ml_car_options@
create view ml_car_options as 
select vin, rtrim(vertriebsschluessel) || '@' || varchar(sa_bestelltyp) as option, 1 as value 
from  ml_cars c
     ,bmw.v_vm_fahrzeug_sa sa
where c.vin = sa.fahrgestellnr_7
@


--------------------------------------------------------------------------------
--
-- EXPORT
--
--------------------------------------------------------------------------------

call sysproc.admin_cmd ('
export to /tmp/ml_cars_list.del of del messages on server
select fahrgestellnr_7, class
from ml_cars_list
order by fahrgestellnr_7
')@


call sysproc.admin_cmd ('
export to /tmp/ml_cars.del of del messages on server
export to /home/reinwald/ml_cars.del of del
select class, vin, production_date, line, model, engine_model, model_year 
from ml_cars
order by vin
')@


call sysproc.admin_cmd ('
export to /tmp/ml_readouts.del of del messages on server
export to /home/reinwald/ml_readouts.del of del
select key, vin, repair_case, readout_index, readout_date, mileage, haendlernummer, zipcode 
from ml_readouts
order by vin
')@


call sysproc.admin_cmd ('
export to /tmp/ml_readoutDTCs.del of del messages on server
select key, dtc, value
from ml_readoutDTCs
order by key, dtc
')@


call sysproc.admin_cmd ('
export to /tmp/ml_warr_rep_diag.del of del messages on server
select vin, wid, wrepdate, line_nr, diag_finding
from ml_warr_rep_diag
order by vin, wid, wrepdate, line_nr, diag_finding
')@


call sysproc.admin_cmd ('
export to /tmp/ml_warr_rep_exchgparts.del of del messages on server
select vin, wid, line_nr, item_nummer, partId
from ml_warr_rep_exchgparts
order by vin, wid, line_nr, item_nummer, partId
')@


call sysproc.admin_cmd ('
export to /tmp/ml_car_options.del of del messages on server
select vin, option, value
from ml_car_options
order by vin, option
')@


-- delete files in temp space
call sysproc.admin_cmd ('
export to /tmp/ml_warr_rep_exchgparts.del of del messages on server
values 1
')@



