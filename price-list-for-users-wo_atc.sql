/* 
   Selecting item details for users who viewed the item list 
   but did NOT proceed to add any item to the cart.
*/
SELECT 
    item_name,        -- Name of the item
    item_list_index,  -- Position of the item in the list
    price_range,      -- Predefined price range category of the item
    user_pseudo_id    -- Unique identifier for the user session
FROM ANALYTICS.DM_COMMON.GA4_ITEMS_CS vi
WHERE vi.event_name = 'view_item_list'  -- Filtering only "view_item_list" event (user saw the list)
    /* Ensuring the date range is correctly set */
    AND vi.event_date >= '20240101'  -- Adjusted to YYYYMMDD format to work correctly with filtering
    /* 
       Excluding users who performed an 'add_to_cart' event. 
       This ensures that only users who viewed the list 
       but never added an item to the cart are included.
    */
    AND NOT EXISTS (
        SELECT 1
        FROM ANALYTICS.DM_COMMON.GA4_ITEMS_CS atc
        WHERE atc.event_name = 'add_to_cart'  -- Looking for users who added an item to the cart
            AND atc.event_date >= '20240101'  -- Ensuring the same date range is used
            AND atc.user_pseudo_id = vi.user_pseudo_id  -- Matching users between the main query and the subquery
    );
