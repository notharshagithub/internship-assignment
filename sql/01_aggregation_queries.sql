-- ============================================================================
-- AGGREGATION QUERIES
-- Purpose: COUNT, SUM, AVG operations for business metrics
-- ============================================================================

-- Query 1: Count total customers
-- Purpose: Get total number of customers in database
SELECT COUNT(*) AS total_customers
FROM customers;

-- Query 2: Count customers by status
-- Purpose: Breakdown of customer statuses
SELECT 
    status,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM customers
GROUP BY status
ORDER BY customer_count DESC;

-- Query 3: Count customers by state
-- Purpose: Geographic distribution of customers
SELECT 
    s.state_name,
    s.state_code,
    COUNT(c.customer_id) AS customer_count
FROM states s
LEFT JOIN customers c ON s.state_code = c.state_code
GROUP BY s.state_name, s.state_code
ORDER BY customer_count DESC, s.state_name;

-- Query 4: Count active vs inactive customers
-- Purpose: Active customer base analysis
SELECT 
    CASE 
        WHEN status = 'Active' THEN 'Active'
        ELSE 'Inactive/Pending'
    END AS customer_type,
    COUNT(*) AS count,
    ROUND(AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, registered_at))), 2) AS avg_years_registered
FROM customers
GROUP BY customer_type;

-- Query 5: Total number of orders
-- Purpose: Overall order volume
SELECT 
    COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers_with_orders,
    ROUND(COUNT(*)::NUMERIC / NULLIF(COUNT(DISTINCT customer_id), 0), 2) AS avg_orders_per_customer
FROM orders;

-- Query 6: Total revenue (SUM of order amounts)
-- Purpose: Calculate total business revenue
SELECT 
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS average_order_value,
    MIN(total_amount) AS smallest_order,
    MAX(total_amount) AS largest_order,
    COUNT(*) AS total_orders
FROM orders;

-- Query 7: Revenue by order status
-- Purpose: Revenue breakdown by order status
SELECT 
    order_status,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value,
    MIN(total_amount) AS min_order,
    MAX(total_amount) AS max_order
FROM orders
GROUP BY order_status
ORDER BY total_revenue DESC;

-- Query 8: Revenue by month
-- Purpose: Time series revenue analysis
SELECT 
    TO_CHAR(order_date, 'YYYY-MM') AS month,
    COUNT(*) AS order_count,
    SUM(total_amount) AS monthly_revenue,
    AVG(total_amount) AS avg_order_value
FROM orders
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY month DESC;

-- Query 9: Product statistics
-- Purpose: Product inventory and pricing analysis
SELECT 
    COUNT(*) AS total_products,
    COUNT(CASE WHEN is_active = TRUE THEN 1 END) AS active_products,
    COUNT(CASE WHEN is_active = FALSE THEN 1 END) AS inactive_products,
    AVG(unit_price) AS avg_product_price,
    SUM(stock_quantity) AS total_inventory_units,
    SUM(stock_quantity * unit_price) AS total_inventory_value
FROM products;

-- Query 10: Average order value by customer
-- Purpose: Customer spending analysis
SELECT 
    c.customer_id,
    c.full_name,
    c.email,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_spent,
    AVG(o.total_amount) AS avg_order_value,
    MAX(o.total_amount) AS largest_order
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name, c.email
HAVING COUNT(o.order_id) > 0
ORDER BY total_spent DESC
LIMIT 20;

-- Query 11: Products sold count
-- Purpose: Product performance metrics
SELECT 
    p.product_id,
    p.product_name,
    p.unit_price AS current_price,
    COUNT(oi.order_item_id) AS times_ordered,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.line_total) AS total_revenue,
    AVG(oi.unit_price) AS avg_selling_price
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.unit_price
ORDER BY total_revenue DESC NULLS LAST;

-- Query 12: Average items per order
-- Purpose: Order composition analysis
SELECT 
    AVG(item_count) AS avg_items_per_order,
    MIN(item_count) AS min_items,
    MAX(item_count) AS max_items,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY item_count) AS median_items
FROM (
    SELECT order_id, COUNT(*) AS item_count
    FROM order_items
    GROUP BY order_id
) AS order_sizes;

-- Query 13: Customer acquisition by month
-- Purpose: Growth tracking
SELECT 
    TO_CHAR(registered_at, 'YYYY-MM') AS month,
    COUNT(*) AS new_customers,
    SUM(COUNT(*)) OVER (ORDER BY TO_CHAR(registered_at, 'YYYY-MM')) AS cumulative_customers
FROM customers
GROUP BY TO_CHAR(registered_at, 'YYYY-MM')
ORDER BY month DESC;

-- Query 14: Email verification rate
-- Purpose: Data quality metric
SELECT 
    COUNT(*) AS total_customers,
    COUNT(CASE WHEN email_verified = TRUE THEN 1 END) AS verified_emails,
    COUNT(CASE WHEN email_verified = FALSE THEN 1 END) AS unverified_emails,
    ROUND(COUNT(CASE WHEN email_verified = TRUE THEN 1 END) * 100.0 / COUNT(*), 2) AS verification_rate_percentage
FROM customers;

-- Query 15: Order fulfillment metrics
-- Purpose: Operations dashboard
SELECT 
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END) AS delivered_orders,
    COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) AS cancelled_orders,
    COUNT(CASE WHEN order_status IN ('Pending', 'Processing') THEN 1 END) AS pending_orders,
    ROUND(COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) AS fulfillment_rate_percentage,
    ROUND(COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) AS cancellation_rate_percentage
FROM orders;

-- ============================================================================
-- END OF AGGREGATION QUERIES
-- ============================================================================
