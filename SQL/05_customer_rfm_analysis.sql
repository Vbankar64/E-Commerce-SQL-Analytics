
/*
============================================================
PROJECT: E-COMMERCE BUSINESS INTELLIGENCE & SALES ANALYTICS
FILE: 05_customer_rfm_analysis.sql
DATABASE: ecommerce_analytics
TOOL: PostgreSQL 18

PURPOSE:
Customer segmentation using RFM analysis.

RFM:
R = Recency
F = Frequency
M = Monetary Value

BUSINESS RULE:
Only Delivered orders are considered completed sales.
============================================================
*/


-- ==========================================================
-- 1. DISPLAY ALL CUSTOMER RFM RECORDS
-- ==========================================================

SELECT *
FROM analytics.customer_rfm
ORDER BY rfm_total_score DESC;


-- ==========================================================
-- 2. CUSTOMER SEGMENT SUMMARY
-- ==========================================================

SELECT
    segment,
    COUNT(*) AS total_customers,
    ROUND(AVG(recency_days), 2) AS average_recency_days,
    ROUND(AVG(frequency), 2) AS average_frequency,
    ROUND(AVG(monetary), 2) AS average_monetary_value
FROM analytics.customer_rfm
GROUP BY segment
ORDER BY total_customers DESC;


-- ==========================================================
-- 3. CHAMPIONS - BEST CUSTOMERS
-- ==========================================================

SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    rfm_total_score,
    segment
FROM analytics.customer_rfm
WHERE segment = 'Champions'
ORDER BY monetary DESC;


-- ==========================================================
-- 4. LOYAL CUSTOMERS
-- ==========================================================

SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    rfm_total_score
FROM analytics.customer_rfm
WHERE segment = 'Loyal Customers'
ORDER BY frequency DESC, monetary DESC;


-- ==========================================================
-- 5. POTENTIAL LOYALISTS
-- ==========================================================

SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    rfm_total_score
FROM analytics.customer_rfm
WHERE segment = 'Potential Loyalists'
ORDER BY monetary DESC;


-- ==========================================================
-- 6. NEW CUSTOMERS
-- ==========================================================

SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    rfm_total_score
FROM analytics.customer_rfm
WHERE segment = 'New Customers'
ORDER BY recency_days ASC;


-- ==========================================================
-- 7. CUSTOMERS AT RISK
-- ==========================================================

SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    rfm_total_score
FROM analytics.customer_rfm
WHERE segment = 'At Risk'
ORDER BY recency_days DESC;


-- ==========================================================
-- 8. LOST CUSTOMERS
-- ==========================================================

SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    rfm_total_score
FROM analytics.customer_rfm
WHERE segment = 'Lost Customers'
ORDER BY recency_days DESC;


-- ==========================================================
-- 9. TOP 10 CUSTOMERS BY MONETARY VALUE
-- ==========================================================

SELECT
    customer_id,
    customer_name,
    frequency,
    monetary,
    recency_days,
    segment
FROM analytics.customer_rfm
ORDER BY monetary DESC
LIMIT 10;


-- ==========================================================
-- 10. TOP 10 CUSTOMERS BY FREQUENCY
-- ==========================================================

SELECT
    customer_id,
    customer_name,
    frequency,
    monetary,
    recency_days,
    segment
FROM analytics.customer_rfm
ORDER BY frequency DESC, monetary DESC
LIMIT 10;


-- ==========================================================
-- 11. CUSTOMERS WITH HIGH RECENCY
-- ==========================================================

SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    segment
FROM analytics.customer_rfm
WHERE recency_days >= 180
ORDER BY recency_days DESC;


-- ==========================================================
-- 12. RFM SCORE DISTRIBUTION
-- ==========================================================

SELECT
    rfm_total_score,
    COUNT(*) AS total_customers
FROM analytics.customer_rfm
GROUP BY rfm_total_score
ORDER BY rfm_total_score DESC;


-- ==========================================================
-- 13. CUSTOMER SEGMENT REVENUE CONTRIBUTION
-- ==========================================================

SELECT
    segment,
    COUNT(*) AS total_customers,
    ROUND(SUM(monetary), 2) AS segment_revenue,
    ROUND(
        100.0 * SUM(monetary) /
        NULLIF(
            (SELECT SUM(monetary)
             FROM analytics.customer_rfm), 0
        ),
        2
    ) AS revenue_contribution_percentage
FROM analytics.customer_rfm
GROUP BY segment
ORDER BY segment_revenue DESC;


-- ==========================================================
-- 14. FINAL RFM BUSINESS SUMMARY
-- ==========================================================

SELECT
    COUNT(*) AS total_analyzed_customers,
    COUNT(*) FILTER (
        WHERE segment = 'Champions'
    ) AS champions,
    COUNT(*) FILTER (
        WHERE segment = 'Loyal Customers'
    ) AS loyal_customers,
    COUNT(*) FILTER (
        WHERE segment = 'Potential Loyalists'
    ) AS potential_loyalists,
    COUNT(*) FILTER (
        WHERE segment = 'New Customers'
    ) AS new_customers,
    COUNT(*) FILTER (
        WHERE segment = 'At Risk'
    ) AS at_risk_customers,
    COUNT(*) FILTER (
        WHERE segment = 'Lost Customers'
    ) AS lost_customers,
    ROUND(SUM(monetary), 2) AS total_customer_revenue
FROM analytics.customer_rfm;
