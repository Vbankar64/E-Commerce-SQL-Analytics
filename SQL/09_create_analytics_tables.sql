
-- File: 09_create_analytics_tables.sql
-- Purpose: Transform raw tables into analytics tables
-- Database: PostgreSQL
-- Source: raw schema

-- IMPORTANT:
-- Run this script only when rebuilding the analytics schema
-- in a fresh project setup. It deletes existing analytics objects.

BEGIN;

DROP SCHEMA IF EXISTS analytics CASCADE;
CREATE SCHEMA analytics;

-- 1. Cleaned Customers
CREATE TABLE analytics.customers AS
SELECT
    TRIM(customer_id) AS customer_id,
    TRIM(customer_name) AS customer_name,
    LOWER(TRIM(email)) AS email,
    TRIM(city) AS city,
    TRIM(state) AS state,
    signup_date
FROM raw.customers;

-- 2. Cleaned Products
CREATE TABLE analytics.products AS
SELECT
    TRIM(product_id) AS product_id,
    TRIM(product_name) AS product_name,
    TRIM(category) AS category,
    unit_price,
    cost_price,
    stock_quantity,
    is_active,
    ROUND(unit_price - cost_price, 2) AS profit_per_unit
FROM raw.products;

-- 3. Cleaned Orders
CREATE TABLE analytics.orders AS
SELECT
    TRIM(order_id) AS order_id,
    TRIM(customer_id) AS customer_id,
    order_date,
    TRIM(order_status) AS order_status,
    TRIM(shipping_city) AS shipping_city,
    TRIM(shipping_state) AS shipping_state
FROM raw.orders;

-- 4. Cleaned Order Items
CREATE TABLE analytics.order_items AS
SELECT
    TRIM(order_item_id) AS order_item_id,
    TRIM(order_id) AS order_id,
    TRIM(product_id) AS product_id,
    quantity,
    unit_price,
    discount_percent,
    line_total,
    ROUND(quantity::numeric * unit_price, 2) AS gross_amount,
    ROUND(
        quantity::numeric * unit_price - line_total,
        2
    ) AS discount_amount
FROM raw.order_items;

-- 5. Cleaned Payments
CREATE TABLE analytics.payments AS
SELECT
    TRIM(payment_id) AS payment_id,
    TRIM(order_id) AS order_id,
    payment_date,
    TRIM(payment_method) AS payment_method,
    TRIM(payment_status) AS payment_status,
    amount
FROM raw.payments;

COMMIT;
