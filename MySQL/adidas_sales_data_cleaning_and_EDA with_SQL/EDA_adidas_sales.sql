
	/* After cleaning the sales data, I decided to conduct an exploratory data analysis (EDA) and there are several business questions 
		I am curious with, and that could provide valuable insights. */
        
SELECT * FROM sales_staging;

SELECT MIN(invoice_date), MAX(invoice_date)
FROM sales_staging;

SELECT DISTINCT(sales_method)
FROM sales_staging;

SELECT DISTINCT(retailer)
FROM sales_staging;

	/* The above query helped me know that this data was derived from the beginning of 2020 until the end of 2021, and that these are the combination of sales, made by 6 different retailers,
		from their Online, In-store and Outlet stores all over the US. */
    

-- How have total sales evolved over time (monthly,annually)?

SELECT MONTH (invoice_date) as 'month_2020', SUM(total_sales)
FROM sales_staging
WHERE YEAR(invoice_date) = 2020
GROUP BY MONTH (invoice_date)
ORDER BY MONTH (invoice_date);

SELECT MONTH (invoice_date) as 'month_2021', SUM(total_sales)
FROM sales_staging
WHERE YEAR(invoice_date) = 2021
GROUP BY MONTH (invoice_date)
ORDER BY MONTH (invoice_date);

SELECT YEAR (invoice_date) as 'year', SUM(total_sales)
FROM sales_staging
GROUP BY YEAR (invoice_date)
ORDER BY YEAR (invoice_date);

-- Which products are driving the most sales in relation to units sold?
 
WITH product_sales AS 
	 (SELECT product, SUM(units_sold) as total_units_sold
	 FROM sales_staging
	 GROUP BY product),
     product_ranking AS
     (SELECT *, DENSE_RANK() OVER (ORDER BY total_units_sold DESC)
     FROM product_sales)
SELECT *
FROM product_ranking
LIMIT 3
;

-- Which products have the highest total sales?

WITH product_sales AS 
	 (SELECT product, SUM(total_sales) as sum_sales
	 FROM sales_staging
	 GROUP BY product),
     product_ranking AS
     (SELECT *, DENSE_RANK() OVER (ORDER BY sum_sales DESC)
     FROM product_sales)
SELECT *
FROM product_ranking
LIMIT 3
;

-- What is the average price per unit for the top-selling products?

WITH product_sales AS 
	 (SELECT product, SUM(total_sales) as sum_sales
	 FROM sales_staging
	 GROUP BY product),
     product_ranking AS
     (SELECT *, DENSE_RANK() OVER (ORDER BY sum_sales DESC) as ranking
     FROM product_sales
     LIMIT 3),
	 avg_price AS
     (SELECT product, ROUND(AVG(price_per_unit_usd)) as avg_price_per_unit
     FROM sales_staging
     GROUP BY product)
SELECT pr.product, sum_sales, ranking, avg_price_per_unit
FROM product_ranking pr
JOIN avg_price ap
	ON pr.product = ap.product;

-- Which retailers generate the most sales?

WITH retailer_sales AS 
	 (SELECT retailer, SUM(total_sales) as sum_sales
	 FROM sales_staging
	 GROUP BY retailer),
     retailer_ranking AS
     (SELECT *, DENSE_RANK() OVER (ORDER BY sum_sales DESC)
     FROM retailer_sales)
SELECT *
FROM retailer_ranking
LIMIT 3;

-- Which retailer has the highest operating profit?

SELECT retailer, SUM(operating_profit)
FROM sales_staging
GROUP BY retailer
ORDER BY SUM(operating_profit) DESC
LIMIT 1;

-- What are the top-performing regions, states, and cities in terms of total sales?

WITH regional_sales AS 
	 (SELECT region, SUM(total_sales) as sum_regional_sales
	 FROM sales_staging
	 GROUP BY region),
     regional_ranking AS
     (SELECT *, DENSE_RANK() OVER (ORDER BY sum_regional_sales DESC)
     FROM regional_sales)
SELECT *
FROM regional_ranking
LIMIT 3;

WITH state_sales AS 
	 (SELECT state, SUM(total_sales) as sum_state_sales
	 FROM sales_staging
	 GROUP BY state),
     state_ranking AS
     (SELECT *, DENSE_RANK() OVER (ORDER BY sum_state_sales DESC)
     FROM state_sales)
SELECT *
FROM state_ranking
LIMIT 3;

WITH city_sales AS 
	 (SELECT city, SUM(total_sales) as sum_city_sales
	 FROM sales_staging
	 GROUP BY city),
     city_ranking AS
     (SELECT *, DENSE_RANK() OVER (ORDER BY sum_city_sales DESC)
     FROM city_sales)
SELECT *
FROM city_ranking
LIMIT 3;

-- Are there specific regions, states, or cities where certain products sell better?

WITH ranking as (
SELECT region, state, city, product, units_sold,
RANK() OVER (PARTITION BY product ORDER BY units_sold DESC) as rank_num
FROM sales_staging)
SELECT * FROM ranking
WHERE rank_num = 1;

-- Which regions, states, and cities contribute the most to overall operating profit?

SELECT MAX(operating_profit)
FROM sales_staging;

SELECT region, state, city, operating_profit
FROM sales_staging
WHERE operating_profit IN (
SELECT MAX(operating_profit)
FROM sales_staging);

-- Are there any regions, states, or cities where profitability is low or negative?

SELECT AVG(operating_profit)
FROM sales_staging;

SELECT region, state, city, operating_profit
FROM sales_staging
WHERE operating_profit < (
SELECT AVG(operating_profit)
FROM sales_staging)
ORDER BY operating_profit;

-- How does operating profit compare across different sales methods?

SELECT sales_method, ROUND(AVG(operating_profit)) as avg_operating_profit
FROM sales_staging
GROUP BY sales_method
ORDER BY avg_operating_profit DESC;

-- How does seasonality affect sales? 
        -- Winter is considered December, January and February; spring is March through May; summer is June through August; and fall or autumn is September through November.

WITH season_cte as (
	SELECT total_sales, MONTH(invoice_date) as 'month',
		CASE 
			WHEN MONTH(invoice_date) IN (12,1,2) THEN 'Winter'
			WHEN MONTH(invoice_date) IN (3,4,5) THEN 'Spring'
			WHEN MONTH(invoice_date) IN (6,7,8) THEN 'Summer'
			ELSE 'Autumn'
		END as season
	FROM sales_staging)
SELECT season, SUM(total_sales)
FROM season_cte
GROUP BY season;

-- Do different products have different seasonal trends?

WITH season_cte as (
	SELECT product, total_sales, MONTH(invoice_date) as 'month',
		CASE 
			WHEN MONTH(invoice_date) IN (12,1,2) THEN 'Winter'
			WHEN MONTH(invoice_date) IN (3,4,5) THEN 'Spring'
			WHEN MONTH(invoice_date) IN (6,7,8) THEN 'Summer'
			ELSE 'Autumn'
		END as season
	FROM sales_staging),
    sales_per_season as (
	SELECT product, season, SUM(total_sales) as sum_total_sales
	FROM season_cte
	GROUP BY product, season)
SELECT *, DENSE_RANK() OVER (PARTITION BY product ORDER BY sum_total_sales)
FROM sales_per_season
ORDER BY product, season;

-- How does the price per unit impact the number of units sold?

SELECT DISTINCT(price_per_unit_usd), ROUND(AVG(units_sold))
FROM sales_staging
GROUP BY price_per_unit_usd
ORDER BY price_per_unit_usd;

-- What are the top-selling products in each region and state?

WITH region_product_sales AS (
	SELECT region, product, SUM(total_sales) as total_of_sales
	FROM sales_staging
	GROUP BY region, product),
    ranking AS(
	SELECT *, DENSE_RANK() OVER (PARTITION BY region ORDER BY total_of_sales DESC) as rank_num
	FROM region_product_sales)
SELECT *
FROM ranking
WHERE rank_num = 1;

WITH state_product_sales AS (
	SELECT state, product, SUM(total_sales) as total_of_sales
	FROM sales_staging
	GROUP BY state, product),
    ranking AS(
	SELECT *, DENSE_RANK() OVER (PARTITION BY state ORDER BY total_of_sales DESC) as rank_num
	FROM state_product_sales)
SELECT *
FROM ranking
WHERE rank_num = 1;

-- Is there a significant difference in the average price per unit across regions?

WITH average_per_region AS (
	SELECT region, ROUND(AVG(price_per_unit_usd)) as avg_price_per_unit
	FROM sales_staging
	GROUP BY region),
    regional_average AS (
    SELECT *, AVG(avg_price_per_unit) OVER () as overall_average_price
    FROM average_per_region)
SELECT *, (avg_price_per_unit - overall_average_price) AS difference
FROM regional_average;

-- How do sales methods vary across regions, states, and cities?

WITH region_sales_method AS (
	SELECT region, sales_method, SUM(total_sales) as total_of_sales
	FROM sales_staging
	GROUP BY region, sales_method),
    ranking AS(
	SELECT *, DENSE_RANK() OVER (PARTITION BY region ORDER BY total_of_sales DESC) as rank_num
	FROM region_sales_method)
SELECT *
FROM ranking;

WITH state_sales_method AS (
	SELECT state, sales_method, SUM(total_sales) as total_of_sales
	FROM sales_staging
	GROUP BY state, sales_method),
    ranking AS(
	SELECT *, DENSE_RANK() OVER (PARTITION BY state ORDER BY total_of_sales DESC) as rank_num
	FROM state_sales_method)
SELECT *
FROM ranking;

WITH city_sales_method AS (
	SELECT city, sales_method, SUM(total_sales) as total_of_sales
	FROM sales_staging
	GROUP BY city, sales_method),
    ranking AS(
	SELECT *, DENSE_RANK() OVER (PARTITION BY city ORDER BY total_of_sales DESC) as rank_num
	FROM city_sales_method)
SELECT *
FROM ranking;


SELECT * FROM sales_staging;

-- END



