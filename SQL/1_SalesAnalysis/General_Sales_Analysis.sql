-- ANALYSIS 1: GENERAL SALES ANALYSIS
---Objective: Sales Performance Analysis
----Purpose:
----Track key performance indicators (KPIs) such as total sales revenue, discounted total sales revenue, total orders, and average discount.
----Evaluate sales performance over time to facilitate quick decision-making.

--Step 1
--Calculating Total Sales Revenue, Discounted Total Sales Revenue, Total Orders, Average Discount (excluding zeros), and Discount per Product:
SELECT 
    ROUND(SUM(unit_price * quantity)::decimal, 2) AS total_revenue,
	ROUND(SUM(unit_price * quantity*(1-discount))::decimal, 2) as sales_netrevenue,
    COUNT(DISTINCT order_id) AS total_order,
    AVG(CASE WHEN discount > 0 THEN discount ELSE NULL END) AS avg_discount
FROM order_details;

--Step 2 
--Distribution of Total Sales Revenue, Discounted Total Sales Revenue, Total Orders, and Average Discount by Category:
SELECT 
    c.category_name,
    round(sum(od.unit_price * od.quantity)::decimal, 2) AS total_revenue,
    ROUND(AVG(CASE WHEN discount > 0 THEN discount ELSE NULL END)::decimal,2)  AS avg_discount,
    count(distinct od.order_id) AS total_order
FROM 
    categories AS c
LEFT JOIN 
    products AS p ON c.category_id = p.category_id
LEFT JOIN 
    order_details AS od ON p.product_id = od.product_id
GROUP BY 
    c.category_name;

--- Step 3
--- Distribution of Sales Revenue, Net Income, and Order Count by Month and Year, and Comparison with Previous Months:
with linechart_revenue as
(
SELECT 
	to_char(date_trunc('month',order_date)::date,'yyyy-mm') as monthyear,
	round(sum(od.unit_price*od.quantity)::decimal,2) as total_revenue,
	ROUND(SUM(unit_price * quantity*(1-discount))::decimal, 2) as salesnet_revenue,
    COUNT(DISTINCT o.order_id) AS total_order
from orders as o
LEFT JOIN order_details as od
on o.order_id=od.order_id
group by 1
order by monthyear
)
select 
	monthyear,
	total_revenue,
	lag(total_revenue) over (order by monthyear) as premonth_sales,
	salesnet_revenue,
	lag(salesnet_revenue) over (order by monthyear) as premonth_net,
	total_order,
	lag(total_order) over (order by monthyear) as premonth_order
from linechart_revenue
