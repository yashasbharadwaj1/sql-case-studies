
USE Iplproject

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
sum(balls) as sum_of_balls,
round(cast(sum(runs) as float)/cast((sum(case when out_not_out='out' then 1 else 0 end)* 1.0) as float) 
,2)
as batting_average
from q1 
group by batsmanName,match_year 
having sum(balls) >= 60
)
select top 10 batsmanName,round(avg(batting_average),2) as overall_batting_average
from q2 
group by batsmanName 
order by overall_batting_average desc

/*
My followup  
2.a Top 10 batsmen of every year based on batting average. (min 60 balls faced in
each season)
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
sum(balls) as sum_of_balls,
round(cast(sum(runs) as float)/cast((sum(case when out_not_out='out' then 1 else 0 end)* 1.0) as float) 
,2)
as batting_average
from q1 
group by batsmanName,match_year 
having sum(balls) >= 60
)


/*
select top 10 batsmanName,batting_average 
into top_10_batsmen_based_on_batting_average_in_2021   
from q2 
where match_year = 2021
order by batting_average desc,match_year
---
select top 10 batsmanName,batting_average 
into top_10_batsmen_based_on_batting_average_in_2022   
from q2 
where match_year = 2022
order by batting_average desc,match_year
---
select top 10 batsmanName,batting_average 
into top_10_batsmen_based_on_batting_average_in_2023   
from q2 
where match_year = 2023
order by batting_average desc,match_year
*/


select * from top_10_batsmen_based_on_batting_average_in_2021
select * from top_10_batsmen_based_on_batting_average_in_2022
select * from top_10_batsmen_based_on_batting_average_in_2023

/*
3. Top 10 batsmen based on past 3 years strike rate (min 60 balls faced in each
season)
*/


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


