--splitting users into new and existing cohorts

SELECT ex.experiment_group,
       DATE_TRUNC('month',u.activated_at),
       COUNT(CASE WHEN ex.experiment_group = 'test_group' THEN ex.user_id ELSE NULL END) AS test_group,
       COUNT(CASE WHEN ex.experiment_group = 'control_group' THEN ex.user_id ELSE NULL END) AS control_group
    FROM tutorial.yammer_experiments ex 
    JOIN tutorial.yammer_users u 
    ON ex.user_id = u.user_id 
    GROUP BY 1,2
    ORDER BY 2
