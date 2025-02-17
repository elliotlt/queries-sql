/* 
   Creating a CTE (Common Table Expression) named 'landing' 
   to capture the first page visited (landing page) for each session.
*/
WITH landing AS (
    SELECT 
        visit_date,  
        unique_session_id,  
        /* Extract the base URL of the landing page by removing any query parameters */
        IFF(CHARINDEX('?', page_location) > 0, 
            LEFT(page_location, CHARINDEX('?', page_location, 0) - 1), 
            page_location) AS landingPage
    FROM ga4_table 
    WHERE event_name = 'session_start' -- Only considering session start events
),

/* 
   Creating a CTE named 'conversions' 
   to capture all sessions that resulted in a purchase.
*/
conversions AS (
    SELECT 
        visit_date,  -
        unique_session_id  
    FROM ga4_table
    WHERE event_name = 'purchase' -- Only considering purchase events
)

/* 
   Main query to aggregate sessions and purchases per landing page and visit date.
*/
SELECT
    lp.landingPage, 
    lp.visit_date,  
    COUNT(DISTINCT lp.unique_session_id) AS total_sessions,  
    COUNT(DISTINCT cv.unique_session_id) AS purchase  -
FROM landing AS lp
LEFT JOIN conversions AS cv
    /* Joining on unique session ID and visit date to track which sessions led to purchases */
    ON lp.unique_session_id = cv.unique_session_id
    AND lp.visit_date = cv.visit_date
GROUP BY lp.landingPage, lp.visit_date;  
