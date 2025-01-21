
--Task 1 : Top 10 highest revenue generating products

select product_id , ROUND(cast(sum(sale_price_per_quantity * quantity) as numeric), 0) as revenue
from df_orders
group by product_id
order by revenue desc
limit 10

-- Task 2: Top 5 highest selling products in each region

with cte as (

  Select region , product_id , ROUND(cast(sum(sale_price_per_quantity * quantity) as numeric), 0) as sale
  from df_orders
  group by region , product_id
  order by region ,sale desc 
  
)

select * from (
select * , 
row_number() over(partition by region order by sale desc) as row_num
from cte)
where row_num <=5

-- Task 3: find month over month growth comparison for 2022 and 2023 eg. jan 2022 vs jan 2023
-- Method 1

WITH CTE1 AS (

SELECT  to_char(order_date , 'MM') AS month_ , ROUND(CAST(SUM(sale_price_per_quantity * quantity) AS DECIMAL) , 0) AS revenue_22
from df_orders
where  to_char(order_date , 'YYYY') = '2022'
group by  to_char(order_date , 'MM')

) , CTE2 AS (

SELECT  to_char(order_date , 'MM') AS month_ , ROUND(CAST(SUM(sale_price_per_quantity * quantity) AS DECIMAL) , 0) AS revenue_23
from df_orders
where  to_char(order_date , 'YYYY') = '2023'
group by  to_char(order_date , 'MM')

) 

SELECT CTE1.month_ , revenue_22 , revenue_23 
from CTE1
NATURAL JOIN 
CTE2

-- Method 2

with cte1 as (

Select  to_char(order_date , 'YYYY') AS year_ , to_char(order_date , 'MM') AS month_ , 
ROUND(CAST(SUM(sale_price_per_quantity * quantity) AS DECIMAL) , 0) as revenue
from df_orders
group by  year_ , month_
order by year_ , month_

)
SELECT month_  , 
SUM(CASE when year_ = '2022' then revenue else null end) as revenue_22 , 
SUM(CASE when year_ = '2023' then revenue else null end) as revenue_23
FROM cte1
group by month_
order by  month_ 

-- Task 4: For each category which month had highest sales

-- With merger of months such as jan 2022 + jan 2023

With cte_ as (

SELECT category ,to_char(order_date , 'MM') as month_ , ROUND(CAST(max(sale_price_per_quantity * quantity) AS DECIMAL),
0) AS sales
FROM df_orders
GROUP BY category , month_
order by category , month_

), cte2 as (

SELECT category  , month_, sales,
ROW_NUMBER() over(partition by category order by sales desc) as max_sales
FROM cte_

)

SELECT category , month_ , sales
from cte2
where max_sales = 1

-- 2nd way - Year over year profitable months for each categories like pivot table

WITH Cte_1 as (

SELECT category , to_char(order_date , 'YYYY') AS year_,
to_char(order_date , 'MM') AS months_ , ROUND(CAST(SUM(sale_price_per_quantity * quantity) AS DECIMAL) , 0) as revenue
FROM df_orders 
GROUP BY category , year_ , months_

), cte_2 AS (

   SELECT category , year_  , months_ 
   , row_number() over(PARTITION BY category , year_ ORDER BY revenue DESC) AS row_no
   FROM Cte_1
   
)

SELECT category , SUM(CASE WHEN year_ = '2022' then CAST(months_ AS INT) ELSE 0  end) as year_22 , SUM(CASE WHEN year_ = '2023' THEN CAST(months_ AS INT)
ELSE 0 end) as year_23
FROM cte_2
WHERE row_no = 1
GROUP BY category 

-- Task 5: Which sub - category had highest growth by profit in 2023 compare to 2022

with cte as (
select sub_category, to_char(order_date , 'YYYY') as order_year,
sum(sale_price_per_quantity) as sales
from df_orders
group by sub_category,to_char(order_date , 'YYYY')

)
, cte2 as (
select sub_category
, sum(case when order_year= '2022' then CAST(sales AS INT) else 0 end) as sales_2022
, sum(case when order_year= '2023' then CAST(sales AS INT) else 0 end) as sales_2023
from cte 
group by sub_category
)
select  *
,(sales_2023-sales_2022)
from  cte2
order by (sales_2023-sales_2022) desc
limit 1