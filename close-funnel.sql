/*
This query analyzes the time taken between specific events in a user's session on a website,
using data from a Google Analytics 4 (GA4) table.
*/

WITH events AS (
    /*
    Select relevant events from the GA4 table.
    These events represent key steps in the user's journey.
    */
    SELECT
        visit_date,
        unique_session_id,
        event_name AS step,
        click_time
    FROM ga4_table
    WHERE event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'add_payment_info', 'purchase')
),

steps AS (
    /*
    Assign an order to each step to define the sequence of events.
    This helps further in calculating the time difference between consecutive steps.
    */
    SELECT
        visit_date,
        unique_session_id,
        step,
        click_time,
        CASE
            WHEN step = 'view_item' THEN 1
            WHEN step = 'add_to_cart' THEN 2
            WHEN step = 'begin_checkout' THEN 3
            WHEN step = 'add_payment_info' THEN 4
            WHEN step = 'purchase' THEN 5
            ELSE NULL
        END AS step_order
    FROM events
),

next_steps_time AS (
    /*
    Use the LEAD function to get the next step and its timestamp for each session.
    This allows us to calculate the time difference between consecutive steps.
    */
    SELECT
        visit_date,
        unique_session_id,
        step,
        step_order,
        click_time,
        LEAD(step) OVER (PARTITION BY unique_session_id ORDER BY click_time) AS next_step,
        LEAD(click_time) OVER (PARTITION BY unique_session_id ORDER BY click_time) AS next_click_time
    FROM steps
    WHERE step_order IS NOT NULL
),

step_times AS (
    /*
    Calculate the time difference in seconds between consecutive steps.
    Filter out steps where the time difference is more than 15 minutes (900 seconds).
    */
    SELECT
        visit_date,
        unique_session_id,
        step_order,
        step,
        DATEDIFF('seconds', click_time, next_click_time) AS time_sec
    FROM next_steps_time
    WHERE step_order IS NOT NULL
        AND next_click_time IS NOT NULL
        AND DATEDIFF('seconds', click_time, next_click_time) <= 900
)

/*
Final selection: Aggregate the data to calculate the average time per step, weighted by the number of sessions.
Group the results by visit_date, step_order, and step.
*/
SELECT
    visit_date,
    step_order,
    step,
    COUNT(unique_session_id) AS sessions,
    SUM(time_sec) AS sum_time_sec
FROM step_times
GROUP BY visit_date, step_order, step
ORDER BY step_order;





