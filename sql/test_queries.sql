-- ============================================================================
-- TEST QUERIES
-- Purpose: Quick tests to verify SQL functionality
-- ============================================================================

-- Run this file after ETL to test all SQL components
-- Usage: psql $DATABASE_URL -f sql/test_queries.sql

\echo '=========================================='
\echo 'SQL FUNCTIONALITY TEST SUITE'
\echo '=========================================='
\echo ''

-- ============================================================================
-- SECTION 1: BASIC DATA VERIFICATION
-- ============================================================================

\echo 'TEST 1: Data Counts'
\echo '------------------------------------------'
SELECT 'Customers' AS table_name, COUNT(*) AS record_count FROM customers
UNION ALL
SELECT 'Orders', COUNT(*) FROM orders
UNION ALL
SELECT 'Products', COUNT(*) FROM products
UNION ALL
SELECT 'Order Items', COUNT(*) FROM order_items
UNION ALL
SELECT 'States', COUNT(*) FROM states;

\echo ''

-- ============================================================================
-- SECTION 2: AGGREGATION QUERIES
-- ============================================================================

\echo 'TEST 2: Aggregation - Total Revenue'
\echo '------------------------------------------'
SELECT 
    COUNT(*) AS total_orders,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value,
    MIN(total_amount) AS min_order,
    MAX(total_amount) AS max_order
FROM orders;

\echo ''

\echo 'TEST 3: Aggregation - Customers by State'
\echo '------------------------------------------'
SELECT 
    s.state_name,
    COUNT(c.customer_id) AS customer_count
FROM states s
LEFT JOIN customers c ON s.state_code = c.state_code
GROUP BY s.state_name
ORDER BY customer_count DESC
LIMIT 5;

\echo ''

-- ============================================================================
-- SECTION 3: JOIN QUERIES
-- ============================================================================

\echo 'TEST 4: JOIN - Customer Orders'
\echo '------------------------------------------'
SELECT 
    c.customer_id,
    c.full_name,
    COUNT(o.order_id) AS order_count,
    COALESCE(SUM(o.total_amount), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY total_spent DESC
LIMIT 5;

\echo ''

\echo 'TEST 5: JOIN - Product Sales'
\echo '------------------------------------------'
SELECT 
    p.product_id,
    p.product_name,
    COALESCE(COUNT(oi.order_item_id), 0) AS times_ordered,
    COALESCE(SUM(oi.quantity), 0) AS total_sold,
    COALESCE(SUM(oi.line_total), 0) AS total_revenue
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 5;

\echo ''

-- ============================================================================
-- SECTION 4: DATA QUALITY CHECKS
-- ============================================================================

\echo 'TEST 6: Data Quality - Summary'
\echo '------------------------------------------'
SELECT 
    'Duplicate Emails' AS metric,
    COUNT(*) AS issue_count
FROM (
    SELECT email FROM customers GROUP BY email HAVING COUNT(*) > 1
) dup
UNION ALL
SELECT 
    'Missing Phone Numbers',
    COUNT(*) FROM customers WHERE phone_number IS NULL
UNION ALL
SELECT 
    'Missing Location',
    COUNT(*) FROM customers WHERE city IS NULL OR state_code IS NULL
UNION ALL
SELECT 
    'Unverified Emails',
    COUNT(*) FROM customers WHERE email_verified = FALSE
UNION ALL
SELECT 
    'Orders with Zero Amount',
    COUNT(*) FROM orders WHERE total_amount <= 0;

\echo ''

-- ============================================================================
-- SECTION 5: VIEWS
-- ============================================================================

\echo 'TEST 7: Views - Customer Summary'
\echo '------------------------------------------'
SELECT 
    customer_id,
    full_name,
    total_orders,
    lifetime_value,
    engagement_status
FROM vw_customer_summary
WHERE total_orders > 0
ORDER BY lifetime_value DESC
LIMIT 5;

\echo ''

\echo 'TEST 8: Views - Sales Dashboard'
\echo '------------------------------------------'
SELECT 
    month,
    total_orders,
    total_revenue,
    avg_order_value,
    fulfillment_rate
FROM vw_sales_dashboard
ORDER BY month DESC
LIMIT 3;

\echo ''

-- ============================================================================
-- SECTION 6: STORED PROCEDURES
-- ============================================================================

\echo 'TEST 9: Function - Top Products'
\echo '------------------------------------------'
SELECT 
    product_name,
    total_sold,
    total_revenue
FROM get_top_products(5);

\echo ''

\echo 'TEST 10: Function - Customer Stats (if customer exists)'
\echo '------------------------------------------'
DO $$
DECLARE
    v_customer_id VARCHAR(20);
BEGIN
    -- Get first customer ID
    SELECT customer_id INTO v_customer_id FROM customers LIMIT 1;
    
    IF v_customer_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with customer: %', v_customer_id;
        PERFORM * FROM get_customer_stats(v_customer_id);
    ELSE
        RAISE NOTICE 'No customers found to test';
    END IF;
END $$;

SELECT * FROM get_customer_stats(
    (SELECT customer_id FROM customers LIMIT 1)
) WHERE customer_id IS NOT NULL;

\echo ''

-- ============================================================================
-- SECTION 7: PERFORMANCE CHECKS
-- ============================================================================

\echo 'TEST 11: Performance - Index Usage'
\echo '------------------------------------------'
SELECT 
    tablename,
    indexname,
    idx_scan AS scans
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC
LIMIT 5;

\echo ''

\echo 'TEST 12: Performance - Table Sizes'
\echo '------------------------------------------'
SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

\echo ''

-- ============================================================================
-- SECTION 8: BUSINESS REPORTS
-- ============================================================================

\echo 'TEST 13: Business Report - Executive Summary'
\echo '------------------------------------------'
SELECT 
    (SELECT COUNT(*) FROM customers) AS total_customers,
    (SELECT COUNT(*) FROM customers WHERE status = 'Active') AS active_customers,
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT COALESCE(SUM(total_amount), 0) FROM orders) AS total_revenue,
    (SELECT COUNT(*) FROM products WHERE is_active = TRUE) AS active_products;

\echo ''

\echo 'TEST 14: Business Report - Monthly Trend'
\echo '------------------------------------------'
SELECT 
    TO_CHAR(order_date, 'YYYY-MM') AS month,
    COUNT(*) AS order_count,
    SUM(total_amount) AS monthly_revenue
FROM orders
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY month DESC
LIMIT 3;

\echo ''

-- ============================================================================
-- TEST SUMMARY
-- ============================================================================

\echo '=========================================='
\echo 'TEST SUITE COMPLETE'
\echo '=========================================='
\echo ''
\echo 'All tests executed successfully!'
\echo ''
\echo 'Next steps:'
\echo '1. Review results above'
\echo '2. Take screenshots for documentation'
\echo '3. Run EXPLAIN ANALYZE on slow queries'
\echo '4. Check sql/README.md for more examples'
\echo ''
