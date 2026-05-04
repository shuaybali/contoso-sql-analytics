# Contoso Sales Analytics

I cleaned and analysed a retail dataset (100K+ records) using PostgreSQL and built a Power BI dashboard.

## What I did

**Data cleaning (PostgreSQL):**
- Fixed missing store status values (15,000+ records) using business logic
- Cleaned customer names that contained numbers (10,000+ records)
- Corrected wrong net price calculations using the formula `netprice = quantity * unitprice`
- Removed duplicate records and fixed data types

**SQL analytics:**
- Yearly revenue with percentage share (CTE + Window Functions)
- Year-on-year growth using `LAG()` – found 103% growth in 2022
- Monthly sales trends – found seasonal patterns
- Customer segmentation (Premium, Gold, Silver, Bronze) using `CASE WHEN`
- Store performance ranking with `RANK()` and `DENSE_RANK()`

**Power BI dashboard (4 pages):**
- Page 1: Yearly overview (sales trend, growth percentage, key KPIs)
- Page 2: Monthly sales trend line chart
- Page 3: Top 5 products + store performance table
- Page 4: Customer segmentation pie chart + top 10 customers

## What I found

- 22% of customers bring 68% of total revenue
- 2022 was the best year (103% growth)
- Online store makes up 38% of total sales
- Silver segment is the largest customer group (43%)

## Files in this repo

- `queries.sql` – all the SQL code I wrote (cleaning + analysis)
- `dashboard_page1.png` to `dashboard_page4.png` – Power BI screenshots

## Tools

- PostgreSQL
- Power BI
- GitHub

## About me

I'm Ali, a data analyst based in Birmingham, UK. I built this project to show my SQL and data visualisation skills. I'm currently looking for a junior data analyst role.
