-- Winners

SET SEARCH_PATH TO parlgov;
drop table if exists q2 cascade;

-- You must not change this table definition.

create table q2(
countryName VARCHaR(100),
partyName VARCHaR(100),
partyFamily VARCHaR(100),
wonElections INT,
mostRecentlyWonElectionId INT,
mostRecentlyWonElectionYear INT
);


-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS maxInElection CASCADE;

-- Define views for your intermediate steps here.
--Get the max votes for each election.
create view maxInElection as select election_id, max(votes) as votes
from election_result group by election_id;

--Find winners by natural joining with the max votes
create view winners as select election_id, party_id, votes from
election_result natural join maxInElection;

--Get the country_id column for each row in winners
create view winners1 as select e.country_id, e.e_date, w.election_id as id,
 w.party_id, w.votes from winners w, election e
 where w.election_id = e.id;

--View which has number of elections which were won in a country.
create view partiesWon as select country_id, count(*) as num_elections_won
from winners1 group by country_id;

--View which shoes the number of times a party has won in a Country.
create view partyWins as select country_id, party_id, count(party_id)
as num_wins from winners1 group by party_id, country_id;

--View which shows how many parties are in each Country.
create view numParties as select country_id, count(country_id) as num_parties
from party group by country_id;

--Average wins for each Country.
create view averageWins as select p.country_id, cast(sum(w.num_elections_won)
as decimal)/p.num_parties as average from numParties p, partiesWon w
where p.country_id = w.country_id group by p.country_id, p.num_parties;

--All parties which have more than 3 times avg wins
create view morethan3 as select * from partyWins p where num_wins >
3 * (select average from averageWins a where p.country_id = a.country_id);

--All parties which have morethan3 combined with country to get country info.
create view countryinfo as select * from morethan3 m , country c
where m.country_id=c.id;

--Gets all party info and adds it to the view with the countryinfo.
create view partyinfo as select * from countryinfo c
natural left join party_family p;

--Finds not the most recent elections
create view notrecentlywon as select distinct
w1.id, w1.country_id, w1.party_id, w1.e_date
from winners1 w1, winners1 w2 where w1.country_id=w2.country_id
and w1.party_id = w2.party_id and w1.e_date < w2.e_date and w1.id <> w2.id;

--Most recently won elections
create view recentlywon as (select id, country_id, party_id, e_date
from winners1) EXCEPT (select id, country_id, party_id, e_date
  from notrecentlywon);

--A view with almost all required information.
create view allinfo as select p.name as countryName, p.party_id,
p.family as partyFamily, p.num_wins as wonElections,  r.e_date,
r.id as mostRecentlyWonElectionId from recentlywon r, partyinfo p
where r.party_id = p.party_id;

--A view with all required information for the question
create view allinfo1 as select countryName, p.name as partyName, partyFamily,
wonElections, mostRecentlyWonElectionId,
extract(year from e_date) as mostRecentlyWonElectionYear
from allinfo a, party p where a.party_id = p.id;

-- the answer to the query
insert into q2 select * from allinfo1;
