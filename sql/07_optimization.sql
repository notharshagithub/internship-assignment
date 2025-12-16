-- ============================================================================
-- QUERY OPTIMIZATION & PERFORMANCE
-- Purpose: Indexes, query optimization, and performance analysis
-- ============================================================================

-- ============================================================================
-- SECTION 1: INDEX CREATION
-- ============================================================================

-- Note: Some indexes are already created as PRIMARY KEY and UNIQUE constraints
-- These are additional indexes for performance optimization

-- Index 1: Customer email lookup (already UNIQUE, but good to note)
-- Already exists as UNIQUE constraint

-- Index 2: Customer state lookup
CREATE INDEX IF NOT EXISTS idx_customers_state_code 
ON customers(state_code);
COMMENT ON INDEX idx_customers_state_code IS 'Optimize queries filtering by state';

-- Index 3: Customer status lookup
CREATE INDEX IF NOT EXISTS idx_customers_status 
ON customers(status);
COMMENT ON INDEX idx_customers_status IS 'Optimize queries filtering by customer status';

-- Index 4: Customer registration date
CREATE INDEX IF NOT EXISTS idx_customers_registered_at 
ON customers(registered_at);
COMMENT ON INDEX idx_customers_registered_at IS 'Optimize date range queries on registration';

-- Index 5: Orders by customer lookup
CREATE INDEX IF NOT EXISTS idx_orders_customer_id 
ON orders(customer_id);
COMMENT ON INDEX idx_orders_customer_id IS 'Optimize customer order lookups (FK index)';

-- Index 6: Orders by date
CREATE INDEX IF NOT EXISTS idx_orders_order_date 
ON orders(order_date);
COMMENT ON INDEX idx_orders_order_date IS 'Optimize date range queries on orders';

-- Index 7: Orders by status
CREATE INDEX IF NOT EXISTS idx_orders_status 
ON orders(order_status);
COMMENT ON INDEX idx_orders_status IS 'Optimize filtering by order status';

-- Index 8: Composite index for orders (customer + date)
CREATE INDEX IF NOT EXISTS idx_orders_customer_date 
ON orders(customer_id, order_date DESC);
COMMENT ON INDEX idx_orders_customer_date IS 'Optimize customer order history queries';

-- Index 9: Order items by order lookup
CREATE INDEX IF NOT EXISTS idx_order_items_order_id 
ON order_items(order_id);
COMMENT ON INDEX idx_order_items_order_id IS 'Optimize order item lookups (FK index)';

-- Index 10: Order items by product lookup
CREATE INDEX IF NOT EXISTS idx_order_items_product_id 
ON order_items(product_id);
COMMENT ON INDEX idx_order_items_product_id IS 'Optimize product sales queries (FK index)';

-- Index 11: Products by active status
CREATE INDEX IF NOT EXISTS idx_products_is_active 
ON products(is_active);
COMMENT ON INDEX idx_products_is_active IS 'Optimize active product queries';

-- Index 12: Products by stock quantity
CREATE INDEX IF NOT EXISTS idx_products_stock_quantity 
ON products(stock_quantity) 
WHERE is_active = TRUE;
COMMENT ON INDEX idx_products_stock_quantity IS 'Partial index for low stock alerts on active products';

-- Index 13: Composite index for product search
CREATE INDEX IF NOT EXISTS idx_products_name_active 
ON products(product_name, is_active);
COMMENT ON INDEX idx_products_name_active IS 'Optimize product name searches with active filter';

-- Index 14: Full-text search index on customer names
CREATE INDEX IF NOT EXISTS idx_customers_name_trgm 
ON customers USING gin(full_name gin_trgm_ops);
COMMENT ON INDEX idx_customers_name_trgm IS 'Trigram index for fuzzy name searches (requires pg_trgm extension)';

-- Note: Enable pg_trgm extension if not already enabled
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ============================================================================
-- SECTION 2: INDEX USAGE ANALYSIS
-- ============================================================================

-- Query to check existing indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Query to check index sizes
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Query to check index usage statistics
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan AS index_scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- Query to find unused indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
  AND idx_scan = 0
  AND indexrelid NOT IN (
      SELECT conindid 
      FROM pg_constraint 
      WHERE contype IN ('p', 'u')  -- Exclude primary key and unique constraint indexes
  )
ORDER BY pg_relation_size(indexrelid) DESC;

-- ============================================================================
-- SECTION 3: QUERY OPTIMIZATION EXAMPLES WITH EXPLAIN ANALYZE
-- ============================================================================

-- Example 1: Customer order lookup (BEFORE optimization)
-- This query benefits from idx_orders_customer_id
EXPLAIN ANALYZE
SELECT 
    c.customer_id,
    c.full_name,
    COUNT(o.order_id) AS order_count,
    SUM(o.total_amount) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.customer_id = 'C001'
GROUP BY c.customer_id, c.full_name;

-- Example 2: Date range query (BEFORE optimization)
-- This query benefits from idx_orders_order_date
EXPLAIN ANALYZE
SELECT 
    order_id,
    customer_id,
    order_date,
    total_amount
FROM orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY order_date DESC;

-- Example 3: Status filter query
-- This query benefits from idx_orders_status
EXPLAIN ANALYZE
SELECT 
    order_id,
    customer_id,
    order_date,
    total_amount,
    order_status
FROM orders
WHERE order_status = 'Pending'
ORDER BY order_date DESC;

-- Example 4: Product sales aggregation
-- This query benefits from idx_order_items_product_id
EXPLAIN ANALYZE
SELECT 
    p.product_id,
    p.product_name,
    COUNT(oi.order_item_id) AS times_ordered,
    SUM(oi.quantity) AS total_sold,
    SUM(oi.line_total) AS total_revenue
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

-- Example 5: Customer with recent orders (composite index benefit)
-- This query benefits from idx_orders_customer_date
EXPLAIN ANALYZE
SELECT 
    o.order_id,
    o.order_date,
    o.total_amount
FROM orders o
WHERE o.customer_id = 'C001'
  AND o.order_date >= CURRENT_DATE - INTERVAL '90 days'
ORDER BY o.order_date DESC;

-- Example 6: Active products with low stock (partial index benefit)
-- This query benefits from idx_products_stock_quantity
EXPLAIN ANALYZE
SELECT 
    product_id,
    product_name,
    stock_quantity,
    unit_price
FROM products
WHERE is_active = TRUE
  AND stock_quantity < 10
ORDER BY stock_quantity ASC;

-- Example 7: Complex JOIN query
-- Benefits from multiple indexes
EXPLAIN ANALYZE
SELECT 
    c.customer_id,
    c.full_name,
    o.order_id,
    o.order_date,
    p.product_name,
    oi.quantity,
    oi.line_total
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '30 days'
  AND c.state_code = 'CA'
ORDER BY o.order_date DESC
LIMIT 100;

-- Example 8: Aggregation with GROUP BY
-- Benefits from idx_orders_customer_id
EXPLAIN ANALYZE
SELECT 
    customer_id,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_spent,
    AVG(total_amount) AS avg_order_value
FROM orders
WHERE order_date >= '2024-01-01'
GROUP BY customer_id
HAVING SUM(total_amount) > 1000
ORDER BY total_spent DESC;

-- ============================================================================
-- SECTION 4: QUERY OPTIMIZATION TECHNIQUES
-- ============================================================================

-- Technique 1: Use LIMIT for large result sets
-- BAD: Fetches all rows
SELECT * FROM customers;

-- GOOD: Limits result set
SELECT * FROM customers ORDER BY customer_id LIMIT 100;

-- Technique 2: Use EXISTS instead of IN for subqueries
-- BAD: IN with subquery
SELECT * FROM customers
WHERE customer_id IN (
    SELECT customer_id FROM orders WHERE order_date >= '2024-01-01'
);

-- GOOD: EXISTS (often faster)
SELECT * FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o 
    WHERE o.customer_id = c.customer_id 
    AND o.order_date >= '2024-01-01'
);

-- Technique 3: Avoid SELECT * 
-- BAD: Selects all columns
SELECT * FROM orders WHERE order_date >= '2024-01-01';

-- GOOD: Select only needed columns
SELECT order_id, customer_id, order_date, total_amount 
FROM orders 
WHERE order_date >= '2024-01-01';

-- Technique 4: Use covering indexes
-- If query only needs indexed columns, it can be satisfied from index alone
-- Example: Query that benefits from covering index
CREATE INDEX IF NOT EXISTS idx_orders_covering 
ON orders(customer_id, order_date, total_amount);

SELECT customer_id, order_date, total_amount
FROM orders
WHERE customer_id = 'C001';

-- Technique 5: Use ANALYZE to update statistics
ANALYZE customers;
ANALYZE orders;
ANALYZE products;
ANALYZE order_items;
ANALYZE states;

-- Technique 6: Use materialized views for expensive queries
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_customer_summary AS
SELECT 
    c.customer_id,
    c.full_name,
    c.email,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS lifetime_value,
    MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name, c.email;

-- Create index on materialized view
CREATE INDEX IF NOT EXISTS idx_mv_customer_summary_ltv 
ON mv_customer_summary(lifetime_value DESC);

-- Refresh materialized view
REFRESH MATERIALIZED VIEW mv_customer_summary;

-- ============================================================================
-- SECTION 5: PERFORMANCE MONITORING QUERIES
-- ============================================================================

-- Query 1: Table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS indexes_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Query 2: Slow queries (requires pg_stat_statements extension)
/*
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time,
    rows
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY mean_exec_time DESC
LIMIT 20;
*/

-- Query 3: Cache hit ratio (should be > 99%)
SELECT 
    'cache hit rate' AS metric,
    ROUND(sum(heap_blks_hit) / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0) * 100, 2) AS percentage
FROM pg_statio_user_tables;

-- Query 4: Table bloat estimation
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    n_live_tup AS live_tuples,
    n_dead_tup AS dead_tuples,
    ROUND(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_tuple_percent
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_dead_tup DESC;

-- Query 5: Sequential scans vs index scans
SELECT 
    schemaname,
    tablename,
    seq_scan AS sequential_scans,
    idx_scan AS index_scans,
    CASE 
        WHEN seq_scan + idx_scan > 0 
        THEN ROUND(idx_scan * 100.0 / (seq_scan + idx_scan), 2)
        ELSE 0 
    END AS index_scan_percent
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY seq_scan DESC;

-- ============================================================================
-- SECTION 6: MAINTENANCE COMMANDS
-- ============================================================================

-- Vacuum and analyze (run periodically to maintain performance)
VACUUM ANALYZE customers;
VACUUM ANALYZE orders;
VACUUM ANALYZE products;
VACUUM ANALYZE order_items;
VACUUM ANALYZE states;

-- Reindex (if indexes are bloated)
-- REINDEX TABLE customers;
-- REINDEX TABLE orders;
-- REINDEX TABLE products;
-- REINDEX TABLE order_items;

-- Update statistics (faster than VACUUM ANALYZE)
ANALYZE customers;
ANALYZE orders;
ANALYZE products;
ANALYZE order_items;

-- ============================================================================
-- SECTION 7: QUERY OPTIMIZATION CHECKLIST
-- ============================================================================

/*
OPTIMIZATION CHECKLIST:
======================

✓ 1. Indexes created on:
   - Foreign keys (customer_id, product_id, order_id)
   - Frequently filtered columns (status, date, state_code)
   - Columns used in JOIN conditions
   - Columns used in WHERE clauses
   - Columns used in ORDER BY

✓ 2. Query optimization techniques:
   - Use EXPLAIN ANALYZE to understand query plans
   - Select only needed columns (avoid SELECT *)
   - Use appropriate JOIN types
   - Filter data as early as possible
   - Use indexes effectively
   - Consider covering indexes
   - Use LIMIT for large result sets

✓ 3. Performance monitoring:
   - Monitor index usage
   - Check for unused indexes
   - Monitor cache hit ratio (should be > 99%)
   - Track slow queries
   - Monitor table/index bloat

✓ 4. Regular maintenance:
   - VACUUM ANALYZE tables regularly
   - Update statistics with ANALYZE
   - Reindex if needed
   - Monitor and clean up dead tuples

✓ 5. Best practices:
   - Use connection pooling
   - Batch operations where possible
   - Use transactions appropriately
   - Avoid N+1 queries
   - Use prepared statements
   - Monitor and tune PostgreSQL configuration
*/

-- ============================================================================
-- END OF OPTIMIZATION
-- ============================================================================
