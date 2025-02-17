WITH events AS (
    /* 
       Extract relevant columns from the GA4 table 
       Filtering only 'form_steps' events 
    */
    SELECT 
        visit_date,
        unique_session_id,
        event_name,
        event_action AS step,  -- Assuming event_action holds the form step name
        click_time
    FROM ga4_table
    WHERE event_name = 'form_steps'
),

steps AS (
    /* 
       Assign numerical step order to each form step for sorting 
       and filtering out any unexpected step names
    */
    SELECT 
        visit_date,
        unique_session_id,
        event_name,
        step,
        CASE 
            WHEN step = 'form_step1' THEN 1
            WHEN step = 'form_step2' THEN 2
            WHEN step = 'form_step3' THEN 3
            WHEN step = 'form_step4' THEN 4
            WHEN step = 'form_step5' THEN 5
            ELSE NULL -- Ensures invalid steps are ignored
        END AS step_order,
        click_time
    FROM events
),

ordered_steps AS (
    /* 
       Create a structured step sequence, ensuring proper ordering 
    */
    SELECT 
        visit_date,
        unique_session_id,
        step_order,
        CONCAT(step_order, '_', step) AS steps, -- Unique representation of steps
        click_time
    FROM steps
    WHERE step_order IS NOT NULL  -- Filter valid steps
),

source_to_target AS (
    /* 
       Compute source → target transitions using LEAD function 
       If there is no next step, mark as 'exit' 
    */
    SELECT 
        visit_date,
        unique_session_id,
        steps AS source,
        step_order AS source_step_order,
        click_time AS source_clicktime,
        COALESCE(
            LEAD(steps) OVER (PARTITION BY visit_date, unique_session_id ORDER BY click_time ASC), 
            'exit' 
        ) AS target,
        COALESCE(
            LEAD(step_order) OVER (PARTITION BY visit_date, unique_session_id ORDER BY click_time ASC), 
            0
        ) AS target_step_order,
        LEAD(click_time) OVER (PARTITION BY visit_date, unique_session_id ORDER BY click_time ASC) AS target_clicktime
    FROM ordered_steps
)

SELECT 
    visit_date,
    source,
    source_step_order,
    target,
    target_step_order,
    COUNT(DISTINCT unique_session_id) AS sessions -- Count unique session transitions
FROM source_to_target
GROUP BY visit_date, source, source_step_order, target, target_step_order
ORDER BY visit_date, source_step_order
  
;
