-- ============================================================================
-- JOIN QUERIES
-- Purpose: Customer ↔ Orders ↔ Products relationships
-- ============================================================================

-- Query 1: Customer orders summary
-- Purpose: Get all customers with their order history
SELECT 
    c.customer_id,
    c.full_name,
    c.email,
    c.city,
    s.state_name,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS total_spent,
    MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN states s ON c.state_code = s.state_code
GROUP BY c.customer_id, c.full_name, c.email, c.city, s.state_name
ORDER BY total_spent DESC;

-- Query 2: Order details with customer information
-- Purpose: Full order breakdown with customer context
SELECT 
    o.order_id,
    o.order_date,
    o.order_status,
    o.total_amount,
    c.customer_id,
    c.full_name,
    c.email,
    c.phone_number,
    c.city,
    s.state_name,
    COUNT(oi.order_item_id) AS total_items
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN states s ON c.state_code = s.state_code
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.order_date, o.order_status, o.total_amount,
         c.customer_id, c.full_name, c.email, c.phone_number, c.city, s.state_name
ORDER BY o.order_date DESC;

-- Query 3: Order items with product details
-- Purpose: Complete order line item breakdown
SELECT 
    o.order_id,
    o.order_date,
    c.full_name AS customer_name,
    oi.order_item_id,
    p.product_name,
    p.description AS product_description,
    oi.quantity,
    oi.unit_price,
    oi.line_total,
    p.unit_price AS current_product_price,
    (p.unit_price - oi.unit_price) AS price_difference
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
ORDER BY o.order_date DESC, o.order_id, oi.order_item_id;

-- Query 4: Products never ordered
-- Purpose: Identify stale inventory
SELECT 
    p.product_id,
    p.product_name,
    p.unit_price,
    p.stock_quantity,
    p.is_active,
    p.created_at
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.order_item_id IS NULL
ORDER BY p.created_at DESC;

-- Query 5: Customers who never ordered
-- Purpose: Identify inactive customers
SELECT 
    c.customer_id,
    c.full_name,
    c.email,
    c.registered_at,
    c.status,
    EXTRACT(DAY FROM AGE(CURRENT_DATE, c.registered_at)) AS days_since_registration
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.registered_at DESC;

-- Query 6: Top customers by state
-- Purpose: Best customers per geographic region
WITH customer_rankings AS (
    SELECT 
        c.customer_id,
        c.full_name,
        c.state_code,
        s.state_name,
        COUNT(o.order_id) AS order_count,
        SUM(o.total_amount) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.state_code ORDER BY SUM(o.total_amount) DESC) AS rank_in_state
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    LEFT JOIN states s ON c.state_code = s.state_code
    GROUP BY c.customer_id, c.full_name, c.state_code, s.state_name
)
SELECT 
    state_name,
    state_code,
    customer_id,
    full_name,
    order_count,
    total_spent,
    rank_in_state
FROM customer_rankings
WHERE rank_in_state <= 3 AND total_spent > 0
ORDER BY state_name, rank_in_state;

-- Query 7: Product sales by customer
-- Purpose: Which customers buy which products
SELECT 
    c.customer_id,
    c.full_name,
    p.product_name,
    COUNT(oi.order_item_id) AS times_purchased,
    SUM(oi.quantity) AS total_quantity,
    SUM(oi.line_total) AS total_spent_on_product
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
GROUP BY c.customer_id, c.full_name, p.product_name
ORDER BY total_spent_on_product DESC
LIMIT 50;

-- Query 8: Orders with multiple products
-- Purpose: Cross-selling analysis
SELECT 
    o.order_id,
    o.order_date,
    c.full_name,
    COUNT(oi.order_item_id) AS product_count,
    STRING_AGG(p.product_name, ', ' ORDER BY p.product_name) AS products_ordered,
    o.total_amount
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
GROUP BY o.order_id, o.order_date, c.full_name, o.total_amount
HAVING COUNT(oi.order_item_id) > 1
ORDER BY product_count DESC, o.order_date DESC;

-- Query 9: Revenue by product category (assuming we have product names)
-- Purpose: Product performance analysis
SELECT 
    p.product_id,
    p.product_name,
    COUNT(DISTINCT o.order_id) AS orders_containing_product,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.line_total) AS total_revenue,
    AVG(oi.line_total) AS avg_revenue_per_order
FROM products p
INNER JOIN order_items oi ON p.product_id = oi.product_id
INNER JOIN orders o ON oi.order_id = o.order_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC;

-- Query 10: Customer lifetime value (CLV)
-- Purpose: Identify most valuable customers
SELECT 
    c.customer_id,
    c.full_name,
    c.email,
    c.registered_at,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value,
    AVG(o.total_amount) AS avg_order_value,
    MAX(o.order_date) AS last_order_date,
    EXTRACT(DAY FROM AGE(CURRENT_DATE, MAX(o.order_date))) AS days_since_last_order,
    EXTRACT(DAY FROM AGE(CURRENT_DATE, c.registered_at)) AS customer_age_days
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name, c.email, c.registered_at
ORDER BY lifetime_value DESC
LIMIT 50;

-- Query 11: Orders by state
-- Purpose: Geographic revenue analysis
SELECT 
    s.state_name,
    s.state_code,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(o.order_id) AS order_count,
    SUM(o.total_amount) AS total_revenue,
    AVG(o.total_amount) AS avg_order_value
FROM states s
LEFT JOIN customers c ON s.state_code = c.state_code
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY s.state_name, s.state_code
HAVING COUNT(o.order_id) > 0
ORDER BY total_revenue DESC;

-- Query 12: Recent orders with full details
-- Purpose: Recent activity dashboard
SELECT 
    o.order_id,
    o.order_date,
    o.order_status,
    c.full_name AS customer_name,
    c.email,
    c.city || ', ' || s.state_code AS location,
    STRING_AGG(p.product_name || ' (x' || oi.quantity || ')', ', ') AS items,
    o.total_amount
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN states s ON c.state_code = s.state_code
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
GROUP BY o.order_id, o.order_date, o.order_status, c.full_name, c.email, c.city, s.state_code, o.total_amount
ORDER BY o.order_date DESC, o.order_id
LIMIT 25;

-- ============================================================================
-- END OF JOIN QUERIES
-- ============================================================================
