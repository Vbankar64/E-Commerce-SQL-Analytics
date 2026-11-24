
-- File: 07_create_customer_rfm_view.sql
-- Purpose: Create customer RFM analysis view

CREATE OR REPLACE VIEW analytics.customer_rfm AS

WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.city,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(oi.line_total), 2) AS monetary,
        MAX(o.order_date::date) AS last_purchase_date
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
),

rfm_scores AS (
    SELECT
        customer_id,
        customer_name,
        city,
        frequency,
        monetary,
        last_purchase_date,

        CURRENT_DATE - last_purchase_date AS recency_days,

        6 - NTILE(5) OVER (
            ORDER BY last_purchase_date DESC
        ) AS recency_score,

        6 - NTILE(5) OVER (
            ORDER BY frequency
        ) AS frequency_score,

        6 - NTILE(5) OVER (
            ORDER BY monetary
        ) AS monetary_score

    FROM customer_metrics
)

SELECT
    customer_id,
    customer_name,
    city,
    frequency,
    monetary,
    last_purchase_date,
    recency_days,
    recency_score,
    frequency_score,
    monetary_score,

    recency_score
        + frequency_score
        + monetary_score AS rfm_total_score,

    CASE
        WHEN recency_score >= 4
         AND frequency_score >= 4
         AND monetary_score >= 4
            THEN 'Champions'

        WHEN frequency_score >= 4
            THEN 'Loyal Customers'

        WHEN recency_score >= 4
         AND frequency_score <= 2
            THEN 'New Customers'

        WHEN recency_score <= 2
         AND frequency_score >= 3
            THEN 'At Risk'

        WHEN recency_score <= 2
         AND frequency_score <= 2
            THEN 'Lost Customers'

        ELSE 'Potential Loyalists'
    END AS customer_segment

FROM rfm_scores;
