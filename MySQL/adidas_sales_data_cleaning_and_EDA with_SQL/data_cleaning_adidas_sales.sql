CREATE DATABASE adidas_sales;
USE adidas_sales;

CREATE TABLE sales (
retailer VARCHAR(50) NULL,
retailer_id INT NULL,
invoice_date DATE NULL,
region VARCHAR(50) NULL,
state VARCHAR(50) NULL,
city VARCHAR(50) NULL,
product VARCHAR(100) NULL,
price_per_unit_usd DOUBLE NULL,
units_sold INT NULL,
total_sales DOUBLE NULL,
operating_profit DOUBLE NULL,
sales_method VARCHAR(50) NULL
);

SELECT * FROM sales;

	/* To import the table data more efficiently, I used this command */

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/raw_adidas_sales_data.csv'
INTO TABLE sales
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

	/* While importing, I encountered an error where it did not accept null values,so modified that specific column */

ALTER TABLE sales 
MODIFY COLUMN 
price_per_unit_usd INT NULL;

	/* Another error,so I temporarily set the data type like this, and all the data had been successfully imported */

ALTER TABLE sales 
MODIFY COLUMN 
price_per_unit_usd VARCHAR(50) NULL;

	/* When cleaning data, ensure you have a backup as this is crucial in case something goes wrong. so, I created a staging table */
    
CREATE TABLE sales_staging
LIKE sales;

INSERT sales_staging
SELECT * FROM sales;
    
SELECT * FROM sales_staging;

	/* 1) Remove Duplicates, if any */

WITH duplicates as (
SELECT *,
ROW_NUMBER () OVER (PARTITION BY retailer, retailer_id, invoice_date, region, state, city, product, price_per_unit_usd, units_sold, total_sales, operating_profit, sales_method) as row_num
FROM sales_staging)
SELECT *
FROM duplicates
WHERE row_num > 1
;

	/* There are no duplicates */
    
	/* 2) Standardize data and fix any errors 
       3) Remove or fill-in nulls or blank data  */
    
    
 SELECT DISTINCT(retailer)
 FROM sales_staging
 ORDER BY retailer;
 
 SELECT DISTINCT(retailer_id)
 FROM sales_staging
 ORDER BY retailer_id;
 
 SELECT DISTINCT(invoice_date)
 FROM sales_staging
 ORDER BY invoice_date;
 
 SELECT DISTINCT(region)
 FROM sales_staging
 ORDER BY region;
 
 SELECT DISTINCT(state)
 FROM sales_staging
 ORDER BY state;
 
 SELECT DISTINCT(city)
 FROM sales_staging
 ORDER BY city;
 
 SELECT DISTINCT(product)
 FROM sales_staging
 ORDER BY product;
 
	/* saw that one product name was misspelled making it look like a distinct one where it was just the same with those that are correctly spelled. To fix it, I wrote a command like this */

SELECT product
FROM sales_staging
WHERE product = "Men's aparel";  

UPDATE sales_staging
SET product = "Men's Apparel"
WHERE product = "Men's aparel"; 

SELECT DISTINCT(price_per_unit_usd)
FROM sales_staging
ORDER BY price_per_unit_usd;
	/* saw here that there's a blank field, so I'm gonna go back at that later and will fix it */

SELECT DISTINCT(total_sales)
FROM sales_staging
ORDER BY total_sales;

SELECT DISTINCT(operating_profit)
FROM sales_staging
ORDER BY operating_profit;
	/* saw here that there's a blank field, so I'm gonna go back at that later and will fix it */
    
SELECT DISTINCT(sales_method)
FROM sales_staging
ORDER BY sales_method;

	/* Then, I checked the data types of each column and saw that the price_per_unit_usd column data type is incorrect, which I intentionally changed while importing the database, so now is the time to convert it */

ALTER TABLE sales_staging
MODIFY price_per_unit_usd DOUBLE;
	/* I'm still getting the same error in same particular row 6726, so I'll have to check it */
   
SELECT *
FROM sales_staging
ORDER BY retailer_id
LIMIT 10 OFFSET 6720;

	/* Upon further investigation, I think I need to fix the blank values on this particular column which I discovered while looking duplicates previously */

SELECT *
FROM sales_staging
WHERE price_per_unit_usd IN (NULL, '');
	/* confirmed that it can be populated based on other available data */

	/* used cte to test out the result first before making an update */
 WITH blank AS (
	SELECT *
	FROM sales_staging
	WHERE price_per_unit_usd IN (NULL, ''))
SELECT *,
		CASE 
			WHEN price_per_unit_usd = '' THEN ( total_sales / units_sold )
		END AS test_ppu
FROM blank;

UPDATE sales_staging
SET price_per_unit_usd =
	CASE 
		WHEN price_per_unit_usd = '' THEN ( total_sales / units_sold )
	END
WHERE price_per_unit_usd IN (NULL, '');

	/* Now, that it's filled, I'll try to change the data type of price_per_unit_usd again */
    
ALTER TABLE sales_staging
MODIFY price_per_unit_usd DOUBLE;

	/* remove unnecessary column or rows */
    
SELECT *
FROM sales_staging
WHERE	retailer = ''		
        OR retailer_id = ''
        OR region = ''
        OR state = ''
        OR city = ''
        OR product = ''
        OR price_per_unit_usd = ''
        OR units_sold = ''
		OR total_sales = ''
        OR Operating_profit = ''
        OR Sales_method = '';
			/* discovered 4 rows with no value for units sold and operating profit so it's safe to consider it not useful for analysis */
          
DELETE
FROM sales_staging
WHERE	 units_sold = ''
        AND Operating_profit = '';
        

SELECT * FROM sales_staging;


-- END







