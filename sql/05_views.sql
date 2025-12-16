-- ============================================================================
-- DATABASE VIEWS
-- Purpose: Pre-built queries for common reporting needs
-- ============================================================================

-- View 1: Customer Summary View
-- Purpose: Quick access to customer metrics
CREATE OR REPLACE VIEW vw_customer_summary AS
SELECT 
    c.customer_id,
    c.full_name,
    c.email,
    c.phone_number,
    c.city,
    c.state_code,
    s.state_name,
    c.registered_at,
    c.status,
    c.email_verified,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS lifetime_value,
    COALESCE(AVG(o.total_amount), 0) AS avg_order_value,
    MAX(o.order_date) AS last_order_date,
    EXTRACT(DAY FROM AGE(CURRENT_DATE, c.registered_at)) AS days_as_customer,
    CASE 
        WHEN COUNT(o.order_id) = 0 THEN 'Never Ordered'
        WHEN EXTRACT(DAY FROM AGE(CURRENT_DATE, MAX(o.order_date))) > 90 THEN 'At Risk'
        WHEN EXTRACT(DAY FROM AGE(CURRENT_DATE, MAX(o.order_date))) > 30 THEN 'Dormant'
        ELSE 'Active'
    END AS engagement_status
FROM customers c
LEFT JOIN states s ON c.state_code = s.state_code
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name, c.email, c.phone_number, 
         c.city, c.state_code, s.state_name, c.registered_at, 
         c.status, c.email_verified;

COMMENT ON VIEW vw_customer_summary IS 'Comprehensive customer metrics including order history and engagement status';

-- View 2: Order Details View
-- Purpose: Complete order information with customer and items
CREATE OR REPLACE VIEW vw_order_details AS
SELECT 
    o.order_id,
    o.order_date,
    o.order_status,
    o.total_amount,
    o.notes,
    c.customer_id,
    c.full_name AS customer_name,
    c.email AS customer_email,
    c.phone_number AS customer_phone,
    c.city,
    s.state_name,
    COUNT(oi.order_item_id) AS item_count,
    SUM(oi.quantity) AS total_units,
    STRING_AGG(DISTINCT p.product_name, ', ' ORDER BY p.product_name) AS products,
    o.created_at,
    o.updated_at
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN states s ON c.state_code = s.state_code
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.product_id
GROUP BY o.order_id, o.order_date, o.order_status, o.total_amount, o.notes,
         c.customer_id, c.full_name, c.email, c.phone_number, c.city, 
         s.state_name, o.created_at, o.updated_at;

COMMENT ON VIEW vw_order_details IS 'Complete order information with customer details and product summary';

-- View 3: Product Performance View
-- Purpose: Product sales metrics
CREATE OR REPLACE VIEW vw_product_performance AS
SELECT 
    p.product_id,
    p.product_name,
    p.description,
    p.unit_price AS current_price,
    p.stock_quantity,
    p.is_active,
    COALESCE(COUNT(DISTINCT oi.order_id), 0) AS orders_count,
    COALESCE(COUNT(DISTINCT o.customer_id), 0) AS unique_customers,
    COALESCE(SUM(oi.quantity), 0) AS total_units_sold,
    COALESCE(SUM(oi.line_total), 0) AS total_revenue,
    COALESCE(AVG(oi.unit_price), 0) AS avg_selling_price,
    MAX(o.order_date) AS last_sold_date,
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
    END AS inventory_status,
    p.stock_quantity * p.unit_price AS inventory_value
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
GROUP BY p.product_id, p.product_name, p.description, p.unit_price, 
         p.stock_quantity, p.is_active;

COMMENT ON VIEW vw_product_performance IS 'Product sales performance and inventory metrics';

-- View 4: Top Customers View
-- Purpose: High-value customer identification
CREATE OR REPLACE VIEW vw_top_customers AS
SELECT 
    c.customer_id,
    c.full_name,
    c.email,
    c.city,
    s.state_name,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value,
    AVG(o.total_amount) AS avg_order_value,
    MAX(o.order_date) AS last_order_date,
    MIN(o.order_date) AS first_order_date,
    CASE 
        WHEN COUNT(o.order_id) >= 10 THEN 'VIP'
        WHEN COUNT(o.order_id) >= 5 THEN 'Loyal'
        WHEN COUNT(o.order_id) >= 2 THEN 'Regular'
        ELSE 'New'
    END AS customer_tier
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN states s ON c.state_code = s.state_code
GROUP BY c.customer_id, c.full_name, c.email, c.city, s.state_name
HAVING SUM(o.total_amount) > 0
ORDER BY lifetime_value DESC;

COMMENT ON VIEW vw_top_customers IS 'High-value customers ranked by lifetime value';

-- View 5: Sales Dashboard View
-- Purpose: Executive summary metrics
CREATE OR REPLACE VIEW vw_sales_dashboard AS
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value,
    MIN(total_amount) AS min_order,
    MAX(total_amount) AS max_order,
    COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END) AS delivered_orders,
    COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) AS cancelled_orders,
    ROUND(COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END) * 100.0 / 
          NULLIF(COUNT(*), 0), 2) AS fulfillment_rate
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month DESC;

COMMENT ON VIEW vw_sales_dashboard IS 'Monthly sales performance dashboard';

-- View 6: Inventory Alert View
-- Purpose: Products requiring attention
CREATE OR REPLACE VIEW vw_inventory_alerts AS
SELECT 
    p.product_id,
    p.product_name,
    p.unit_price,
    p.stock_quantity,
    p.is_active,
    COALESCE(SUM(oi.quantity), 0) AS total_sold_all_time,
    CASE 
        WHEN p.stock_quantity = 0 AND p.is_active = TRUE THEN 'URGENT: Out of Stock'
        WHEN p.stock_quantity < 10 AND p.is_active = TRUE THEN 'WARNING: Low Stock'
        WHEN p.stock_quantity > 100 AND COALESCE(SUM(oi.quantity), 0) < 10 THEN 'REVIEW: Overstocked'
        WHEN p.is_active = FALSE AND p.stock_quantity > 0 THEN 'CLEANUP: Inactive with Stock'
        ELSE 'Normal'
    END AS alert_type,
    p.stock_quantity * p.unit_price AS inventory_value,
    p.updated_at AS last_updated
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.unit_price, p.stock_quantity, 
         p.is_active, p.updated_at
HAVING (p.stock_quantity <= 10 AND p.is_active = TRUE)
    OR (p.stock_quantity > 100 AND COALESCE(SUM(oi.quantity), 0) < 10)
    OR (p.is_active = FALSE AND p.stock_quantity > 0);

COMMENT ON VIEW vw_inventory_alerts IS 'Products requiring inventory management attention';

-- View 7: Recent Orders View
-- Purpose: Latest order activity
CREATE OR REPLACE VIEW vw_recent_orders AS
SELECT 
    o.order_id,
    o.order_date,
    o.order_status,
    c.full_name AS customer_name,
    c.email AS customer_email,
    o.total_amount,
    COUNT(oi.order_item_id) AS item_count,
    STRING_AGG(p.product_name, ', ' ORDER BY p.product_name) AS products,
    o.created_at,
    EXTRACT(DAY FROM AGE(CURRENT_TIMESTAMP, o.created_at)) AS days_old
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY o.order_id, o.order_date, o.order_status, c.full_name, 
         c.email, o.total_amount, o.created_at
ORDER BY o.order_date DESC;

COMMENT ON VIEW vw_recent_orders IS 'Orders from the last 30 days';

-- View 8: State Performance View
-- Purpose: Geographic analysis
CREATE OR REPLACE VIEW vw_state_performance AS
SELECT 
    s.state_code,
    s.state_name,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(DISTINCT o.order_id) AS order_count,
    COALESCE(SUM(o.total_amount), 0) AS total_revenue,
    COALESCE(AVG(o.total_amount), 0) AS avg_order_value,
    COUNT(DISTINCT CASE WHEN c.registered_at >= CURRENT_DATE - INTERVAL '30 days' THEN c.customer_id END) AS new_customers_30d,
    COUNT(DISTINCT CASE WHEN o.order_date >= CURRENT_DATE - INTERVAL '30 days' THEN o.order_id END) AS orders_30d
FROM states s
LEFT JOIN customers c ON s.state_code = c.state_code
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY s.state_code, s.state_name
ORDER BY total_revenue DESC;

COMMENT ON VIEW vw_state_performance IS 'Sales and customer metrics by state';

-- View 9: Customer Cohort View
-- Purpose: Cohort analysis by registration month
CREATE OR REPLACE VIEW vw_customer_cohorts AS
SELECT 
    DATE_TRUNC('month', c.registered_at) AS cohort_month,
    COUNT(DISTINCT c.customer_id) AS cohort_size,
    COUNT(DISTINCT o.customer_id) AS customers_with_orders,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS total_revenue,
    ROUND(COUNT(DISTINCT o.customer_id) * 100.0 / COUNT(DISTINCT c.customer_id), 2) AS activation_rate,
    ROUND(COALESCE(SUM(o.total_amount), 0) / COUNT(DISTINCT c.customer_id), 2) AS revenue_per_customer
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY DATE_TRUNC('month', c.registered_at)
ORDER BY cohort_month DESC;

COMMENT ON VIEW vw_customer_cohorts IS 'Customer cohort analysis by registration month';

-- View 10: Order Item Details View
-- Purpose: Line-level order details
CREATE OR REPLACE VIEW vw_order_item_details AS
SELECT 
    oi.order_item_id,
    o.order_id,
    o.order_date,
    o.order_status,
    c.customer_id,
    c.full_name AS customer_name,
    p.product_id,
    p.product_name,
    oi.quantity,
    oi.unit_price AS price_at_order,
    oi.line_total,
    p.unit_price AS current_price,
    (p.unit_price - oi.unit_price) AS price_change,
    oi.created_at
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.order_id
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN products p ON oi.product_id = p.product_id;

COMMENT ON VIEW vw_order_item_details IS 'Detailed view of all order line items';

-- View 11: Data Quality Dashboard View
-- Purpose: Monitor data quality metrics
CREATE OR REPLACE VIEW vw_data_quality_dashboard AS
SELECT 
    'Total Customers' AS metric,
    COUNT(*)::TEXT AS value,
    'count' AS metric_type
FROM customers
UNION ALL
SELECT 
    'Customers Missing Phone',
    COUNT(*)::TEXT,
    'issue'
FROM customers WHERE phone_number IS NULL
UNION ALL
SELECT 
    'Customers Missing Location',
    COUNT(*)::TEXT,
    'issue'
FROM customers WHERE city IS NULL OR state_code IS NULL
UNION ALL
SELECT 
    'Unverified Emails',
    COUNT(*)::TEXT,
    'issue'
FROM customers WHERE email_verified = FALSE
UNION ALL
SELECT 
    'Orders Without Items',
    COUNT(*)::TEXT,
    'issue'
FROM orders o 
LEFT JOIN order_items oi ON o.order_id = oi.order_id 
WHERE oi.order_item_id IS NULL
UNION ALL
SELECT 
    'Products Out of Stock',
    COUNT(*)::TEXT,
    'issue'
FROM products WHERE stock_quantity = 0 AND is_active = TRUE;

COMMENT ON VIEW vw_data_quality_dashboard IS 'Data quality metrics dashboard';

-- View 12: Monthly KPI View
-- Purpose: Key performance indicators by month
CREATE OR REPLACE VIEW vw_monthly_kpis AS
WITH monthly_data AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        COUNT(DISTINCT order_id) AS orders,
        COUNT(DISTINCT customer_id) AS customers,
        SUM(total_amount) AS revenue
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT 
    month,
    orders,
    customers,
    revenue,
    ROUND(revenue / orders, 2) AS avg_order_value,
    LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0 / 
          NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2) AS revenue_growth_pct,
    SUM(revenue) OVER (ORDER BY month) AS cumulative_revenue
FROM monthly_data
ORDER BY month DESC;

COMMENT ON VIEW vw_monthly_kpis IS 'Monthly KPIs with growth metrics';

-- ============================================================================
-- VIEW USAGE EXAMPLES
-- ============================================================================

/*
-- Example 1: Get customer summary
SELECT * FROM vw_customer_summary WHERE status = 'Active' ORDER BY lifetime_value DESC LIMIT 10;

-- Example 2: View recent orders
SELECT * FROM vw_recent_orders WHERE order_status = 'Pending';

-- Example 3: Check inventory alerts
SELECT * FROM vw_inventory_alerts ORDER BY alert_type;

-- Example 4: Monthly sales dashboard
SELECT * FROM vw_sales_dashboard WHERE month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '6 months');

-- Example 5: Top customers
SELECT * FROM vw_top_customers WHERE customer_tier IN ('VIP', 'Loyal') LIMIT 20;
*/

-- ============================================================================
-- END OF VIEWS
-- ============================================================================
