WITH
/* CTE to create cohort items by truncating purchase dates to the month level */
cohort_items AS (
    SELECT
        date_trunc(date, month) AS cohort_month,
        userid as customer_id
    FROM < _your_table_ >
),

/* CTE to calculate the first purchase month for each customer */
first_purchase_month AS (
    SELECT
        customer_id,
        MIN(cohort_month) AS cohort_month_start
    FROM cohort_items
    GROUP BY customer_id
),

/* CTE to calculate customer activities by comparing cohort months */
customer_activities AS (
    SELECT
        f.customer_id,
        f.cohort_month_start,
        c.cohort_month AS cohort_month_next,
        date_diff(c.cohort_month, f.cohort_month_start, month) AS month_number
    FROM first_purchase_month AS f
    JOIN cohort_items AS c
        ON f.customer_id = c.customer_id
        AND c.cohort_month >= f.cohort_month_start
),

/* CTE to calculate the number of customers retained in each cohort month */
retention_table AS (
    SELECT
        cohort_month_start,
        month_number,
        COUNT(DISTINCT customer_id) AS num_customers
    FROM customer_activities
    GROUP BY cohort_month_start, month_number
),

/* CTE to calculate the size of each cohort */
cohort_size AS (
    SELECT
        cohort_month_start,
        COUNT(DISTINCT customer_id) AS num_customers
    FROM first_purchase_month
    GROUP BY cohort_month_start
)

/* Final SELECT to calculate the retention percentage */
SELECT
    r.cohort_month_start,
    s.num_customers AS cohort_size,
    r.month_number,
    r.num_customers / s.num_customers AS percentage
FROM retention_table AS r
JOIN cohort_size AS s
    ON r.cohort_month_start = s.cohort_month_start
ORDER BY r.cohort_month_start, r.month_number;
