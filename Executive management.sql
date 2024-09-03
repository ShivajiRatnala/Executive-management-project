use gdb023;

-- /* Total Quantity sold by segment */

select p.segment , sum(fs.sold_quantity) Total_quantity from dim_product p
join fact_sales_monthly fs on 
p.product_code = fs.product_code group by p.segment;

-- /* Total quantity sold by Year */

select sum(sold_quantity) total_quantity ,fiscal_year from fact_sales_monthly group by fiscal_year;

-- /* Top 5 products , customers and country*/

-- -- Top 5 Customers

select dc.customer , sum(fs.sold_quantity) Total_Quantity from dim_customer dc 
join fact_sales_monthly fs on
dc.customer_code = fs.customer_code group by dc.customer order by Total_quantity desc limit 5;

-- Top 5 Countries 
select dc.market, sum(fs.sold_quantity) Total_Quantity from dim_customer dc
join fact_sales_monthly fs on
dc.customer_code = fs.customer_code group by dc.market order by Total_quantity desc limit 5;

-- -- Top 5 Products
select dp.product , sum(fs.sold_quantity) Total_Quantity from dim_product dp 
join fact_sales_monthly fs on
dp.product_code = fs.product_code group by dp.product order by Total_quantity desc limit 5;

-- -- Avg Discount price by customer
select a.customer_code,a.customer,round((avg(b.pre_invoice_discount_pct) *100),2)as average_discount_percentage
from dim_customer as a
join fact_pre_invoice_deductions as b
on a.customer_code=b.customer_code
group by 1,2
order by 3 desc
limit 5 ;



-- -- Request1
-- -- list of markets in which customer "Atliq Exclusive" operates its business in the APAC region

select * from dim_customer where region = 'APAC' and customer = 'Atliq Exclusive';

-- -- Request2 
-- --  What is the percentage of unique product increase in 2021 vs. 2020? The
-- -- final output contains these fields,
-- --  unique_products_2020
-- --  unique_products_2021
-- --  percentage_chg 

with cte1 as(
select count(distinct(product_code)) year_2020 from fact_sales_monthly where fiscal_year = 2020
),
cte2 as (
select count(distinct(product_code)) year_2021 from fact_sales_monthly where fiscal_year = 2021
)

select (((year_2021)-(year_2020))/(year_2020))*100 percentage_diff from cte1 cross join cte2;


-- Request 3
-- Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields,
-- segment
-- product_count

select segment, count(distinct product) distinct_products from dim_product group by segment;

-- Request 4
 -- Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference

select a.segment,
	   count(distinct case when b.fiscal_year=2020 then b.product_code end ) as unique_product_2020 ,
	   count(distinct case when b.fiscal_year=2021 then b.product_code end ) as unique_product_2021 ,
       
      (count(distinct case when b.fiscal_year=2021 then b.product_code end)
             -count(distinct case when b.fiscal_year=2020 then b.product_code end)) as difference
       
from dim_product as a
join fact_sales_monthly as b
on a.product_code = b.product_code
group by a.segment
order by 4 desc ;

-- Request 5
-- Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost

select * from fact_manufacturing_cost fm
join dim_product dp
on fm.product_code = dp.product_code
where fm.manufacturing_cost in 
(
select max(manufacturing_cost)
from fact_manufacturing_cost
union all
select min(manufacturing_cost)
from fact_manufacturing_cost
);

-- Request6
 -- Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

select a.customer_code,a.customer,round((avg(b.pre_invoice_discount_pct) *100),2)as average_discount_percentage
from dim_customer as a
join fact_pre_invoice_deductions as b
on a.customer_code=b.customer_code
where (b.fiscal_year=2021 and a.market='India')
group by 1,2
order by 3 desc
limit 5;

-- Request 7
-- Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount

select 
monthname(fsm.date) month_name,
(fsm.fiscal_year),
round((fsm.sold_quantity * fgp.gross_price),3) total_sales
from fact_sales_monthly fsm 
join  fact_gross_price fgp
on fsm.product_code = fgp.product_code
group by month_name;


-- task 8
/* In which quarter of 2020, got the maximum total_sold_quantity?
   The final output contains these fields  
	-- sorted by the total_sold_quantity,
    -- Quarter
	-- total_sold_quantity */

-- select quarter(date) quater,round(sum(sold_quantity),3) quantity from fact_sales_monthly
--  where fiscal_year = 2020 
--  group by quater order by 1;
 
 -- task 9
/*  Which channel helped to bring more gross sales in the fiscal year 2021
    and the percentage of contribution? 
    The final output contains these fields,
    -- channel
	-- gross_sales_mln
    -- percentage
*/
WITH cte1 AS (
    SELECT
        channel,
        ROUND(SUM(s.sold_quantity * p.gross_price) / 1000000, 2) AS gross_sales_mln
    FROM fact_sales_monthly AS s
    JOIN fact_gross_price AS p ON s.product_code = p.product_code AND s.fiscal_year = p.fiscal_year
    JOIN dim_customer AS c ON s.customer_code = c.customer_code
    WHERE s.fiscal_year = 2021
    GROUP BY channel
)

SELECT
    cte1.*,
    ROUND(gross_sales_mln * 100 / (SELECT SUM(gross_sales_mln) FROM cte1), 2) AS percentage
FROM cte1
ORDER BY percentage DESC;

-- Request 10
/* Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? 
The final output contains these fields
-- division
-- product_code
-- product
-- total_sold_quantity
-- rank_order
*/

with cte1 as(
SELECT division,dim_product.product_code, product, sum(fs.sold_quantity) total_quantity,
rank() over(partition by dim_product.division order by sum(fs.sold_quantity) ) ranked
from dim_product 
join 
fact_sales_monthly fs on dim_product.product_code = fs.product_code
group by product,dim_product.product_code,division)

select * from cte1 where ranked <=3










