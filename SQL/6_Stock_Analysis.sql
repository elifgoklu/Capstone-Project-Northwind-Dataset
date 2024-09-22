--STOCK ANALYSIS
--Objective: Stock Status Control

--Generate a list of products with insufficient stock and determine how many units need to be ordered to reach the required stock levels.
--Identify how many orders are currently placed for products with insufficient stock.
--Identify products that have low stock and require urgent action.

--Step 1:
--List of Products with Insufficient Stock and Required Minimum Order Quantities:
SELECT
    product_id,
    product_name,
    unit_in_stock AS stock_quantity,
    unit_on_order AS order_quantity,
    reorder_level,
    reorder_level - unit_in_stock AS stock_deficit
FROM products
WHERE unit_in_stock < reorder_level AND discontinued = 0
ORDER BY stock_deficit DESC;

--Step 2:
--Deficit Stock Products That Require Urgent Re_Orders:
SELECT
    product_id,
    product_name,
    unit_in_stock AS stock_quantity,
    unit_on_order AS order_quantity,
    reorder_level,
    discontinued
FROM products
WHERE (unit_in_stock + unit_on_order) < reorder_level AND discontinued = 0;

--Step 3:
--Products No Longer Sold and Potential Financial Losses:
SELECT
   product_id,
   product_name,
   unit_in_stock,
   unit_on_order,
   reorder_level,
   unit_price,
   ROUND((unit_in_stock+unit_on_order)*unit_price::decimal,2) as loss,
   discontinued
FROM products
where discontinued=1
