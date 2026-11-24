
/*
============================================================
PROJECT: E-COMMERCE BUSINESS INTELLIGENCE & SALES ANALYTICS
FILE: 06_advanced_sql_analysis.sql
DATABASE: ecommerce_analytics
TOOL: PostgreSQL 18

PURPOSE:
Advanced SQL analysis using CTEs, window functions,
ranking, customer behaviour and sales analytics.

BUSINESS RULE:
Only Delivered orders are considered completed sales.
============================================================
*/


-- ==========================================================
-- 1. CTE: PRODUCTS GENERATING MORE THAN ₹10,000 REVENUE
-- ==========================================================

WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity) AS units_sold,
        SUM(oi.line_total) AS revenue
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    JOIN analytics.products p
        ON oi.product_id = p.product_id
    WHERE LOWER(TRIM(o.order_status)) = 'delivered'
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
)
SELECT
    product_name,
    category,
    units_sold,
    ROUND(revenue, 2) AS total_revenue
FROM product_sales
WHERE revenue > 10000
ORDER BY revenue DESC;


-- ==========================================================
-- 2. MULTIPLE CTEs: CATEGORY-WISE PROFIT ANALYSIS
-- ==========================================================

WITH category_revenue AS (
    SELECT
        p.category,
        SUM(oi.line_total) AS revenue
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    JOIN analytics.products p
        ON oi.product_id = p.product_id
    WHERE LOWER(TRIM(o.order_status)) = 'delivered'
    GROUP BY p.category
),
category_cost AS (
    SELECT
        p.category,
        SUM(oi.quantity * p.cost_price) AS total_cost
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    JOIN analytics.products p
        ON oi.product_id = p.product_id
    WHERE LOWER(TRIM(o.order_status)) = 'delivered'
    GROUP BY p.category
)
SELECT
    r.category,
    ROUND(r.revenue, 2) AS total_revenue,
    ROUND(c.total_cost, 2) AS total_cost,
    ROUND(r.revenue - c.total_cost, 2) AS estimated_profit
FROM category_revenue r
JOIN category_cost c
    ON r.category = c.category
ORDER BY estimated_profit DESC;


-- ==========================================================
-- 3. WINDOW FUNCTION: CUMULATIVE MONTHLY REVENUE
-- ==========================================================

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS sales_month,
        SUM(oi.line_total) AS monthly_revenue
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    WHERE LOWER(TRIM(o.order_status)) = 'delivered'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
    TO_CHAR(sales_month, 'YYYY-MM') AS sales_month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(
        SUM(monthly_revenue) OVER (
            ORDER BY sales_month
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ), 2
    ) AS cumulative_revenue
FROM monthly_sales
ORDER BY sales_month;


-- ==========================================================
-- 4. WINDOW FUNCTION: MONTH-OVER-MONTH REVENUE GROWTH
-- ==========================================================

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS sales_month,
        SUM(oi.line_total) AS monthly_revenue
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    WHERE LOWER(TRIM(o.order_status)) = 'delivered'
    GROUP BY DATE_TRUNC('month', o.order_date)
),
sales_comparison AS (
    SELECT
        sales_month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            ORDER BY sales_month
        ) AS previous_month_revenue
    FROM monthly_sales
)
SELECT
    TO_CHAR(sales_month, 'YYYY-MM') AS sales_month,
    ROUND(monthly_revenue, 2) AS current_revenue,
    ROUND(previous_month_revenue, 2) AS previous_revenue,
    ROUND(
        monthly_revenue - previous_month_revenue, 2
    ) AS revenue_difference,
    ROUND(
        100.0 * (monthly_revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0), 2
    ) AS growth_percentage
FROM sales_comparison
ORDER BY sales_month;


-- ==========================================================
-- 5. DENSE_RANK: PRODUCT RANKING WITHIN EACH CATEGORY
-- ==========================================================

WITH product_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.line_total) AS revenue
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    JOIN analytics.products p
        ON oi.product_id = p.product_id
    WHERE LOWER(TRIM(o.order_status)) = 'delivered'
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
)
SELECT
    product_name,
    category,
    ROUND(revenue, 2) AS total_revenue,
    DENSE_RANK() OVER (
        PARTITION BY category
        ORDER BY revenue DESC
    ) AS product_rank
FROM product_revenue
ORDER BY category, product_rank;


-- ==========================================================
-- 6. CUSTOMER PURCHASE FREQUENCY ANALYSIS
-- ==========================================================

SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.line_total), 2) AS total_revenue,
    CASE
        WHEN COUNT(DISTINCT o.order_id) >= 3
            THEN 'High Frequency'
        WHEN COUNT(DISTINCT o.order_id) = 2
            THEN 'Repeat Customer'
        ELSE 'Single Purchase'
    END AS purchase_category
FROM analytics.customers c
JOIN analytics.orders o
    ON c.customer_id = o.customer_id
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
WHERE LOWER(TRIM(o.order_status)) = 'delivered'
GROUP BY
    c.customer_id,
    c.customer_name
ORDER BY total_orders DESC, total_revenue DESC;


-- ==========================================================
-- 7. TOP 5 CUSTOMERS USING RANKING
-- ==========================================================

WITH customer_revenue AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(oi.line_total) AS revenue
    FROM analytics.customers c
    JOIN analytics.orders o
        ON c.customer_id = o.customer_id
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    WHERE LOWER(TRIM(o.order_status)) = 'delivered'
    GROUP BY c.customer_id, c.customer_name
),
ranked_customers AS (
    SELECT
        customer_id,
        customer_name,
        revenue,
        DENSE_RANK() OVER (
            ORDER BY revenue DESC
        ) AS customer_rank
    FROM customer_revenue
)
SELECT
    customer_id,
    customer_name,
    ROUND(revenue, 2) AS total_revenue,
    customer_rank
FROM ranked_customers
WHERE customer_rank <= 5
ORDER BY customer_rank;


-- ==========================================================
-- 8. PRODUCT PROFIT MARGIN ANALYSIS
-- ==========================================================

SELECT
    p.product_name,
    p.category,
    ROUND(SUM(oi.line_total), 2) AS revenue,
    ROUND(
        SUM(oi.quantity * p.cost_price), 2
    ) AS estimated_cost,
    ROUND(
        SUM(oi.line_total - (oi.quantity * p.cost_price)), 2
    ) AS estimated_profit,
    ROUND(
        100.0 * SUM(
            oi.line_total - (oi.quantity * p.cost_price)
        ) / NULLIF(SUM(oi.line_total), 0),
        2
    ) AS profit_margin_percentage
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
JOIN analytics.products p
    ON oi.product_id = p.product_id
WHERE LOWER(TRIM(o.order_status)) = 'delivered'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY profit_margin_percentage DESC;


-- ==========================================================
-- 9. CUSTOMER RFM SEGMENT REVENUE ANALYSIS
-- ==========================================================

SELECT
    segment,
    COUNT(*) AS total_customers,
    ROUND(SUM(monetary), 2) AS segment_revenue,
    ROUND(AVG(frequency), 2) AS average_frequency,
    ROUND(AVG(recency_days), 2) AS average_recency_days
FROM analytics.customer_rfm
GROUP BY segment
ORDER BY segment_revenue DESC;


-- ==========================================================
-- 10. HIGH-VALUE CUSTOMERS
-- ==========================================================

SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    segment
FROM analytics.customer_rfm
WHERE monetary > (
    SELECT AVG(monetary)
    FROM analytics.customer_rfm
)
ORDER BY monetary DESC;


-- ==========================================================
-- 11. ORDER VALUE ANALYSIS
-- ==========================================================

WITH order_values AS (
    SELECT
        o.order_id,
        o.customer_id,
        SUM(oi.line_total) AS order_value
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    WHERE LOWER(TRIM(o.order_status)) = 'delivered'
    GROUP BY o.order_id, o.customer_id
)
SELECT
    COUNT(*) AS total_delivered_orders,
    ROUND(MIN(order_value), 2) AS minimum_order_value,
    ROUND(MAX(order_value), 2) AS maximum_order_value,
    ROUND(AVG(order_value), 2) AS average_order_value,
    ROUND(SUM(order_value), 2) AS total_revenue
FROM order_values;


-- ==========================================================
-- 12. FINAL BUSINESS PERFORMANCE SUMMARY
-- ==========================================================

SELECT
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT o.customer_id) AS purchasing_customers,
    SUM(oi.quantity) AS total_units_sold,
    ROUND(SUM(oi.line_total), 2) AS total_revenue,
    ROUND(
        SUM(oi.quantity * p.cost_price), 2
    ) AS estimated_cost,
    ROUND(
        SUM(oi.line_total - (oi.quantity * p.cost_price)), 2
    ) AS estimated_profit,
    ROUND(
        100.0 * SUM(
            oi.line_total - (oi.quantity * p.cost_price)
        ) / NULLIF(SUM(oi.line_total), 0),
        2
    ) AS profit_margin_percentage
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
JOIN analytics.products p
    ON oi.product_id = p.product_id
WHERE LOWER(TRIM(o.order_status)) = 'delivered';
