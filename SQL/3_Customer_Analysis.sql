--Objective: Customer Revenue and Behavior Analysis

--Purpose:

--Customer count and monthly distribution: Assist the marketing team in understanding the impact of campaigns and efforts on attracting and retaining customers.
--Which countries have the most profitable customers: Geographically target marketing campaigns and maximize customer potential in specific regions.
--Simple segmentation based on customer spend: Better understand target audiences and provide tailored marketing messages and offers.

--Step 1:
--Customer ID, Total Customer Count, and Average Revenue per Customer:
WITH customer_revenue AS (
    SELECT 
        c.customer_id,
        (SELECT count(DISTINCT customer_id) FROM customers) AS total_customer,
        ROUND(SUM((od.unit_price * od.quantity) * (1 - od.discount))::decimal, 2) AS net_amount
    FROM customers AS c
    LEFT JOIN orders AS o ON c.customer_id = o.customer_id
    LEFT JOIN order_details AS od ON o.order_id = od.order_id
    GROUP BY c.customer_id
)
SELECT 
    customer_id,
    total_customer,
    net_amount,
    ROUND(AVG(net_amount) OVER ()::decimal,2) AS avgamount_percustomer
FROM customer_revenue;

--Step 2:
--Change in Customer Count by Month and Year:
select  
	to_char(date_trunc('Month',order_date)::date,'YYYY-MM'),
	COUNT(distinct customer_id)
from orders
group by 1

--Step 3:
--Top 5 Most Profitable Customers and Their Countries:
SELECT
    c.country,
    ROUND(SUM((od.unit_price * od.quantity) * (1 - od.discount))::decimal, 2) AS net_amount
FROM orders AS o
LEFT JOIN customers AS c ON c.customer_id = o.customer_id
LEFT JOIN order_details AS od ON o.order_id = od.order_id
GROUP BY c.country
ORDER BY net_amount DESC
LIMIT 5;

--Step 4:
--Top 5 Highest-Grossing Customer Countries:
SELECT
    o.customer_id,
    c.country,
    ROUND(SUM((od.unit_price * od.quantity) * (1 - od.discount))::decimal, 2) AS net_amount
FROM orders AS o
LEFT JOIN customers AS c ON c.customer_id = o.customer_id
LEFT JOIN order_details AS od ON o.order_id = od.order_id
GROUP BY o.customer_id, c.country
ORDER BY net_amount DESC
LIMIT 5;

--Step 5:
--Customer Segmentation Based on Revenue:
WITH cust_netsales AS (
    SELECT
        customer_id,
        ROUND(SUM((od.unit_price * od.quantity) * (1 - od.discount))::decimal, 2) AS net_sales
    FROM orders AS o
    LEFT JOIN order_details AS od ON o.order_id = od.order_id
    GROUP BY customer_id
    ORDER BY net_sales DESC
)
SELECT
    customer_id,
    net_sales,
    CASE
        WHEN net_sales >= 45000 THEN 'Diamond'
        WHEN net_sales >= 20000 AND net_sales < 45000 THEN 'Gold'
        WHEN net_sales >= 10000 AND net_sales < 20000 THEN 'Silver'
        WHEN net_sales >= 5000 AND net_sales < 10000 THEN 'Bronze'
        ELSE 'General'
    END AS cust_segment
FROM cust_netsales;

--Step 6:
--Customer Segmentation Based on Frequency and Recency Values:
-- RFM ANALYSIS
-- reference date: 1998-05-06
-- RFM ANALYSIS
-- 1998-05-06

-- Recency
WITH Recency AS (
    SELECT
        customer_id,
        ('1998-05-06' - MAX(order_date)) AS recency
    FROM orders
    GROUP BY customer_id
),

-- Frequency
Frequency AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT order_id) AS frequency
    FROM orders
    GROUP BY customer_id
),

-- Monetary
Monetary AS (
    SELECT
        customer_id,
        ROUND(SUM((od.unit_price * od.quantity) * (1 - od.discount))::decimal, 2) AS monetary
    FROM orders AS o
    LEFT JOIN order_details AS od ON o.order_id = od.order_id
    GROUP BY customer_id
    ORDER BY monetary DESC
),

-- Scores Calculation
scores AS (
    SELECT
        r.customer_id,
        r.recency,
        CASE 
            WHEN r.recency > 200 THEN 1
            ELSE CASE NTILE(4) OVER (ORDER BY r.recency DESC)
                WHEN 1 THEN 2
                WHEN 2 THEN 3
                WHEN 3 THEN 4 
                WHEN 4 THEN 5
            END
        END AS recency_score,
        f.frequency,
        NTILE(5) OVER (ORDER BY f.frequency) AS frequency_score,
        m.monetary,
        CASE 
            WHEN m.monetary >= 100000 THEN 5
            ELSE NTILE(4) OVER (ORDER BY m.monetary)
        END AS monetary_score
    FROM Recency AS r
    LEFT JOIN Frequency AS f ON r.customer_id = f.customer_id
    LEFT JOIN Monetary AS m ON r.customer_id = m.customer_id
),

-- Merge Frequency and Monetary Scores
merge_mont_fre AS (
    SELECT 
        customer_id,
        recency_score,
        frequency_score + monetary_score AS mix_score
    FROM scores
),

-- Final Scores
final_scores AS (
    SELECT 
        customer_id,
        recency_score,
        NTILE(5) OVER (ORDER BY mix_score) AS mixscore
    FROM merge_mont_fre
)

-- Final Segmentation
SELECT 
    customer_id,
    recency_score,
    mixscore,
    CASE 
        WHEN recency_score::varchar SIMILAR TO '[1-2]%' AND mixscore::varchar SIMILAR TO '[1-2]%' THEN 'Hibernating'
        WHEN recency_score::varchar SIMILAR TO '[1-2]%' AND mixscore::varchar SIMILAR TO '[3-4]%' THEN 'At Risk'
        WHEN recency_score::varchar SIMILAR TO '[1-2]%' AND mixscore::varchar SIMILAR TO '[5]%' THEN 'Cant Loose'
        WHEN recency_score::varchar SIMILAR TO '[3]%' AND mixscore::varchar SIMILAR TO '[1-2]%' THEN 'About to_Sleep'
        WHEN recency_score::varchar SIMILAR TO '[3]%' AND mixscore::varchar SIMILAR TO '[3]%' THEN 'Need Attention'
        WHEN recency_score::varchar SIMILAR TO '[4]%' AND mixscore::varchar SIMILAR TO '[1]%' THEN 'Promising'
        WHEN recency_score::varchar SIMILAR TO '[5]%' AND mixscore::varchar SIMILAR TO '[1]%' THEN 'New Customers'
        WHEN recency_score::varchar SIMILAR TO '[4-5]%' AND mixscore::varchar SIMILAR TO '[2-3]%' THEN 'Potential Loyaltist'
        WHEN recency_score::varchar SIMILAR TO '[3-4]%' AND mixscore::varchar SIMILAR TO '[4-5]%' THEN 'Loyal Customers'
        WHEN recency_score::varchar SIMILAR TO '[5]%' AND mixscore::varchar SIMILAR TO '[4-5]%' THEN 'Champions'
    END AS customer_segmentation
FROM final_scores 
ORDER BY recency_score DESC;

