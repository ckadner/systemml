that I use to copy/paste  in R:

library(RPostgreSQL)
library(sqldf)
#library(RSQLite)
library(glmnet)
library(randomForest)
library(caTools)
library(data.table)
library(Matrix)
library(caret)
require(doMC)
require(doRNG)

options(sqldf.RPostgreSQL.user = "postgres", 
  sqldf.RPostgreSQL.password = "postgres",
  sqldf.RPostgreSQL.dbname = "bmwdb",
  sqldf.RPostgreSQL.hostname = "localhost", 
  sqldf.RPostgreSQL.port = 5432)

registerDoMC(4)
#msql<-function(s,...) sqldf(s,dbname="mydb",...) #for sqlite
msql<-function(s,...) sqldf(s,...)


# computes first k singular values of A with corresponding singular vectors
stochSvd <- function(A, k) {
  p <- 10              # may need a larger value here
  n <- dim(A)[1]
  m <- dim(A)[2]

  # random projection of A    
  Y <- (A %*% matrix(rnorm((k+p) * m), ncol=k+p))
  # the left part of the decomposition works for A (approximately)
  Q <- qr.Q(qr(Y))
  # taking that off gives us something small to decompose
  B <- t(Q) %*% A

  # decomposing B gives us singular values and right vectors for A  
  s <- svd(B)
  U <- Q %*% s$u
  # and then we can put it all together for a complete result
  list(u=U, v=s$v, d=s$d)
}

prepareData<-function() {
#  unlink("mydb")
#  sqldf("attach mydb as new")

  #add missing median function
  msql("create or replace function _final_median(anyarray)
        returns float8 as $$
        with q as (
          select val from unnest($1) val where val is not null order by val
        ),cnt as (
          select count(*) c from q
        )
        select avg(val)::float8
        from (
          select val from q
          limit 2 - mod( (select c from cnt),2 )
          offset greatest(ceil((select c from cnt)/2.0)-1,0)
        ) q2;
        $$
        language sql immutable")

  msql("create aggregate median(anyelement) (
        sfunc=array_append,
        stype=anyarray,
        finalfunc=_final_median,
        initcond='{}'
        )")
  
                                        #read and normalize dtcs
  msql("create table DTC(key integer,dtc varchar(20),value char(1))")
  msql("copy DTC from '/BMWtmp/data/ReadOutDTCs.del' with delimiter ',' csv quote '\"' ")
#  msql("copy DTC from '/Users/Shared/ReadOutDTCs.del' with delimiter ',' csv quote '\"' ")
#  system.time(read.csv.sql("ReadOutDTCs.del",sql="insert into DTC select * from file",header=F,dbname="mydb")) #sqlite
#  msql("create table distDTC(dtcid integer primary key autoincrement,dtc varchar(20))") #sqlite
  msql("create table distDTC(dtcid serial primary key,dtc varchar(20))")
  msql("insert into distDTC(dtc) select distinct dtc from DTC")
  msql("create unique index dtcidx1 on distDTC(dtc)")
  msql("alter table DTC rename to oldDTC")
  system.time(msql("create table DTC as select a.key,b.dtcid from oldDTC a,distDTC b where a.dtc=b.dtc"))
  msql("drop table oldDTC")
  msql("create index dtckeyidx on DTC(key)")
  msql("analyze DTC")
                                        #msql("vacuum") #too slow, but reduces the size considerably
  
  
                                        #read and normalize info table
  msql("create table INFO(key integer,vin varchar(32),repair_case bigint,readout_index bigint,readout_date char(8),mileage integer,model varchar(8),production_date char(8),class varchar(32),ldate char(8),dtccnt integer)")
#  system.time(read.csv.sql("ReadOutInfos2.del",sql="insert into INFO select * from file",header=F,dbname="mydb"))
  msql("copy INFO from '/BMWtmp/data/ReadOutInfos2.del' with delimiter ',' csv quote '\"' ")
#  msql("copy INFO from '/Users/Shared/ReadOutInfos2.del' with delimiter ',' csv quote '\"' ")
  msql("analyze INFO")
#  msql("create table distVIN(vinid integer primary key autoincrement,vin varchar(32))")
  msql("create table distVIN(vinid serial primary key,vin varchar(32))")
  msql("insert into distVIN(vin) select distinct vin from INFO")
  msql("create unique index vinidx1 on distVIN(vin)")
#  msql("alter table info add column vinid integer references distvin(vinid)")
  msql("alter table info add column vinid integer")
  msql("analyze  distvin")
  msql("update info set vinid = (select vinid from distvin a where a.vin=info.vin)")
  msql("alter table info add column readout_date2 date")
  msql("alter table info add column production_date2 date")
#  msql("update info set readout_date2 = strftime(substr(readout_date,1,4)||'-'||substr(readout_date,5,2)||'-'||substr(readout_date,7,2))") #sqlite
  msql("update info set readout_date2 = to_date(substr(readout_date,1,4)||'-'||substr(readout_date,5,2)||'-'||substr(readout_date,7,2),'YYYY-MM-DD')")
  msql("update info set production_date2 = to_date(substr(production_date,1,4)||'-'||substr(production_date,5,2)||'-'||substr(production_date,7,2),'YYYY-MM-DD')")
  msql("alter table info add column ldate2 date")
  msql("update info set ldate2 = case when ldate is null then null else to_date(substr(ldate,1,4)||'-'||substr(ldate,5,2)||'-'||substr(ldate,7,2),'YYYY-MM-DD') end")
  msql("create index infokeyidx on INFO(key)")
  msql("create index infovinididx on INFO(vinid,ldate2)")
  msql("analyze INFO")

  #ignore readings after a lemon is declared (or not?)
#  msql("create view info2 as select * from info where ldate='' or (ldate!='' and ldate>=readout_date)")
#  msql("create table info2 as select * from info where ldate2 is null or (ldate2 is not null and ldate2>=readout_date2)")

  msql("drop table info2")
  msql("create table info2 as select * from info where ldate2 is null or (ldate2 is not null and ldate2>=readout_date2)")
#    msql("create table info2 as with t as (select vinid from info group by vinid having count(*)>=10) select i.* from info i,t where i.vinid=t.vinid and ldate2>=readout_date2")
#      #STRESS IT OUT!!
#    msql("create table info2 as
#            with t as (
#              select vinid
#              from info
#              group by vinid
#              having count(*)>4
#            ), p as (
#              select key,vinid,dense_rank() over (partition by vinid order by readout_date2 asc) as rnk
#              from info i
#              where ldate2 is not null and readout_date2<=ldate2
#                    and i.vinid in (select vinid from t)
#            ), q as (
#              select *,max(rnk) over (partition by vinid) as maxrnk from p
#            ), q0 as (
#              select key from q where rnk<=maxrnk
#            )
#              select i.* from info i,q0 where i.key=q0.key
#              union all
#              select * from info i where ldate2 is null and i.vinid in (select vinid from t)
#         ")
#    
#    msql("create table info2 as
#          with t as (
#            select key,
#                   vinid,
#                   readout_date2,
#                   dense_rank() over (partition by vinid order by readout_date2 asc) as rnk
#            from info
#            where ldate2 is not null and readout_date2<=ldate2),
#          p as (
#             select *,
#                    max(rnk) over (partition by vinid) as maxrnk from t),
#          q as (select key from p where rnk<maxrnk-2)
#          select i.* from info i,q where i.key=q.key
#          union all
#          select * from info where ldate2 is null
#     ")
  msql("create index info2idx on info2(key)")
  msql("analyze info2")

  #compute dtc aggregates (used for tfidf ranking)
  msql("drop table dtcstats")
  msql("create table dtcstats as select 1 as lemon,dtcid,count(*) as allcnt,count(distinct vinid) as distvincnt from info2 i,dtc d where i.key=d.key and i.class='lemon' group by dtcid") #use all lemons
  msql("insert into dtcstats select 0 as lemon,dtcid,count(*) as allcnt,count(distinct vinid) as distvincnt from info2 i,dtc d where i.key=d.key and i.class is null and i.vinid%10=1 group by dtcid") #use a 10% sample for non-lemons
  

  #create features table
  msql("drop table features")
  system.time(msql("create table features as
        select vinid,model,class,
               min(to_date(substr(production_date,1,4),'YYYY')) as prodyear,
               min(readout_date2-production_date2) as minlivedays,
               avg(readout_date2-production_date2) as avglivedays,
               median(readout_date2-production_date2) as medlivedays,
               case when count(*)=1 then 0 else stddev(readout_date2-production_date2) end as devlivedays,
               max(readout_date2-production_date2) as maxlivedays,
               count(*) as allcnt,
               count(distinct readout_date2) as distreaddatecnt,
--               (max(readout_date2)-min(readout_date2))/count(distinct key) as avgvisitdaygap,
               min(readout_index) as minreadoutidx,
               avg(readout_index) as avgreadoutidx,
               median(readout_index) as medreadoutidx,
               case when count(*)=1 then 0 else stddev(readout_index) end as devreadoutidx,
               max(readout_index) as maxreadoutidx,
               min(repair_case) as minrepaircase,
               avg(repair_case) as avgrepaircase,
               median(repair_case) as medrepaircase,
               case when count(*)=1 then 0 else stddev(repair_case) end as devrepaircase,
               max(repair_case) as maxrepaircase,
               min(mileage) as minmileage,
               avg(mileage) as avgmileage,
               median(mileage) as medmileage,
               case when count(*)=1 then 0 else stddev(mileage) end as devmileage,
               max(mileage) as maxmileage
--               (max(mileage)-min(mileage))/count(distinct key) as avgmileagevisitgap,
--               min(dtccnt) as mindtccnt,
--               avg(dtccnt) as avgdtccnt,
--               case when count(*)=1 then 0 else stddev(dtccnt) end as devdtccnt,
--               max(dtccnt) as maxdtccnt
         from info2 group by vinid,model,class"))

  msql("create index featuresvinidx on features(vinid)")
  msql("analyze features")

  #create sliding window over readout date stats
  msql("drop table slidefeatures")
  system.time(msql("create table slidefeatures as with t as (
        select vinid,
               readout_date2-lag(readout_date2,1) over (partition by vinid order by readout_date2 asc) as readoutdatelag,
                mileage-lag(mileage,1) over (partition by vinid order by readout_date2 asc) as mileagelag from info2)
        select vinid,
               min(readoutdatelag) as minreadoutdatelag,
               avg(readoutdatelag) as avgreadoutdatelag,
               median(readoutdatelag) as medreadoutdatelag,
               case when count(*)=1 then 0 else stddev(readoutdatelag) end as devreadoutdatelag,
               max(readoutdatelag) as maxreadoutdatelag,
               min(mileagelag) as minmileagelag,
               avg(mileagelag) as avgmileagelag,
               median(mileagelag) as medmileagelag,
               case when count(*)=1 then 0 else stddev(mileagelag) end as devmileagelag,
               max(mileagelag) as maxmileagelag
        from t
        group by vinid"))

  msql("create index slidefeaturesvinidx on slidefeatures(vinid)")
  msql("analyze slidefeatures")

  #********************************************************************************
  #compute some stats for the dtc's lags
#  msql("drop table dtcfeatures")
#  msql("create table dtcfeatures as
#        with t as (
#          select vinid,
#                 dtcid,
#                 readout_date2-lag(readout_date2,1) over (partition by vinid,dtcid order by readout_date2 asc) as rlag,
#                 mileage-lag(mileage,1) over (partition by vinid,dtcid order by readout_date2 asc) as mlag
#          from info2 i,dtc d where i.key=d.key)
#        select vinid,
#               min(rlag) as mindtcreaddlag,
#               avg(rlag) as avgdtcreaddlag,
#               case when count(*)=1 then 0 else stddev(rlag) end as devdtcreaddlag,
#               max(rlag) as maxdtcreaddlag,
#               min(mlag) as mindtcmileagelag,
#               avg(mlag) as avgdtcmileagelag,
#               case when count(*)=1 then 0 else stddev(mlag) end as devdtcmileagelag,
#               max(mlag) as maxdtcmileagelag
#        from t
#        group by vinid")


  #utility functions for intersection 2,3 or 4 arrays in sql
  msql("CREATE OR REPLACE FUNCTION array_intersect(anyarray, anyarray) 
        RETURNS anyarray AS $$
          SELECT ARRAY(SELECT unnest($1) 
                       INTERSECT 
                       SELECT unnest($2))
          $$ LANGUAGE sql")
  
  msql("CREATE OR REPLACE FUNCTION length_intersect(anyarray, anyarray) 
        RETURNS BIGINT AS $$
          WITH T AS
                       (SELECT unnest($1) 
                       INTERSECT 
                       SELECT unnest($2))
          SELECT COUNT(*) FROM T
          $$ LANGUAGE sql")

  msql("CREATE OR REPLACE FUNCTION array_intersect(anyarray, anyarray, anyarray) 
        RETURNS anyarray AS $$
          SELECT ARRAY(SELECT unnest($1) 
                       INTERSECT 
                       SELECT unnest($2)
                       INTERSECT
                       SELECT unnest($3)
                       )
          $$ LANGUAGE sql")

  msql("CREATE OR REPLACE FUNCTION length_intersect(anyarray, anyarray, anyarray) 
        RETURNS BIGINT AS $$
          WITH T AS (SELECT unnest($1) 
                       INTERSECT 
                       SELECT unnest($2)
                       INTERSECT
                       SELECT unnest($3)
                       )
          SELECT COUNT(*) FROM T
          $$ LANGUAGE sql")

  msql("CREATE OR REPLACE FUNCTION array_intersect(anyarray, anyarray, anyarray, anyarray) 
        RETURNS anyarray AS $$
          SELECT ARRAY(SELECT unnest($1) 
                       INTERSECT 
                       SELECT unnest($2)
                       INTERSECT
                       SELECT unnest($3)
                       INTERSECT
                       SELECT unnest($4)
                       )
          $$ LANGUAGE sql")

  msql("CREATE OR REPLACE FUNCTION length_intersect(anyarray, anyarray, anyarray, anyarray) 
        RETURNS BIGINT AS $$
          WITH T AS (SELECT unnest($1) 
                       INTERSECT 
                       SELECT unnest($2)
                       INTERSECT
                       SELECT unnest($3)
                       INTERSECT
                       SELECT unnest($4)
                       )
          SELECT COUNT(*) FROM T
          $$ LANGUAGE sql")

  msql("CREATE OR REPLACE FUNCTION array_intersect(anyarray, anyarray, anyarray, anyarray, anyarray) 
        RETURNS anyarray AS $$
          SELECT ARRAY(SELECT unnest($1) 
                       INTERSECT 
                       SELECT unnest($2)
                       INTERSECT
                       SELECT unnest($3)
                       INTERSECT
                       SELECT unnest($4)
                       INTERSECT
                       SELECT unnest($5)
                       )
          $$ LANGUAGE sql")

  msql("CREATE OR REPLACE FUNCTION length_intersect(anyarray, anyarray, anyarray, anyarray, anyarray) 
        RETURNS BIGINT AS $$
          WITH T AS(SELECT unnest($1) 
                       INTERSECT 
                       SELECT unnest($2)
                       INTERSECT
                       SELECT unnest($3)
                       INTERSECT
                       SELECT unnest($4)
                       INTERSECT
                       SELECT unnest($5)
                       )
          SELECT COUNT(*) FROM T
          $$ LANGUAGE sql")

#  msql("drop table dtcfeatures")
#  msql("create table dtcfeatures as with t as (
#           select vinid,
#                  readout_date2,
#                  array_agg(dtcid) as dtcarr
#           from info2 i,dtc d
#           where i.key=d.key
#           group by vinid,readout_date2),
#        p as (
#           select vinid,
#               readout_date2,
#               array_length(
#                   array_intersect(
#                     dtcarr,
#                     lag(dtcarr,1) over (partition by vinid order by readout_date2))
#                ,1) as numcommondtcprev,
#                array_length(
#                  array_intersect(
#                    dtcarr,
#                    lag(dtcarr,1) over (partition by vinid order by readout_date2),
#                    lag(dtcarr,2) over (partition by vinid order by readout_date2))
#                ,1) as numcommondtcprev2,
#                array_length(
#                  array_intersect(
#                    dtcarr,
#                    lag(dtcarr,1) over (partition by vinid order by readout_date2),
#                    lag(dtcarr,2) over (partition by vinid order by readout_date2),
#                    lag(dtcarr,3) over (partition by vinid order by readout_date2))
#                ,1) as numcommondtcprev3,
#             array_length(
#                  array_intersect(
#                    dtcarr,
#                    lag(dtcarr,1) over (partition by vinid order by readout_date2),
#                    lag(dtcarr,2) over (partition by vinid order by readout_date2),
#                    lag(dtcarr,3) over (partition by vinid order by readout_date2),
#                    lag(dtcarr,4) over (partition by vinid order by readout_date2))
#                ,1) as numcommondtcprev4
#           from t)
#        select vinid,
#               min(numcommondtcprev) as minnumcommondtcprev,
#               avg(numcommondtcprev) as avgnumcommondtcprev,
#               case when count(*)=1 then 0 else stddev(numcommondtcprev) end as devnumcommondtcprev,
#               max(numcommondtcprev) as maxnumcommondtcprev,
#               min(numcommondtcprev2) as minnumcommondtcprev2,
#               avg(numcommondtcprev2) as avgnumcommondtcprev2,
#               case when count(*)=1 then 0 else stddev(numcommondtcprev2) end as devnumcommondtcprev2,
#               max(numcommondtcprev2) as maxnumcommondtcprev2,
#               min(numcommondtcprev3) as minnumcommondtcprev3,
#               avg(numcommondtcprev3) as avgnumcommondtcprev3,
#               case when count(*)=1 then 0 else stddev(numcommondtcprev3) end as devnumcommondtcprev3,
#               max(numcommondtcprev3) as maxnumcommondtcprev3,
#               min(numcommondtcprev4) as minnumcommondtcprev4,
#               avg(numcommondtcprev4) as avgnumcommondtcprev4,
#               case when count(*)=1 then 0 else stddev(numcommondtcprev4) end as devnumcommondtcprev4,
#               max(numcommondtcprev4) as maxnumcommondtcprev4
#        from p
#        group by vinid
#        ")

  #modified above for speed
  msql("drop table dtcfeatures")
  msql("drop table dtcagg")
  system.time(msql("create table dtcagg as
          select vinid,class,readout_date2,array_agg(dtcid) as dtcarr
          from info2 i,dtc d
          where i.key=d.key
-- BJR!! taken care of with DATEITYP = 'M' list ... and readout_index=1
          group by vinid,class,readout_date2"))
  msql("create index dtcaggidx on dtcagg(vinid,readout_date2)")
  msql("analyze dtcagg")
  system.time(msql("create table dtcfeatures as with t as (
          select vinid,dtcarr,readout_date2,
            array_length(dtcarr,1) as numdtc,
            lag(dtcarr,1) over (partition by vinid order by readout_date2) as l1,
            lag(dtcarr,2) over (partition by vinid order by readout_date2) as l2,
            lag(dtcarr,3) over (partition by vinid order by readout_date2) as l3,
            lag(dtcarr,4) over (partition by vinid order by readout_date2) as l4
          from dtcagg
        ),p as (
          select vinid,numdtc,
                 numdtc-array_length(l1,1) as dn1,
                 array_length(array_intersect(dtcarr,l1),1) as numcommondtcprev,
                 array_length(array_intersect(dtcarr,l1,l2),1) as numcommondtcprev2,
                 array_length(array_intersect(dtcarr,l1,l2,l3),1) as numcommondtcprev3,
                 array_length(array_intersect(dtcarr,l1,l2,l3,l4),1) as numcommondtcprev4
          from t
        ) select vinid,
               min(numdtc) as minnumdtc,
               avg(numdtc) as avgnumdtc,
               median(numdtc) as mednumdtc,
               case when count(*)=1 then 0 else stddev(numdtc) end as devnumdtc,
               max(numdtc) as maxnumdtc,
               sum(numdtc) as sumnumdtc,
               min(dn1) as mindeltadtc,
               avg(dn1) as avgdeltadtc,
               median(dn1) as meddeltadtc,
               case when count(*)=1 then 0 else stddev(dn1) end as devdeltadtc,
               max(dn1) as maxdeltadtc,
               min(numcommondtcprev) as minnumcommondtcprev,
               avg(numcommondtcprev) as avgnumcommondtcprev,
               median(numcommondtcprev) as mednumcommondtcprev,
               case when count(*)=1 then 0 else stddev(numcommondtcprev) end as devnumcommondtcprev,
               max(numcommondtcprev) as maxnumcommondtcprev,
               min(numcommondtcprev2) as minnumcommondtcprev2,
               avg(numcommondtcprev2) as avgnumcommondtcprev2,
               median(numcommondtcprev2) as mednumcommondtcprev2,
               case when count(*)=1 then 0 else stddev(numcommondtcprev2) end as devnumcommondtcprev2,
               max(numcommondtcprev2) as maxnumcommondtcprev2,
               min(numcommondtcprev3) as minnumcommondtcprev3,
               avg(numcommondtcprev3) as avgnumcommondtcprev3,
               median(numcommondtcprev3) as mednumcommondtcprev3,
               case when count(*)=1 then 0 else stddev(numcommondtcprev3) end as devnumcommondtcprev3,
               max(numcommondtcprev3) as maxnumcommondtcprev3
--               min(numcommondtcprev4) as minnumcommondtcprev4,
--               avg(numcommondtcprev4) as avgnumcommondtcprev4,
--               case when count(*)=1 then 0 else stddev(numcommondtcprev4) end as devnumcommondtcprev4,
--               max(numcommondtcprev4) as maxnumcommondtcprev4
          from p
          group by vinid
        "));
  
  msql("create index dtcfeaturesvinidx on dtcfeatures(vinid)")
  msql("analyze dtcfeatures")

  
  #********************************************************************************
  #find the most predictive dtc's using something like tf*idf (not that great...)
  #dtcs<-data.table(msql("select * from dtcstats"))
  #setkey(dtcs,dtcid)
  #pp<-dtcs[dtcs$lemon == 1,]$dtcid
  #dtcs<-dtcs[dtcs$dtcid %in% pp,]
  #dtcs.l<-dtcs[dtcs$lemon==1,]
  #setkey(dtcs.l,dtcid)
  #dtcs.nl<-dtcs[dtcs$lemon==0,]
  #dtcs.mis<-setdiff(dtcs.l$dtcid,dtcs.nl$dtcid)
  #dtcs.nl<-rbind(dtcs.nl,data.frame(0,dtcs.mis,0,0),use.names=F)
  #setkey(dtcs.nl,dtcid)
                                        ##zz<-log(2+dtcs.l[[4]])/log(2+dtcs.nl[[4]])
                                        ##zz<-(1+dtcs.l[[4]])/(1+dtcs.nl[[4]])
                                        ##zz<-dtcs.l[[4]]
  #zz<-dtcs.l[[3]]/(1+log(1+dtcs.nl[[4]]+dtcs.l[[4]])) #tfidf-like ranking
  #zz.p<-sort.list(zz,dec=T)
  #gdtc<-data.frame(dtcid=dtcs.l[zz.p[1:100]]$dtcid)

#********************************************************************************
  #OR find the most predictive dtcs using laso regression (MUCH BETTER)
  #system.time( msql("create table vinalldtc as select vinid,dtcid,class,count(*) from info2 i,dtc d where i.key=d.key and (class='\"lemon\"' or (class='' and vinid%100=1)) group by vinid,dtcid,class") )
  #msql("drop view info2sample")
  #msql("create table info2sample as select * from info2 where class='lemon' or ( class is null and vinid%10=1)")
  #msql("create table info2sample as select * from info2 where class='lemon' or ( class is null and vinid%10=1)")
  #msql("create index info2sampleidx on info2sample(key)")
  #msql("create view info2sample as select * from info2")
#  msql("drop table dtcsample")
#  msql("create table dtcsample as select i.vinid,i.class,d.dtcid,count(*) as cntall from info2 i,dtc d where i.key=d.key group by i.vinid,i.class,d.dtcid")
  #msql("create table dtcsample as with t as (select vinid,count(*) as cntkey from info2 group by vinid), p as (select i.vinid,i.class,d.dtcid,count(*) as cntall from info2 i,dtc d where i.key=d.key group by i.vinid,i.class,d.dtcid) select p.vinid,p.class,p.dtcid,cntkey,cntall from p,t where p.vinid=t.vinid")
  #z<-msql("select * from dtcsample where class='lemon' or (class is null and vinid%10=1)") #lasso chokes on more non-lemons
  z<-msql("select vinid,class,unnest(dtcarr) as dtcid,count(*) as cntall from dtcagg where class='lemon' or (class is null and vinid%11=3) group by vinid,class,dtcid")
  #z<-msql("select * from dtcsample")
  #do lasso/glmnet using sparseMatrix(!!!)/target combination
  z.vin<-factor(z[,1],levels=unique(z[,1]))
  z.dtcid<-factor(z[,3],levels=unique(z[,3]))
  z[is.na(z[,2]),2]<-0
  z.target<-as.integer(factor(z[,2]))
  z.target<-tapply(z.target,z.vin,min)
  z.a<-sparseMatrix(i=as.integer(z.vin),j=as.integer(z.dtcid),x=as.numeric(z[,4]))
  pp.lemon<-which(z.target==2)
  pp.nlemon<-setdiff(1:nrow(z.a),pp.lemon)
  dtcid.good<-foreach(i=1:30,.combine=c) %dorng% {
    pp<-c(sample(pp.lemon,repl=F),sample(pp.nlemon,length(pp.lemon),repl=F))
    foo<-cv.glmnet(z.a[pp,],factor(z.target[pp]),family="binomial",alpha=1,maxit=10000)
                                        #keep all the non-zero coefficients/dtcs
    cc<-coef(foo)[-1,1]
    cc.p<-which(cc!=0)
    cat(length(cc.p),"(",foo$lambda.min,") ")
    as.integer(as.character(levels(z.dtcid)[cc.p]))
  }
  dtcid.good<-unlist(dtcid.good)
  gg<-tapply(dtcid.good,dtcid.good,length)
  gdtc<-data.frame(dtcid=as.integer(names(gg[gg>=30])))

  #keep only the most predictive dtcs in subdtc and vindtc
  msql("drop table gdtc2")
  msql("create table gdtc2 as select * from gdtc")
  msql("create index gdtcidx on gdtc2(dtcid)")
  msql("analyze gdtc2")
  msql("drop table subdtc")
  msql("create table subdtc as select d.key,d.dtcid from dtc d,gdtc2 g where d.dtcid=g.dtcid")
#  msql("create index subdtcidx on subdtc(key)")
  msql("analyze subdtc")
  msql("drop table vindtc")
  system.time( msql("create table vindtc as select vinid,dtcid,class,count(*) from info2 i,subdtc d where i.key=d.key group by vinid,dtcid,class") )

} #prepareData

bideviance<-function(p,q) {
  q[q<0.01]<-0.01
  q[q>0.99]<-0.99
  -mean(p*log(q)+(1-p)*log(1-q))
}

set.seed(2)
#get the features/vin
y<-msql("select * from features f,slidefeatures s,dtcfeatures d where f.vinid=s.vinid and f.vinid=d.vinid")
#y<-msql("select * from features f,slidefeatures s where f.vinid=s.vinid")
#y<-msql("select * from features f left outer join slidefeatures s on f.vinid=s.vinid left outer join dtcfeatures d on f.vinid=d.vinid")
y$vinid<-NULL #remove one duplicate join column...
y$vinid<-NULL #remove one duplicate join column...
y$model<-factor(y$model)
y$class[is.na(y$class)]<-0
y$class<-factor(as.integer(factor(y$class)))  #empty class creates problems, so use 1,2
#keep a sample of non-lemons and all lemons
pp<-which(y$class==2)
pq<-sample(1:nrow(y),nrow(y)*1.0,replace=F)  #10% of non-lemons or all if you have enough memory/core
pq<-union(pq,pp)
y<-y[pq,]
y[is.na(y)]<-0 #get rid of NA's (due to windows or stdevs)

#get the corresponding dtc's and dummify them using a sparseMatrix
z<-msql("select * from vindtc")
z<-z[z$vinid %in% y$vinid,]
#z<-msql("select * from vindtc where vindtc.vinid in (select vinid from y)") #much slower...
z.vin<-factor(z[,1])
z.dtcid<-factor(z[,2])
z.a<-sparseMatrix(i=as.integer(z.vin),j=as.integer(z.dtcid),x=z[,4])
colnames(z.a)<-paste("dtc",levels(z.dtcid),sep="")
zz<-data.frame(vinid=as.integer(levels(z.vin)),as.matrix(z.a)) #unfortunately no "sparse" data.frames....
#fill-in missing vins (no ridge-selected dtcs)
zz.mis<-setdiff(y$vinid,zz$vinid)
zz.a<-matrix(0,nrow=length(zz.mis),ncol=ncol(z.a))
colnames(zz.a)<-colnames(z.a)
zz.mis<-data.frame(vinid=zz.mis,zz.a)
zz<-rbind(zz,zz.mis)

#join with the rest of the features (use data.tables for speed....)
y<-data.table(y)
setkey(y,vinid)
zz<-data.table(zz)
setkey(zz,vinid)
#normalize dtc counts
zzn<-zz
for(i in 2:ncol(zz)) zzn[[i]]<-zzn[[i]]/y$allcnt
yy<-merge(y,zz,by='vinid',all.x=T)
y<-merge(yy,zzn,by='vinid',all.x=T)
#yy[is.na(yy)]<-0
#y<-data.frame(yy)

#clear up some memory
rm(yy,z,zz,zzn)
gc(verbose=T)

##remove keys
#y$vinid<-NULL
##remove categoricals with >32 levels (rf cannot handle) and convert to dummies
#dummy<-data.table(model.matrix(~model,data=y))
#y$model<-NULL
dummy.a<-sparseMatrix(i=as.integer(factor(y$vinid)),j=as.integer(factor(y$model)),x=1)
colnames(dummy.a)<-paste("model",levels(factor(y$model)),sep="")
dummy<-data.table(vinid=as.integer(levels(factor(y$vinid))),as.matrix(dummy.a))
setkey(dummy,vinid)
y<-merge(y,dummy,by='vinid')
rm(dummy)
gc()
y$vinid<-NULL
y$model<-NULL
#write all features to dbms
#con<-dbConnect(PostgreSQL(),host="localhost",user="postgres",dbname="bmwdb")
#dbWriteTable(con,"yFeatures",y)

#zero var
gg1<-which(sapply(1:ncol(train),function(i) var(y[[i]]))==0)
y<-y[,-gg1,with=F]

#write features data.frame to csv
write.table(y,file="featuresTMP.csv",sep=",",row.names=F,col.names=T)


############################TRAINING STARTS HERE################################


#separate a train/c.v. set
targetVar<-which(names(y)=="class")
sa.lemon<-sample(which(y$class==2),1000,repl=F) #1000'lemons
sa.nolemon<-sample(which(y$class==1),1000,repl=F) #1000'non-lemons
sa<-union(sa.lemon,sa.nolemon)
#train<-cBind(y[-sa,-targetVar,with=F],dummy[-sa,])
train<-y[-sa,-targetVar,with=F,]
target<-y[-sa,targetVar,with=F][[1]]
#cv.train<-cBind(y[sa,-targetVar,with=F],dummy[sa,])
cv.train<-y[sa,-targetVar,with=F,]
cv.target<-y[sa,targetVar,with=F][[1]]
maxsampsize<-length(which(target==2))

#clear up some memory
rm(y)
gc(verbose=T)

#throw-away "useless" features
#gg1<-nearZeroVar(data.matrix(train))
#ff<-rBind(train,cv.train)
#gg1<-which(sapply(1:ncol(train),function(i) var(ff[[i]]))==0)
#train<-train[,-gg1,with=F]
#cv.train<-cv.train[,-gg1,with=F]
#ff<-ff[,-gg1]
#gg2<-findCorrelation(cor(data.matrix(ff)),cutoff=0.99,verbose=F)
#train<-train[,-gg2]
#cv.train<-cv.train[,-gg2]
#rm(ff)
#gc(verbose=T)

#train
foo<-foreach(i=1:4,.combine=combine) %dorng%
randomForest(train,target,ntree=50,sampsize=c(maxsampsize,maxsampsize),repl=T,do.trace=1,importance=F,mtry=5*floor(sqrt(ncol(train))),norm.votes=F)

#weights
ww<-rep(1,length(target))
ww[target==2]<-length(which(target==1))/length(which(target==2))

#train using glmnet
boo<-cv.glmnet(data.matrix(train),target,weights=ww,family="binomial",alpha=0)

#train using gbm
goo<-gbm.fit(data.matrix(train),as.integer(target)-1,distribution="bernoulli",w=ww,keep.data=T,shrinkage=0.1,n.trees=500,bag.fraction=0.5,interaction.depth=2)

#check feature importance
imp<-importance(foo)
imp.p<-sort.list(imp,dec=T)
rownames(imp)[imp.p]

#check probs (auc and deviance)
foo.pred<-predict(foo,cv.train,type="prob")
colAUC(foo.pred[,2],cv.target,plotROC=F)
bideviance(as.integer(cv.target)-1,foo.pred[,2])

#check ranking using probs
pp<-sort.list(foo.pred[,2],dec=T)
summary(cv.target[pp[1:100]])
summary(cv.target[pp[1:250]])
summary(cv.target[pp[1:500]])
summary(cv.target[pp[1:1000]])

#check binary accuracy
foo.pred<-predict(foo,cv.train)
length(which(foo.pred==cv.target))/length(cv.target)


