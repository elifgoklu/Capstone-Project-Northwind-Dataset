--SHIPPING ANALYSIS
--Objective:

--To provide analysis for the Logistics Department, including metrics such as average delivery times, average fees paid to different shipping companies, and the average time taken by shipping companies to deliver a single product based on total orders.
--To segment delivery statuses for better analysis of delivery conditions.

--Step 1:
--Calculation of Shipping Companies' Delivery Times and Costs Paid for Orders:
WITH Shipping_Analysis AS
(
    SELECT
        ship_via,
        company_name,
        order_id,
        order_date,
        required_date,
        shipped_date,
        shipped_date-order_date as shipping_time,
        freight
    FROM orders o
    LEFT JOIN shippers s ON o.ship_via = s.shipper_id
)
Select
	company_name,
	round(avg(shipping_time)::decimal,2) as company_avgdays,
	count(distinct order_id) as total_order,
	sum(freight) as company_shipping_cost,
	(Select sum(freight) from Shipping_Analysis) as total_shipping_cost,
	(Select round(avg(shipping_time)::decimal,2) from Shipping_Analysis) as avg_days
from Shipping_Analysis
group by 1

--Step 2:
--Segmentation of Order Delay Times for Two Shipping Companies:
WITH Shipping_Analysis AS
(
    SELECT
        company_name,
        order_id,
        order_date,
        required_date,
        shipped_date,
        ship_country,
        required_date-shipped_date  AS delay_time,
        freight,
        SUM(freight) OVER() AS total_shipping_cost
    FROM orders o
    LEFT JOIN shippers s ON o.ship_via = s.shipper_id
),
shipping_cost_time AS
(
    SELECT 
        company_name,
        delay_time,
        order_id,
        CASE
            WHEN delay_time >= 3 THEN 'On Time'
            WHEN delay_time > 0 AND delay_time < 3 THEN 'Risky'
            WHEN delay_time >= -3 AND delay_time <= 0 THEN 'Late'
            WHEN delay_time >= -10 AND delay_time < -3 THEN 'Mid-Late'
            WHEN delay_time < -10 THEN 'High-Late'
			ELSE 'Unknown'
        END AS Delay_Segment,
        ROUND(SUM(freight) OVER()::decimal, 2) AS total_shipping_cost
    FROM Shipping_Analysis
)
SELECT 
    s.company_name,
    s.Delay_Segment,
    COUNT(DISTINCT s.order_id) AS order_count,
    ROUND(SUM(sa.freight)::decimal, 2) AS total_freight
FROM shipping_cost_time s
LEFT JOIN Shipping_Analysis sa ON s.company_name = sa.company_name
GROUP BY 1, 2

--Step 3:
--Calculation of Average Dispatch Times and Shipping Costs by Country:
WITH Shipping_Analysis AS
(
    SELECT
        ship_country,
        order_id,
        order_date,
        required_date,
        shipped_date,
        shipped_date-order_date AS shipping_time,
        freight
    FROM orders
)
SELECT 
    ship_country,
    COUNT(DISTINCT order_id) AS total_order,
    ROUND(AVG(shipping_time)::decimal,2) AS avg_shipping_time,
    ROUND(SUM(freight)::decimal,2) AS total_shipping_cost
FROM Shipping_Analysis
GROUP BY ship_country; 

--Step 4:
--Count of Delayed, Risky, or Unknown Status Orders by Shipping Company:
WITH Shipping_Analysis AS
(
    SELECT
        s.company_name,
        o.order_id,
        o.required_date - o.shipped_date AS delay_time
    FROM orders o
    LEFT JOIN shippers s ON o.ship_via = s.shipper_id
)
SELECT 
    company_name,
    COUNT(DISTINCT order_id) AS total_order_count,
    COUNT(DISTINCT CASE WHEN delay_time < 3 OR delay_time IS NULL THEN order_id END) AS unreliable_orders
FROM Shipping_Analysis
GROUP BY company_name;






