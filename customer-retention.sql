WITH cohort_items AS (
    SELECT
        date_trunc('month', purchase_date) AS cohort_month,
        customer_id
    FROM _table_
),

customer_activities AS (
    SELECT
        a.customer_id,
        a.cohort_month AS cohort_month_start,
        b.cohort_month AS cohort_month_next,
        DATEDIFF('month', a.cohort_month, b.cohort_month) AS month_number
    FROM cohort_items AS a
    LEFT JOIN cohort_items AS b
        ON a.customer_id = b.customer_id
        AND b.cohort_month >= a.cohort_month
),

retention_table AS (
    SELECT
        cohort_month_start,
        month_number,
        COUNT(DISTINCT customer_id) AS num_customers
    FROM customer_activities
    GROUP BY cohort_month_start, month_number
),

cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS num_customers
    FROM cohort_items
    GROUP BY cohort_month
)

SELECT
    a.cohort_month_start,
    b.num_customers AS cohort_size,
    a.month_number,
    a.num_customers::FLOAT / b.num_customers AS percentage
FROM retention_table AS a
LEFT JOIN cohort_size AS b
    ON a.cohort_month_start = b.cohort_month
ORDER BY a.cohort_month_start, a.month_number;
