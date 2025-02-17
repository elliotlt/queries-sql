/* Strict close sequential funnel analysis */

-- CTE to extract relevant events from the specified funnel
WITH events AS (
    SELECT
        visit_date,
        unique_session_id,
        user_pseudo_id,
        event_name AS step,
        click_time
    FROM ga4_table
    WHERE event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'add_payment_info', 'purchase')
    /* Filtering only the events relevant to the funnel */
),

-- CTE to assign step order numbers to each event, creating a clear sequence for the funnel
steps AS (
    SELECT
        visit_date,
        unique_session_id,
        user_pseudo_id,
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
    /* Assigning a sequential order to each step in the funnel */
),

-- CTE to identify transitions between steps and calculate time difference between them
funnel AS (
    SELECT
        s1.visit_date,
        s1.unique_session_id,
        s1.user_pseudo_id,
        s1.step AS current_step,
        s1.step_order AS current_step_order,
        s1.click_time AS current_step_time,
        s2.step AS next_step,
        s2.step_order AS next_step_order,
        s2.click_time AS next_step_time,
        DATEDIFF('seconds', s1.click_time, s2.click_time) AS step_diff_seconds
    FROM steps s1
    LEFT JOIN steps s2
        ON s1.unique_session_id = s2.unique_session_id
        /* Ensure both steps occurred within the same session */
        AND s1.visit_date = s2.visit_date
        /* Ensure both steps occurred within the same visit */
        AND s1.step_order + 1 = s2.step_order
        /* Ensure the steps are consecutive (step order difference of 1) */
    /* Identifying consecutive steps and calculating the time difference between them */
),

-- CTE to filter out invalid sessions based on broken sequences or excessive time gaps between steps
valid_sessions AS (
    SELECT
        unique_session_id,
        user_pseudo_id,
        MAX(current_step_order) AS max_valid_step_order -- Get the highest valid step for each session
    FROM funnel
    WHERE next_step IS NULL -- Include sessions that did not have a valid next step (end of funnel or broken)
       OR step_diff_seconds <= 900 -- Include sessions where the time between steps was less than or equal to 15 minutes
    GROUP BY unique_session_id, user_pseudo_id
    /* Filtering out sessions with broken sequences or excessive time gaps */
)

-- Final select to aggregate the funnel data
SELECT
    f.visit_date,
    f.current_step_order AS previous_step_order,
    f.current_step AS previous_step,
    f.next_step_order AS step_order,
    f.next_step AS step,
    AVG(step_diff_seconds) AS time_diff,
    COUNT(DISTINCT f.unique_session_id) AS sessions,
    COUNT(DISTINCT f.user_pseudo_id) AS users
FROM funnel f
JOIN valid_sessions vs
    ON f.unique_session_id = vs.unique_session_id
    AND f.current_step_order <= vs.max_valid_step_order -- Ensure we only count steps up to the valid cut-off for each session
GROUP BY
    f.visit_date,
    f.current_step_order,
    f.current_step,
    f.next_step_order,
    f.next_step
/* Aggregating the funnel data to get average time differences, session counts, and user counts */
