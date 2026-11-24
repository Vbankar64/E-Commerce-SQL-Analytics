
/*
============================================================
PROJECT: E-COMMERCE BUSINESS INTELLIGENCE & SALES ANALYTICS
FILE: 04_advanced_sales_analysis.sql
DATABASE: ecommerce_analytics
TOOL: PostgreSQL 18

PURPOSE:
Advanced sales analysis using CTEs, window functions,
ranking, cumulative revenue and monthly comparisons.

BUSINESS RULE:
Only Delivered orders are considered completed sales.
============================================================
*/


-- ==========================================================
-- 1. TOP 10 PRODUCTS BY REVENUE
-- ==========================================================

SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.line_total), 2) AS total_revenue
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
ORDER BY total_revenue DESC
LIMIT 10;


-- ==========================================================
-- 2. CATEGORY-WISE REVENUE AND PROFIT
-- ==========================================================

SELECT
    p.category,
    SUM(oi.quantity) AS total_units_sold,
    ROUND(SUM(oi.line_total), 2) AS total_revenue,
    ROUND(
        SUM(oi.quantity * p.cost_price), 2
    ) AS total_cost,
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
GROUP BY p.category
ORDER BY total_revenue DESC;


-- ==========================================================
-- 3. MONTHLY SALES TREND
-- ==========================================================

SELECT
    TO_CHAR(o.order_date, 'YYYY-MM') AS sales_month,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.line_total), 2) AS monthly_revenue
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
WHERE LOWER(TRIM(o.order_status)) = 'delivered'
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY DATE_TRUNC('month', o.order_date);


-- ==========================================================
-- 4. MONTH-OVER-MONTH REVENUE COMPARISON
-- ==========================================================

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS sales_month,
        SUM(oi.line_total) AS revenue
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    WHERE LOWER(TRIM(o.order_status)) = 'delivered'
    GROUP BY DATE_TRUNC('month', o.order_date)
),
monthly_comparison AS (
    SELECT
        sales_month,
        revenue,
        LAG(revenue) OVER (
            ORDER BY sales_month
        ) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    TO_CHAR(sales_month, 'YYYY-MM') AS sales_month,
    ROUND(revenue, 2) AS current_revenue,
    ROUND(previous_month_revenue, 2) AS previous_revenue,
    ROUND(
        revenue - previous_month_revenue, 2
    ) AS revenue_difference,
    ROUND(
        100.0 * (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0),
        2
    ) AS growth_percentage
FROM monthly_comparison
ORDER BY sales_month;


-- ==========================================================
-- 5. CUMULATIVE MONTHLY REVENUE
-- ==========================================================

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS sales_month,
        SUM(oi.line_total) AS revenue
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    WHERE LOWER(TRIM(o.order_status)) = 'delivered'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
    TO_CHAR(sales_month, 'YYYY-MM') AS sales_month,
    ROUND(revenue, 2) AS monthly_revenue,
    ROUND(
        SUM(revenue) OVER (
            ORDER BY sales_month
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ), 2
    ) AS cumulative_revenue
FROM monthly_revenue
ORDER BY sales_month;


-- ==========================================================
-- 6. RANK PRODUCTS BY REVENUE WITHIN EACH CATEGORY
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
    ROUND(revenue, 2) AS revenue,
    DENSE_RANK() OVER (
        PARTITION BY category
        ORDER BY revenue DESC
    ) AS category_rank
FROM product_sales
ORDER BY category, category_rank;


-- ==========================================================
-- 7. TOP 10 CUSTOMERS BY TOTAL REVENUE
-- ==========================================================

SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(SUM(oi.line_total), 2) AS total_revenue,
    DENSE_RANK() OVER (
        ORDER BY SUM(oi.line_total) DESC
    ) AS customer_rank
FROM analytics.customers c
JOIN analytics.orders o
    ON c.customer_id = o.customer_id
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
WHERE LOWER(TRIM(o.order_status)) = 'delivered'
GROUP BY
    c.customer_id,
    c.customer_name,
    c.city
ORDER BY customer_rank
LIMIT 10;


-- ==========================================================
-- 8. CITY-WISE SALES RANKING
-- ==========================================================

WITH city_sales AS (
    SELECT
        o.shipping_city,
        COUNT(DISTINCT o.order_id) AS delivered_orders,
        SUM(oi.line_total) AS revenue
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    WHERE LOWER(TRIM(o.order_status)) = 'delivered'
    GROUP BY o.shipping_city
)
SELECT
    shipping_city,
    delivered_orders,
    ROUND(revenue, 2) AS total_revenue,
    DENSE_RANK() OVER (
        ORDER BY revenue DESC
    ) AS city_rank
FROM city_sales
ORDER BY city_rank;


-- ==========================================================
-- 9. HIGH-VALUE ORDERS
-- ==========================================================

WITH order_totals AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        SUM(oi.line_total) AS order_value
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    WHERE LOWER(TRIM(o.order_status)) = 'delivered'
    GROUP BY
        o.order_id,
        o.customer_id,
        o.order_date
)
SELECT
    ot.order_id,
    c.customer_name,
    ot.order_date,
    ROUND(ot.order_value, 2) AS order_value
FROM order_totals ot
JOIN analytics.customers c
    ON ot.customer_id = c.customer_id
WHERE ot.order_value > (
    SELECT AVG(order_value)
    FROM order_totals
)
ORDER BY ot.order_value DESC;


-- ==========================================================
-- 10. REPEAT CUSTOMER REVENUE ANALYSIS
-- ==========================================================

SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(SUM(oi.line_total), 2) AS total_revenue,
    CASE
        WHEN COUNT(DISTINCT o.order_id) >= 3
            THEN 'Frequent Customer'
        WHEN COUNT(DISTINCT o.order_id) = 2
            THEN 'Repeat Customer'
        ELSE 'Single Order Customer'
    END AS customer_type
FROM analytics.customers c
JOIN analytics.orders o
    ON c.customer_id = o.customer_id
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
WHERE LOWER(TRIM(o.order_status)) = 'delivered'
GROUP BY
    c.customer_id,
    c.customer_name
ORDER BY delivered_orders DESC, total_revenue DESC;


-- ==========================================================
-- 11. BEST REVENUE-GENERATING MONTH
-- ==========================================================

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS sales_month,
        SUM(oi.line_total) AS revenue
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    WHERE LOWER(TRIM(o.order_status)) = 'delivered'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
    TO_CHAR(sales_month, 'YYYY-MM') AS best_sales_month,
    ROUND(revenue, 2) AS total_revenue
FROM monthly_revenue
ORDER BY revenue DESC
LIMIT 1;


-- ==========================================================
-- 12. FINAL ADVANCED SALES SUMMARY
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
    ) AS estimated_profit
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
JOIN analytics.products p
    ON oi.product_id = p.product_id
WHERE LOWER(TRIM(o.order_status)) = 'delivered';
