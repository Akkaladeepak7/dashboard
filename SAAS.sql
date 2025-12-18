CREATE DATABASE saas_project;
use saas_project;
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    signup_date DATE NOT NULL,
    plan_type VARCHAR(20) NOT NULL
);
CREATE TABLE activity (
    activity_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    login_date DATE NOT NULL,
    watch_hours FLOAT
);
CREATE TABLE subscriptions (
    subscription_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    plan_type VARCHAR(20),
    monthly_fee FLOAT,
    start_date DATE,
    end_date DATE
);

INSERT INTO users (signup_date, plan_type) VALUES
('2025-01-10','Basic'),
('2025-01-15','Premium'),
('2025-02-05','Basic'),
('2025-02-20','Premium'),
('2025-03-01','Pro');

INSERT INTO activity (user_id, login_date, watch_hours) VALUES
(1,'2025-01-11',2),
(1,'2025-01-15',1),
(2,'2025-01-16',3),
(3,'2025-02-06',0.5),
(3,'2025-02-08',2),
(4,'2025-02-21',1),
(5,'2025-03-02',4);

INSERT INTO subscriptions (user_id, plan_type, monthly_fee, start_date, end_date) VALUES
(1,'Basic',10,'2025-01-10','2025-02-09'),
(1,'Premium',15,'2025-02-10','2025-03-09'), -- Upgraded
(2,'Premium',15,'2025-01-15','2025-02-14'),
(3,'Basic',10,'2025-02-05','2025-03-04'),
(4,'Premium',15,'2025-02-20','2025-03-19'),
(5,'Pro',20,'2025-03-01','2025-03-31');

-- Cohort: users by signup month
WITH cohort AS (
    SELECT 
        user_id,
        DATE_FORMAT(signup_date, '%Y-%m-01') AS cohort_month
    FROM users
),
activity_month AS (
    SELECT 
        user_id,
        DATE_FORMAT(login_date, '%Y-%m-01') AS login_month,
        COUNT(*) AS login_count
    FROM activity
    GROUP BY user_id, DATE_FORMAT(login_date, '%Y-%m-01')
)
SELECT 
    c.cohort_month,
    a.login_month,
    COUNT(a.user_id) AS active_users
FROM cohort c
LEFT JOIN activity_month a ON c.user_id = a.user_id
GROUP BY c.cohort_month, a.login_month
ORDER BY c.cohort_month, a.login_month;

-- Categorize users as Active, At Risk, or Churned
WITH monthly_logins AS (
    SELECT 
        user_id,
        DATE_FORMAT(login_date, '%Y-%m-01') AS month,
        COUNT(*) AS logins
    FROM activity
    GROUP BY user_id, DATE_FORMAT(login_date, '%Y-%m-01')
)
SELECT 
    user_id,
    month,
    CASE 
        WHEN logins >= 3 THEN 'Active'
        WHEN logins BETWEEN 1 AND 2 THEN 'At Risk'
        ELSE 'Churned'
    END AS user_status
FROM monthly_logins
ORDER BY month, user_id;

-- Compare previous and next month plan fees per user
WITH prev_sub AS (
    SELECT 
        user_id, 
        monthly_fee AS prev_fee, 
        LEAD(monthly_fee) OVER (PARTITION BY user_id ORDER BY start_date) AS next_fee,
        start_date
    FROM subscriptions
)
SELECT 
    DATE_FORMAT(start_date, '%Y-%m') AS month,
    SUM(CASE WHEN next_fee > prev_fee THEN next_fee - prev_fee ELSE 0 END) AS expansion_revenue,
    SUM(CASE WHEN next_fee < prev_fee THEN prev_fee - next_fee ELSE 0 END) AS contraction_revenue
FROM prev_sub
GROUP BY DATE_FORMAT(start_date, '%Y-%m')
ORDER BY month;



