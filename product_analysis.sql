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

-- Building Product-Level Conversion Funnels

DROP TEMPORARY TABLE IF EXISTS conversion_funnel;

CREATE TEMPORARY TABLE conversion_funnel
WITH product_page AS
(
	SELECT 
		website_session_id,
		website_pageview_id,
		pageview_url AS product_viewed
	FROM website_pageviews 
	WHERE created_at BETWEEN '2013-01-06' AND '2013-04-10'
		AND pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear')
),
find_next_url AS 
(
	SELECT DISTINCT
		wp.pageview_url 
	FROM product_page pp
	JOIN website_pageviews wp
		ON wp.website_session_id = pp.website_session_id
			AND wp.website_pageview_id > pp.website_pageview_id
),
next_pageviews AS 
(
	SELECT 
		pp.website_session_id,
		pp.product_viewed,
		CASE WHEN wp.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
		CASE WHEN wp.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
		CASE WHEN wp.pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
		CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
	FROM product_page pp
	LEFT JOIN website_pageviews wp 
		ON wp.website_session_id = pp.website_session_id
			AND wp.website_pageview_id > pp.website_pageview_id
	ORDER BY pp.website_session_id, wp.created_at
),
sessions_made_it AS 
(
	SELECT 
		website_session_id,
		CASE 
			WHEN product_viewed = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
			WHEN product_viewed = '/the-forever-love-bear' THEN 'lovebear'
		END AS product_seen,
		MAX(cart_page) AS cart_made_it,
		MAX(shipping_page) AS shipping_made_it,
		MAX(billing_page) AS billing_made_it,
		MAX(thankyou_page) AS thankyou_made_it
	FROM next_pageviews
	GROUP BY website_session_id, product_seen
)
SELECT 
	product_seen,
	COUNT(DISTINCT website_session_id) AS sessions_count,
	COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart_count,
	COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping_count,
	COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing_count,
	COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou_count
FROM sessions_made_it
GROUP BY product_seen;

SELECT 
	*
FROM conversion_funnel;

SELECT
	product_seen,
	to_cart_count / sessions_count AS products_clickthrough_rt,
	to_shipping_count / to_cart_count AS cart_clickthrough_rt,
	to_billing_count / to_shipping_count AS shipping_clickthrough_rt,
	to_thankyou_count / to_billing_count AS billing_clickthrough_rt
FROM conversion_funnel;

-- Cross-Sell Analysis

WITH cart_pageviews AS
(
	SELECT 
		website_session_id,
		website_pageview_id,
		CASE 
			WHEN created_at < '2013-09-25' THEN 'A.pre_cross_sell'
			WHEN created_at >= '2013-09-25' THEN 'B.post_cross_sell'
		END AS time_period
	FROM website_pageviews 
	WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25'
		AND pageview_url = '/cart'
),
next_pageview_id AS 
(
	SELECT 
		cp.time_period,
		cp.website_session_id,
		MIN(wp.website_pageview_id) AS min_next_pageview_id
	FROM cart_pageviews cp
	LEFT JOIN website_pageviews wp 
		ON cp.website_session_id = wp.website_session_id 
			AND wp.website_pageview_id > cp.website_pageview_id
	GROUP BY cp.time_period, cp.website_session_id
)
SELECT 
	npi.time_period,
	COUNT(DISTINCT npi.website_session_id) AS cart_sessions,
	COUNT(DISTINCT npi.min_next_pageview_id) AS clickthroughs,
	COUNT(DISTINCT npi.min_next_pageview_id)/COUNT(DISTINCT npi.website_session_id) AS cart_ctr,
	SUM(o.items_purchased)/COUNT(DISTINCT o.order_id) AS products_per_order,
	SUM(o.price_usd)/COUNT(DISTINCT o.order_id) AS aov,
	SUM(o.price_usd)/COUNT(DISTINCT npi.website_session_id) AS revenue_per_cart_session
FROM next_pageview_id npi
LEFT JOIN orders o
	USING (website_session_id)
GROUP BY npi.time_period;

-- Product Portfolio Expansion

SELECT
	CASE 
		WHEN ws.created_at < '2013-12-12' THEN 'A.pre_birthday_bear'
		WHEN ws.created_at >= '2013-12-12' THEN 'B.post_birthday_bear'
	END AS time_period,
	COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS conv_rate,
	SUM(o.price_usd)/COUNT(DISTINCT o.order_id) AS aov,
	SUM(o.items_purchased)/COUNT(DISTINCT o.order_id) AS products_per_order,
	SUM(o.price_usd)/COUNT(DISTINCT ws.website_session_id) AS revenue_per_session
FROM website_sessions ws 
LEFT JOIN orders o 
	USING (website_session_id)
WHERE ws.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY time_period;

-- More detailed approach:

WITH sessions AS
(
	SELECT 
		DISTINCT website_session_id,
		CASE 
			WHEN created_at < '2013-12-12' THEN 'A.pre_birthday_bear'
			WHEN created_at >= '2013-12-12' THEN 'B.post_birthday_bear'
		END AS time_period
	FROM website_sessions
	WHERE created_at BETWEEN '2013-11-12' AND '2014-01-12'
),
product_sessions AS 
(
	SELECT 
		s.website_session_id,
		o.order_id,
		AVG(o.price_usd) AS aov_session,
		AVG(o.items_purchased) AS products_count,
		SUM(o.price_usd) AS revenue_session
	FROM sessions s
	JOIN orders o 
		USING (website_session_id)
	GROUP BY s.website_session_id, o.order_id
)
SELECT 
	s.time_period,
	COUNT(DISTINCT ps.order_id)/COUNT(DISTINCT s.website_session_id) AS conv_rate,
	AVG(ps.aov_session) AS aov,
	AVG(ps.products_count) AS products_per_order,
	SUM(ps.revenue_session)/COUNT(DISTINCT s.website_session_id) AS revenue_per_session
FROM sessions s
LEFT JOIN product_sessions ps 
	USING (website_session_id)
GROUP BY s.time_period;