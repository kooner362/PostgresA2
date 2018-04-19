-- Alliances

SET SEARCH_PATH TO parlgov;
drop table if exists q7 cascade;

-- You must not change this table definition.

DROP TABLE IF EXISTS q7 CASCADE;
CREATE TABLE q7(
        countryId INT,
        alliedPartyId1 INT,
        alliedPartyId2 INT
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.
--All parties which have formed an alliance.
create view alliedpairs as select e1.election_id, e1.id,
e1.party_id as alliedPartyId1,  e2.party_id as alliedPartyId2,
e2.alliance_id from election_result e1, election_result e2
where e1.election_id = e2.election_id and e1.party_id < e2.party_id
and (e1.alliance_id = e2.alliance_id or e1.id = e2.alliance_id);

--View which includes the country_id for alliedpairs view.
create view alliedpairscountry as select election_id, a.id, alliedPartyId1,
alliedPartyId2, alliance_id, country_id from alliedpairs a, election e
where a.election_id = e.id;

--Number of elections which took place in a country.
create view countrytotalelection as select country_id ,
count(*) as num_elections from election group by country_id;

--Number of elections where the two parties have been allies.
create view numalliedpairelections as select country_id, alliedPartyId1,
alliedPartyId2, count(*) as num_wins from alliedpairscountry
group by alliedPartyId1, alliedPartyId2, country_id;

--Election percentage for allied parties.
create view alliedpercentage as select c.country_id, alliedPartyId1,
alliedPartyId2, CAST(n.num_wins as decimal)/c.num_elections as win_percentage
from countrytotalelection c, numalliedpairelections n
where c.country_id = n.country_id
group by c.country_id, alliedPartyId1, alliedPartyId2,
n.num_wins, c.num_elections;

--All allied pairs which have been in 30% or more elections as allies.
create view atleast30  as select country_id, alliedPartyId1, alliedPartyId2
from alliedpercentage where win_percentage >= 0.3;

-- the answer to the query
insert into q7 select * from atleast30;
