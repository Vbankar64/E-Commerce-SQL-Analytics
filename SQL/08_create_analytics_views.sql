
-- File: 08_create_analytics_views.sql
-- Purpose: Create business intelligence analytics views
-- Business rule: Only Delivered orders count as completed sales.

-- 1. Business KPIs
CREATE OR REPLACE VIEW analytics.business_kpis AS
SELECT
    COUNT(DISTINCT o.order_id) AS completed_orders,
    COUNT(DISTINCT o.customer_id) AS purchasing_customers,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.line_total), 2) AS total_revenue,
    ROUND(SUM(oi.quantity::numeric * p.cost_price), 2) AS total_cost,
    ROUND(
        SUM(oi.line_total - oi.quantity::numeric * p.cost_price),
        2
    ) AS estimated_profit,
    ROUND(
        100.0 * SUM(
            oi.line_total - oi.quantity::numeric * p.cost_price
        ) / NULLIF(SUM(oi.line_total), 0),
        2
    ) AS profit_margin_percentage
FROM analytics.orders o
JOIN analytics.order_items oi
    ON oi.order_id = o.order_id
JOIN analytics.products p
    ON p.product_id = oi.product_id
WHERE LOWER(TRIM(o.order_status)) = 'delivered';


-- 2. Customer Performance
CREATE OR REPLACE VIEW analytics.customer_performance AS
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.line_total), 2) AS total_spending
FROM analytics.customers c
JOIN analytics.orders o
    ON c.customer_id = o.customer_id
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
WHERE LOWER(TRIM(o.order_status)) = 'delivered'
GROUP BY
    c.customer_id,
    c.customer_name,
    c.city;


-- 3. Monthly Revenue Growth
CREATE OR REPLACE VIEW analytics.monthly_revenue_growth AS
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', o.order_date)::date AS sales_month,
        SUM(oi.line_total) AS revenue
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    WHERE LOWER(TRIM(o.order_status)) = 'delivered'
    GROUP BY DATE_TRUNC('month', o.order_date)
),
comparison AS (
    SELECT
        sales_month,
        revenue,
        LAG(revenue) OVER (
            ORDER BY sales_month
        ) AS previous_revenue
    FROM monthly_sales
)
SELECT
    sales_month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_revenue, 2) AS previous_revenue,
    ROUND(
        100.0 * (revenue - previous_revenue)
        / NULLIF(previous_revenue, 0),
        2
    ) AS growth_percentage
FROM comparison;


-- 4. Monthly Sales
CREATE OR REPLACE VIEW analytics.monthly_sales AS
SELECT
    TO_CHAR(o.order_date, 'YYYY-MM') AS sales_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.line_total), 2) AS total_revenue
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
WHERE LOWER(TRIM(o.order_status)) = 'delivered'
GROUP BY TO_CHAR(o.order_date, 'YYYY-MM');


-- 5. Product Performance
CREATE OR REPLACE VIEW analytics.product_performance AS
SELECT
    p.product_name,
    p.category,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.line_total), 2) AS revenue,
    ROUND(
        SUM(oi.line_total - oi.quantity::numeric * p.cost_price),
        2
    ) AS estimated_profit
FROM analytics.products p
JOIN analytics.order_items oi
    ON p.product_id = oi.product_id
JOIN analytics.orders o
    ON oi.order_id = o.order_id
WHERE LOWER(TRIM(o.order_status)) = 'delivered'
GROUP BY
    p.product_id,
    p.product_name,
    p.category;
