-- Left-right

SET SEARCH_PATH TO parlgov;
drop table if exists q4 cascade;

-- You must not change this table definition.


CREATE TABLE q4(
        countryName VARCHAR(50),
        r0_2 INT,
        r2_4 INT,
        r4_6 INT,
        r6_8 INT,
        r8_10 INT
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.
--Combination of party and party_position table
create view countryparty4 as select * from party_position p1, party p2
where p1.party_id = p2.id;

--View for all countrys in this range
create view r0_2 as select country_id, count(*) as r0_2 from countryparty4
where left_right < 2 group by country_id;

--View for all countrys in this range
create view r2_4 as select country_id, count(*) as r2_4 from countryparty4
where left_right >=2 and left_right < 4 group by country_id;

--View for all countrys in this range
create view r4_6 as select country_id, count(*) as r4_6 from countryparty4
where left_right >=4 and left_right < 6 group by country_id;

--View for all countrys in this range
create view r6_8 as select country_id, count(*) as r6_8 from countryparty4
where left_right >=6 and left_right < 8 group by country_id;

--View for all countrys in this range
create view r8_10 as select country_id, count(*) as r8_10 from countryparty4
where left_right >=8 group by country_id;

--View with the first range and the countryname for country table.
create view nameresult4 as select name as countryName, country_id, r0_2
from r0_2 r right join country c on r.country_id = c.id;

--Joining the next range with the previous view.
create view result14 as select countryName, r0.country_id, r0_2, r2_4
from nameresult4 r0 left join r2_4 r1
on r0.country_id = r1.country_id or r0.country_id =NULL;

--Joining the next range with the previous view.
create view result24 as select countryName, r0.country_id, r0_2, r2_4, r4_6
from result14 r0 left join r4_6 r1
on r0.country_id = r1.country_id or r0.country_id =NULL;

--Joining the next range with the previous view.
create view result34 as select countryName, r0.country_id,
r0_2, r2_4, r4_6, r6_8 from result24 r0 left join r6_8 r1
on r0.country_id = r1.country_id or r0.country_id =NULL;

--Final result q4
create view result4 as select countryName, r0_2, r2_4, r4_6, r6_8, r8_10
from result34 r0 left join r8_10 r1
on r0.country_id = r1.country_id or r0.country_id =NULL;

-- the answer to the query
INSERT INTO q4 select * from result4;
