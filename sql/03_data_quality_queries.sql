-- ============================================================================
-- DATA QUALITY QUERIES
-- Purpose: Detect duplicates, invalid entries, and data issues
-- ============================================================================

-- Query 1: Duplicate email addresses
-- Purpose: Find customers with duplicate emails
SELECT 
    email,
    COUNT(*) AS duplicate_count,
    STRING_AGG(customer_id, ', ' ORDER BY customer_id) AS customer_ids,
    STRING_AGG(full_name, ', ' ORDER BY customer_id) AS names
FROM customers
GROUP BY email
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Query 2: Duplicate customer names
-- Purpose: Identify potentially duplicate customer records
SELECT 
    full_name,
    COUNT(*) AS duplicate_count,
    STRING_AGG(customer_id, ', ' ORDER BY customer_id) AS customer_ids,
    STRING_AGG(email, ', ' ORDER BY customer_id) AS emails
FROM customers
GROUP BY full_name
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Query 3: Invalid email formats (bypassing constraint)
-- Purpose: Find emails that might have slipped through validation
SELECT 
    customer_id,
    full_name,
    email,
    'Invalid email format' AS issue
FROM customers
WHERE email !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
   OR email LIKE '%@%@%'
   OR email NOT LIKE '%@%.%';

-- Query 4: Invalid phone number formats
-- Purpose: Find phone numbers not matching standard format
SELECT 
    customer_id,
    full_name,
    phone_number,
    CASE 
        WHEN phone_number IS NULL THEN 'Missing phone'
        WHEN phone_number !~ '^[0-9]{3}-[0-9]{4}$' AND phone_number !~ '^[0-9]{10}$' THEN 'Invalid format'
        ELSE 'Unknown issue'
    END AS issue
FROM customers
WHERE phone_number IS NOT NULL 
  AND phone_number !~ '^[0-9]{3}-[0-9]{4}$' 
  AND phone_number !~ '^[0-9]{10}$';

-- Query 5: Customers with incomplete data
-- Purpose: Find records missing critical information
SELECT 
    customer_id,
    full_name,
    email,
    CASE 
        WHEN phone_number IS NULL THEN 'Missing phone'
        ELSE 'Has phone'
    END AS phone_status,
    CASE 
        WHEN city IS NULL THEN 'Missing city'
        ELSE 'Has city'
    END AS city_status,
    CASE 
        WHEN state_code IS NULL THEN 'Missing state'
        ELSE 'Has state'
    END AS state_status,
    CASE 
        WHEN email_verified = FALSE THEN 'Email not verified'
        ELSE 'Email verified'
    END AS verification_status
FROM customers
WHERE phone_number IS NULL 
   OR city IS NULL 
   OR state_code IS NULL 
   OR email_verified = FALSE
ORDER BY registered_at DESC;

-- Query 6: Orders with zero or negative amounts
-- Purpose: Find invalid order amounts
SELECT 
    order_id,
    customer_id,
    order_date,
    total_amount,
    order_status,
    'Invalid total amount' AS issue
FROM orders
WHERE total_amount <= 0;

-- Query 7: Order total mismatch
-- Purpose: Verify order totals match sum of line items
SELECT 
    o.order_id,
    o.total_amount AS order_total,
    COALESCE(SUM(oi.line_total), 0) AS calculated_total,
    ABS(o.total_amount - COALESCE(SUM(oi.line_total), 0)) AS difference
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.total_amount
HAVING ABS(o.total_amount - COALESCE(SUM(oi.line_total), 0)) > 0.01
ORDER BY difference DESC;

-- Query 8: Orders with no items
-- Purpose: Find orphaned orders
SELECT 
    o.order_id,
    o.customer_id,
    o.order_date,
    o.order_status,
    o.total_amount,
    'No order items' AS issue
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_item_id IS NULL;

-- Query 9: Products with negative or zero prices
-- Purpose: Find invalid product pricing
SELECT 
    product_id,
    product_name,
    unit_price,
    stock_quantity,
    is_active,
    'Invalid price' AS issue
FROM products
WHERE unit_price <= 0;

-- Query 10: Products with negative stock
-- Purpose: Find inventory data issues
SELECT 
    product_id,
    product_name,
    unit_price,
    stock_quantity,
    'Negative stock' AS issue
FROM products
WHERE stock_quantity < 0;

-- Query 11: Inactive products in recent orders
-- Purpose: Find orders referencing inactive products
SELECT 
    o.order_id,
    o.order_date,
    p.product_id,
    p.product_name,
    p.is_active,
    oi.quantity,
    'Inactive product ordered' AS issue
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.order_id
INNER JOIN products p ON oi.product_id = p.product_id
WHERE p.is_active = FALSE
  AND o.order_date > CURRENT_DATE - INTERVAL '90 days'
ORDER BY o.order_date DESC;

-- Query 12: Future order dates
-- Purpose: Find impossible order dates
SELECT 
    order_id,
    customer_id,
    order_date,
    order_status,
    'Future order date' AS issue
FROM orders
WHERE order_date > CURRENT_DATE;

-- Query 13: Customer IDs not matching format
-- Purpose: Find invalid customer ID formats
SELECT 
    customer_id,
    full_name,
    email,
    'Invalid customer_id format' AS issue
FROM customers
WHERE customer_id !~ '^C[0-9]+$';

-- Query 14: Order IDs not matching format
-- Purpose: Find invalid order ID formats
SELECT 
    order_id,
    customer_id,
    order_date,
    'Invalid order_id format' AS issue
FROM orders
WHERE order_id !~ '^ORD[0-9]+$';

-- Query 15: Customers registered in the future
-- Purpose: Find invalid registration dates
SELECT 
    customer_id,
    full_name,
    email,
    registered_at,
    'Future registration date' AS issue
FROM customers
WHERE registered_at > CURRENT_DATE;

-- Query 16: Duplicate product names
-- Purpose: Find products with same name
SELECT 
    product_name,
    COUNT(*) AS duplicate_count,
    STRING_AGG(product_id::TEXT, ', ' ORDER BY product_id) AS product_ids,
    STRING_AGG(unit_price::TEXT, ', ' ORDER BY product_id) AS prices
FROM products
GROUP BY product_name
HAVING COUNT(*) > 1;

-- Query 17: Missing foreign key references (orphaned records)
-- Purpose: Find data integrity issues
SELECT 
    'customers' AS table_name,
    customer_id AS record_id,
    state_code AS foreign_key,
    'Invalid state_code reference' AS issue
FROM customers
WHERE state_code IS NOT NULL 
  AND state_code NOT IN (SELECT state_code FROM states)
UNION ALL
SELECT 
    'orders' AS table_name,
    order_id AS record_id,
    customer_id AS foreign_key,
    'Invalid customer_id reference' AS issue
FROM orders
WHERE customer_id NOT IN (SELECT customer_id FROM customers)
UNION ALL
SELECT 
    'order_items' AS table_name,
    order_item_id::TEXT AS record_id,
    order_id AS foreign_key,
    'Invalid order_id reference' AS issue
FROM order_items
WHERE order_id NOT IN (SELECT order_id FROM orders)
UNION ALL
SELECT 
    'order_items' AS table_name,
    order_item_id::TEXT AS record_id,
    product_id::TEXT AS foreign_key,
    'Invalid product_id reference' AS issue
FROM order_items
WHERE product_id NOT IN (SELECT product_id FROM products);

-- Query 18: Summary of all data quality issues
-- Purpose: Dashboard view of data quality
WITH quality_metrics AS (
    SELECT 'Duplicate Emails' AS metric, COUNT(*) AS issue_count
    FROM (SELECT email FROM customers GROUP BY email HAVING COUNT(*) > 1) dup_emails
    UNION ALL
    SELECT 'Missing Phone Numbers', COUNT(*) FROM customers WHERE phone_number IS NULL
    UNION ALL
    SELECT 'Missing Location Data', COUNT(*) FROM customers WHERE city IS NULL OR state_code IS NULL
    UNION ALL
    SELECT 'Unverified Emails', COUNT(*) FROM customers WHERE email_verified = FALSE
    UNION ALL
    SELECT 'Orders with Zero Amount', COUNT(*) FROM orders WHERE total_amount <= 0
    UNION ALL
    SELECT 'Orders without Items', COUNT(*) 
    FROM orders o 
    LEFT JOIN order_items oi ON o.order_id = oi.order_id 
    WHERE oi.order_item_id IS NULL
    UNION ALL
    SELECT 'Inactive Products with Stock', COUNT(*) FROM products WHERE is_active = FALSE AND stock_quantity > 0
    UNION ALL
    SELECT 'Products with Zero Price', COUNT(*) FROM products WHERE unit_price <= 0
)
SELECT 
    metric,
    issue_count,
    CASE 
        WHEN issue_count = 0 THEN '✓ Good'
        WHEN issue_count <= 5 THEN '⚠ Warning'
        ELSE '✗ Critical'
    END AS status
FROM quality_metrics
ORDER BY issue_count DESC;

-- Query 19: Data completeness report
-- Purpose: Measure overall data quality
SELECT 
    'Customers' AS entity,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN phone_number IS NOT NULL THEN 1 END) AS records_with_phone,
    ROUND(COUNT(CASE WHEN phone_number IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) AS phone_completeness_pct,
    COUNT(CASE WHEN state_code IS NOT NULL THEN 1 END) AS records_with_state,
    ROUND(COUNT(CASE WHEN state_code IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) AS state_completeness_pct,
    COUNT(CASE WHEN email_verified = TRUE THEN 1 END) AS verified_emails,
    ROUND(COUNT(CASE WHEN email_verified = TRUE THEN 1 END) * 100.0 / COUNT(*), 2) AS verification_pct
FROM customers;

-- Query 20: Anomaly detection - unusual order patterns
-- Purpose: Find suspicious orders
SELECT 
    o.order_id,
    o.customer_id,
    c.full_name,
    o.order_date,
    o.total_amount,
    COUNT(oi.order_item_id) AS item_count,
    CASE 
        WHEN o.total_amount > (SELECT AVG(total_amount) * 3 FROM orders) THEN 'Unusually high amount'
        WHEN COUNT(oi.order_item_id) > (SELECT AVG(cnt) * 3 FROM (SELECT COUNT(*) AS cnt FROM order_items GROUP BY order_id) x) THEN 'Unusually many items'
        WHEN o.total_amount < 1 THEN 'Unusually low amount'
        ELSE 'Normal'
    END AS anomaly_type
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.customer_id, c.full_name, o.order_date, o.total_amount
HAVING o.total_amount > (SELECT AVG(total_amount) * 3 FROM orders)
    OR COUNT(oi.order_item_id) > (SELECT AVG(cnt) * 3 FROM (SELECT COUNT(*) AS cnt FROM order_items GROUP BY order_id) x)
    OR o.total_amount < 1
ORDER BY o.total_amount DESC;

-- ============================================================================
-- END OF DATA QUALITY QUERIES
-- ============================================================================
