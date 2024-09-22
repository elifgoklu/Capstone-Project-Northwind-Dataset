-- EMPLOYEE ANALYSIS

--Objective: Sales Representative Performance Analysis

--Purpose:

--Gather data on the total number of orders sold by sales representatives, the total value of products they sold, the customer segments they targeted, and the categories in which they made sales. This information aims to identify potential improvements to enhance sales performance.

--Step 1:
--Calculation of Overall Performance Metrics for Sales Representatives:
WITH employee_general AS (
    SELECT
        COUNT(e.employee_id) OVER() AS total_employee,
        e.employee_id,
        e.title,
        CONCAT(e.first_name, ' ', e.last_name) AS full_name,
        ROUND(SUM((od.unit_price * od.quantity) * (1 - od.discount))::decimal, 2) AS total_sales,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT o.customer_id) AS total_customers,
        COUNT(DISTINCT od.product_id) AS total_product_types
    FROM employees e
    LEFT JOIN orders o ON e.employee_id = o.employee_id
    LEFT JOIN order_details od ON od.order_id = o.order_id
    GROUP BY e.employee_id, e.title, e.first_name, e.last_name
)
SELECT 
    *,
    EXTRACT(DAY FROM age(last_order_date, first_order_date)) AS date_difference
FROM employee_general
WHERE title = 'Sales Representative';


--Step 2:
--Sales Representatives' Countributions by Category:
SELECT
    c.category_id,
    c.category_name,
    e.employee_id,
    e.title,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    ROUND(SUM((od.unit_price * od.quantity) * (1 - od.discount))::decimal, 2) AS total_sales,
    ROUND(AVG(od.discount)::decimal, 2) AS average_discount_per_order,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    COUNT(DISTINCT od.product_id) AS total_product_types
FROM employees e
LEFT JOIN orders o ON e.employee_id = o.employee_id
LEFT JOIN order_details od ON od.order_id = o.order_id
LEFT JOIN products p ON p.product_id = od.product_id
LEFT JOIN categories c ON c.category_id = p.category_id
WHERE title = 'Sales Representative'
GROUP BY 1, 2, 3, 4, 5;


--Step 3:
--Performance of Each Sales Representative by Customer Segment:
SELECT
	e.employee_id,
	concat(e.first_name,' ',e.last_name) as full_name,
	income_segment,
	round(sum((od.unit_price*od.quantity)*(1-od.discount))::decimal,2) as net_sales,
	count(distinct o.customer_id) as muster_sayısı
FROM employees e
LEFT JOIN orders o
on o.employee_id=e.employee_id
LEFT JOIN order_details od
on o.order_id=od.order_id
where e.title='Sales Representative'
group by 1,2,3






