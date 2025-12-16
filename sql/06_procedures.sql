-- ============================================================================
-- STORED PROCEDURES AND FUNCTIONS
-- Purpose: Reusable database operations
-- ============================================================================

-- Function 1: Get Customer Statistics
-- Purpose: Return comprehensive customer metrics
CREATE OR REPLACE FUNCTION get_customer_stats(p_customer_id VARCHAR(20))
RETURNS TABLE (
    customer_id VARCHAR(20),
    full_name VARCHAR(100),
    email VARCHAR(255),
    total_orders BIGINT,
    lifetime_value NUMERIC,
    avg_order_value NUMERIC,
    last_order_date DATE,
    days_since_last_order INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.customer_id,
        c.full_name,
        c.email,
        COUNT(o.order_id) AS total_orders,
        COALESCE(SUM(o.total_amount), 0) AS lifetime_value,
        COALESCE(AVG(o.total_amount), 0) AS avg_order_value,
        MAX(o.order_date) AS last_order_date,
        EXTRACT(DAY FROM AGE(CURRENT_DATE, MAX(o.order_date)))::INTEGER AS days_since_last_order
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    WHERE c.customer_id = p_customer_id
    GROUP BY c.customer_id, c.full_name, c.email;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_customer_stats IS 'Get comprehensive statistics for a specific customer';

-- Function 2: Calculate Order Total
-- Purpose: Calculate total amount for an order from its items
CREATE OR REPLACE FUNCTION calculate_order_total(p_order_id VARCHAR(20))
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(line_total), 0)
    INTO v_total
    FROM order_items
    WHERE order_id = p_order_id;
    
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_order_total IS 'Calculate total amount for an order based on its line items';

-- Function 3: Update Order Total
-- Purpose: Sync order total with sum of line items
CREATE OR REPLACE FUNCTION update_order_total(p_order_id VARCHAR(20))
RETURNS VOID AS $$
DECLARE
    v_calculated_total NUMERIC;
BEGIN
    -- Calculate total from order items
    SELECT COALESCE(SUM(line_total), 0)
    INTO v_calculated_total
    FROM order_items
    WHERE order_id = p_order_id;
    
    -- Update order total
    UPDATE orders
    SET total_amount = v_calculated_total,
        updated_at = NOW()
    WHERE order_id = p_order_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_order_total IS 'Update order total_amount to match sum of line items';

-- Function 4: Get Top Products
-- Purpose: Return best-selling products
CREATE OR REPLACE FUNCTION get_top_products(p_limit INTEGER DEFAULT 10)
RETURNS TABLE (
    product_id INTEGER,
    product_name VARCHAR(255),
    total_sold BIGINT,
    total_revenue NUMERIC,
    orders_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.product_id,
        p.product_name,
        COALESCE(SUM(oi.quantity), 0) AS total_sold,
        COALESCE(SUM(oi.line_total), 0) AS total_revenue,
        COUNT(DISTINCT oi.order_id) AS orders_count
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.product_name
    ORDER BY total_revenue DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_top_products IS 'Get top N products by revenue';

-- Function 5: Get Revenue by Period
-- Purpose: Calculate revenue for a date range
CREATE OR REPLACE FUNCTION get_revenue_by_period(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    order_count BIGINT,
    total_revenue NUMERIC,
    avg_order_value NUMERIC,
    unique_customers BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(order_id) AS order_count,
        COALESCE(SUM(total_amount), 0) AS total_revenue,
        COALESCE(AVG(total_amount), 0) AS avg_order_value,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM orders
    WHERE order_date BETWEEN p_start_date AND p_end_date;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_revenue_by_period IS 'Get revenue metrics for a specific date range';

-- Function 6: Search Customers
-- Purpose: Search customers by name, email, or customer_id
CREATE OR REPLACE FUNCTION search_customers(p_search_term VARCHAR)
RETURNS TABLE (
    customer_id VARCHAR(20),
    full_name VARCHAR(100),
    email VARCHAR(255),
    phone_number VARCHAR(20),
    city VARCHAR(100),
    state_code VARCHAR(2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.customer_id,
        c.full_name,
        c.email,
        c.phone_number,
        c.city,
        c.state_code
    FROM customers c
    WHERE c.customer_id ILIKE '%' || p_search_term || '%'
       OR c.full_name ILIKE '%' || p_search_term || '%'
       OR c.email ILIKE '%' || p_search_term || '%'
    ORDER BY c.full_name
    LIMIT 50;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION search_customers IS 'Search customers by ID, name, or email';

-- Function 7: Get Customer Order History
-- Purpose: Return all orders for a customer
CREATE OR REPLACE FUNCTION get_customer_orders(p_customer_id VARCHAR(20))
RETURNS TABLE (
    order_id VARCHAR(20),
    order_date DATE,
    order_status order_status_enum,
    total_amount NUMERIC,
    item_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        o.order_id,
        o.order_date,
        o.order_status,
        o.total_amount,
        COUNT(oi.order_item_id) AS item_count
    FROM orders o
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = p_customer_id
    GROUP BY o.order_id, o.order_date, o.order_status, o.total_amount
    ORDER BY o.order_date DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_customer_orders IS 'Get all orders for a specific customer';

-- Function 8: Check Product Stock
-- Purpose: Check if product has sufficient stock
CREATE OR REPLACE FUNCTION check_product_stock(
    p_product_id INTEGER,
    p_quantity INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_current_stock INTEGER;
BEGIN
    SELECT stock_quantity
    INTO v_current_stock
    FROM products
    WHERE product_id = p_product_id;
    
    RETURN v_current_stock >= p_quantity;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_product_stock IS 'Check if product has sufficient stock for order';

-- Function 9: Update Product Stock
-- Purpose: Decrease stock when order is placed
CREATE OR REPLACE FUNCTION update_product_stock(
    p_product_id INTEGER,
    p_quantity INTEGER
)
RETURNS VOID AS $$
BEGIN
    UPDATE products
    SET stock_quantity = stock_quantity - p_quantity,
        updated_at = NOW()
    WHERE product_id = p_product_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_product_stock IS 'Decrease product stock by specified quantity';

-- Function 10: Get Monthly Revenue Report
-- Purpose: Revenue breakdown by month
CREATE OR REPLACE FUNCTION get_monthly_revenue(p_year INTEGER)
RETURNS TABLE (
    month INTEGER,
    month_name TEXT,
    order_count BIGINT,
    total_revenue NUMERIC,
    avg_order_value NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        EXTRACT(MONTH FROM order_date)::INTEGER AS month,
        TO_CHAR(order_date, 'Month') AS month_name,
        COUNT(order_id) AS order_count,
        SUM(total_amount) AS total_revenue,
        AVG(total_amount) AS avg_order_value
    FROM orders
    WHERE EXTRACT(YEAR FROM order_date) = p_year
    GROUP BY EXTRACT(MONTH FROM order_date), TO_CHAR(order_date, 'Month')
    ORDER BY month;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_monthly_revenue IS 'Get monthly revenue breakdown for a specific year';

-- Procedure 1: Process New Order
-- Purpose: Create order with validation
CREATE OR REPLACE PROCEDURE create_order(
    p_customer_id VARCHAR(20),
    p_order_id VARCHAR(20),
    p_order_date DATE DEFAULT CURRENT_DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validate customer exists
    IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
        RAISE EXCEPTION 'Customer % does not exist', p_customer_id;
    END IF;
    
    -- Insert order
    INSERT INTO orders (order_id, customer_id, order_date, order_status, total_amount)
    VALUES (p_order_id, p_customer_id, p_order_date, 'Pending', 0);
    
    RAISE NOTICE 'Order % created successfully', p_order_id;
END;
$$;

COMMENT ON PROCEDURE create_order IS 'Create a new order with validation';

-- Procedure 2: Add Order Item
-- Purpose: Add item to order with stock check
CREATE OR REPLACE PROCEDURE add_order_item(
    p_order_id VARCHAR(20),
    p_product_id INTEGER,
    p_quantity INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_unit_price NUMERIC;
    v_stock INTEGER;
BEGIN
    -- Validate order exists
    IF NOT EXISTS (SELECT 1 FROM orders WHERE order_id = p_order_id) THEN
        RAISE EXCEPTION 'Order % does not exist', p_order_id;
    END IF;
    
    -- Get product price and stock
    SELECT unit_price, stock_quantity
    INTO v_unit_price, v_stock
    FROM products
    WHERE product_id = p_product_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Product % does not exist', p_product_id;
    END IF;
    
    -- Check stock availability
    IF v_stock < p_quantity THEN
        RAISE EXCEPTION 'Insufficient stock for product %. Available: %, Requested: %', 
                        p_product_id, v_stock, p_quantity;
    END IF;
    
    -- Insert order item
    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    VALUES (p_order_id, p_product_id, p_quantity, v_unit_price);
    
    -- Update order total
    PERFORM update_order_total(p_order_id);
    
    RAISE NOTICE 'Item added to order %', p_order_id;
END;
$$;

COMMENT ON PROCEDURE add_order_item IS 'Add item to order with stock validation';

-- Procedure 3: Cancel Order
-- Purpose: Cancel order and restore stock
CREATE OR REPLACE PROCEDURE cancel_order(p_order_id VARCHAR(20))
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validate order exists
    IF NOT EXISTS (SELECT 1 FROM orders WHERE order_id = p_order_id) THEN
        RAISE EXCEPTION 'Order % does not exist', p_order_id;
    END IF;
    
    -- Restore stock for all items
    UPDATE products p
    SET stock_quantity = stock_quantity + oi.quantity,
        updated_at = NOW()
    FROM order_items oi
    WHERE oi.product_id = p.product_id
      AND oi.order_id = p_order_id;
    
    -- Update order status
    UPDATE orders
    SET order_status = 'Cancelled',
        updated_at = NOW()
    WHERE order_id = p_order_id;
    
    RAISE NOTICE 'Order % cancelled successfully', p_order_id;
END;
$$;

COMMENT ON PROCEDURE cancel_order IS 'Cancel order and restore product stock';

-- Procedure 4: Complete Order
-- Purpose: Mark order as delivered and decrease stock
CREATE OR REPLACE PROCEDURE complete_order(p_order_id VARCHAR(20))
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validate order exists
    IF NOT EXISTS (SELECT 1 FROM orders WHERE order_id = p_order_id) THEN
        RAISE EXCEPTION 'Order % does not exist', p_order_id;
    END IF;
    
    -- Decrease stock for all items
    UPDATE products p
    SET stock_quantity = stock_quantity - oi.quantity,
        updated_at = NOW()
    FROM order_items oi
    WHERE oi.product_id = p.product_id
      AND oi.order_id = p_order_id;
    
    -- Update order status
    UPDATE orders
    SET order_status = 'Delivered',
        updated_at = NOW()
    WHERE order_id = p_order_id;
    
    RAISE NOTICE 'Order % completed successfully', p_order_id;
END;
$$;

COMMENT ON PROCEDURE complete_order IS 'Complete order and decrease product stock';

-- Procedure 5: Archive Old Orders
-- Purpose: Archive orders older than specified days
CREATE OR REPLACE PROCEDURE archive_old_orders(p_days_old INTEGER DEFAULT 365)
LANGUAGE plpgsql
AS $$
DECLARE
    v_archived_count INTEGER;
BEGIN
    -- This is a placeholder - in production you'd move to archive table
    -- For now, we'll just update a flag or status
    
    SELECT COUNT(*)
    INTO v_archived_count
    FROM orders
    WHERE order_date < CURRENT_DATE - INTERVAL '1 day' * p_days_old
      AND order_status = 'Delivered';
    
    RAISE NOTICE 'Found % orders eligible for archiving', v_archived_count;
END;
$$;

COMMENT ON PROCEDURE archive_old_orders IS 'Archive orders older than specified days';

-- ============================================================================
-- TRIGGER FUNCTIONS
-- ============================================================================

-- Trigger Function 1: Auto-update order total when item added
CREATE OR REPLACE FUNCTION trg_update_order_total()
RETURNS TRIGGER AS $$
BEGIN
    -- Update order total when item is inserted or updated
    PERFORM update_order_total(NEW.order_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger Function 2: Auto-update timestamp
CREATE OR REPLACE FUNCTION trg_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers (commented out - uncomment to activate)
/*
DROP TRIGGER IF EXISTS update_order_total_trigger ON order_items;
CREATE TRIGGER update_order_total_trigger
AFTER INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW
EXECUTE FUNCTION trg_update_order_total();

DROP TRIGGER IF EXISTS update_timestamp_customers ON customers;
CREATE TRIGGER update_timestamp_customers
BEFORE UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION trg_update_timestamp();

DROP TRIGGER IF EXISTS update_timestamp_products ON products;
CREATE TRIGGER update_timestamp_products
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION trg_update_timestamp();

DROP TRIGGER IF EXISTS update_timestamp_orders ON orders;
CREATE TRIGGER update_timestamp_orders
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION trg_update_timestamp();
*/

-- ============================================================================
-- USAGE EXAMPLES
-- ============================================================================

/*
-- Example 1: Get customer statistics
SELECT * FROM get_customer_stats('C001');

-- Example 2: Get top 10 products
SELECT * FROM get_top_products(10);

-- Example 3: Get revenue for date range
SELECT * FROM get_revenue_by_period('2024-01-01', '2024-12-31');

-- Example 4: Search customers
SELECT * FROM search_customers('john');

-- Example 5: Get customer order history
SELECT * FROM get_customer_orders('C001');

-- Example 6: Check product stock
SELECT check_product_stock(1, 5);

-- Example 7: Get monthly revenue for 2024
SELECT * FROM get_monthly_revenue(2024);

-- Example 8: Create new order
CALL create_order('C001', 'ORD999', CURRENT_DATE);

-- Example 9: Add item to order
CALL add_order_item('ORD999', 1, 2);

-- Example 10: Cancel order
CALL cancel_order('ORD999');
*/

-- ============================================================================
-- END OF PROCEDURES
-- ============================================================================
