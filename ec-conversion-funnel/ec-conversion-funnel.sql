-- Conversion rate by stage
WITH funnel AS (
  SELECT COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS total_page_view,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS total_add_to_cart,
    COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS total_checkout_start,
    COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS total_payment_info,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS total_purchase 
  FROM `ecommerce.u_event`
  WHERE DATE(event_date) BETWEEN '2025-12-01' AND '2026-02-28'
)

SELECT total_page_view,
  total_add_to_cart,
  ROUND(total_add_to_cart * 100 / total_page_view,1) AS conversion_to_cart,
  total_checkout_start,
  ROUND(total_checkout_start * 100 / total_add_to_cart,1) AS conversion_to_checkout,
  total_payment_info,
  ROUND(total_payment_info * 100 / total_checkout_start,1) AS conversion_to_payment,
  total_purchase,
  ROUND(total_purchase * 100 / total_payment_info,1) AS conversion_to_purchase,
  ROUND(total_purchase * 100 / total_page_view,1) AS conversion_total
FROM funnel;

-- Purchase rate by source
WITH traffic_src AS (
  SELECT traffic_source,
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS total_page_view,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS total_add_to_cart,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS total_purchase 
  FROM `ecommerce.u_event`
  WHERE DATE(event_date) BETWEEN '2025-12-01' AND '2026-02-28'
  GROUP BY 1
)

SELECT traffic_source,
  ROUND(total_page_view * 100 / (SELECT SUM(total_page_view) FROM traffic_src),1) AS pct_traffic,
  total_page_view,
  total_add_to_cart,
  ROUND(total_add_to_cart * 100 / total_page_view,1) AS conversion_to_cart,
  total_purchase,
  ROUND(total_purchase * 100 / total_add_to_cart,1) AS conversion_to_purchase,
  ROUND(total_purchase * 100 / total_page_view,1) AS conversion_rate,
FROM traffic_src;

-- Average shopping time
WITH user_journey AS (
  SELECT user_id,
    MIN(CASE WHEN event_type = 'page_view' THEN event_date END) AS time_page_view,
    MIN(CASE WHEN event_type = 'add_to_cart' THEN event_date END) AS time_add_to_cart,
    MIN(CASE WHEN event_type = 'purchase' THEN event_date END) AS time_purchase 
  FROM `ecommerce.u_event`
  WHERE DATE(event_date) BETWEEN '2025-12-01' AND '2026-02-28'
  GROUP BY 1
  HAVING MIN(CASE WHEN event_type = 'purchase' THEN event_date END) IS NOT NULL
)

SELECT COUNT(1) AS total_purchase,
  ROUND(AVG(TIMESTAMP_DIFF(time_add_to_cart, time_page_view, MINUTE)),1) AS avg_to_cart,
  ROUND(AVG(TIMESTAMP_DIFF(time_purchase, time_add_to_cart, MINUTE)),1) AS avg_to_purchase,
  ROUND(AVG(TIMESTAMP_DIFF(time_purchase, time_page_view, MINUTE)),1) AS avg_shopping_time
FROM user_journey;

-- Revenue by user
WITH revenue AS (
  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS total_visitor,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS total_buyer,
    SUM(CASE WHEN event_type = 'purchase' THEN amount END) AS total_revenue,
    COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) AS total_order
  FROM `ecommerce.u_event`
  WHERE DATE(event_date) BETWEEN '2025-12-01' AND '2026-02-28'
)

SELECT total_visitor,
  total_buyer,
  ROUND(total_revenue, 2) AS total_revenue,
  total_order,
  ROUND(total_revenue / total_buyer,2) AS revenue_per_buyer,
  ROUND(total_revenue / total_order,2) AS revenue_per_order,
  ROUND(total_revenue / total_visitor,2) AS revenue_per_visitor
FROM revenue;
