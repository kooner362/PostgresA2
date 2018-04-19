-- Participate

SET SEARCH_PATH TO parlgov;
drop table if exists q3 cascade;

-- You must not change this table definition.

create table q3(
        countryName varchar(50),
        year int,
        participationRatio real
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS participantratio CASCADE;

-- Define views for your intermediate steps here.
--participationratio for countries with multiple elections in the same year.
create view participationratio as select id, country_id, e_date,
cast(votes_cast as decimal)/electorate as participation_ratio
from election group by country_id, electorate, votes_cast, id, e_date;

--check whether there is at least more than one
--election in the same year reports country ...
create view morethanone as select e1.id, e1.country_id,
extract(year from e1.e_date) as year
from participationratio e1, participationratio e2
where extract(year from e1.e_date) = extract(year from e2.e_date)
and e1.id < e2.id and e1.country_id = e2.country_id;

--avg participationratio for countries with multiple elections in the same year.
create view multipleyear as select extract(year from e_date) as year,
country_id, cast(sum(participation_ratio) as decimal)/count(country_id)
as participation_ratio from participationratio
group by country_id, extract(year from e_date);

--combine countries with multiple elections with new ratio
create view multipleyear1 as select m2.country_id, m2.year,
m2.participation_ratio from morethanone m1, multipleyear m2
where m1.year = m2.year and m1.country_id = m2.country_id;

--all countries with one election per year.
create view onelectionperyear as select country_id, extract(year from e_date)
as year from participationratio
EXCEPT select country_id, year from multipleyear1;

--participation_ratio of all countries without multiple elections in a year
create view participationrationomultiple as select p.country_id,
extract(year from e_date) as year, participation_ratio
from participationratio p, onelectionperyear o
where p.country_id=o.country_id and extract(year from e_date) = o.year;

--New view with combined participantratio.
create view participationratiowithmultiple as select *
from participationrationomultiple UNION select * from multipleyear1;

--All participationratios for each country for the past 15 years.
create view last15years as select * from participationratiowithmultiple
where year <= extract(year from CURRENT_DATE)-1
and year >= extract(year from CURRENT_DATE)-16;

--All results which aren't monotonic
create view notmonotonic  as select distinct l1.country_id
from last15years l1 , last15years l2 where l1.country_id = l2.country_id
and l1.year > l2.year and l1.participation_ratio < l2.participation_ratio;

--All monotonic countries for the past 15 years
create view monotonic as select * from last15years l
where not exists
(select * from notmonotonic n where l.country_id = n.country_id);

--Result for q3
create view result3 as select c.name as countryName, year, participation_ratio
from monotonic r, country c where r.country_id = c.id;
-- the answer to the query
insert into q3 select * from result3;
