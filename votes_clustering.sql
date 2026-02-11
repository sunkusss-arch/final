-- 기간별 클러스터링 테이블 만들기
CREATE TABLE user_agg_period_v2 AS
WITH base AS (
    SELECT
        user_id,
        created_at,
        question_id,
        chosen_user_id,
        has_read,
        report_count
    FROM accounts_userquestionrecord
    WHERE created_at >= '2023-05-14'
      AND created_at <  '2023-06-25'
),
labeled AS (
    SELECT
        user_id,
        CASE
            WHEN created_at >= '2023-05-14' AND created_at < '2023-05-28' THEN 'before'
            WHEN created_at >= '2023-05-28' AND created_at < '2023-06-11' THEN 'during'
            WHEN created_at >= '2023-06-11' AND created_at < '2023-06-25' THEN 'after'
        END AS period,
        question_id,
        chosen_user_id,
        has_read,
        report_count,
        created_at,
        DATE(created_at) AS activity_date
    FROM base
),
daily AS (
    SELECT
        user_id,
        period,
        activity_date,
        COUNT(*) AS daily_chosen_count
    FROM labeled
    WHERE period IS NOT NULL
    GROUP BY user_id, period, activity_date
),
agg AS (
    SELECT
        user_id,
        period,
        /* 기본 참여 지표 */
        COUNT(*) AS chosen_count,
        COUNT(DISTINCT question_id) AS unique_question_count,
        COUNT(DISTINCT chosen_user_id) AS unique_chosen_user_count,
        /* 전환 지표 */
        AVG(has_read) AS read_rate,
        SUM(CASE WHEN has_read = 1 THEN 1 ELSE 0 END) AS read_count,
        COUNT(*) AS exposure_count,
        SUM(CASE WHEN has_read = 1 THEN 1 ELSE 0 END) / COUNT(*) AS read_exposure_rate,
        /* 활동 빈도 */
        COUNT(DISTINCT activity_date) AS active_days,
        /* 리스크 지표 */
        SUM(report_count) AS total_report_count,
        MAX(report_count) > 0 AS has_report
    FROM labeled
    WHERE period IS NOT NULL
    GROUP BY user_id, period
)
SELECT
    a.*,
    /* 활동 강도 */
    a.chosen_count / NULLIF(a.active_days, 0) AS chosen_per_active_day,
    /* 하루 최대 행동량 */
    d.max_daily_chosen_count
FROM agg a
LEFT JOIN (
    SELECT
        user_id,
        period,
        MAX(daily_chosen_count) AS max_daily_chosen_count
    FROM daily
    GROUP BY user_id, period
) d
ON a.user_id = d.user_id
AND a.period = d.period;

-- 결측값 확인
SELECT COUNT(*) FROM accounts_userquestionrecord
WHERE user_id is NULL;

-- 중복값 확인
SELECT
  user_id,
  question_id,
  chosen_user_id,
  has_read,
  answer_status,
  report_count,
  opened_times,
  created_at,
  COUNT(*) AS cnt
FROM accounts_userquestionrecord
GROUP BY
  user_id,
  question_id,
  chosen_user_id,
  has_read,
  answer_status,
  report_count,
  opened_times,
  created_at
HAVING COUNT(*) > 1;

-- 팀원 공유용 테이블 만들기
CREATE TABLE cluster_result (
    user_id BIGINT,  -- before/during/after 모두 포함
    cluster_id INT,
    PRIMARY KEY (user_id)
);

SELECT * FROM cluster_result;

SELECT COUNT(DISTINCT user_id) FROM user_agg_period_v2;
