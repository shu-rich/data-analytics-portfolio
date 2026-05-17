-- This query pulls for each status and the total accounts within the funnel. The output dataset was imported into Tableau to make the visualization.

WITH trial AS (
  SELECT subscription_id,
  account_id
  FROM saas_subscription.subscriptions
  WHERE is_trial = TRUE
),

usage AS (
  SELECT usage.subscription_id,
    SUM(usage_count) total_usage_count,
    SUM(usage_duration_secs) total_usage_duration_secs
  FROM saas_subscription.feature_usage usage
    JOIN trial USING(subscription_id)
  GROUP BY usage.subscription_id
),

support AS (
  SELECT sp.account_id,
    ticket_id,
    satisfaction_score
  FROM saas_subscription.support_tickets sp
    JOIN trial USING(account_id)
),

activated AS (
  SELECT sub.subscription_id
  FROM saas_subscription.subscriptions sub
    JOIN trial USING(subscription_id)
  WHERE sub.upgrade_flag = TRUE
),

churned AS (
  SELECT sub.subscription_id
  FROM saas_subscription.subscriptions sub
    JOIN trial USING(subscription_id)
  WHERE sub.churn_flag = TRUE
),

steps AS (
  SELECT 'Trial' step, COUNT(DISTINCT subscription_id) total FROM trial
  UNION ALL
  SELECT 'Feature Used' step, COUNT(DISTINCT subscription_id) total FROM usage
  UNION ALL
  SELECT 'Support Requested' step, COUNT(DISTINCT account_id) total FROM support
  UNION ALL
  SELECT 'Support Rated' step, COUNT(DISTINCT account_id) total FROM support WHERE satisfaction_score IS NOT NULL
  UNION ALL
  SELECT 'Activated' step, COUNT(DISTINCT subscription_id) total FROM activated
)

SELECT step,
  total,
  ROUND(total / lag(total, 1) OVER(ORDER BY total DESC), 2) conversion
FROM steps;