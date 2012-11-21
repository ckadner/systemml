
--------------------------------------------------------------------------------
--
-- Zip codes mapping tables downloaded from http://www.sqldbpros.com/2011/11/free-zip-code-city-county-state-csv/
--
--------------------------------------------------------------------------------

drop table zipcode_map@
create table zipcode_map (
    zipcode   varchar(5)
   ,lat	      varchar(15)
   ,long      varchar(15)
   ,city      varchar(30)
   ,state     varchar(2)
   ,county    varchar(30)
   ,shipping  varchar(20)
)@

create unique index zipcode_map_key ON zipcode_map (zipcode)@

import from "ZIP_CODES.csv" of del WARNINGCOUNT 1 replace into zipcode_map@ 

