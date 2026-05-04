-- =====================================================
-- CONTOSO 100K SQL PROJECT – DATA CLEANING & ANALYTICS
-- =====================================================

-- 1. DATABASE OVERVIEW
SELECT 'customer' AS table_name, COUNT(*) FROM customer
UNION ALL SELECT 'currentexchange', COUNT(*) FROM currencyexchange
UNION ALL SELECT 'date', COUNT(*) FROM date
UNION ALL SELECT 'product', COUNT(*) FROM product
UNION ALL SELECT 'sales', COUNT(*) FROM sales
UNION ALL SELECT 'store', COUNT(*) FROM store;

-- =====================================================
-- 2. DATA CLEANING
-- =====================================================

-- 2.1 Store – Fix NULL Status
UPDATE store
SET status = CASE
    WHEN status = 'Close' THEN 'Close'
    WHEN status = 'Restructured' THEN 'Restructured'
    WHEN closedate IS NOT NULL THEN 'Closed'
    WHEN status IS NULL AND closedate IS NULL THEN 'Active'
    ELSE 'Unknown'
END
WHERE status IS NULL OR closedate IS NOT NULL;

-- 2.2 Store – Remove Duplicates
DELETE FROM store
WHERE (storekey, COALESCE(closedate, '1900-01-01')) NOT IN (
    SELECT DISTINCT ON (storekey) storekey, COALESCE(closedate, '1900-01-01')
    FROM store ORDER BY storekey, closedate DESC NULLS LAST
);

-- 2.3 Customer – Age Validation
SELECT
    COUNT(CASE WHEN age < 0 THEN 1 END) AS negative_age,
    COUNT(CASE WHEN age > 120 THEN 1 END) AS too_old,
    MIN(age) AS min_age,
    MAX(age) AS max_age,
    AVG(age) AS avg_age
FROM customer;

-- 2.4 Sales – Fix quantity = 0
DELETE FROM sales WHERE quantity = 0;

-- 2.5 Sales – Fix incorrect netprice
UPDATE sales
SET netprice = quantity * unitprice
WHERE quantity > 0 AND netprice != (quantity * unitprice);

-- 2.6 Sales – Fix data types
ALTER TABLE sales ALTER COLUMN netprice TYPE numeric(18,2);
ALTER TABLE sales ALTER COLUMN unitprice TYPE numeric(18,2);
ALTER TABLE sales ALTER COLUMN unitcost TYPE numeric(18,2);
ALTER TABLE sales ALTER COLUMN exchangerate TYPE numeric(18,6);

-- 2.7 Sales – Delivery time analysis
SELECT
    COUNT(*) AS total_orders,
    ROUND(AVG(deliverydate - orderdate), 2) AS avg_delivery_days,
    MAX(deliverydate - orderdate) AS max_delivery_days
FROM sales
WHERE deliverydate IS NOT NULL AND orderdate IS NOT NULL;

-- 2.8 Date – Check duplicates
SELECT date, COUNT(*) FROM date GROUP BY date HAVING COUNT(*) > 1;

-- =====================================================
-- 3. ADVANCED SQL ANALYTICS
-- =====================================================

-- 3.1 Yearly Sales with Percentage
WITH yearly_total_sales AS (
    SELECT d.year, SUM(s.netprice) AS total_sales
    FROM sales s
    JOIN date d ON s.orderdate = d.date
    GROUP BY d.year
)
SELECT
    year,
    total_sales,
    ROUND(100.0 * total_sales / SUM(total_sales) OVER(), 2) AS percentage
FROM yearly_total_sales;

-- 3.2 Year-over-Year Growth (LAG)
WITH yearly_sales AS (
    SELECT d.year, SUM(s.netprice) AS total_sales
    FROM sales s
    JOIN date d ON s.orderdate = d.date
    GROUP BY d.year
),
with_previous AS (
    SELECT year, total_sales,
           LAG(total_sales) OVER (ORDER BY year) AS previous_year_sales
    FROM yearly_sales
)
SELECT
    year,
    total_sales,
    previous_year_sales,
    ROUND(100.0 * (total_sales - previous_year_sales) / previous_year_sales, 2) || '%' AS growth_percentage
FROM with_previous
WHERE previous_year_sales IS NOT NULL;

-- 3.3 Monthly Sales Trend
WITH monthly_revenue AS (
    SELECT d.year, d.month, SUM(s.netprice) AS monthly_sales
    FROM date d
    JOIN sales s ON d.date = s.orderdate
    GROUP BY d.year, d.month
),
with_previous AS (
    SELECT year, month, monthly_sales,
           LAG(monthly_sales) OVER (ORDER BY year, month) AS previous_month_sales
    FROM monthly_revenue
)
SELECT
    year,
    month,
    monthly_sales,
    previous_month_sales,
    ROUND(100.0 * (monthly_sales - previous_month_sales) / previous_month_sales, 2) AS growth_percentage
FROM with_previous
WHERE previous_month_sales IS NOT NULL;

-- 3.4 Top 5 Products
WITH top_products AS (
    SELECT p.productname, SUM(s.netprice) AS total_sales
    FROM product p
    JOIN sales s ON p.productkey = s.productkey
    GROUP BY p.productname
)
SELECT productname, total_sales
FROM top_products
ORDER BY total_sales DESC
LIMIT 5;

-- 3.5 Category Sales with Percentage
WITH category_sales AS (
    SELECT p.categoryname, SUM(s.netprice) AS total_sales
    FROM product p
    JOIN sales s ON p.productkey = s.productkey
    GROUP BY p.categoryname
)
SELECT
    categoryname,
    total_sales,
    ROUND(100.0 * total_sales / SUM(total_sales) OVER(), 2) || '%' AS percentage
FROM category_sales
ORDER BY total_sales DESC;

-- 3.6 Store Performance Ranking
WITH store_sales AS (
    SELECT st.storekey, st.countryname, st.state, SUM(s.netprice) AS total_sales
    FROM store st
    JOIN sales s ON st.storekey = s.storekey
    GROUP BY st.storekey, st.countryname, st.state
)
SELECT
    storekey,
    countryname,
    state,
    total_sales,
    ROUND(100.0 * total_sales / SUM(total_sales) OVER(), 2) AS sales_percentage,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM store_sales
LIMIT 10;

-- 3.7 Customer Segmentation (Spending)
WITH customer_spending AS (
    SELECT s.customerkey, SUM(s.netprice) AS total_spent
    FROM sales s
    GROUP BY s.customerkey
),
customer_segment AS (
    SELECT
        customerkey,
        total_spent,
        CASE
            WHEN total_spent >= 20000 THEN 'Premium'
            WHEN total_spent >= 10000 THEN 'Gold'
            WHEN total_spent >= 5000 THEN 'Silver'
            ELSE 'Bronze'
        END AS segment
    FROM customer_spending
)
SELECT
    segment,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_spent), 2) AS total_revenue,
    ROUND(AVG(total_spent), 2) AS avg_spent
FROM customer_segment
GROUP BY segment
ORDER BY
    CASE segment
        WHEN 'Premium' THEN 1
        WHEN 'Gold' THEN 2
        WHEN 'Silver' THEN 3
        ELSE 4
    END;

-- 3.8 Top 10 Customers (Age, Gender, Country)
WITH customer_spend AS (
    SELECT
        c.givenname, c.surname, c.gender, c.countryfull, c.birthday,
        SUM(s.netprice) AS total_spent
    FROM customer c
    JOIN sales s ON c.customerkey = s.customerkey
    GROUP BY c.givenname, c.surname, c.gender, c.countryfull, c.birthday
),
customer_age AS (
    SELECT
        CONCAT(givenname, ' ', surname) AS full_name,
        gender,
        countryfull,
        total_spent,
        DATE_PART('year', AGE(CURRENT_DATE, birthday))::INT AS age
    FROM customer_spend
)
SELECT full_name, gender, countryfull, total_spent, age
FROM customer_age
ORDER BY total_spent DESC
LIMIT 10;

-- =====================================================
-- END OF PROJECT
-- =====================================================
