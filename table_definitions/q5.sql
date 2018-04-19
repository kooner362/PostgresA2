-- Committed

SET SEARCH_PATH TO parlgov;
drop table if exists q5 cascade;

-- You must not change this table definition.

CREATE TABLE q5(
        countryName VARCHAR(50),
        partyName VARCHAR(100),
        partyFamily VARCHAR(50),
        stateMarket REAL
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS cabinetparties CASCADE;

-- Define views for your intermediate steps here.

--Combination of cabinet and cabinet_party table
create view cabinetparties as select c.id as cabinet_id,
c.country_id, c.start_date, p.party_id
from cabinet c, cabinet_party p where c.id = p.cabinet_id;

--Number of cabinets in each country.
create view numcountrycabinets as select distinct country_id,
count(country_id) as num_cabinets from cabinet
where (date_part('year', CURRENT_DATE)-1) >= date_part('year', start_date)
and  date_part('year', start_date) >= (date_part('year', CURRENT_DATE)-21)
group by country_id;

--Number of cabinets which each party has been a part of.
create view numcabinetsforeachparty as select country_id, party_id,
count(party_id) as num_cabinets from cabinetparties
group by party_id, country_id;

--Parties which have been in all cabinets which were formed.
create view inallcabinets as select * from numcountrycabinets
natural join numcabinetsforeachparty;

--Added counrty information from country table
create view countryinfo5 as select c.name as countryName, country_id,
party_id as id from country c, inallcabinets i where c.id = i.country_id;

--Added party information from the party table.
create view partyinfo5 as select * from countryinfo5 natural join party;

--Added party family information from the party family table
create view partyfamilyinfo5 as select * from partyinfo5 p
left join party_family p1 on p.id = p1.party_id;

--Final result for q5
create view marketinfo5 as select countryName, p.name as partyName,
p.family as partyFamily, p1.state_market as stateMarket
from partyfamilyinfo5 p left join party_position p1 on p.id = p1.party_id;
-- the answer to the query
insert into q5 select * from marketinfo5;
