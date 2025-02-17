WITH
/* CTE to create cohort items by truncating purchase dates to the month level */
cohort_items AS (
    SELECT
        date_trunc('month', purchase_date) AS cohort_month,
        customer_id
    FROM _table_
),

/* CTE to calculate customer activities by comparing cohort months */
customer_activities AS (
    SELECT
        a.customer_id,
        a.cohort_month AS cohort_month_start, /* The month the customer first made a purchase */
        b.cohort_month AS cohort_month_next,  /* Subsequent months the customer made purchases */
        DATEDIFF('month', a.cohort_month, b.cohort_month) AS month_number /* Difference in months between first purchase and subsequent purchases */
    FROM cohort_items AS a
    LEFT JOIN cohort_items AS b
        ON a.customer_id = b.customer_id /* Join on the same customer */
        AND b.cohort_month >= a.cohort_month /* Ensure the subsequent month is greater than or equal to the first purchase month */
    /* This join ensures we capture all subsequent months for each customer's first purchase month */
),

/* CTE to calculate the number of customers retained in each cohort month */
retention_table AS (
    SELECT
        cohort_month_start,
        month_number,
        COUNT(DISTINCT customer_id) AS num_customers /* Count distinct customers for each cohort month and month number */
    FROM customer_activities
    GROUP BY cohort_month_start, month_number
),

/* CTE to calculate the size of each cohort */
cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS num_customers /* Count distinct customers for each cohort month */
    FROM cohort_items
    GROUP BY cohort_month
)

/* Final SELECT to calculate the retention percentage */
SELECT
    a.cohort_month_start,
    b.num_customers AS cohort_size, /* Size of the cohort */
    a.month_number,
    a.num_customers::FLOAT / b.num_customers AS percentage /* Retention percentage */
FROM retention_table AS a
LEFT JOIN cohort_size AS b
    ON a.cohort_month_start = b.cohort_month /* Join on the cohort month to get the cohort size */
ORDER BY a.cohort_month_start, a.month_number; /* Order by cohort month and month number */
