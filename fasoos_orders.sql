drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table  driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2021 21:30:45','25km','25mins',null),
(8,2,'01-10-2021 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2021 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;


-- 1. How many rolls were ordered?
select count(*) rolls_ordered from customer_orders

-- 2. How many unique customer orders were made? 
select count(distinct(customer_id)) from customer_orders

-- 3. how many successful orders were delivered by the each  driver?

select driver_id ,count(driver_id) total_orders from driver_order
where duration is not null
group by driver_id


-- 4. How many each types of rolls were delivered?

select t2.roll_id,count(t2.roll_id) roll_delivered from (
select *,
case when cancellation in ('Cancellation','Customer Cancellation') then 'c' else 'nc' end as cancellation_updated
from driver_order) t1
inner join customer_orders as t2
on t1.order_id = t2.order_id
where t1.cancellation_updated <> 'c'
group by t2.roll_id


-- 5. How many veg and non veg rolls ordered by each customer?

select t1.customer_id,t2.roll_name,count(t1.roll_id) as rolls_ordered from customer_orders t1
inner join rolls t2
on t1.roll_id = t2.roll_id
group by t1.customer_id,t2.roll_name


--6. what was maximum number of rolls delivered in single order?

select * from (
select * ,rank() over(order by rolls_delivered desc) rank_ from (
select  t1.order_id,count(t2.roll_id) rolls_delivered from (
select *,
case when cancellation in ('Cancellation','Customer Cancellation') then 'c' else 'nc' end as cancellation_updated
from driver_order) t1
inner join customer_orders as t2
on t1.order_id = t2.order_id
where t1.cancellation_updated ='nc'
group by t1.order_id
) t11
) t22 
where rank_=1

--7. For each customer, how many delivered roll had atleast one change, and how many had no change?

with temp_customers_order (order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) as
(
	select order_id,customer_id,roll_id,
	case when not_include_items is null or not_include_items = ' ' then '0' else not_include_items end as new_not_include_items,
	case when extra_items_included is null or extra_items_included = ' ' or extra_items_included = 'NaN' then '0' else extra_items_included end as new_extra_items_included,
	order_date
	from customer_orders
),
temp_driver_order (order_id,driver_id,pickup_time,distance,duration,new_cancellation) as 
(
	select order_id,driver_id,pickup_time,distance,duration,
	case when cancellation in ('Cancellation','Customer Cancellation') then 0 else 1 end as new_cancellation
	from driver_order
)
select customer_id,changes_made,count(order_id) order_count from (
select *,
case when not_include_items='0' and extra_items_included='0' then 'no change' else 'change' end as changes_made
from temp_customers_order
where order_id in (select order_id from temp_driver_order where new_cancellation=1)) a
group by customer_id,changes_made




-- 8. How many rolls had delivered that has both exclusions and extras?
with temp_customers_order (order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) as
(
	select order_id,customer_id,roll_id,
	case when not_include_items is null or not_include_items = ' ' then '0' else not_include_items end as new_not_include_items,
	case when extra_items_included is null or extra_items_included = ' ' or extra_items_included = 'NaN' then '0' else extra_items_included end as new_extra_items_included,
	order_date
	from customer_orders
),
temp_driver_order (order_id,driver_id,pickup_time,distance,duration,new_cancellation) as 
(
	select order_id,driver_id,pickup_time,distance,duration,
	case when cancellation in ('Cancellation','Customer Cancellation') then 0 else 1 end as new_cancellation
	from driver_order
)
select changes_made,count(roll_id) from(
select *,
case when not_include_items!='0' and extra_items_included!='0' then 'excl_or_extr' else 'either_excl_or_extr' end as changes_made
from temp_customers_order
where order_id in (select order_id from temp_driver_order where new_cancellation=1)) a
group by changes_made


-- 9. What was total number of rolls ordered for each hours of the day?
select hour_bucket,count(roll_id) from (
select *,concat(cast(DATEPART(hour,order_date)as varchar),'-',cast(DATEPART(hour,order_date)+1 as varchar)) as hour_bucket from customer_orders
) a
group by hour_bucket


-- 10. What is the number of orders for each day of the week?

select dow,count(distinct(order_id)) from (
select *,DATENAME(dw,order_date) as dow from customer_orders
) a 
group by dow


-- 11. what was the avereage time in minutes it took for each driver to arrive at the fasqoo hq to pick the order?
select driver_id,avg(driver_arrival_min) from (

select order_id,driver_id,driver_arrival_min,ROW_NUMBER() over(partition by order_id order by driver_arrival_min) row_num from 
(
select t1.order_id,t2.driver_id,DATEDIFF(minute,t1.order_date,t2.pickup_time) driver_arrival_min from customer_orders as t1
inner join driver_order t2
on t1.order_id = t2.order_id
where t2.duration is not null
) a
) b
where row_num=1
group by driver_id


--12. Is there any relationship between the number of rolls and how long it takes a order to prepare?
select order_id,count(roll_id) cnt,sum(order_prepared_min)/count(roll_id) from 
(
select t1.order_id,t1.roll_id,DATEDIFF(minute,t1.order_date,t2.pickup_time) order_prepared_min from customer_orders as t1
inner join driver_order t2
on t1.order_id = t2.order_id
where t2.duration is not null
) a
group by order_id

--13. What is the average distance travelled for each of the customers
select customer_id,avg(distance) avg_dist from 
(
select * from 
(
select *,ROW_NUMBER() over(partition by order_id order by distance) as row_num from 
(
select t1.order_id,t1.customer_id,t1.roll_id,t1.not_include_items,t1.extra_items_included,t1.order_date,
t2.driver_id,t2.pickup_time,
cast(REPLACE(t2.distance,'km','') as float) distance,
t2.cancellation from customer_orders t1
inner join driver_order t2
on t1.order_id = t2.order_id
where t2.distance is not null
) a
)b
where row_num = 1
)c
 group by customer_id




--14. what is the difference between the longest and shortest delivery time for all the order
select max(updated_duration)-min(updated_duration) from 
(
select *,
case when duration like '%min%' then cast(left(duration,charindex('m',duration)-1) as int) else duration end as updated_duration
from driver_order
where duration is not null
) a




-- 15. What is the average speed of each driver for each delivery and do you notice any trend for these values?
select order_id,driver_id,(distance/updated_duration) as speed from
(
select order_id,driver_id,
cast(REPLACE(distance,'km','') as float) distance,
case when duration like '%min%' then cast(left(duration,charindex('m',duration)-1) as int) else duration end as updated_duration
from driver_order
where distance is not null
) a

-- 16. What is successful percentage of delivery of each driver

select driver_id, (success_pct*1.0/total_order) as successful_pct from 
(
select driver_id,count(order_id) as total_order,
sum(cancel_pct) as  success_pct from 
(
select *,
case when lower(cancellation) like '%cancel%' then 0 else 1 end cancel_pct
from driver_order
) a
group by driver_id
)b
