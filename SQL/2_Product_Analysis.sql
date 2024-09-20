--Objective: PRODUCT ANALYSIS

--Purpose:

--Develop marketing strategies based on product price trends.
--Identify cross-selling opportunities through product market analysis and enhance sales strategies.
--Review pricing policies by examining unit price change rates of products.

-- Step 1: 
-- Number of Products in the Catalog and Count of Discontinued Products:
SELECT 
    COUNT(product_id) AS total_product_count,
    SUM(CASE WHEN Discontinued = 1 THEN 1 ELSE 0 END) AS discontinued_products
FROM Products;

--Step 2:
--Product List - Sales Price Change:

SELECT
	p.product_id AS product_id,
    p.product_name,
	min(od.unit_price) as previous_unitprice,
	max(p.unit_price) as current_unitprice,
	round(100*(max(p.unit_price) - min(od.unit_price)) /max(p.unit_price)) as percantege_increase
FROM order_details AS od
LEFT JOIN products AS p 
ON od.product_id = p.product_id
group by 1,2
order by 5 desc

-- Step 3:
-- Basket Analysis - Which Products and Categories Are Most Frequently Purchased Together?
--Basket analysis measures how often a pair of products is repeated across different orders. 
--This helps identify whether customers tend to purchase specific pairs of products together (e.g., diapers and beer), providing insights into customer behavior.
--Step 3.1 Products most frequently purchased together:
SELECT 
    p1.product_name AS firstproduct, 
    t.first_productcount,
    p2.product_name AS secondproduct,
    t.second_productcount,
    t.frequency
FROM
(
    SELECT 
        od.product_id AS first_productid,
        SUM(od.quantity) AS first_productcount,
        ods.product_id AS second_product_id,
        SUM(ods.quantity) AS second_productcount,
        COUNT(*) AS frequency
    FROM order_details AS od
    JOIN order_details AS ods
        ON od.order_id = ods.order_id 
        AND od.product_id < ods.product_id
    GROUP BY first_productid, second_product_id
    ORDER BY frequency DESC
) AS t
JOIN products AS p1 
    ON p1.product_id = t.first_productid
JOIN products AS p2 
    ON p2.product_id = t.second_product_id
ORDER BY t.frequency DESC;
--Upon examining the results, it was found that maple syrup and biscuits were seen together in 8 different orders. This result is unsatisfactory due to both the low consumption rates of these products and the insufficient number of occurrences. I believe this analysis is not functional for this data. Therefore, I have decided to conduct this valuable analysis on product category pairs for campaigns as well

-- Step 3.2 Categories frequently purchased together:
SELECT DISTINCT
    c1.category_name AS first_category,
    c1.category_id AS first_id,
    c2.category_name AS second_category,
    c2.category_id AS second_id,
    COUNT(DISTINCT t.order_id) AS order_count
FROM
(
    SELECT
        od1.order_id,
        p1.category_id AS first_categoryid,
        p2.category_id AS second_categoryid
    FROM 
        order_details AS od1
    JOIN 
        products AS p1 ON p1.product_id = od1.product_id
    JOIN 
        order_details AS od2 ON od1.order_id = od2.order_id 
    JOIN 
        products AS p2 ON p2.product_id = od2.product_id
    WHERE
        p1.category_id < p2.category_id
    GROUP BY 
        od1.order_id,
        p1.category_id,
        p2.category_id
) AS t
JOIN 
    categories AS c1 ON c1.category_id = t.first_categoryid
JOIN 
    categories AS c2 ON c2.category_id = t.second_categoryid
GROUP BY 
    c1.category_name, 
    c1.category_id, 
    c2.category_name, 
    c2.category_id
ORDER BY 
    order_count DESC;

--Step 4:
--Category-Based Monthly Sales:
Select
    c.category_name,
    TO_CHAR(DATE_TRUNC('month', order_date)::date, 'yyyy-mm') AS monthyear,
    ROUND(SUM(od.unit_price * od.quantity*(1-discount))::decimal, 2) as sales_netrevenue,
FROM 
    categories AS c
LEFT JOIN 
    products AS p ON c.category_id = p.category_id
LEFT JOIN 
    order_details AS od ON p.product_id = od.product_id
LEFT JOIN 
	orders AS o on od.order_id=o.order_id
GROUP BY 
    c.category_name,2

--Step 5:
--Top 3 Highest-Grossing Products by Category:
WITH category_product AS (
    SELECT
        c.category_name AS category,
        p.product_name AS product,
        ROUND(SUM(od.unit_price * od.quantity * (1 - discount))::decimal, 2) AS sales_net_revenue
    FROM 
        categories AS c
    LEFT JOIN 
        products AS p ON c.category_id = p.category_id
    LEFT JOIN 
        order_details AS od ON p.product_id = od.product_id
    LEFT JOIN 
        orders AS o ON od.order_id = o.order_id
    GROUP BY 
        c.category_name, p.product_name
    ORDER BY 
        sales_net_revenue DESC
),

category_topproducts AS (
    SELECT 
        category,
        product,
        sales_net_revenue,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales_net_revenue DESC) AS row_number
    FROM 
        category_product
)

SELECT 
    category,
    product,
    sales_net_revenue
FROM 
    category_topproducts 
WHERE 
    row_number BETWEEN 1 AND 3;



