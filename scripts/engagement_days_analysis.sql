--Step 1: Extract user metrics (days engaged) from experiment, user, and event tables
WITH user_metrics AS (
  SELECT ex.experiment,
         ex.experiment_group,
         e.user_id,
         CASE WHEN e.event_name = 'login' THEN DATE_TRUNC('day', e.occurred_at) ELSE NULL END AS days
    FROM (SELECT user_id,
                 experiment,
                 experiment_group,
                 occurred_at
            FROM tutorial.yammer_experiments
           WHERE experiment = 'publisher_update'
         ) ex
   JOIN tutorial.yammer_users u
     ON u.user_id = ex.user_id
   JOIN tutorial.yammer_events e
     ON e.user_id = ex.user_id
    AND e.occurred_at >= ex.occurred_at
    AND e.occurred_at < '2014-07-01'
    AND e.occurred_at IS NOT NULL
    AND e.event_type = 'engagement'
   GROUP BY 1, 2, 3, 4
),

-- Step 2: Count distinct days each user was engaged
user_metrics_combined AS (
  SELECT experiment,
         experiment_group,
         user_id,
         COUNT(DISTINCT days) AS diff_days
    FROM user_metrics
    GROUP BY 1, 2, 3
),

-- Step 3: Calculate control group statistics (user count, average, total, standard deviation, variance)
control_group_stats AS (
  SELECT t.experiment,
         t.experiment_group,
         COUNT(t.user_id) AS users,
         AVG(t.diff_days) AS average,      -- Average days engaged for control group
         SUM(t.diff_days) AS total,        -- Total days engaged for control group
         STDDEV(t.diff_days) AS stdev,     -- Standard deviation for control group
         VARIANCE(t.diff_days) AS variance -- Variance for control group
    FROM user_metrics_combined t
   WHERE t.experiment_group = 'control_group'
   GROUP BY 1, 2
),

-- Step 4: Calculate test group statistics (user count, average, total, standard deviation, variance)
test_group_stats AS (
  SELECT t.experiment,
         t.experiment_group,
         COUNT(t.user_id) AS users,
         AVG(t.diff_days) AS average,      -- Average days engaged for test group
         SUM(t.diff_days) AS total,        -- Total days engaged for test group
         STDDEV(t.diff_days) AS stdev,     -- Standard deviation for test group
         VARIANCE(t.diff_days) AS variance -- Variance for test group
    FROM user_metrics_combined t
   WHERE t.experiment_group = 'test_group'
   GROUP BY t.experiment, t.experiment_group
),

-- Step 5: Combine control and test group statistics, calculating differences
final_comparison AS (
  SELECT t.experiment,
         t.experiment_group,
         c.experiment_group,
         t.users AS test_users,        -- Number of users in the test group
         c.users AS control_users,     -- Number of users in the control group
         ROUND(CAST(t.users::FLOAT / (t.users + c.users)::FLOAT AS numeric), 4) AS test_percent,
         ROUND(CAST(c.users::FLOAT / (t.users + c.users)::FLOAT AS numeric), 4) AS control_percent,
         t.total AS test_total,        -- Total days engaged for test group
         c.total AS control_total,     -- Total days engaged for control group
         ROUND(CAST(t.average AS NUMERIC), 4) AS test_average,      -- Average days engaged for test group
         ROUND(CAST(c.average AS NUMERIC), 4) AS control_average,   -- Average days engaged for control group
         ROUND(CAST(t.average - c.average AS NUMERIC), 4) AS rate_difference, -- Difference in average days engaged
         ROUND(CAST((t.average - c.average) / c.average AS NUMERIC), 4) AS rate_lift, -- Relative lift in engagement
         ROUND(CAST(t.stdev AS NUMERIC), 4) AS test_stdev,   -- Standard deviation for test group
         ROUND(CAST(c.stdev AS NUMERIC), 4) AS control_stdev, -- Standard deviation for control group
         ROUND(CAST((t.average - c.average) /
            SQRT((t.variance / t.users) + (c.variance / c.users)) AS NUMERIC), 4) AS t_stat -- T-statistic
    FROM test_group_stats t
    CROSS JOIN control_group_stats c
),

-- Step 6: Calculate p-value based on t-statistic
final_comparison_with_p_value AS (
  SELECT final_comparison.*,
       (1 - COALESCE(nd.value, 1)) * 2 AS p_value -- Calculate p-value for statistical significance
  FROM final_comparison
  LEFT JOIN benn.normal_distribution nd
    ON nd.score = ABS(ROUND(final_comparison.t_stat, 3))
)

-- Step 7: Generate final output with metrics for both groups
SELECT ex.experiment,
      ex.experiment_group,
      CASE WHEN ex.experiment_group = 'control_group' THEN f.control_users ELSE f.test_users END AS users,
      CASE WHEN ex.experiment_group = 'control_group' THEN f.control_percent ELSE f.test_percent END AS treatment_percent,
      CASE WHEN ex.experiment_group = 'control_group' THEN f.control_total ELSE test_total END AS total,
      CASE WHEN ex.experiment_group = 'control_group' THEN f.control_average ELSE test_average END AS average,
      CASE WHEN ex.experiment_group = 'test_group' THEN f.rate_difference ELSE 0 END AS rate_difference,
      CASE WHEN ex.experiment_group = 'test_group' THEN f.rate_lift ELSE 0 END AS rate_lift,
      CASE WHEN ex.experiment_group = 'control_group' THEN f.control_stdev ELSE f.test_stdev END AS stdev,
      CASE WHEN ex.experiment_group = 'test_group' THEN f.t_stat ELSE 0 END AS t_stat,
      CASE WHEN ex.experiment_group = 'test_group' THEN f.p_value ELSE 1 END AS p_value
  FROM final_comparison_with_p_value f
  JOIN user_metrics ex
  ON f.experiment = ex.experiment
  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
