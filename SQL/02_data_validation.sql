
/*
========================================================
PROJECT: E-COMMERCE BUSINESS INTELLIGENCE & SALES ANALYTICS
FILE: 02_data_validation.sql
DATABASE: ecommerce_analytics
TOOL: PostgreSQL 18
PURPOSE: Data quality and validation checks
========================================================
*/


-- ======================================================
-- 1. CHECK RAW TABLE RECORD COUNTS
-- ======================================================

SELECT 'customers' AS table_name, COUNT(*) AS total_records
FROM raw.customers

UNION ALL

SELECT 'products', COUNT(*)
FROM raw.products

UNION ALL

SELECT 'orders', COUNT(*)
FROM raw.orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM raw.order_items

UNION ALL

SELECT 'payments', COUNT(*)
FROM raw.payments;


-- ======================================================
-- 2. CHECK MISSING VALUES IN CUSTOMERS
-- ======================================================

SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE customer_name IS NULL) AS missing_names,
    COUNT(*) FILTER (WHERE email IS NULL) AS missing_emails,
    COUNT(*) FILTER (WHERE city IS NULL) AS missing_cities,
    COUNT(*) FILTER (WHERE signup_date IS NULL) AS missing_signup_dates
FROM raw.customers;


-- ======================================================
-- 3. CHECK DUPLICATE CUSTOMER EMAILS
-- ======================================================

SELECT
    LOWER(TRIM(email)) AS email,
    COUNT(*) AS duplicate_count
FROM raw.customers
WHERE email IS NOT NULL
GROUP BY LOWER(TRIM(email))
HAVING COUNT(*) > 1;


-- ======================================================
-- 4. CHECK PRODUCT DATA QUALITY
-- ======================================================

SELECT
    COUNT(*) AS total_products,
    COUNT(*) FILTER (WHERE product_name IS NULL) AS missing_names,
    COUNT(*) FILTER (WHERE category IS NULL) AS missing_categories,
    COUNT(*) FILTER (WHERE unit_price IS NULL) AS missing_prices,
    COUNT(*) FILTER (WHERE cost_price IS NULL) AS missing_costs,
    COUNT(*) FILTER (WHERE stock_quantity < 0) AS negative_stock,
    COUNT(*) FILTER (WHERE unit_price < 0) AS negative_prices,
    COUNT(*) FILTER (WHERE cost_price < 0) AS negative_costs
FROM raw.products;


-- ======================================================
-- 5. CHECK ORDER STATUS DISTRIBUTION
-- ======================================================

SELECT
    TRIM(order_status) AS order_status,
    COUNT(*) AS total_orders
FROM raw.orders
GROUP BY TRIM(order_status)
ORDER BY total_orders DESC;


-- ======================================================
-- 6. CHECK MISSING CUSTOMER REFERENCES IN ORDERS
-- ======================================================

SELECT
    o.order_id,
    o.customer_id
FROM raw.orders o
LEFT JOIN raw.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- ======================================================
-- 7. CHECK INVALID ORDER ITEM REFERENCES
-- ======================================================

SELECT
    oi.order_item_id,
    oi.order_id,
    oi.product_id
FROM raw.order_items oi
LEFT JOIN raw.orders o
    ON oi.order_id = o.order_id
LEFT JOIN raw.products p
    ON oi.product_id = p.product_id
WHERE o.order_id IS NULL
   OR p.product_id IS NULL;


-- ======================================================
-- 8. CHECK INVALID ORDER ITEM VALUES
-- ======================================================

SELECT
    order_item_id,
    quantity,
    unit_price,
    discount_percent,
    line_total
FROM raw.order_items
WHERE quantity <= 0
   OR unit_price < 0
   OR discount_percent < 0
   OR discount_percent > 100
   OR line_total < 0;


-- ======================================================
-- 9. CHECK PAYMENT STATUS DISTRIBUTION
-- ======================================================

SELECT
    TRIM(payment_status) AS payment_status,
    COUNT(*) AS total_payments,
    ROUND(SUM(amount), 2) AS total_amount
FROM raw.payments
GROUP BY TRIM(payment_status)
ORDER BY total_payments DESC;


-- ======================================================
-- 10. CHECK PAYMENT ORDER REFERENCES
-- ======================================================

SELECT
    p.payment_id,
    p.order_id
FROM raw.payments p
LEFT JOIN raw.orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ======================================================
-- 11. CHECK INVALID PAYMENT AMOUNTS
-- ======================================================

SELECT
    payment_id,
    order_id,
    amount,
    payment_status
FROM raw.payments
WHERE amount < 0
   OR amount IS NULL;


-- ======================================================
-- 12. CHECK DUPLICATE PRIMARY KEY VALUES
-- ======================================================

SELECT
    'customers' AS table_name,
    customer_id AS duplicate_id,
    COUNT(*) AS duplicate_count
FROM raw.customers
GROUP BY customer_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'products',
    product_id,
    COUNT(*)
FROM raw.products
GROUP BY product_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'orders',
    order_id,
    COUNT(*)
FROM raw.orders
GROUP BY order_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'order_items',
    order_item_id,
    COUNT(*)
FROM raw.order_items
GROUP BY order_item_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'payments',
    payment_id,
    COUNT(*)
FROM raw.payments
GROUP BY payment_id
HAVING COUNT(*) > 1;


-- ======================================================
-- 13. CHECK ORDER DATE AND CUSTOMER SIGNUP DATE
-- ======================================================

SELECT
    o.order_id,
    o.order_date,
    c.signup_date
FROM raw.orders o
JOIN raw.customers c
    ON o.customer_id = c.customer_id
WHERE o.order_date < c.signup_date;


-- ======================================================
-- 14. CHECK CLEANED ANALYTICS TABLE COUNTS
-- ======================================================

SELECT 'customers' AS table_name, COUNT(*) AS total_records
FROM analytics.customers

UNION ALL

SELECT 'products', COUNT(*)
FROM analytics.products

UNION ALL

SELECT 'orders', COUNT(*)
FROM analytics.orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM analytics.order_items

UNION ALL

SELECT 'payments', COUNT(*)
FROM analytics.payments;


-- ======================================================
-- 15. FINAL DATA VALIDATION SUMMARY
-- ======================================================

SELECT
    (SELECT COUNT(*) FROM raw.customers) AS customers,
    (SELECT COUNT(*) FROM raw.products) AS products,
    (SELECT COUNT(*) FROM raw.orders) AS orders,
    (SELECT COUNT(*) FROM raw.order_items) AS order_items,
    (SELECT COUNT(*) FROM raw.payments) AS payments;
