-- ============================================================================
-- BUSINESS REPORTS
-- Purpose: Comprehensive business intelligence queries
-- ============================================================================

-- Report 1: Executive Dashboard Summary
-- Purpose: High-level KPIs for leadership
SELECT 
    (SELECT COUNT(*) FROM customers) AS total_customers,
    (SELECT COUNT(*) FROM customers WHERE status = 'Active') AS active_customers,
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT COALESCE(SUM(total_amount), 0) FROM orders) AS total_revenue,
    (SELECT COALESCE(AVG(total_amount), 0) FROM orders) AS avg_order_value,
    (SELECT COUNT(*) FROM products WHERE is_active = TRUE) AS active_products,
    (SELECT COALESCE(SUM(stock_quantity * unit_price), 0) FROM products) AS inventory_value,
    (SELECT COUNT(*) FROM orders WHERE order_date >= CURRENT_DATE - INTERVAL '30 days') AS orders_last_30_days,
    (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE order_date >= CURRENT_DATE - INTERVAL '30 days') AS revenue_last_30_days;

-- Report 2: Monthly Revenue Trend
-- Purpose: Track revenue over time
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value,
    SUM(SUM(total_amount)) OVER (ORDER BY DATE_TRUNC('month', order_date)) AS cumulative_revenue
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month DESC
LIMIT 12;

-- Report 3: Customer Segmentation by Spending
-- Purpose: Categorize customers by value
WITH customer_spending AS (
    SELECT 
        c.customer_id,
        c.full_name,
        c.email,
        COALESCE(SUM(o.total_amount), 0) AS total_spent,
        COUNT(o.order_id) AS order_count
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.full_name, c.email
),
spending_percentiles AS (
    SELECT 
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_spent) AS p75,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_spent) AS p25
    FROM customer_spending
    WHERE total_spent > 0
)
SELECT 
    cs.customer_id,
    cs.full_name,
    cs.email,
    cs.total_spent,
    cs.order_count,
    CASE 
        WHEN cs.total_spent = 0 THEN 'Inactive'
        WHEN cs.total_spent >= sp.p75 THEN 'High Value'
        WHEN cs.total_spent >= sp.p25 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM customer_spending cs, spending_percentiles sp
ORDER BY cs.total_spent DESC;

-- Report 4: Top 10 Products by Revenue
-- Purpose: Best performing products
SELECT 
    p.product_id,
    p.product_name,
    p.unit_price AS current_price,
    COUNT(DISTINCT oi.order_id) AS times_ordered,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.line_total) AS total_revenue,
    AVG(oi.unit_price) AS avg_selling_price,
    p.stock_quantity AS current_stock
FROM products p
INNER JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.unit_price, p.stock_quantity
ORDER BY total_revenue DESC
LIMIT 10;

-- Report 5: Customer Acquisition by State
-- Purpose: Geographic growth analysis
SELECT 
    s.state_name,
    s.state_code,
    COUNT(c.customer_id) AS customer_count,
    COUNT(CASE WHEN c.registered_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) AS new_last_30_days,
    COUNT(CASE WHEN c.registered_at >= CURRENT_DATE - INTERVAL '90 days' THEN 1 END) AS new_last_90_days,
    COALESCE(SUM(o.total_amount), 0) AS total_revenue,
    COALESCE(AVG(o.total_amount), 0) AS avg_order_value
FROM states s
LEFT JOIN customers c ON s.state_code = c.state_code
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY s.state_name, s.state_code
HAVING COUNT(c.customer_id) > 0
ORDER BY customer_count DESC;

-- Report 6: Order Fulfillment Status Report
-- Purpose: Operations metrics
SELECT 
    order_status,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_value,
    AVG(total_amount) AS avg_order_value,
    MIN(order_date) AS oldest_order,
    MAX(order_date) AS newest_order,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM orders
GROUP BY order_status
ORDER BY 
    CASE order_status
        WHEN 'Pending' THEN 1
        WHEN 'Processing' THEN 2
        WHEN 'Shipped' THEN 3
        WHEN 'Delivered' THEN 4
        WHEN 'Cancelled' THEN 5
    END;

-- Report 7: Customer Retention Analysis
-- Purpose: Track repeat purchase behavior
WITH customer_order_counts AS (
    SELECT 
        customer_id,
        COUNT(*) AS order_count,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date
    FROM orders
    GROUP BY customer_id
)
SELECT 
    CASE 
        WHEN order_count = 1 THEN '1 Order (New)'
        WHEN order_count BETWEEN 2 AND 5 THEN '2-5 Orders (Regular)'
        WHEN order_count BETWEEN 6 AND 10 THEN '6-10 Orders (Loyal)'
        ELSE '11+ Orders (VIP)'
    END AS customer_type,
    COUNT(*) AS customer_count,
    ROUND(AVG(EXTRACT(DAY FROM (last_order_date - first_order_date))), 0) AS avg_days_between_first_last,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM customer_order_counts
GROUP BY 
    CASE 
        WHEN order_count = 1 THEN '1 Order (New)'
        WHEN order_count BETWEEN 2 AND 5 THEN '2-5 Orders (Regular)'
        WHEN order_count BETWEEN 6 AND 10 THEN '6-10 Orders (Loyal)'
        ELSE '11+ Orders (VIP)'
    END
ORDER BY MIN(order_count);

-- Report 8: Product Performance Scorecard
-- Purpose: Comprehensive product analysis
SELECT 
    p.product_id,
    p.product_name,
    p.is_active,
    p.unit_price,
    p.stock_quantity,
    COALESCE(COUNT(DISTINCT oi.order_id), 0) AS orders_count,
    COALESCE(SUM(oi.quantity), 0) AS units_sold,
    COALESCE(SUM(oi.line_total), 0) AS revenue,
    CASE 
        WHEN COUNT(DISTINCT oi.order_id) = 0 THEN 'No Sales'
        WHEN COUNT(DISTINCT oi.order_id) >= 10 THEN 'Best Seller'
        WHEN COUNT(DISTINCT oi.order_id) >= 5 THEN 'Good Performer'
        ELSE 'Slow Mover'
    END AS performance_category,
    CASE 
        WHEN p.stock_quantity = 0 THEN 'Out of Stock'
        WHEN p.stock_quantity < 10 THEN 'Low Stock'
        WHEN p.stock_quantity < 50 THEN 'Normal Stock'
        ELSE 'High Stock'
    END AS inventory_status
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.is_active, p.unit_price, p.stock_quantity
ORDER BY revenue DESC NULLS LAST;

-- Report 9: Customer Lifetime Value (CLV) Report
-- Purpose: Identify most valuable customers
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.full_name,
        c.email,
        c.city,
        s.state_name,
        c.registered_at,
        COUNT(o.order_id) AS total_orders,
        COALESCE(SUM(o.total_amount), 0) AS lifetime_value,
        COALESCE(AVG(o.total_amount), 0) AS avg_order_value,
        MAX(o.order_date) AS last_order_date,
        EXTRACT(DAY FROM AGE(CURRENT_DATE, c.registered_at)) AS days_as_customer
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    LEFT JOIN states s ON c.state_code = s.state_code
    GROUP BY c.customer_id, c.full_name, c.email, c.city, s.state_name, c.registered_at
)
SELECT 
    customer_id,
    full_name,
    email,
    city,
    state_name,
    registered_at,
    total_orders,
    lifetime_value,
    avg_order_value,
    last_order_date,
    EXTRACT(DAY FROM AGE(CURRENT_DATE, last_order_date)) AS days_since_last_order,
    ROUND(lifetime_value / NULLIF(days_as_customer, 0), 2) AS value_per_day,
    CASE 
        WHEN total_orders = 0 THEN 'Never Ordered'
        WHEN EXTRACT(DAY FROM AGE(CURRENT_DATE, last_order_date)) > 90 THEN 'At Risk'
        WHEN EXTRACT(DAY FROM AGE(CURRENT_DATE, last_order_date)) > 30 THEN 'Dormant'
        ELSE 'Active'
    END AS customer_status
FROM customer_metrics
WHERE lifetime_value > 0
ORDER BY lifetime_value DESC
LIMIT 50;

-- Report 10: Weekly Sales Performance
-- Purpose: Track weekly trends
SELECT 
    DATE_TRUNC('week', order_date) AS week_start,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(total_amount) AS weekly_revenue,
    AVG(total_amount) AS avg_order_value,
    LAG(SUM(total_amount)) OVER (ORDER BY DATE_TRUNC('week', order_date)) AS previous_week_revenue,
    ROUND((SUM(total_amount) - LAG(SUM(total_amount)) OVER (ORDER BY DATE_TRUNC('week', order_date))) * 100.0 / 
          NULLIF(LAG(SUM(total_amount)) OVER (ORDER BY DATE_TRUNC('week', order_date)), 0), 2) AS revenue_change_pct
FROM orders
GROUP BY DATE_TRUNC('week', order_date)
ORDER BY week_start DESC
LIMIT 12;

-- Report 11: Inventory Alert Report
-- Purpose: Products needing attention
SELECT 
    p.product_id,
    p.product_name,
    p.unit_price,
    p.stock_quantity,
    p.is_active,
    COALESCE(SUM(oi.quantity), 0) AS total_sold,
    CASE 
        WHEN p.stock_quantity = 0 AND p.is_active = TRUE THEN 'URGENT: Out of Stock'
        WHEN p.stock_quantity < 10 AND p.is_active = TRUE THEN 'WARNING: Low Stock'
        WHEN p.stock_quantity > 100 AND COALESCE(SUM(oi.quantity), 0) < 10 THEN 'REVIEW: Overstocked'
        WHEN p.is_active = FALSE AND p.stock_quantity > 0 THEN 'CLEANUP: Inactive with Stock'
        ELSE 'Normal'
    END AS alert_type,
    p.stock_quantity * p.unit_price AS inventory_value
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.unit_price, p.stock_quantity, p.is_active
HAVING (p.stock_quantity <= 10 AND p.is_active = TRUE)
    OR (p.stock_quantity > 100 AND COALESCE(SUM(oi.quantity), 0) < 10)
    OR (p.is_active = FALSE AND p.stock_quantity > 0)
ORDER BY 
    CASE 
        WHEN p.stock_quantity = 0 AND p.is_active = TRUE THEN 1
        WHEN p.stock_quantity < 10 AND p.is_active = TRUE THEN 2
        ELSE 3
    END,
    p.stock_quantity;

-- Report 12: Revenue by Day of Week
-- Purpose: Identify peak sales days
SELECT 
    TO_CHAR(order_date, 'Day') AS day_of_week,
    EXTRACT(DOW FROM order_date) AS day_number,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_of_orders
FROM orders
GROUP BY TO_CHAR(order_date, 'Day'), EXTRACT(DOW FROM order_date)
ORDER BY day_number;

-- ============================================================================
-- END OF BUSINESS REPORTS
-- ============================================================================
