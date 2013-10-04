--------------------------------------------------------------------------------
--
-- Create sparse matrix w/ rowId/columnId recoded for SVM
--
--------------------------------------------------------------------------------

create table svm_readoutinfo as (
  select key, 0 as key_rcd, class
  from readoutinfo
) with no data@

-- create and populate recode map for key

create table svm_key_rcd_map (
   rowid  integer, 
   key    integer
)@

insert into svm_key_rcd_map
  select row_number() over (order by key asc), key 
  from ReadOutInfo@

CREATE INDEX svm_key_rcd_map_rowid ON svm_key_rcd_map (rowid)@
CREATE INDEX svm_key_rcd_map_key ON svm_key_rcd_map (key)@
runstats on table svm_key_rcd_map@

-- populate the readoutinfo including recode

insert into svm_readoutinfo 
  select roi.key, rcd.rowid, roi.class
  from readoutinfo roi, svm_key_rcd_map rcd
  where roi.key = rcd.key
@

CREATE INDEX svm_readoutinfo_key ON svm_readoutinfo (key)@
CREATE INDEX svm_readoutinfo_key_rcd_map_key ON svm_readoutinfo (key_rcd)@
runstats on table svm_readoutinfo@

--
-- readoutDTCs for SVM
--

create table svm_readoutdtcs as (
  select key, dtc, 0 as dtc_rcd, value
  from readoutdtcs
) with no data@

-- create and recode map for DTCs

create table svm_dtc_rcd_map (
    rowid integer,
    dtc varchar(20)
)@


insert into svm_dtc_rcd_map
  with t as (
    select distinct dtc
    from readoutdtcs)
  select row_number() over (order by dtc asc), dtc
  from t
@

CREATE INDEX svm_dtc_rcd_map_rowid ON svm_dtc_rcd_map (rowid)@
CREATE INDEX svm_dtc_rcd_map_key ON svm_dtc_rcd_map (dtc)@
runstats on table svm_dtc_rcd_map@

-- populate readoutdtcs including recode

update command options using c off@
alter table svm_readoutdtcs activate not logged initially@
insert into svm_readoutdtcs
   select rod.key, rod.dtc, rcd.rowid, rod.value
   from readoutdtcs rod, svm_dtc_rcd_map rcd
   where rod.dtc = rcd.dtc
@
commit@

-- insert class label column

insert into svm_readoutdtcs
  select key, 'class', (select max(rowid) from svm_dtc_rcd_map)+1, 1
  from svm_readoutinfo roi
  where class = 'lemon'

CREATE INDEX svm_readoutdtcs_key ON svm_readoutdtcs (key)@
CREATE INDEX svm_readoutdtcs_dtc_rcd_ ON svm_readoutdtcs (dtc_rcd)@
runstats on table svm_readoutdtcs@

--
-- Create Matrix <i, j, v> w/ recoded values
--

call sysproc.admin_cmd ('
 to /stage/reinwald/svm_dtcs.mtx of del messages on server
   select roi.key_rcd, rod.dtc_rcd, rod.value
   from svm_readoutinfo roi, svm_readoutdtcs rod
   where roi.key = rod.key
')


--   rows= 13835947
select max(key_rcd) from svm_readoutinfo

--   cols = 74747
select max(dtc_rcd)+1 from svm_readoutdtcs

--