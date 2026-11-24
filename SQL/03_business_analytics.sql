
/*
============================================================
PROJECT: E-COMMERCE BUSINESS INTELLIGENCE & SALES ANALYTICS
FILE: 03_business_analysis.sql
DATABASE: ecommerce_analytics
TOOL: PostgreSQL 18
PURPOSE: Business and sales performance analysis

BUSINESS RULE:
Only Delivered orders are treated as completed sales.
============================================================
*/


-- ==========================================================
-- 1. OVERALL BUSINESS PERFORMANCE
-- ==========================================================

SELECT
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT o.customer_id) AS purchasing_customers,
    COALESCE(SUM(oi.quantity), 0) AS units_sold,
    ROUND(COALESCE(SUM(oi.line_total), 0), 2) AS total_revenue,
    ROUND(
        COALESCE(SUM(oi.quantity * p.cost_price), 0), 2
    ) AS total_cost,
    ROUND(
        COALESCE(
            SUM(oi.line_total - (oi.quantity * p.cost_price)), 0
        ), 2
    ) AS estimated_profit,
    ROUND(
        100.0 * (
            SUM(oi.line_total - (oi.quantity * p.cost_price))
            / NULLIF(SUM(oi.line_total), 0)
        ), 2
    ) AS profit_margin_percentage
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
JOIN analytics.products p
    ON oi.product_id = p.product_id
WHERE LOWER(TRIM(o.order_status)) = 'delivered';


-- ==========================================================
-- 2. MONTHLY REVENUE ANALYSIS
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
GROUP BY TO_CHAR(o.order_date, 'YYYY-MM')
ORDER BY sales_month;


-- ==========================================================
-- 3. CATEGORY-WISE SALES ANALYSIS
-- ==========================================================

SELECT
    p.category,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.line_total), 2) AS total_revenue,
    ROUND(
        SUM(oi.quantity * p.cost_price), 2
    ) AS total_cost,
    ROUND(
        SUM(oi.line_total - (oi.quantity * p.cost_price)), 2
    ) AS estimated_profit
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
JOIN analytics.products p
    ON oi.product_id = p.product_id
WHERE LOWER(TRIM(o.order_status)) = 'delivered'
GROUP BY p.category
ORDER BY total_revenue DESC;


-- ==========================================================
-- 4. TOP 10 PRODUCTS BY REVENUE
-- ==========================================================

SELECT
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
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC
LIMIT 10;


-- ==========================================================
-- 5. TOP 10 CUSTOMERS BY REVENUE
-- ==========================================================

SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(SUM(oi.line_total), 2) AS total_revenue
FROM analytics.customers c
JOIN analytics.orders o
    ON c.customer_id = o.customer_id
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
WHERE LOWER(TRIM(o.order_status)) = 'delivered'
GROUP BY c.customer_id, c.customer_name, c.city
ORDER BY total_revenue DESC
LIMIT 10;


-- ==========================================================
-- 6. CITY-WISE REVENUE ANALYSIS
-- ==========================================================

SELECT
    o.shipping_city,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT o.customer_id) AS purchasing_customers,
    ROUND(SUM(oi.line_total), 2) AS total_revenue
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
WHERE LOWER(TRIM(o.order_status)) = 'delivered'
GROUP BY o.shipping_city
ORDER BY total_revenue DESC;


-- ==========================================================
-- 7. AVERAGE ORDER VALUE (AOV)
-- ==========================================================

WITH order_revenue AS (
    SELECT
        o.order_id,
        SUM(oi.line_total) AS order_total
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    WHERE LOWER(TRIM(o.order_status)) = 'delivered'
    GROUP BY o.order_id
)
SELECT
    COUNT(*) AS delivered_orders,
    ROUND(SUM(order_total), 2) AS total_revenue,
    ROUND(AVG(order_total), 2) AS average_order_value
FROM order_revenue;


-- ==========================================================
-- 8. PAYMENT METHOD ANALYSIS
-- ==========================================================

SELECT
    p.payment_method,
    COUNT(*) AS total_payments,
    COUNT(*) FILTER (
        WHERE LOWER(TRIM(p.payment_status)) = 'success'
    ) AS successful_payments,
    ROUND(SUM(p.amount), 2) AS total_payment_amount
FROM analytics.payments p
JOIN analytics.orders o
    ON p.order_id = o.order_id
WHERE LOWER(TRIM(o.order_status)) = 'delivered'
GROUP BY p.payment_method
ORDER BY total_payment_amount DESC;


-- ==========================================================
-- 9. ORDER STATUS ANALYSIS
-- ==========================================================

SELECT
    TRIM(order_status) AS order_status,
    COUNT(*) AS total_orders,
    ROUND(
        100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM analytics.orders), 0),
        2
    ) AS percentage_of_orders
FROM analytics.orders
GROUP BY TRIM(order_status)
ORDER BY total_orders DESC;


-- ==========================================================
-- 10. PRODUCT PROFITABILITY ANALYSIS
-- ==========================================================

SELECT
    p.product_name,
    p.category,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.line_total), 2) AS revenue,
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
WHERE LOWER(TRIM(o.order_status)) = 'delivered'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY estimated_profit DESC;


-- ==========================================================
-- 11. REPEAT CUSTOMER ANALYSIS
-- ==========================================================

SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(SUM(oi.line_total), 2) AS total_revenue
FROM analytics.customers c
JOIN analytics.orders o
    ON c.customer_id = o.customer_id
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
WHERE LOWER(TRIM(o.order_status)) = 'delivered'
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY delivered_orders DESC, total_revenue DESC;


-- ==========================================================
-- 12. BUSINESS KPI VIEW
-- ==========================================================

SELECT *
FROM analytics.business_kpis;
