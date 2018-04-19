-- Sequences

SET SEARCH_PATH TO parlgov;
drop table if exists q6 cascade;

-- You must not change this table definition.

CREATE TABLE q6(
        countryName VARCHAR(50),
        cabinetId INT,
        startDate DATE,
        endDate DATE,
        pmParty VARCHAR(100)
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.
-- All cabinets with start and end dates not including most recent.
create view countrycabinet6 as select c1.id, c1.country_id, c1.start_date,
c.start_date as end_date from cabinet c, cabinet c1
where c.previous_cabinet_id = c1.id;

--Most recent cabinet for each country.
create view recentcabinet6 as select country_id, max(start_date) as start_date
from cabinet group by country_id;

--All cabinet information for most recent country cabinets.
create view recentcabinetfull6 as select id, r.country_id, r.start_date,
CAST(NULL as DATE) as end_date from recentcabinet6 r, cabinet c
where r.country_id = c.country_id and r.start_date = c.start_date;

--Adds most recent cabinets to the view of cabinets with start and end dates.
create view countrycabinetfull6 as select * from countrycabinet6
UNION select * from recentcabinetfull6;

--Adds the partypm column to the countrycabinet6 view.
create view partypm6  as select c.country_id , c.id, start_date, end_date,
party_id, c1.pm as pmParty from countrycabinetfull6 c
left join cabinet_party c1 on c.id = c1.cabinet_id;

--View of all Country parties for which pmparty is true
create view partypmtrue6 as select country_id, id, start_date, party_id, pmparty
from partypm6 where pmparty=true;

-- Combines the countrycabinetfull6 view with the partypmtrue view.
create view countrycabinetfullpm6 as select * from countrycabinetfull6
natural left outer join partypmtrue6;

--View for each country name.
create view countryinfo6 as select id as country_id, name as countryName
from country;

--View with party name for each party.
create view partyinfo6 as select id as party_id, name as pmParty from party;

--Combines the countrycabinetfullpm6 with partyinfo6 view.
create view partyresult6 as select country_id, id as cabinetId, start_date
as startDate, end_date as endDate, p.pmParty from countrycabinetfullpm6 c
left outer join partyinfo6 p on c.party_id = p.party_id or c.party_id =NULL;

--Combines the previous result with countryname view to get final result.
create view result6 as select countryName, cabinetId, startDate, endDate,
pmParty from partyresult6 natural join countryinfo6;

-- the answer to the query
insert into q6 select * from result6;
