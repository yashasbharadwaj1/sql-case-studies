select * from credit_card_transactions;

/*
1- write a query to print top 5 cities with highest spends and their 
percentage contribution of total credit card spends 
*/

with queryone as 
(
select sum(amount) as total_amount_spent_overall from credit_card_transactions
),
querytwo as 
(
select city,sum(amount) as total_amount_spent_grouped_by_city
from credit_card_transactions 
group by city 
),
querythree as 
(
select city,total_amount_spent_grouped_by_city,
rank() over(order by total_amount_spent_grouped_by_city desc ) as rnk
from querytwo
),
queryfour as
(
select * from querythree
where rnk <=5
), 
queryfive as 
(
select * 
from queryfour a
inner join queryone b 
on 1=1
),
querysix as
(
select *,
round(((total_amount_spent_grouped_by_city/total_amount_spent_overall)*100),2)
as percentage_contribution_of_each_city
from 
queryfive
)
select * from querysix


/*
2- write a query to print highest spend month and amount spent in that month for each card type
*/

with queryone as 
(
select card_type,
date_part('year',transaction_date) as year,
date_part('month',transaction_date) as month,
sum(amount) as total_amount_spent_in_that_month
from credit_card_transactions
group by card_type,month,year 
),
querytwo as
(
select *,
rank() over(partition by card_type order by total_amount_spent_in_that_month desc) rnk
from queryone 
)
select * from querytwo 
where rnk=1


/*
3- write a query to print the transaction details(all columns from the table) 
for each card type when
it reaches a cumulative of 1000000 total spends
Note :-(We should have 4 rows in the o/p one for each card type)
*/ 

with queryone as
(
select *,
sum(amount) over(partition by card_type) as total_amount_partitioned_over_card_type
from credit_card_transactions
),
querytwo as 
(
select *,
rank() over(partition by card_type order by total_amount_partitioned_over_card_type,transaction_id desc) rnk
from 
queryone
where total_amount_partitioned_over_card_type >= 1000000
)
select * from querytwo 
where rnk=1 


/* 
4- write a query to find city which had lowest percentage spend for gold card type
*/

with query1 as 
(
select city,
card_type,sum(amount) as amount,
sum(case when card_type='Gold' then amount end) as gold_amount
from credit_card_transactions
group by city,card_type
)
select 
city,sum(gold_amount)*1.0/sum(amount) as gold_ratio
from query1
group by city
having count(gold_amount) > 0 and sum(gold_amount)>0
order by gold_ratio
limit 1


/*
5- write a query to print 3 columns:  city, highest_expense_type , 
lowest_expense_type (example format : Delhi , bills, Fuel)
*/

with q1 as 
(
select city,exp_type, sum(amount) as total_amount from credit_card_transactions
group by city,exp_type
),
q2 as 
(
select *
,rank() over(partition by city order by total_amount desc) rn_desc
,rank() over(partition by city order by total_amount asc) rn_asc
from q1
)
select
city , 
max(case when rn_asc=1 then exp_type end) as lowest_exp_type,
min(case when rn_desc=1 then exp_type end) as highest_exp_type
from q2
group by city;


/*
6- write a query to find percentage contribution of spends by females for each expense type
*/

select exp_type,
sum(case when gender='F' then amount else 0 end)*1.0/sum(amount) as percentage_female_contribution
from credit_card_transactions
group by exp_type
order by percentage_female_contribution desc;


-- Basic findouts
select distinct(card_type) from credit_card_transactions;
/*
"Signature"
"Silver"
"Platinum"
"Gold"
*/

--
select distinct(exp_type) from credit_card_transactions;
/*
"Travel"
"Bills"
"Grocery"
"Entertainment"
"Food"
"Fuel"
*/ 

--
select distinct(gender) from credit_card_transactions;
/*
"M"
"F"
*/
