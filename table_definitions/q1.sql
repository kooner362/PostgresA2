-- VoteRange

SET SEARCH_PATH TO parlgov;
drop table if exists q1 cascade;

-- You must not change this table definition.

create table q1(
year INT,
countryName VARCHAR(50),
voteRange VARCHAR(20),
partyName VARCHAR(100)
);


-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS last10years CASCADE;

-- Define views for your intermediate steps here.
--All elections which happened in the past 10 years.
create view last10years as select * from election where
extract('year' from e_date) <= extract('year' from CURRENT_DATE)-1
and extract('year' from e_date) >= extract('year' from CURRENT_DATE)-21;

--All parties which were in the elections from the past 10 years.
create view last10yearsparty as select e.election_id, l.country_id,
e.party_id, l.e_date, e.votes, l.votes_valid
from last10years l, election_result e where l.id=e.election_id;

--Percentage of votes over valid votes for every party in the previous view.
create view partypercentage as select election_id, country_id, party_id,
e_date, cast(votes as decimal)/votes_valid as percentage
from last10yearsparty
group by election_id, country_id, party_id, e_date, votes, votes_valid;

--Find all countries which had one or more elections in the same year.
create view morethanone as select l1.country_id,
extract('year' from l1.e_date) as year from last10years l1, last10years l2
where extract('year' from l1.e_date) = extract('year' from l2.e_date)
and l1.country_id = l2.country_id and l1.id < l2.id;

--All percentage stats for parties which only had one election each year.
create view percentageonelection as select * from partypercentage p
where not exists (select * from morethanone m where p.country_id=m.country_id
  and extract('year' from p.e_date) = m.year);

--All percentage stats for parties which had more than one election for
--some year.
create view percentagemorethanone as select * from partypercentage p
where exists (select * from morethanone m where p.country_id=m.country_id
  and extract('year' from p.e_date) = m.year);

-- Average of parties which had more than one election in a year.
create view morethanoneavg as select country_id, party_id,
extract('year' from e_date) as year, sum(percentage)/count(party_id)
as percentage from percentagemorethanone group by country_id,
extract('year' from e_date), party_id;

--New view with all parties with new percentage info.
create view partypercentage1 as (select country_id, party_id, percentage,
extract('year' from e_date) as year from percentageonelection)
UNION (select country_id, party_id, percentage, year from morethanoneavg);

--Find all parties in this range
create view range1 as select year, country_id, cast('(0-5]' as
VARCHAR(20)) as voteRange, party_id from partypercentage1
 where percentage > 0 and percentage <= 0.05;

--Find all parties in this range
create view range2 as select year, country_id, cast('(5-10]' as
VARCHAR(20)) as voteRange, party_id from partypercentage1
where percentage > 0.05 and percentage <= 0.10;

--Find all parties in this range
create view range3 as select year, country_id, cast('(10-20]' as
VARCHAR(20)) as voteRange,party_id from partypercentage1
where percentage > 0.10 and percentage <= 0.20;

--Find all parties in this range
create view range4 as select year, country_id, cast('(20-30]' as
 VARCHAR(20)) as voteRange,party_id from partypercentage1
 where percentage > 0.20 and percentage <= 0.30;

--Find all parties in this range
create view range5 as select year, country_id, cast('(30-40]' as
VARCHAR(20)) as voteRange,party_id from partypercentage1
where percentage > 0.30 and percentage <= 0.40;

--Find all parties in this range
create view range6 as select year, country_id, cast('(40-100]' as
VARCHAR(20)) as voteRange,party_id from partypercentage1
where percentage > 0.40;

--Combine all different ranges into one view
create view result as select * from range1 UNION
select * from range2 UNION
select * from range3 UNION
select * from range4 UNION
select * from range5 UNION select * from range6;

--Add countryName from country table
create view result11 as select year, name as countryName, voteRange, party_id
from result r, country c where r.country_id = c.id;

--Add name_short from party table to result
create view result21 as select year, countryName, voteRange, name_short
as partyName from result11 r, party p where r.party_id = p.id;

-- the answer to the query
insert into q1 select * from result21;
