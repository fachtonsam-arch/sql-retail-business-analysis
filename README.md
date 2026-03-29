# SQL Retail Business Analysis

A multi-year (2014–2016) sales and operations analysis for a US retail business, built entirely in SQL Server (T-SQL). The project covers quarterly revenue trends, discount impact on profitability, customer segment rankings, employee performance, user-defined functions, stored procedures, and dynamic pivot queries.

---

## Tech Stack

![SQL Server](https://img.shields.io/badge/SQL%20Server-CC2927?style=flat&logo=microsoftsqlserver&logoColor=white)
![T-SQL](https://img.shields.io/badge/T--SQL-0078D4?style=flat&logo=microsoft&logoColor=white)
![Excel](https://img.shields.io/badge/Excel-217346?style=flat&logo=microsoft-excel&logoColor=white)
![CSV](https://img.shields.io/badge/CSV-Data-lightgrey?style=flat)

---

## Key Findings

- **High discounts (>50%) consistently produce losses** across all product categories — the business loses money on every heavily discounted order
- **Technology** leads in profit for Consumer and Corporate segments; **Office Supplies** dominates for the Home Office segment
- Sales rank and profit rank **do not always align** — the highest-revenue category is not always the most profitable within each segment
- Most employees derive **60–80% of their total profit from a single product category**, indicating under-diversified sales books
- **State-level profit is highly concentrated** — a small number of high-population states account for the majority of total profit across all quarters

---

## Dashboard Pages / Query Summary

| Query | Title | SQL Technique |
|---|---|---|
| **Query 1** | Furniture Quarterly Sales Trend | `DATEPART`, `GROUP BY`, `ORDER BY` |
| **Query 2** | Discount Impact on Profitability | CTE + `CASE` discount classification |
| **Query 3** | Top Categories by Customer Segment | `RANK() OVER (PARTITION BY ...)` window functions |
| **Query 4** | Employee Profit Distribution by Category | Multi-level CTE + profit % calculation |
| **Query 5** | Profitability Ratio Analysis | User-Defined Scalar Function (`UDF`) |
| **Query 6** | Employee Performance Query Tool | Parameterised Stored Procedure |
| **Query 7** | Regional Profit Pivot — State × Quarter | Dynamic SQL + `STRING_AGG` + `PIVOT` |

---

## Files

| File | Description |
|---|---|
| `SQL Retail Business Analysis Report.html` | Interactive written analysis report (view in browser) |
| `queries/SQL Retail Business Analysis.sql` | Full T-SQL query file — all 7 queries |
| `data/ORDERS.csv` | Source transactional data — 9,994 order records (2014–2016) |
| `data/CUSTOMER.csv` | Customer master data — 793 customers with segment and region |
| `data/PRODUCT.csv` | Product catalogue — 1,862 products across 3 categories |
| `data/EMPLOYEES.csv` | Employee master data — 9 sales employees with regional assignments |

---

## View the Report

**[Open Interactive Report in Browser](https://htmlpreview.github.io/?https://raw.githubusercontent.com/Tommy-Nguyen-Stonera/sql-retail-business-analysis/main/SQL%20Retail%20Business%20Analysis%20Report.html)**

---

## How to Run the Queries

1. Install [SQL Server](https://www.microsoft.com/en-us/sql-server/sql-server-downloads) or [SQL Server Express](https://www.microsoft.com/en-us/sql-server/sql-server-downloads) (free)
2. Import the four CSV files in `data/` as tables: `ORDERS`, `CUSTOMER`, `PRODUCT`, `EMPLOYEES`
3. Open `queries/SQL Retail Business Analysis.sql` in SQL Server Management Studio (SSMS)
4. Run each query block in sequence — queries 5 and 6 create database objects (UDF and stored procedure) before executing the report queries

---

## Dataset Overview

| Table | Rows | Description |
|---|---|---|
| `ORDERS` | 9,994 | Transactional order data with sales, profit, discount, and shipping |
| `CUSTOMER` | 793 | Customer master with segment (Consumer / Corporate / Home Office) and region |
| `PRODUCT` | 1,862 | Product catalogue with category and subcategory |
| `EMPLOYEES` | 9 | Sales employee records with regional assignment |
