-- 1. What is the relationship between social media usage patterns and sleep behavior, including sleep duration, sleep quality, and nighttime usage?
WITH t_ranked AS (
  SELECT
    user_id,
    PERCENT_RANK() OVER(
      PARTITION BY age_group
      ORDER BY
        daily_screen_time_hours
    ) AS p_daily_screen_time_hours,
    sleep_hours
  FROM
    `socialmedia.mentalhealth`
)
SELECT
  CASE
    WHEN tr.p_daily_screen_time_hours >= 0.9 THEN "p90"
    WHEN tr.p_daily_screen_time_hours >= 0.7 THEN "p70"
    WHEN tr.p_daily_screen_time_hours >= 0.5 THEN "p50"
    WHEN tr.p_daily_screen_time_hours >= 0.2 THEN "p20"
    ELSE "Below p20"
  END AS rank_daily_screentime,
  ROUND(AVG(mh.sleep_hours), 1) AS avg_sleep_hours,
  ROUND(AVG(mh.sleep_quality_score), 1) AS avg_sleep_quality_score,
  ROUND(AVG(mh.notification_checks_per_day), 1) AS avg_notificationchecks,
  ROUND(SUM(CASE WHEN mh.uses_social_media_before_bed THEN 1 ELSE 0 END) / COUNT(1), 2) AS p_uses_before_bed,
  ROUND(AVG(mh.anxiety_score), 1) AS avg_anxiety_score,
  ROUND(AVG(mh.depression_score), 1) AS avg_depression_score,
  ROUND(AVG(mh.stress_score), 1) AS avg_stress_score
FROM
  t_ranked tr
  JOIN `socialmedia.mentalhealth` mh USING(user_id)
GROUP BY
  1
ORDER BY
  1;

-- Average Score by Healthy vs. Mental issues
-- 1. Does higher daily social media usage correlate with higher anxiety, depression, or stress scores?
-- 1. How strongly is cyberbullying exposure associated with anxiety, depression, stress, or reduced sleep quality?
SELECT
  CASE
    WHEN mental_health_issue THEN "Has mental issues"
    ELSE "Healthy"
  END AS mental_status,
  ROUND(AVG(daily_screen_time_hours), 1) AS avg_daily_screen_time_hours,
  ROUND(AVG(notification_checks_per_day), 1) AS avg_notification_checks_per_day,
  ROUND(AVG(sleep_hours), 1) AS avg_sleep_hours,
  ROUND(AVG(sleep_quality_score), 1) AS avg_sleep_quality_score,
  ROUND(AVG(anxiety_score), 1) AS avg_anxiety_score,
  ROUND(AVG(depression_score), 1) AS avg_depression_score,
  ROUND(AVG(stress_score), 1) AS avg_stress_score,
  ROUND(SUM(CASE WHEN cyberbullying_exposure THEN 1 ELSE 0 END) / COUNT(1), 2) AS p_cyberbullying_exposure,
  ROUND(SUM(CASE WHEN primary_platform = "X/Twitter" THEN 1 ELSE 0 END) / COUNT(1), 2) AS p_XTwitter,
  ROUND(SUM(CASE WHEN primary_platform = "Snapchat" THEN 1 ELSE 0 END) / COUNT(1), 2) AS p_Snapchat,
  ROUND(SUM(CASE WHEN primary_platform = "Instagram" THEN 1 ELSE 0 END) / COUNT(1), 2) AS p_Instagram,
  ROUND(SUM(CASE WHEN primary_platform = "TikTok" THEN 1 ELSE 0 END) / COUNT(1), 2) AS p_TikTok,
  ROUND(SUM(CASE WHEN primary_platform = "Facebook" THEN 1 ELSE 0 END) / COUNT(1), 2) AS p_Facebook,
  ROUND(SUM(CASE WHEN primary_platform = "YouTube" THEN 1 ELSE 0 END) / COUNT(1), 2) AS p_YouTube,
  ROUND(SUM(CASE WHEN primary_platform = "Reddit" THEN 1 ELSE 0 END) / COUNT(1), 2) AS p_Reddit,
  ROUND(SUM(CASE WHEN trusted_support_system THEN 1 ELSE 0 END) / COUNT(1), 2) AS p_trusted_support_exist
FROM
  `socialmedia.mentalhealth`
GROUP BY
1;

-- Night checking frequency
SELECT
  night_checking_frequency,
  ROUND(AVG(daily_screen_time_hours), 1) AS avg_screentime,
  ROUND(AVG(notification_checks_per_day), 1) AS avg_notificationchecks,
  ROUND(SUM(CASE WHEN uses_social_media_before_bed THEN 1 ELSE 0 END) / COUNT(1), 2) AS p_uses_before_bed,
  ROUND(AVG(sleep_hours), 1) AS avg_sleephour,  -- 1.6h (21.6%) diff
  ROUND(AVG(sleep_quality_score), 1) AS avg_sleepquality,  -- 17.1 diff
  ROUND(AVG(anxiety_score), 1) AS avg_anxiety,  -- 2x
  ROUND(AVG(depression_score), 1) AS avg_depression,  -- 34.8 diff
  ROUND(AVG(stress_score), 1) AS avg_stress
FROM
  `socialmedia.mentalhealth`
GROUP BY
  1;

-- 1. How do mental health issue rates compare between the overall population and users with protective habits, such as regular exercise, social media detox, or limited screen time?
-- 1. Can historical trends be used to forecast future mental health risk levels, and which behavioral changes could help reduce the number of high-risk individuals?
SELECT
  CASE
    WHEN age <= 13 THEN "Gen A"
    WHEN age <= 29 THEN "Gen Z"
    WHEN age <= 45 THEN "Millennials"
    WHEN age <= 61 THEN "Gen X"
    ELSE "Boomers+"
  END AS gen_cohorts,
  format_date("%Y", survey_date) AS timeline,
  ROUND(SUM(CASE WHEN mental_health_issue THEN 1 ELSE 0 END) / COUNT(1), 2) AS p_mental_health_issue,
  ROUND(SUM(CASE WHEN social_media_detox_habit THEN 1 ELSE 0 END) / COUNT(1), 2) AS p_social_media_detox_habit,
  ROUND(SUM(CASE WHEN limited_screen_time_habit THEN 1 ELSE 0 END) / COUNT(1), 2) AS p_limited_screen_time_habit,
  ROUND(SUM(CASE WHEN trusted_support_system THEN 1 ELSE 0 END) / COUNT(1), 2) AS p_trusted_support_system
FROM
  `socialmedia.mentalhealth`
GROUP BY
1, 2;

-- 1. Which platforms or content types show the strongest association with stress, anxiety, depression, or sleep disruption?
SELECT
  primary_content_type,
  ROUND(AVG(sleep_hours), 1) AS avg_sleep_hours,
  ROUND(AVG(sleep_quality_score), 1) AS avg_sleep_quality_score,
  ROUND(AVG(anxiety_score), 1) AS avg_anxiety_score,
  ROUND(AVG(depression_score), 1) AS avg_depression_score,
  ROUND(AVG(stress_score), 1) AS avg_stress_score,
  MAX(anxiety_score) AS max_anxiety_score,
  MAX(depression_score) AS max_depression_score,
  MAX(stress_score) AS max_stress_score
FROM
  `socialmedia.mentalhealth`
GROUP BY
  1
ORDER BY
  avg_depression_score DESC;
