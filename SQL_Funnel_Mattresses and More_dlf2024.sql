/* 1. Build funnel from a single table. */
/* Inspect survey_responses table */
SELECT * FROM survey_responses LIMIT 10;

/* Count the number of distinct user_id who answered each question_text */
SELECT question_text,
COUNT(DISTINCT user_id) AS 'user_count'
FROM survey_responses
GROUP BY question_text;
/*  Questions 2 and 4 have high completion rates, but Questions 3 and 5 have lower rates. */

/* Inspect onboarding_modals table */
SELECT * FROM onboarding_modals LIMIT 10;

/* Count the number of distinct user_id‘s for each value of modal_text */
SELECT modal_text,
COUNT(DISTINCT user_id) AS 'user_count'
FROM onboarding_modals
GROUP BY modal_text;

/* 2. Compare Funnels For A/B (control/variant) Tests. */
/* Count the number of distinct user_id‘s from the control group for each value of modal_text */
SELECT modal_text,
  COUNT(DISTINCT CASE
    WHEN ab_group = 'control' THEN user_id
    END) AS 'control_clicks'
FROM onboarding_modals
GROUP BY 1
ORDER BY 1;

/* Add an additional column to your previous query that counts the number of clicks from the variant group and alias it as ‘variant_clicks’. */
SELECT modal_text,
  COUNT(DISTINCT CASE
    WHEN ab_group = 'control' THEN user_id
    END) AS control_clicks,
    COUNT(DISTINCT CASE
    WHEN ab_group = 'variant' THEN user_id
    END) AS variant_clicks
FROM onboarding_modals
GROUP BY modal_text
ORDER BY modal_text;
/* variant has greater completion rates. */

/* 3. Build a Funnel from Multiple Tables. */
/* Inspect  browse, checkout, and purchase tables */
SELECT * FROM browse LIMIT 10;
SELECT * FROM checkout LIMIT 10;
SELECT * FROM purchase LIMIT 10;

/* Merge all 3 tables */
SELECT *
FROM browse AS 'b'
LEFT JOIN checkout AS 'c'
  ON c.user_id = b.user_id
LEFT JOIN purchase AS 'p'
  ON p.user_id = c.user_id
LIMIT 50;

/* Select relevant columns and rename them */
SELECT DISTINCT b.browse_date,
   b.user_id,
   c.user_id IS NOT NULL AS 'is_checkout',
   p.user_id IS NOT NULL AS 'is_purchase'
FROM browse AS 'b'
LEFT JOIN checkout 'c'
  ON c.user_id = b.user_id
LEFT JOIN purchase 'p'
  ON p.user_id = c.user_id
LIMIT 50;

/* 4. Coversion rate */
/* Add a WITH statement to compute conversion rate */
WITH funnels AS (
  SELECT DISTINCT b.browse_date,
     b.user_id,
     c.user_id IS NOT NULL AS 'is_checkout',
     p.user_id IS NOT NULL AS 'is_purchase'
  FROM browse AS 'b'
  LEFT JOIN checkout AS 'c'
    ON c.user_id = b.user_id
  LEFT JOIN purchase AS 'p'
    ON p.user_id = c.user_id)
SELECT COUNT(*) AS 'num_browse',
SUM(is_checkout) AS 'num_checkout',
SUM(is_purchase) AS 'num_purchase',
1.0 * SUM(is_checkout) / COUNT(user_id) AS 'checkout_perc',
1.0 * SUM(is_purchase) / SUM(is_checkout) AS 'purchase_perc'
FROM funnels;

/* Modify the funnel to obtain conversion rates per browse_date */
WITH funnels AS (
  SELECT DISTINCT b.browse_date,
     b.user_id,
     c.user_id IS NOT NULL AS 'is_checkout',
     p.user_id IS NOT NULL AS 'is_purchase'
  FROM browse AS 'b'
  LEFT JOIN checkout AS 'c'
    ON c.user_id = b.user_id
  LEFT JOIN purchase AS 'p'
    ON p.user_id = c.user_id)
SELECT browse_date,
   COUNT(*) AS 'num_browse',
   SUM(is_checkout) AS 'num_checkout',
   SUM(is_purchase) AS 'num_purchase',
   1.0 * SUM(is_checkout) / COUNT(user_id) AS 'browse_to_checkout',
   1.0 * SUM(is_purchase) / SUM(is_checkout) AS 'checkout_to_purchase'
FROM funnels
GROUP BY browse_date
ORDER BY browse_date;
/* this shows the steady increase in sales (increasing checkout_to_purchase percentage) as we inch closer to Christmas. */





