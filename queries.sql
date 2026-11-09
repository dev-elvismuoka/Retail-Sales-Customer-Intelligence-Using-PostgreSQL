-- queries.sql
-- All 46 business queries[cite: 6]

-- SECTION A: SQL fundamentals
-- Q1: Retrieve all customer records.
SELECT * FROM customers;

-- Q2: Display customer names, cities, and segments.
SELECT customer_name, city, customer_segment FROM customers;

-- Q3: Find customers living in Nairobi.
SELECT * FROM customers WHERE city = 'Nairobi';

-- Q4: Find customers registered after January 1, 2025.
SELECT * FROM customers WHERE registration_date > '2025-01-01';

-- Q5: Display all unique customer cities.
SELECT DISTINCT city FROM customers;

-- Q6: Retrieve the 10 most recent orders.
SELECT * FROM orders ORDER BY order_date DESC LIMIT 10;

-- Q7: Find orders with unit prices above KSh 10,000.
SELECT * FROM orders WHERE unit_price > 10000;

-- Q8: Find customers whose names start with A.
SELECT * FROM customers WHERE customer_name LIKE 'A%';

-- Q9: Retrieve orders with quantities between 2 and 5.
SELECT * FROM orders WHERE quantity BETWEEN 2 AND 5;

-- Q10: Find orders paid through M-Pesa.
SELECT * FROM orders WHERE payment_method = 'M-Pesa';


-- SECTION B: Aggregation and grouping
-- Q11: Count all customers.
SELECT COUNT(customer_id) AS total_customers FROM customers;

-- Q12: Count all orders.
SELECT COUNT(order_id) AS total_orders FROM orders;

-- Q13: Calculate completed-order revenue.
SELECT ROUND(SUM(quantity * unit_price * (1 - discount / 100.0)), 2) AS completed_revenue 
FROM orders WHERE order_status = 'Completed';

-- Q14: Calculate the average completed-order value.
SELECT ROUND(AVG(quantity * unit_price * (1 - discount / 100.0)), 2) AS avg_completed_order_value 
FROM orders WHERE order_status = 'Completed';

-- Q15: Find the highest and lowest product prices.
SELECT MAX(unit_price) AS highest_price, MIN(unit_price) AS lowest_price FROM orders;

-- Q16: Calculate revenue by product category.
SELECT product_category, ROUND(SUM(quantity * unit_price * (1 - discount / 100.0)), 2) AS revenue 
FROM orders WHERE order_status = 'Completed' GROUP BY product_category;

-- Q17: Count customers by city.
SELECT city, COUNT(customer_id) AS customer_count FROM customers GROUP BY city;

-- Q18: Calculate quantity sold by product.
SELECT product_name, SUM(quantity) AS total_quantity 
FROM orders WHERE order_status = 'Completed' GROUP BY product_name;

-- Q19: Find categories generating more than KSh 100,000 in revenue.
SELECT product_category 
FROM orders WHERE order_status = 'Completed' 
GROUP BY product_category 
HAVING SUM(quantity * unit_price * (1 - discount / 100.0)) > 100000;

-- Q20: Calculate the percentage of cancelled orders.
SELECT ROUND(COUNT(*) FILTER (WHERE order_status = 'Cancelled') * 100.0 / COUNT(*), 2) AS cancelled_pct 
FROM orders;


-- SECTION C: Joins and customer analytics
-- Q21: Display orders with customer names and cities.
SELECT o.*, c.customer_name, c.city 
FROM orders o JOIN customers c ON o.customer_id = c.customer_id;

-- Q22: Calculate total spending by customer.
SELECT c.customer_id, c.customer_name, ROUND(SUM(o.quantity * o.unit_price * (1 - o.discount / 100.0)), 2) AS total_spent 
FROM customers c JOIN orders o ON c.customer_id = o.customer_id 
WHERE o.order_status = 'Completed' GROUP BY c.customer_id, c.customer_name;

-- Q23: Identify customers who have never ordered.
SELECT c.customer_id, c.customer_name 
FROM customers c LEFT JOIN orders o ON c.customer_id = o.customer_id 
WHERE o.order_id IS NULL;

-- Q24: Find the 10 highest-spending customers.
SELECT c.customer_id, c.customer_name, ROUND(SUM(o.quantity * o.unit_price * (1 - o.discount / 100.0)), 2) AS total_spent 
FROM customers c JOIN orders o ON c.customer_id = o.customer_id 
WHERE o.order_status = 'Completed' GROUP BY c.customer_id, c.customer_name 
ORDER BY total_spent DESC LIMIT 10;

-- Q25: Calculate revenue by customer city.
SELECT c.city, ROUND(SUM(o.quantity * o.unit_price * (1 - o.discount / 100.0)), 2) AS revenue 
FROM customers c JOIN orders o ON c.customer_id = o.customer_id 
WHERE o.order_status = 'Completed' GROUP BY c.city;

-- Q26: Identify customers with more than five orders.
SELECT c.customer_id, c.customer_name, COUNT(o.order_id) AS total_orders
FROM customers c JOIN orders o ON c.customer_id = o.customer_id 
GROUP BY c.customer_id, c.customer_name HAVING COUNT(o.order_id) > 5;

-- Q27: Calculate average customer spending by segment.
-- Defined as the average of the total amounts spent by distinct customers in each segment.
WITH customer_totals AS (
    SELECT c.customer_segment, c.customer_id, SUM(o.quantity * o.unit_price * (1 - o.discount / 100.0)) AS total_spent 
    FROM customers c JOIN orders o ON c.customer_id = o.customer_id 
    WHERE o.order_status = 'Completed' GROUP BY c.customer_segment, c.customer_id
) 
SELECT customer_segment, ROUND(AVG(total_spent), 2) AS avg_spending FROM customer_totals GROUP BY customer_segment;

-- Q28: Identify the most popular category among VIP customers.
-- Popularity defined by the total units sold in completed orders.
SELECT o.product_category, SUM(o.quantity) AS units_sold 
FROM orders o JOIN customers c ON o.customer_id = c.customer_id 
WHERE c.customer_segment = 'VIP' AND o.order_status = 'Completed' 
GROUP BY o.product_category ORDER BY units_sold DESC LIMIT 1;


-- SECTION D: Subqueries and CTEs
-- Q29: Find customers spending above the average total spending per purchasing customer.
WITH customer_totals AS (
    SELECT customer_id, SUM(quantity * unit_price * (1 - discount / 100.0)) AS total_spent 
    FROM orders WHERE order_status = 'Completed' GROUP BY customer_id
)
SELECT customer_id, ROUND(total_spent, 2) AS total_spent 
FROM customer_totals WHERE total_spent > (SELECT AVG(total_spent) FROM customer_totals);

-- Q30: Find products priced above the overall average unit price.
SELECT DISTINCT product_name, unit_price 
FROM orders WHERE unit_price > (SELECT AVG(unit_price) FROM orders);

-- Q31: Use a CTE to identify the three highest-revenue months.
WITH monthly_revenue AS (
    SELECT DATE_TRUNC('month', order_date) AS month, SUM(quantity * unit_price * (1 - discount / 100.0)) AS revenue 
    FROM orders WHERE order_status = 'Completed' GROUP BY DATE_TRUNC('month', order_date)
)
SELECT month, ROUND(revenue, 2) AS revenue FROM monthly_revenue ORDER BY revenue DESC LIMIT 3;

-- Q32: Find customers purchasing from at least three categories.
SELECT customer_id, COUNT(DISTINCT product_category) AS category_count 
FROM orders GROUP BY customer_id HAVING COUNT(DISTINCT product_category) >= 3;

-- Q33: Use a CTE to calculate category revenue, cost, profit, and profit margin.
WITH category_financials AS (
    SELECT product_category, 
           SUM(quantity * unit_price * (1 - discount / 100.0)) AS revenue, 
           SUM(quantity * cost_price) AS cost 
    FROM orders WHERE order_status = 'Completed' GROUP BY product_category
)
SELECT product_category, ROUND(revenue, 2) AS revenue, ROUND(cost, 2) AS cost, ROUND(revenue - cost, 2) AS profit, 
       ROUND((revenue - cost) / NULLIF(revenue, 0) * 100, 2) AS profit_margin_pct FROM category_financials;

-- Q34: Find customers whose latest completed order is more than 90 days before the latest order date in the dataset.
WITH last_orders AS (
    SELECT customer_id, MAX(order_date) AS last_order_date 
    FROM orders WHERE order_status = 'Completed' GROUP BY customer_id
)
SELECT customer_id, last_order_date 
FROM last_orders WHERE (SELECT MAX(order_date) FROM orders) - last_order_date > 90;


-- SECTION E: Window functions
-- Q35: Rank customers by spending using RANK().
WITH cust_spend AS (
    SELECT customer_id, SUM(quantity * unit_price * (1 - discount / 100.0)) AS total_spent 
    FROM orders WHERE order_status = 'Completed' GROUP BY customer_id
)
SELECT customer_id, ROUND(total_spent, 2) AS total_spent, RANK() OVER(ORDER BY total_spent DESC) AS spending_rank 
FROM cust_spend;

-- Q36: Number each customer's orders by recency using ROW_NUMBER().
SELECT order_id, customer_id, order_date, 
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS recency_num 
FROM orders;

-- Q37: Rank products within categories using DENSE_RANK().
SELECT product_category, product_name, unit_price, 
       DENSE_RANK() OVER (PARTITION BY product_category ORDER BY unit_price DESC) AS price_rank 
FROM (SELECT DISTINCT product_category, product_name, unit_price FROM orders) t;

-- Q38: Calculate cumulative monthly revenue.
WITH monthly_rev AS (
    SELECT DATE_TRUNC('month', order_date) AS month, SUM(quantity * unit_price * (1 - discount / 100.0)) AS revenue 
    FROM orders WHERE order_status = 'Completed' GROUP BY DATE_TRUNC('month', order_date)
)
SELECT month, ROUND(revenue, 2) AS monthly_revenue, ROUND(SUM(revenue) OVER(ORDER BY month), 2) AS cumulative_revenue 
FROM monthly_rev;

-- Q39: Compare monthly revenue using LAG().
WITH monthly_rev AS (
    SELECT DATE_TRUNC('month', order_date) AS month, SUM(quantity * unit_price * (1 - discount / 100.0)) AS revenue 
    FROM orders WHERE order_status = 'Completed' GROUP BY DATE_TRUNC('month', order_date)
)
SELECT month, ROUND(revenue, 2) AS revenue, ROUND(LAG(revenue) OVER(ORDER BY month), 2) AS prev_month_revenue 
FROM monthly_rev;

-- Q40: Calculate month-over-month revenue growth (%).
WITH monthly_rev AS (
    SELECT DATE_TRUNC('month', order_date) AS month, SUM(quantity * unit_price * (1 - discount / 100.0)) AS revenue 
    FROM orders WHERE order_status = 'Completed' GROUP BY DATE_TRUNC('month', order_date)
)
SELECT month, ROUND(revenue, 2) AS revenue, ROUND((revenue - LAG(revenue) OVER(ORDER BY month)) / NULLIF(LAG(revenue) OVER(ORDER BY month), 0) * 100, 2) AS mom_growth_pct 
FROM monthly_rev;

-- Q41: Divide customers into four spending groups using NTILE(4).
WITH cust_spend AS (
    SELECT customer_id, SUM(quantity * unit_price * (1 - discount / 100.0)) AS total_spent 
    FROM orders WHERE order_status = 'Completed' GROUP BY customer_id
)
SELECT customer_id, ROUND(total_spent, 2) AS total_spent, NTILE(4) OVER(ORDER BY total_spent DESC) AS spending_group 
FROM cust_spend;

-- Q42: Calculate each category's share of total revenue using window functions.
WITH cat_rev AS (
    SELECT product_category, SUM(quantity * unit_price * (1 - discount / 100.0)) AS revenue 
    FROM orders WHERE order_status = 'Completed' GROUP BY product_category
)
SELECT product_category, ROUND(revenue, 2) AS revenue, ROUND(revenue / NULLIF(SUM(revenue) OVER(), 0) * 100, 2) AS pct_of_total 
FROM cat_rev;


-- SECTION F: Advanced business intelligence
-- Q43: Create a monthly_sales_summary view (month, orders, revenue, cost, profit), then select from it.
CREATE OR REPLACE VIEW monthly_sales_summary AS 
SELECT DATE_TRUNC('month', order_date) AS month, 
       COUNT(order_id) AS total_orders, 
       ROUND(SUM(quantity * unit_price * (1 - discount / 100.0)), 2) AS revenue, 
       ROUND(SUM(quantity * cost_price), 2) AS cost, 
       ROUND(SUM(quantity * unit_price * (1 - discount / 100.0)) - SUM(quantity * cost_price), 2) AS profit 
FROM orders WHERE order_status = 'Completed' GROUP BY DATE_TRUNC('month', order_date);

SELECT * FROM monthly_sales_summary;

-- Q44: Create a PL/pgSQL function that returns completed-order revenue for a supplied customer ID.
CREATE OR REPLACE FUNCTION get_customer_revenue(p_customer_id INTEGER) RETURNS NUMERIC LANGUAGE plpgsql AS $$ DECLARE v_revenue NUMERIC; BEGIN SELECT COALESCE(SUM(quantity * unit_price * (1 - discount / 100.0)), 0) INTO v_revenue FROM orders WHERE customer_id = p_customer_id AND order_status = 'Completed'; RETURN v_revenue; END; $$;

SELECT get_customer_revenue(141); -- Existing customer
SELECT get_customer_revenue(9999); -- Non-existent customer returns 0

-- Q45: Segment customers into High, Medium and Low Value, and explain thresholds.
-- Thresholds: High Value (>= 150k KSh), Medium Value (50k-150k KSh), Low Value (< 50k KSh).
-- These values match the pricing distributions where TVs/Laptops easily push a user above 150k[cite: 1].
WITH cust_spend AS (
    SELECT customer_id, SUM(quantity * unit_price * (1 - discount / 100.0)) AS total_spent 
    FROM orders WHERE order_status = 'Completed' GROUP BY customer_id
)
SELECT customer_id, ROUND(total_spent, 2) AS total_spent, 
       CASE 
           WHEN total_spent >= 150000 THEN 'High Value' 
           WHEN total_spent >= 50000 THEN 'Medium Value' 
           ELSE 'Low Value' 
       END AS value_segment 
FROM cust_spend;


-- Note: Generated independently using existing CTEs to pull insights for the report.
-- Q46: Produce a management report: top five customers, top five products, the most profitable category, and the lowest-revenue month.

(
    SELECT 
        'Top 5 Customers' AS report_section, 
        c.customer_name::text AS item_name, 
        ROUND(SUM(o.quantity * o.unit_price * (1 - o.discount / 100.0)), 2) AS metric_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, c.customer_name
    ORDER BY metric_value DESC
    LIMIT 5
)
UNION ALL
(
    SELECT 
        'Top 5 Products' AS report_section, 
        product_name::text AS item_name, 
        ROUND(SUM(quantity * unit_price * (1 - discount / 100.0)), 2) AS metric_value
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY product_name
    ORDER BY metric_value DESC
    LIMIT 5
)
UNION ALL
(
    SELECT 
        'Most Profitable Category' AS report_section, 
        product_category::text AS item_name, 
        ROUND(SUM(quantity * unit_price * (1 - discount / 100.0)) - SUM(quantity * cost_price), 2) AS metric_value
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY product_category
    ORDER BY metric_value DESC
    LIMIT 1
)
UNION ALL
(
    SELECT 
        'Lowest-Revenue Month' AS report_section, 
        TO_CHAR(DATE_TRUNC('month', order_date), 'YYYY-MM') AS item_name, 
        ROUND(SUM(quantity * unit_price * (1 - discount / 100.0)), 2) AS metric_value
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY DATE_TRUNC('month', order_date)
    ORDER BY metric_value ASC
    LIMIT 1
);



