-- Step 1: Extract user metrics (login events) from experiment, user, and event tables
WITH user_metrics AS (
  SELECT ex.experiment,
         ex.experiment_group,
         ex.occurred_at AS treatment_start,
         u.user_id,
         u.activated_at,
         COUNT(CASE WHEN e.event_name = 'login' THEN e.user_id ELSE NULL END) AS metric
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
    AND e.event_type = 'engagement'
   GROUP BY 1, 2, 3, 4, 5
),

-- Step 2: Aggregate metrics by experiment and experiment group, calculating key statistics
aggregated_metrics AS (
  SELECT a.experiment,
         a.experiment_group,
         COUNT(a.user_id) AS users,
         AVG(a.metric) AS average,
         SUM(a.metric) AS total,
         STDDEV(a.metric) AS stdev,
         VARIANCE(a.metric) AS variance
    FROM user_metrics a
   GROUP BY 1, 2
),

-- Step 3: Calculate control group statistics (user count, mean, total, standard deviation, variance)
control_group_stats AS (
  SELECT t.experiment,
         t.experiment_group,
         COUNT(t.user_id) AS users,
         AVG(t.metric) AS average,
         SUM(t.metric) AS total,
         STDDEV(t.metric) AS stdev,
         VARIANCE(t.metric) AS variance
    FROM user_metrics t
   WHERE t.experiment_group = 'control_group'
   GROUP BY t.experiment, t.experiment_group
),

-- Step 4: Calculate test group statistics (user count, mean, total, standard deviation, variance)
test_group_stats AS (
  SELECT t.experiment,
         t.experiment_group,
         COUNT(t.user_id) AS users,
         AVG(t.metric) AS average,
         SUM(t.metric) AS total,
         STDDEV(t.metric) AS stdev,
         VARIANCE(t.metric) AS variance
    FROM user_metrics t
   WHERE t.experiment_group = 'test_group'
   GROUP BY t.experiment, t.experiment_group
),

-- Step 5: Join control and test group statistics, calculating comparative metrics
final_comparison AS (
  SELECT t.experiment,
         t.experiment_group,
         c.experiment_group,
         t.users AS test_users,
         c.users AS control_users,
         ROUND(CAST(t.users::FLOAT / (t.users + c.users)::FLOAT AS numeric), 4) AS test_percent,
         ROUND(CAST(c.users::FLOAT / (t.users + c.users)::FLOAT AS numeric), 4) AS control_percent,
         t.total AS test_total,
         c.total AS control_total,
         ROUND(t.average, 4)::FLOAT AS test_average,
         ROUND(c.average, 4)::FLOAT AS control_average,
         ROUND(t.average - c.average, 4) AS rate_difference,
         ROUND((t.average - c.average) / c.average, 4) AS rate_lift,
         ROUND(t.stdev, 4) AS test_stdev,
         ROUND(c.stdev, 4) AS control_stdev,
         ROUND((t.average - c.average) /
            SQRT((t.variance / t.users) + (c.variance / c.users)), 4) AS t_stat
    FROM test_group_stats t
    CROSS JOIN control_group_stats c
),

-- Step 6: Calculate p-value using normal distribution lookup and t-statistic
final_comparison_with_p_value AS (
  SELECT final_comparison.*,
       (1 - COALESCE(nd.value, 1)) * 2 AS p_value
  FROM final_comparison
  LEFT JOIN benn.normal_distribution nd
    ON nd.score = ABS(ROUND(final_comparison.t_stat, 3))
)

-- Step 7: Output the final table with calculated metrics and statistics
SELECT ex.experiment,
      ex.experiment_group,
      CASE WHEN ex.experiment_group = 'control_group' THEN f.control_users ELSE f.test_users END AS users,
       
      CASE WHEN ex.experiment_group = 'control_group' THEN f.control_percent ELSE f.test_percent END AS treatment_percent,
      CASE WHEN ex.experiment_group = 'control_group' THEN f.control_total ELSE test_total END AS total,
      CASE WHEN ex.experiment_group = 'control_group' THEN f.control_average ELSE test_average END AS average,
      CASE WHEN ex.experiment_group = 'test_group' THEN f.rate_difference ELSE 0 END AS rate_difference,
      CASE WHEN ex.experiment_group = 'test_group' THEN f.rate_lift ELSE 0 END AS rate_lift,
      CASE WHEN ex.experiment_group = 'control_group' THEN f.control_stdev ELSE f.test_stdev END AS stdev,
      CASE WHEN ex.experiment_group = 'test_group' THEN f.t_stat ELSE 0 END t_stat,
      CASE WHEN ex.experiment_group = 'test_group' THEN f.p_value ELSE 1 END p_value
  FROM final_comparison_with_p_value f
  JOIN user_metrics ex
  ON f.experiment = ex.experiment
  GROUP BY 1,2,3,4,5,6,7,8,9,10,11
