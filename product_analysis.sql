-- PRODUCT ANALYSIS

-- Product-Level Sales Analysis

SELECT 
	YEAR(created_at) AS year,
	MONTH(created_at) AS month,
	COUNT(DISTINCT order_id) AS orders,
	SUM(price_usd) AS total_revenue,
	SUM(price_usd - cogs_usd) AS total_margin
FROM orders 
WHERE created_at < '2013-01-04'
GROUP BY year, month;

-- Product Launch Sales Analysis

SELECT 
	YEAR(ws.created_at) AS year,
	MONTH(ws.created_at) AS month,
	COUNT(DISTINCT o.order_id) AS orders,
	COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS conv_rate,
	SUM(o.price_usd)/COUNT(DISTINCT ws.website_session_id) AS revenue_per_session,
	COUNT(DISTINCT CASE WHEN o.primary_product_id = 1 THEN o.order_id ELSE NULL END) AS product_one_sales,
	COUNT(DISTINCT CASE WHEN o.primary_product_id = 2 THEN o.order_id ELSE NULL END) AS product_two_sales
FROM website_sessions ws 
LEFT JOIN orders o 
	USING (website_session_id)
WHERE ws.created_at BETWEEN '2012-04-01' AND '2013-04-05'
GROUP BY year, month;