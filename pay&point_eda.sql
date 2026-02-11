-- Payments
-- 최초 구매 상품 분포
WITH ranked AS (
  SELECT
    user_id,
    productID,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at, productID) AS rn
  FROM accounts_paymenthistory
)
SELECT
  productID AS first_productID,
  COUNT(*)  AS users
FROM ranked
WHERE rn = 1
GROUP BY productID
ORDER BY users DESC;

-- 재구매 상품
WITH ordered AS (
  SELECT
    user_id,
    productID,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at, productID) AS purchase_order
  FROM accounts_paymenthistory
)
SELECT
  productID,
  COUNT(*) AS repurchase_cnt
FROM ordered
WHERE purchase_order = 2
GROUP BY productID
ORDER BY repurchase_cnt DESC;

-- 세 번째 구매 상품 
WITH ordered AS (
  SELECT
    user_id,
    productID,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at, productID) AS purchase_order
  FROM accounts_paymenthistory
)
SELECT
  productID,
  COUNT(*) AS repurchase_cnt
FROM ordered
WHERE purchase_order = 3
GROUP BY productID
ORDER BY repurchase_cnt DESC;

-- Point
-- delta_point (+) (-) 비율 비교
SELECT
  CASE
    WHEN delta_point > 0 THEN 'plus'
    WHEN delta_point < 0 THEN 'minus'
    ELSE 'zero'
  END AS delta_type,
  COUNT(*) AS cnt,
  COUNT(*) * 1.0 / (SELECT COUNT(*) FROM accounts_pointhistory) AS ratio
FROM accounts_pointhistory
GROUP BY delta_type
ORDER BY cnt DESC;

-- 유저당 누적 획득 포인트 vs 사용 포인트
WITH user_point AS (
  SELECT
    user_id,
    SUM(CASE WHEN delta_point > 0 THEN delta_point ELSE 0 END) AS earned_point,
    SUM(CASE WHEN delta_point < 0 THEN -delta_point ELSE 0 END) AS spent_point,
    SUM(delta_point) AS net_point
  FROM accounts_pointhistory
  GROUP BY user_id
)
SELECT
  AVG(earned_point) AS avg_earned_per_user,
  AVG(spent_point)  AS avg_spent_per_user,
  AVG(net_point)    AS avg_net_per_user,
  SUM(earned_point) AS total_earned,
  SUM(spent_point)  AS total_spent
FROM user_point;

-- 포인트 잔고 분포
SELECT
    user_id,
    SUM(delta_point) AS balance
FROM accounts_pointhistory
GROUP BY user_id;
WITH user_balance AS (
  SELECT
    user_id,
    SUM(delta_point) AS balance
  FROM accounts_pointhistory
  GROUP BY user_id
)
SELECT
  COUNT(*) AS users,
  MIN(balance) AS min_balance,
  MAX(balance) AS max_balance,
  AVG(balance) AS avg_balance
FROM user_balance;