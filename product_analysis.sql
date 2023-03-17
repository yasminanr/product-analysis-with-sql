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

-- Product-Level Website Pathing

WITH product_pageviews AS
(
	SELECT 
		website_session_id,
		website_pageview_id,
		created_at,
		CASE 
			WHEN created_at < '2013-01-06' THEN 'A.prelaunch_product_2'
			WHEN created_at > '2013-01-06' THEN 'B.postlaunch_product_2'
			ELSE 'check logic'
		END AS time_period
	FROM website_pageviews 
	WHERE created_at BETWEEN '2012-10-06' AND '2013-04-06'
		AND pageview_url = '/products'
),
next_pageview_id AS 
(
	SELECT 
		pp.time_period,
		pp.website_session_id,
		MIN(wp.website_pageview_id) AS min_next_pageview_id
	FROM product_pageviews pp
	LEFT JOIN website_pageviews wp 
		ON pp.website_session_id = wp.website_session_id 
			AND wp.website_pageview_id > pp.website_pageview_id
	GROUP BY pp.time_period, pp.website_session_id
),
next_pageview_url AS 
(
	SELECT 
		npi.time_period,
		npi.website_session_id,
		wp.pageview_url AS next_pageview_url
	FROM next_pageview_id npi
	LEFT JOIN website_pageviews wp
		ON npi.min_next_pageview_id = wp.website_pageview_id
)
SELECT 
	time_period,
	COUNT(DISTINCT website_session_id) AS sessions_count,
	COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS with_next_page,
	COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END)/
		COUNT(DISTINCT website_session_id) AS pct_with_next_page,
	COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
	COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END)/
		COUNT(DISTINCT website_session_id) AS pct_to_mrfuzzy,
	COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS to_lovebear,
	COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END)/
		COUNT(DISTINCT website_session_id) AS pct_to_lovebear
FROM next_pageview_url
GROUP BY time_period
ORDER BY time_period;