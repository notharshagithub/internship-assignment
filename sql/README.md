# SQL Development & Optimization

Complete SQL query library for Customer Order Management System

## 📁 File Structure

```
sql/
├── 01_aggregation_queries.sql    # COUNT, SUM, AVG operations
├── 02_join_queries.sql            # Customer ↔ Orders ↔ Products JOINs
├── 03_data_quality_queries.sql    # Detect duplicates & invalid data
├── 04_business_reports.sql        # Business intelligence queries
├── 05_views.sql                   # Database views
├── 06_procedures.sql              # Stored procedures & functions
├── 07_optimization.sql            # Indexes & performance optimization
└── README.md                      # This file
```

## 🚀 Quick Start

### 1. Run Queries in Order

```bash
# Connect to your database
psql $DATABASE_URL

# Or for individual files
psql $DATABASE_URL -f sql/01_aggregation_queries.sql
psql $DATABASE_URL -f sql/05_views.sql
psql $DATABASE_URL -f sql/06_procedures.sql
psql $DATABASE_URL -f sql/07_optimization.sql
```

### 2. Test Specific Queries

```sql
-- Test aggregation query
\i sql/01_aggregation_queries.sql

-- Test a specific view
SELECT * FROM vw_customer_summary LIMIT 10;

-- Test a stored procedure
SELECT * FROM get_customer_stats('C001');
```

## 📊 Query Categories

### 1. Aggregation Queries (15 queries)
**File:** `01_aggregation_queries.sql`

- Customer counts by status, state
- Order statistics and revenue
- Product inventory metrics
- Average order values
- Monthly/yearly trends
- Email verification rates
- Order fulfillment metrics

**Examples:**
```sql
-- Total revenue
SELECT SUM(total_amount) FROM orders;

-- Customers by state
SELECT state_code, COUNT(*) FROM customers GROUP BY state_code;

-- Average order value
SELECT AVG(total_amount) FROM orders;
```

### 2. JOIN Queries (12 queries)
**File:** `02_join_queries.sql`

- Customer order history
- Order details with customer info
- Product sales analysis
- Geographic revenue breakdown
- Customer lifetime value
- Cross-selling analysis
- Top customers by state

**Examples:**
```sql
-- Customer with orders
SELECT c.*, COUNT(o.order_id) 
FROM customers c 
LEFT JOIN orders o ON c.customer_id = o.customer_id 
GROUP BY c.customer_id;

-- Order items with products
SELECT o.order_id, p.product_name, oi.quantity
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id;
```

### 3. Data Quality Queries (20 queries)
**File:** `03_data_quality_queries.sql`

- Duplicate email detection
- Invalid email/phone formats
- Missing data identification
- Order total mismatches
- Orphaned records
- Foreign key validation
- Anomaly detection
- Data completeness reports

**Examples:**
```sql
-- Find duplicate emails
SELECT email, COUNT(*) 
FROM customers 
GROUP BY email 
HAVING COUNT(*) > 1;

-- Invalid phone formats
SELECT * FROM customers 
WHERE phone_number !~ '^[0-9]{3}-[0-9]{4}$';
```

### 4. Business Reports (12 reports)
**File:** `04_business_reports.sql`

- Executive dashboard summary
- Monthly revenue trends
- Customer segmentation
- Top products by revenue
- Customer acquisition by state
- Order fulfillment status
- Customer retention analysis
- Product performance scorecard
- Customer lifetime value
- Weekly sales performance
- Inventory alerts
- Revenue by day of week

**Examples:**
```sql
-- Executive dashboard
SELECT 
    (SELECT COUNT(*) FROM customers) AS total_customers,
    (SELECT SUM(total_amount) FROM orders) AS total_revenue;

-- Monthly trends
SELECT DATE_TRUNC('month', order_date), SUM(total_amount)
FROM orders
GROUP BY DATE_TRUNC('month', order_date);
```

### 5. Database Views (12 views)
**File:** `05_views.sql`

| View Name | Purpose |
|-----------|---------|
| `vw_customer_summary` | Customer metrics and engagement status |
| `vw_order_details` | Complete order information |
| `vw_product_performance` | Product sales and inventory |
| `vw_top_customers` | High-value customers |
| `vw_sales_dashboard` | Monthly sales metrics |
| `vw_inventory_alerts` | Products needing attention |
| `vw_recent_orders` | Last 30 days orders |
| `vw_state_performance` | Geographic analysis |
| `vw_customer_cohorts` | Cohort analysis |
| `vw_order_item_details` | Line-level details |
| `vw_data_quality_dashboard` | Data quality metrics |
| `vw_monthly_kpis` | Monthly KPIs with growth |

**Examples:**
```sql
-- Use a view
SELECT * FROM vw_customer_summary WHERE lifetime_value > 1000;

-- Top customers
SELECT * FROM vw_top_customers LIMIT 10;

-- Recent orders
SELECT * FROM vw_recent_orders WHERE order_status = 'Pending';
```

### 6. Stored Procedures & Functions (15 functions)
**File:** `06_procedures.sql`

**Functions:**
- `get_customer_stats(customer_id)` - Customer metrics
- `calculate_order_total(order_id)` - Calculate order total
- `update_order_total(order_id)` - Sync order totals
- `get_top_products(limit)` - Best sellers
- `get_revenue_by_period(start, end)` - Revenue metrics
- `search_customers(search_term)` - Customer search
- `get_customer_orders(customer_id)` - Order history
- `check_product_stock(product_id, quantity)` - Stock check
- `update_product_stock(product_id, quantity)` - Update stock
- `get_monthly_revenue(year)` - Monthly breakdown

**Procedures:**
- `create_order(customer_id, order_id, date)` - Create order
- `add_order_item(order_id, product_id, quantity)` - Add item
- `cancel_order(order_id)` - Cancel and restore stock
- `complete_order(order_id)` - Complete and decrease stock
- `archive_old_orders(days_old)` - Archive old orders

**Examples:**
```sql
-- Get customer stats
SELECT * FROM get_customer_stats('C001');

-- Search customers
SELECT * FROM search_customers('john');

-- Create order
CALL create_order('C001', 'ORD999', CURRENT_DATE);

-- Add item to order
CALL add_order_item('ORD999', 1, 2);
```

### 7. Query Optimization (14 indexes + techniques)
**File:** `07_optimization.sql`

**Indexes Created:**
- `idx_customers_state_code` - State filtering
- `idx_customers_status` - Status filtering
- `idx_customers_registered_at` - Date range queries
- `idx_orders_customer_id` - Customer lookups
- `idx_orders_order_date` - Date range queries
- `idx_orders_status` - Status filtering
- `idx_orders_customer_date` - Composite index
- `idx_order_items_order_id` - Order item lookups
- `idx_order_items_product_id` - Product sales queries
- `idx_products_is_active` - Active product filter
- `idx_products_stock_quantity` - Low stock alerts
- And more...

**Performance Monitoring:**
- Index usage analysis
- Slow query detection
- Cache hit ratio monitoring
- Table bloat detection
- Sequential vs index scans

**Examples:**
```sql
-- Create indexes
CREATE INDEX idx_orders_customer_id ON orders(customer_id);

-- Analyze query performance
EXPLAIN ANALYZE
SELECT * FROM orders WHERE customer_id = 'C001';

-- Check index usage
SELECT * FROM pg_stat_user_indexes WHERE schemaname = 'public';
```

## 🎯 Common Use Cases

### Use Case 1: Customer Analysis
```sql
-- Get complete customer profile
SELECT * FROM vw_customer_summary WHERE customer_id = 'C001';

-- Get customer orders
SELECT * FROM get_customer_orders('C001');

-- Customer lifetime value
SELECT customer_id, full_name, lifetime_value 
FROM vw_top_customers 
ORDER BY lifetime_value DESC 
LIMIT 20;
```

### Use Case 2: Sales Reporting
```sql
-- Monthly revenue
SELECT * FROM vw_sales_dashboard 
WHERE month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '6 months');

-- Revenue by state
SELECT * FROM vw_state_performance ORDER BY total_revenue DESC;

-- Top products
SELECT * FROM get_top_products(10);
```

### Use Case 3: Inventory Management
```sql
-- Low stock alerts
SELECT * FROM vw_inventory_alerts;

-- Check product stock
SELECT check_product_stock(1, 10);

-- Product performance
SELECT * FROM vw_product_performance 
WHERE performance_category = 'Best Seller';
```

### Use Case 4: Data Quality Monitoring
```sql
-- Data quality dashboard
SELECT * FROM vw_data_quality_dashboard;

-- Find duplicates
SELECT email, COUNT(*) 
FROM customers 
GROUP BY email 
HAVING COUNT(*) > 1;

-- Missing data
SELECT * FROM customers 
WHERE phone_number IS NULL OR city IS NULL;
```

### Use Case 5: Order Management
```sql
-- Recent orders
SELECT * FROM vw_recent_orders;

-- Pending orders
SELECT * FROM vw_order_details WHERE order_status = 'Pending';

-- Complete an order
CALL complete_order('ORD001');
```

## 📈 Performance Tips

1. **Always use indexes** for frequently queried columns
2. **Run EXPLAIN ANALYZE** to understand query plans
3. **Select only needed columns** (avoid SELECT *)
4. **Use views** for complex, frequently-run queries
5. **Use stored procedures** for repeated operations
6. **Monitor index usage** and remove unused indexes
7. **Run VACUUM ANALYZE** regularly
8. **Use LIMIT** for large result sets
9. **Batch operations** where possible
10. **Monitor slow queries** with pg_stat_statements

## 🧪 Testing Queries

### Test with Sample Data

```sql
-- First, ensure you have data loaded
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM products;

-- Test aggregations
SELECT * FROM vw_sales_dashboard LIMIT 5;

-- Test JOINs
SELECT * FROM vw_order_details LIMIT 10;

-- Test procedures
SELECT * FROM get_customer_stats('C001');
```

### Performance Testing

```sql
-- Test query performance
EXPLAIN ANALYZE
SELECT c.customer_id, COUNT(o.order_id)
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id
LIMIT 100;

-- Check index usage
SELECT * FROM pg_stat_user_indexes 
WHERE schemaname = 'public' 
ORDER BY idx_scan DESC;
```

## 📸 Screenshots to Take

For documentation, capture:

1. **Aggregation Query Results** - Run 3-5 aggregation queries
2. **JOIN Query Results** - Customer order history, product sales
3. **Data Quality Report** - Summary of data issues
4. **Business Reports** - Executive dashboard, top customers
5. **View Results** - Customer summary, sales dashboard
6. **Stored Procedure Execution** - Function calls with results
7. **EXPLAIN ANALYZE Output** - Query execution plans
8. **Index Statistics** - Index usage and performance
9. **Performance Metrics** - Cache hit ratio, table sizes

## 🔧 Maintenance

### Daily
```sql
-- Update statistics
ANALYZE customers;
ANALYZE orders;
ANALYZE products;
```

### Weekly
```sql
-- Vacuum and analyze
VACUUM ANALYZE customers;
VACUUM ANALYZE orders;
VACUUM ANALYZE products;
VACUUM ANALYZE order_items;
```

### Monthly
```sql
-- Check for unused indexes
SELECT * FROM pg_stat_user_indexes 
WHERE idx_scan = 0;

-- Check table bloat
SELECT * FROM pg_stat_user_tables 
ORDER BY n_dead_tup DESC;

-- Refresh materialized views
REFRESH MATERIALIZED VIEW mv_customer_summary;
```

## 📚 Resources

- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **EXPLAIN Documentation**: https://www.postgresql.org/docs/current/using-explain.html
- **Index Types**: https://www.postgresql.org/docs/current/indexes-types.html
- **Query Optimization**: https://wiki.postgresql.org/wiki/Performance_Optimization

## ✅ Task Completion Checklist

- [x] Aggregation queries (COUNT, SUM, AVG)
- [x] JOIN queries (Customer ↔ Orders ↔ Products)
- [x] Data quality queries (duplicates, invalid entries)
- [x] Business reports (customers by state, revenue, etc.)
- [x] Database views (12 views created)
- [x] Stored procedures (10 functions, 5 procedures)
- [x] Query optimization (14+ indexes, EXPLAIN ANALYZE)
- [x] Documentation and examples

---

**Status:** ✅ Task 5 Complete - SQL Development & Optimization

All deliverables created and ready for use!
