# CREATE DATABASE New_Database;
USE New_Database;

# CREATE RAW STAGING TABLE
CREATE TABLE superstore_raw (
Row_ID INT, 
Order_ID VARCHAR(50), 
Order_Date VARCHAR(50), 
Ship_Date VARCHAR(50), 
Ship_Mode VARCHAR(50), 
Customer_ID VARCHAR(50), 
Customer_Name VARCHAR(100), 
Segment VARCHAR(50), 
Country VARCHAR(50), 
City VARCHAR(50), 
State VARCHAR(50), 
Postal_Code VARCHAR(20), 
Region VARCHAR(50), 
Product_ID VARCHAR(50), 
Category VARCHAR(50), 
Sub_Category VARCHAR(50), 
Product_Name TEXT, 
Sales DECIMAL(10,2), 
Quantity INT, 
Discount DECIMAL(5,2), 
Profit DECIMAL(10,2)
);

# DATA CLEANING
# Checking data
SELECT * FROM superstore_raw LIMIT 10;

# Checking NULL values
SELECT count(*),
COUNT(order_id) as orders_count,
count(Customer_id) as customer_count
FROM superstore_raw;

# Identifying duplicates
SELECT order_ID, Product_ID, count(*)
FROM superstore_raw
GROUP BY Order_ID, Product_ID
HAVING count(*) > 1;

# Checking Duplicates before Removing
SELECT Row_ID, Order_ID, Product_ID
FROM superstore_raw
WHERE Row_ID NOT IN (SELECT min(Row_ID)
						FROM superstore_raw
						GROUP BY Order_ID, Product_ID
                        );

# Removing duplicates
DELETE FROM superstore_raw
WHERE Row_ID NOT IN ( SELECT * 
					   FROM (
							 SELECT MIN(Row_ID)
							 FROM superstore_raw
							 GROUP BY Order_ID, Product_ID
							 ) t 
);

# CREATE NEW CLEAN TABLE
CREATE TABLE superstore_clean AS 
		SELECT * FROM ( 
                SELECT *,
				ROW_NUMBER() OVER (PARTITION BY order_id, product_id ORDER BY row_id) AS rn
				FROM superstore_raw) t 
		WHERE rn = 1;
                                            
SELECT * FROM superstore_clean LIMIT 5;

UPDATE superstore_clean
SET Order_id = trim(Order_id), 
	ship_date = trim(ship_date),
	customer_name = trim(customer_name),
    segment = trim(segment),
    country = trim(country),
    city = trim(city),
    state = trim(state),
    region = trim(region),
    category  = trim(category),
    sub_category = trim(sub_category),
    product_name = trim(product_name),
    ship_mode = trim(ship_mode);

# Adding new Date column and kept original untouched    
ALTER TABLE superstore_clean
ADD COLUMN order_date_new DATE;

# Changing Date type into proper DATE format
UPDATE superstore_clean
SET order_date_new = str_to_date(order_date, '%m\%d\%Y');

UPDATE superstore_clean
SET order_date_new = 
CASE
	WHEN order_date LIKE '%/%' THEN str_to_date(order_date, '%m/%d/%Y')
	WHEN order_date LIKE '%-%' THEN str_to_date(order_date, '%m-%d-%Y')
    ELSE order_date
END;

SELECT * FROM superstore_clean LIMIT 5;

# CREATE FINAL TABLE (FACT TABLE)
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
      postal_code, 
      region, 
      product_id, 
      category, 
      sub_category, 
      product_name, 
      sales, 
      quantity, 
      discount, 
      profit
FROM superstore_clean
ORDER BY row_id;

SELECT * FROM fact_sales;

# Monthly Sales
SELECT month(order_date) as Month, sum(sales) AS Total_Sales
FROM fact_sales
GROUP BY month
ORDER BY Total_Sales DESC;

# Top 10 Products
SELECT product_name, sum(sales) AS total_sales
FROM fact_sales
GROUP BY product_name
ORDER BY total_sales DESC
LIMIT 10;

# Sales By Region
SELECT region, sum(sales) AS total_sales
FROM fact_sales
GROUP BY region;

# Discount Impact
SELECT discount, sum(profit) AS total_profit
FROM fact_sales
GROUP BY discount
ORDER BY discount;

# Total Average sales
SELECT avg(sales) AS Avg_sales
FROM fact_sales;

# Total Sales
SELECT SUM(sales) 
FROM fact_sales;

# Total profit
SELECT SUM(profit) 
FROM fact_sales;	

# Average Discount
SELECT avg(discount)
FROM fact_sales ;

# No.of Unique Orders
SELECT count(DISTINCT order_id)
FROM fact_sales;

# Region wise Lowest sales
SELECT region,  min(sales) AS min_sales
FROM fact_sales 
GROUP BY region
ORDER BY min_sales;

# Last 6 months Total sales
SELECT month(order_date) as month, 
			sum(sales) as total_sales, 
            (SELECT sum(sales) 
            FROM fact_sales
			WHERE month(order_date) BETWEEN 7 AND 12) as whole_sum
FROM fact_sales
GROUP BY month
HAVING month BETWEEN 7 AND 12;

# Total last 6 months sales
SELECT sum(sales) as total_sales
FROM fact_sales 
WHERE month(order_date) BETWEEN 7 AND 12;



