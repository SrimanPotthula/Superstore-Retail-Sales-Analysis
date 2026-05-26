CREATE DATABASE Retail_Project;
USE Retail_Project;
CREATE TABLE superstore_raw (
    row_id INT,
    order_id VARCHAR(50),
    order_date VARCHAR(50),
    ship_date VARCHAR(50),
    ship_mode VARCHAR(50),
    customer_id VARCHAR(50),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    region VARCHAR(50),
    product_id VARCHAR(50),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name TEXT,
    sales DECIMAL(10,2),
    quantity INT,
    discount DECIMAL(5,2),
    profit DECIMAL(10,2)
);

SELECT * FROM superstore_raw
ORDER BY row_id DESC
limit 10;

SELECT 
COUNT(*) AS total_rows,
COUNT(order_id) AS order_id_count,
COUNT(sales) AS sales_count
FROM superstore_raw;

SELECT COUNT(*) As count_all
FROM superstore_raw
WHERE order_id IS NULL;

SELECT order_id, product_id, COUNT(*)
FROM superstore_raw
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;

CREATE TABLE superstore_clean AS 
SELECT *
FROM (SELECT *,
		ROW_NUMBER() OVER (PARTITION BY order_id, product_id ORDER BY order_id) AS rn
        FROM superstore_raw) t 
WHERE rn = 1;

UPDATE superstore_clean
SET product_name = trim(product_name),
	customer_name = trim(customer_name);

ALTER TABLE superstore_clean
ADD order_date_new DATE;

UPDATE superstore_clean
SET order_date_new = str_to_date(order_date, '%m/%d/%Y');

UPDATE superstore_clean
SET order_date_new = 
CASE
	WHEN order_date LIKE '%/%' THEN str_to_date(order_date, '%m/%d/%Y')
	WHEN order_date LIKE '%-%' THEN str_to_date(order_date, '%m-%d-%Y')
    ELSE order_date
END;    

CREATE TABLE fact_sales AS
SELECT 
    row_id,
    order_id,
    order_date_new AS order_date,
    ship_mode,
    customer_id,
    customer_name,
    segment,
    country,
    city,
    state,
    region,
    product_id,
    category,
    sub_category,
    product_name,
    sales,
    quantity,
    discount,
    profit
FROM superstore_clean;

SELECT SUM(sales) FROM fact_sales;

SELECT 
month(order_date) AS month,
SUM(sales) AS total_sales
FROM fact_sales
GROUP BY month;

SELECT product_name, sum(Sales) AS Total_sales
FROM fact_sales
GROUP BY product_name
ORDER BY Total_sales DESC
LIMIT 10;

SELECT region, sum(sales) AS total_sales
FROM fact_sales
GROUP BY region;

SELECT discount, Sum(profit) AS total_profit
FROM fact_sales
GROUP BY discount
ORDER BY discount;

SELECT avg(discount) AS avg_discnt
FROM fact_sales;



