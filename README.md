# E-Commerce Business Intelligence & Sales Analytics Using SQL

## Project Overview

This project focuses on analyzing e-commerce business data using PostgreSQL to generate meaningful business insights.

The project uses SQL queries, joins, aggregate functions, Common Table Expressions (CTEs), window functions, and analytical views to understand sales performance, product performance, customer purchasing behavior, and business profitability.

The objective is to transform raw e-commerce data into useful information that supports business decision-making.

## Project Objectives

- Analyze overall e-commerce sales performance.
- Calculate business KPIs such as revenue, estimated profit, and profit margin.
- Identify top-performing products and categories.
- Analyze customer purchasing behavior.
- Track monthly sales trends.
- Segment customers using RFM analysis.
- Generate insights to support business decisions.

## Tools and Technologies

- PostgreSQL 18
- pgAdmin 4
- SQL
- Microsoft Excel (for dataset handling)
- Git and GitHub

## Dataset Information

The project contains five datasets with 824 total records.

| Dataset | Records |
|---|---:|
| Customers | 100 |
| Products | 30 |
| Orders | 200 |
| Order Items | 294 |
| Payments | 200 |
| **Total** | **824** |

The dataset contains e-commerce customer, product, order, sales, and payment information.

## Database Structure

The project uses two schemas:

- `raw` – Stores the original imported datasets.
- `analytics` – Stores cleaned analytical tables and views.

### Main Tables

1. customers
2. products
3. orders
4. order_items
5. payments

## SQL Concepts Used

- Database and schema creation
- Table creation and data types
- Primary keys and foreign keys
- Data cleaning using TRIM and LOWER
- SELECT, WHERE, ORDER BY
- GROUP BY and HAVING
- INNER JOIN
- Aggregate functions
- Subqueries
- Common Table Expressions (CTEs)
- Window functions
- NTILE and ranking functions
- Views
- Customer RFM analysis

## Business Analysis

The project includes four main analytical views:

1. **Business KPIs:** Measures delivered orders, purchasing customers, revenue, estimated cost, profit, and profit margin.
2. **Monthly Sales:** Analyzes monthly orders, units sold, and revenue.
3. **Product Performance:** Identifies products by units sold, revenue, and estimated profit.
4. **Customer Performance:** Identifies customer spending and purchasing activity.

## Customer Segmentation Using RFM

RFM analysis classifies customers based on:

- Recency – How recently the customer purchased.
- Frequency – How often the customer purchased.
- Monetary – How much the customer spent.

The project identifies six customer segments:

- Champions
- Loyal Customers
- Potential Loyalists
- New Customers
- At Risk
- Lost Customers

### Customer Segmentation Results

| Segment | Customers |
|---|---:|
| Loyal Customers | 20 |
| Potential Loyalists | 14 |
| New Customers | 13 |
| Champions | 6 |
| At Risk | 5 |
| Lost Customers | 5 |
| **Total** | **63** |

## Key Business Findings

- Total delivered orders: 113.
- Purchasing customers: 63.
- Units sold: 214.
- Total revenue: ₹3,14,649.60.
- Estimated cost: ₹2,09,801.36.
- Estimated profit: ₹1,04,848.24.
- Estimated profit margin: 33.32%.
- November 2025 generated the highest monthly revenue.

*Profit is estimated using the product cost prices available in the dataset.*

## Project Folder Structure

```text
E-Commerce-Analytics-Project/
│
├── dataset/
├── sql/
├── screenshots/
└── README.md
```

## Business Recommendations

- Provide loyalty benefits to repeat customers.
- Develop promotional campaigns for potential loyalists.
- Encourage new customers to make repeat purchases.
- Offer exclusive rewards to champion customers.
- Run customer re-engagement campaigns for at-risk customers.
- Monitor monthly sales and product profitability.

## Conclusion

This project demonstrates how SQL and PostgreSQL can be used to analyze e-commerce data and generate actionable business insights.

It provides practical experience in database management, data cleaning, sales analysis, KPI reporting, and customer segmentation.

## Author

**Vrushali Bankar**

Data Analytics Project | PostgreSQL | SQL