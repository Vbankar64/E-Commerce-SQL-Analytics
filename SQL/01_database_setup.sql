
/*
========================================================
PROJECT: E-COMMERCE BUSINESS INTELLIGENCE & SALES ANALYTICS
FILE: 01_database_setup.sql
DATABASE: ecommerce_analytics
TOOL: PostgreSQL 18
PURPOSE: Create schemas and raw data tables
========================================================
*/

-- 1. Create raw schema
CREATE SCHEMA IF NOT EXISTS raw;

-- 2. Create analytics schema
CREATE SCHEMA IF NOT EXISTS analytics;

-- 3. Customers table
CREATE TABLE IF NOT EXISTS raw.customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(150),
    city VARCHAR(100),
    state VARCHAR(100),
    signup_date DATE
);

-- 4. Products table
CREATE TABLE IF NOT EXISTS raw.products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(150),
    category VARCHAR(100),
    unit_price NUMERIC(12,2),
    cost_price NUMERIC(12,2),
    stock_quantity INT,
    is_active BOOLEAN
);

-- 5. Orders table
CREATE TABLE IF NOT EXISTS raw.orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    order_status VARCHAR(50),
    shipping_city VARCHAR(100),
    shipping_state VARCHAR(100)
);

-- 6. Order items table
CREATE TABLE IF NOT EXISTS raw.order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price NUMERIC(12,2),
    discount_percent NUMERIC(5,2),
    line_total NUMERIC(12,2)
);

-- 7. Payments table
CREATE TABLE IF NOT EXISTS raw.payments (
    payment_id INT PRIMARY KEY,
    order_id INT UNIQUE,
    payment_date DATE,
    payment_method VARCHAR(50),
    payment_status VARCHAR(50),
    amount NUMERIC(12,2)
);

-- 8. Verify raw tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'raw'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 9. Verify analytics schema
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('raw', 'analytics')
ORDER BY schema_name;
