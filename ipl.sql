
USE Iplproject
--IPL, 2024
--22 March - 26 May
/*
select * from dim_match_summary
transformation  on dim_match_summary
deriving columns from matchdate
*/

with q1 as 
(
select *,
PARSENAME(REPLACE((matchDate), ',', '.'), 1)as match_year,
PARSENAME(REPLACE((matchDate), ',', '.'), 2) as match_month_name_and_date
from dim_match_summary
),
q2 as 
(
select *,
PARSENAME(REPLACE((match_month_name_and_date), ' ', '.'), 2) as match_month_name,
PARSENAME(REPLACE((match_month_name_and_date), ' ', '.'), 1) as match_date
from q1
)

select * into dim_match_summary_transformed from q2

/*
basic findouts
select distinct(match_month_name) from q2
Apr
Mar
May
Oct
Sep
*/
/*
select distinct(match_year) from q2
 2021
 2022
 2023 

 this means we have 3 years data from 2021 to 2023
*/



--select * from dim_players

--select * from fact_bating_summary

-- select * from fact_bowling_summary

-- Primary Insights 

/*
1. Top 10 batsmen based on past 3 years total runs scored.
*/

select top 10 batsmanName,sum(runs) as total_runs
from fact_bating_summary 
group by batsmanName 
order by total_runs desc

-- my followup analysis on question 1 
-- top 5 batsman 2021
select top 5 batsmanName,
sum(runs) as total_runs,
2021 as year
into top_5_batsman_2021
from 
(
select ms.match_year,bs.*
from dim_match_summary_transformed ms
inner join fact_bating_summary bs 
on ms.match_id = bs.match_id 
) a
where match_year =2021
group by batsmanName
order by total_runs desc

-- top 5 batsman 2022
select top 5 batsmanName,
sum(runs) as total_runs,
2022 as year
into top_5_batsman_2022
from 
(
select ms.match_year,bs.*
from dim_match_summary_transformed ms
inner join fact_bating_summary bs 
on ms.match_id = bs.match_id 
) a
where match_year =2022
group by batsmanName
order by total_runs desc

-- top 5 batsman 2023
select top 5  batsmanName,
sum(runs) as total_runs,
2023 as year
into top_5_batsman_2023
from 
(
select ms.match_year,bs.*
from dim_match_summary_transformed ms
inner join fact_bating_summary bs 
on ms.match_id = bs.match_id 
) a
where match_year =2023
group by batsmanName
order by total_runs desc


--select * from top_5_batsman_2021
--select * from top_5_batsman_2022 
--select * from top_5_batsman_2023 


/*
2. Top 10 batsmen based on past 3 years batting average. (min 60 balls faced in
each season)
*/

-- source :- https://captaincalculator.com/sports/cricket/batting-average-calculator/
-- Batting Average = Runs Scored ÷ Times Out 

with q1 as 
(
select ms.match_year,bs.*
from dim_match_summary_transformed ms
inner join fact_bating_summary bs 
on ms.match_id = bs.match_id
),
q2 as
(
select batsmanName,
match_year,
round(cast(sum(runs) as float)/cast((sum(case when out_not_out='out' then 1 else 0 end)* 1.0) as float) 
,2)
as batting_average,
sum(balls) as sum_of_balls
from q1 
group by batsmanName,match_year 
having SUM(balls) >= 60
),
q3 as 
(
select batsmanName,
match_year,
batting_average
from q2
where batsmanName in (
select batsmanName 
from q2
group by batsmanName
having count(distinct match_year) = 3)
)
select top 10 batsmanName,round(avg(batting_average),2) as overall_batting_average
from q3 
group by batsmanName 
order by overall_batting_average desc


/*
3. Top 10 batsmen based on past 3 years strike rate (min 60 balls faced in each
season)

--source https://www.geeksforgeeks.org/how-to-calculate-strike-rate-of-a-batsman/
Strike Rate = (Runs Scored / Balls faced) * 100 
*/


with q1 as 
(
select ms.match_year,bs.*
from dim_match_summary_transformed ms
inner join fact_bating_summary bs 
on ms.match_id = bs.match_id
),
q2 as
(
select batsmanName,
match_year,
ROUND(( cast(SUM(runs) * 100.0 as float ) / SUM(balls) * 1.0), 2)  as sr,
sum(balls) as sum_of_balls
from q1 
group by batsmanName,match_year
having SUM(balls) >= 60
),
q3 as 
(
select batsmanName,
match_year,
sr
from q2
where batsmanName in (
select batsmanName 
from q2
group by batsmanName
having count(distinct match_year) = 3)
)
select top 10 batsmanName,
round(avg(sr),2) as avg_sr
from q3 
group by batsmanName 
order by avg_sr desc

/*
4. Top 10 bowlers based on past 3 years total wickets taken
*/

select top 10 bowlerName ,sum(wickets) as total_wickets_taken
from fact_bowling_summary 
group by bowlerName
order by total_wickets_taken desc

/*
5. Top 10 bowlers based on past 3 years bowling average. (min 60 balls bowled in
each season)
*/ 

-- source :- https://madaboutsports.in/blog/glossary/bowling-average-cricket/#:~:text=The%20formula%20to%20calculate%20bowling%20average%20is%20as,his%2Fher%20bowling%20average%20would%20be%3A%20300%2F15%20%3D%2020 
-- Bowling Average = (Total Runs Conceded)/(Total Wickets Taken) 


with q1 as 
(
select ms.match_year,bs.*
from dim_match_summary_transformed ms
inner join fact_bowling_summary bs 
on ms.match_id = bs.match_id
),
q2 as 
(
select bowlerName,match_year,
round((sum(runs)/ (sum(wickets)*1.0)),2) as bowling_average
from q1
group by bowlerName,match_year
having sum(overs) * 6 >= 60
),
q3 as 
(
select * 
from q2
where bowlerName in (
select bowlerName 
from q2
group by bowlerName
having count(distinct match_year) = 3)
)
select top 10 bowlerName,
round(avg(bowling_average),2) as overall_avg
from q3 
group by bowlerName
order by overall_avg 


/*
6. Top 10 bowlers based on past 3 years economy rate. (min 60 balls bowled in
each season)
--source - https://sports.icalculator.com/cricket-economy-rate-calculator.html 
Economy Rate = Total Runs Conceded / Total Overs Bowled
*/ 

with q1 as 
(
select ms.match_year,bs.*
from dim_match_summary_transformed ms
inner join fact_bowling_summary bs 
on ms.match_id = bs.match_id
),
q2 as 
(
select bowlerName,match_year,
round((sum(runs)/sum(overs)*1.0),2) as economy_rate
from q1
group by bowlerName,match_year
having sum(overs) * 6 >= 60
),
q3 as 
(
select *
from q2
where bowlerName in (
select bowlerName 
from q2
group by bowlerName
having count(distinct match_year) = 3)
)
select top 10 bowlerName,
round(avg(economy_rate),2) as avg_economy_rate
from q3 
group by bowlerName
order by avg_economy_rate asc


/*
7. Top 5 batsmen based on past 3 years boundary % (fours and sixes).
-- source https://madaboutsports.in/blog/glossary/boundaries-and-singles-percentages/ 
Boundary Percentage = (Total Runs Scored through Boundaries / Total Runs Scored) x 100 
*/ 

with q1 as 
(
select ms.match_year,bs.*
from dim_match_summary_transformed ms
inner join fact_bating_summary bs 
on ms.match_id = bs.match_id
),
q2 as
(
select q1.*,dim_players.playing_role 
from q1 
inner join dim_players 
on q1.batsmanName = dim_players.name 
where playing_role not in ('Bowler','Bowling Allrounder')
),
q3 as 
(
select *
from q2
where batsmanName in (
select batsmanName
from q2
group by batsmanName
having count(distinct match_year) = 3)
),
q4 as 
(
select batsmanName,
sum(_4s)*4 + sum(_6s)*6 as total_runs_scored_through_boundaries,
nullif(sum(runs),0) as total_runs_scored
from q3
group by batsmanName
),
q5 as 
(
select batsmanName,
round(
(cast(total_runs_scored_through_boundaries as float)/cast(total_runs_scored as float))*100.0
,2) as boundary_percentage
from q4 
) 
select top 5*
from q5 
order by boundary_percentage desc


/*
8. Top 5 bowlers based on past 3 years dot ball %. 
source :- https://madaboutsports.in/blog/glossary/dot-ball-in-cricket/ 
Dot ball percentage = (Number of dot balls bowled/Number of total deliveries bowled)x100
*/ 

with q1 as 
(
select ms.match_year,bs.*
from dim_match_summary_transformed ms
inner join fact_bowling_summary bs 
on ms.match_id = bs.match_id
),
q2 as 
(
select *
from q1
where bowlerName in (
select bowlerName 
from q1
group by bowlerName
having count(distinct match_year) = 3)
),
q3 as 
(
select bowlerName,
sum(_0s) as total_dot_balls,
round(sum(overs *6),0) as total_balls
from q2 
group by bowlerName 
)
select top 5 bowlerName,
round((total_dot_balls/total_balls) * 100 ,2)
as dot_ball_percentage
from q3
order by dot_ball_percentage desc


/*
9. Top 4 teams based on past 3 years winning %.
source :- https://www.quora.com/How-is-a-winning-percentage-calculated
Winning Percentage = (Wins / Total Games Played) * 100
*/ 
--select * from dim_match_summary_transformed

with all_teams as 
(
select team1 as team, case when team1=winner then 1 else 0 end as win_flag from dim_match_summary_transformed
union all
select team2 as team, case when team2=winner then 1 else 0 end as win_flag from dim_match_summary_transformed
),
q2 as 
(
select team,
count(1) as total_matches_played , 
sum(win_flag) as matches_won
from all_teams
group by team
)
select top 4 team,
round((cast( matches_won as float)/cast (total_matches_played as float))*100 ,2)
as winning_percentage
from q2
order by winning_percentage desc


/*
10.Top 2 teams with the highest number of wins achieved by chasing targets over
the past 3 years.
*/
--select * from dim_match_summary_transformed 

with q1 as 
(
select *,
case 
when margin LIKE '%runs' THEN 'defending'
when margin LIKE '%wickets' THEN 'chasing'
else 'unknown'
end as winning_type
from dim_match_summary_transformed
),
q2 as 
(
select * 
from q1 
where winning_type='chasing'
),
q3 as
(
select team1 as team, case when team1=winner then 1 else 0 end as win_flag from q2
union all
select team2 as team, case when team2=winner then 1 else 0 end as win_flag from q2
)
select top 2 team, 
sum(win_flag) as matches_won
from q3
group by team




