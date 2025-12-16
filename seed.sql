-- ============================================================================
-- Seed Data for Customer Order Management System
-- Author: Development Team
-- Date: December 2024
-- Purpose: Populate database with sample data for testing and development
-- ============================================================================

-- Disable triggers temporarily for bulk insert (optional, for performance)
-- SET session_replication_role = 'replica';

BEGIN;

-- ============================================================================
-- TABLE: states
-- Insert US States reference data
-- ============================================================================

INSERT INTO states (state_code, state_name) VALUES
('AL', 'Alabama'),
('AK', 'Alaska'),
('AZ', 'Arizona'),
('AR', 'Arkansas'),
('CA', 'California'),
('CO', 'Colorado'),
('CT', 'Connecticut'),
('DE', 'Delaware'),
('FL', 'Florida'),
('GA', 'Georgia'),
('HI', 'Hawaii'),
('ID', 'Idaho'),
('IL', 'Illinois'),
('IN', 'Indiana'),
('IA', 'Iowa'),
('KS', 'Kansas'),
('KY', 'Kentucky'),
('LA', 'Louisiana'),
('ME', 'Maine'),
('MD', 'Maryland'),
('MA', 'Massachusetts'),
('MI', 'Michigan'),
('MN', 'Minnesota'),
('MS', 'Mississippi'),
('MO', 'Missouri'),
('MT', 'Montana'),
('NE', 'Nebraska'),
('NV', 'Nevada'),
('NH', 'New Hampshire'),
('NJ', 'New Jersey'),
('NM', 'New Mexico'),
('NY', 'New York'),
('NC', 'North Carolina'),
('ND', 'North Dakota'),
('OH', 'Ohio'),
('OK', 'Oklahoma'),
('OR', 'Oregon'),
('PA', 'Pennsylvania'),
('RI', 'Rhode Island'),
('SC', 'South Carolina'),
('SD', 'South Dakota'),
('TN', 'Tennessee'),
('TX', 'Texas'),
('UT', 'Utah'),
('VT', 'Vermont'),
('VA', 'Virginia'),
('WA', 'Washington'),
('WV', 'West Virginia'),
('WI', 'Wisconsin'),
('WY', 'Wyoming');

-- ============================================================================
-- TABLE: customers
-- Insert cleaned customer data (from Google Sheets audit)
-- ============================================================================

INSERT INTO customers (customer_id, full_name, email, phone_number, city, state_code, registered_at, status, email_verified) VALUES
-- Clean, verified customers
('C001', 'John Doe', 'john.doe@email.com', '555-0101', 'New York', 'NY', '2023-01-15', 'Active', TRUE),
('C002', 'Jane Smith', 'jane.smith@email.com', '555-0102', 'Los Angeles', 'CA', '2023-02-20', 'Active', TRUE),
('C003', 'Bob Johnson', 'bob.johnson@email.com', '555-0103', 'Chicago', 'IL', '2023-03-10', 'Active', TRUE),
('C004', 'Alice Williams', 'alice.w@email.com', '555-0104', 'Houston', 'TX', '2023-03-25', 'Active', TRUE),
('C005', 'Charlie Brown', 'charlie.brown@email.com', '555-0106', 'Phoenix', 'AZ', '2023-03-15', 'Active', FALSE),
('C006', 'Diana Prince', 'diana.prince@email.com', '555-0107', 'Philadelphia', 'PA', '2023-05-20', 'Active', TRUE),
('C007', 'Frank Miller', 'frank.miller@email.com', '555-0109', 'San Diego', 'CA', '2023-06-15', 'Active', FALSE),
('C008', 'Grace Lee', 'grace.lee@email.com', '555-0111', 'San Jose', 'CA', '2023-08-15', 'Active', TRUE),
('C009', 'Henry Wilson', 'henry.w@email.com', '555-0112', 'Austin', 'TX', '2023-09-01', 'Inactive', TRUE),
('C010', 'Ivy Chen', 'ivy.chen@email.com', '555-0114', 'Seattle', 'WA', '2023-10-05', 'Active', TRUE),
('C011', 'José García', 'jose.garcia@email.com', '555-0115', 'San Francisco', 'CA', '2023-11-12', 'Active', TRUE),
('C012', 'Karen Moore', 'karen.moore@email.com', '555-0117', 'Denver', 'CO', '2024-01-15', 'Active', FALSE),
('C013', 'Larry Page', 'larry@email.com', '555-0118', 'Portland', 'OR', '2024-01-20', 'Pending', FALSE),
('C014', 'Mary Johnson', 'mary.j@email.com', '555-0119', 'Boston', 'MA', '2024-02-01', 'Active', TRUE),
('C015', 'Nathan Drake', 'nathan.drake@email.com', '555-0120', 'Miami', 'FL', '2024-02-15', 'Active', TRUE);

-- ============================================================================
-- TABLE: products
-- Insert product catalog
-- ============================================================================

INSERT INTO products (product_name, description, unit_price, stock_quantity, is_active) VALUES
-- Electronics
('Laptop', 'High-performance laptop with 16GB RAM and 512GB SSD', 999.99, 50, TRUE),
('Wireless Mouse', 'Ergonomic wireless mouse with USB receiver', 25.50, 200, TRUE),
('Mechanical Keyboard', 'RGB mechanical keyboard with blue switches', 75.00, 100, TRUE),
('27" Monitor', '4K UHD monitor with HDR support', 299.99, 75, TRUE),
('USB-C Cable', 'USB-C to USB-C cable, 6ft length', 15.99, 500, TRUE),
('Wireless Headphones', 'Noise-canceling over-ear headphones', 150.00, 80, TRUE),
('Webcam', '1080p HD webcam with built-in microphone', 89.99, 60, TRUE),
('External SSD Drive', '1TB portable SSD with USB 3.2', 199.99, 120, TRUE),
('RAM Module 16GB', 'DDR4 16GB RAM module for desktop', 120.00, 90, TRUE),
('Microphone', 'USB condenser microphone for streaming', 89.99, 45, TRUE),

-- Office Supplies
('Notebook Pack', 'Pack of 5 college-ruled notebooks', 12.99, 300, TRUE),
('Pen Set', 'Set of 12 ballpoint pens, assorted colors', 8.50, 250, TRUE),
('Desk Lamp', 'LED desk lamp with adjustable brightness', 35.00, 150, TRUE),
('Ergonomic Chair', 'Adjustable office chair with lumbar support', 249.99, 40, TRUE),
('Standing Desk', 'Electric height-adjustable standing desk', 449.99, 25, TRUE),

-- Discontinued products
('Old Model Laptop', 'Previous generation laptop', 799.99, 0, FALSE),
('Legacy Mouse', 'Older mouse model', 15.00, 0, FALSE);

-- ============================================================================
-- TABLE: orders
-- Insert order headers
-- ============================================================================

INSERT INTO orders (order_id, customer_id, order_date, order_status, notes) VALUES
('ORD001', 'C001', '2023-06-15', 'Delivered', 'First order - welcome discount applied'),
('ORD002', 'C002', '2023-06-16', 'Delivered', NULL),
('ORD003', 'C003', '2023-06-17', 'Delivered', NULL),
('ORD004', 'C001', '2023-06-20', 'Delivered', 'Repeat customer'),
('ORD005', 'C002', '2023-06-21', 'Shipped', 'Express shipping'),
('ORD006', 'C006', '2023-06-22', 'Cancelled', 'Customer requested cancellation'),
('ORD007', 'C007', '2023-06-23', 'Delivered', NULL),
('ORD008', 'C008', '2023-06-24', 'Delivered', NULL),
('ORD009', 'C009', '2023-06-25', 'Processing', NULL),
('ORD010', 'C001', '2023-07-01', 'Delivered', 'Loyal customer - 3rd order'),
('ORD011', 'C010', '2023-07-05', 'Shipped', NULL),
('ORD012', 'C011', '2023-07-10', 'Delivered', NULL),
('ORD013', 'C004', '2023-07-15', 'Delivered', NULL),
('ORD014', 'C005', '2023-07-20', 'Delivered', NULL),
('ORD015', 'C012', '2024-01-25', 'Pending', 'New customer order'),
('ORD016', 'C013', '2024-02-01', 'Processing', NULL),
('ORD017', 'C014', '2024-02-10', 'Shipped', NULL),
('ORD018', 'C015', '2024-02-20', 'Delivered', NULL),
('ORD019', 'C002', '2024-02-25', 'Processing', 'Bulk order'),
('ORD020', 'C008', '2024-03-01', 'Pending', NULL);

-- ============================================================================
-- TABLE: order_items
-- Insert order line items (products for each order)
-- Note: total_amount in orders will be automatically calculated by trigger
-- ============================================================================

-- Insert order items using INSERT INTO ... SELECT
-- ORD001: Laptop
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD001', product_id, 1, unit_price FROM products WHERE product_name = 'Laptop';

-- ORD002: Mouse (2 units)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD002', product_id, 2, unit_price FROM products WHERE product_name = 'Wireless Mouse';

-- ORD003: Keyboard
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD003', product_id, 1, unit_price FROM products WHERE product_name = 'Mechanical Keyboard';

-- ORD004: USB Cable (5 units)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD004', product_id, 5, unit_price FROM products WHERE product_name = 'USB-C Cable';

-- ORD005: Headphones
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD005', product_id, 1, unit_price FROM products WHERE product_name = 'Wireless Headphones';

-- ORD006: Webcam (Cancelled order)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD006', product_id, 1, unit_price FROM products WHERE product_name = 'Webcam';

-- ORD007: Monitor
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD007', product_id, 1, unit_price FROM products WHERE product_name = '27" Monitor';

-- ORD008: External SSD
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD008', product_id, 1, unit_price FROM products WHERE product_name = 'External SSD Drive';

-- ORD009: RAM (2 units)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD009', product_id, 2, unit_price FROM products WHERE product_name = 'RAM Module 16GB';

-- ORD010: Multiple items
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD010', product_id, 1, unit_price FROM products WHERE product_name = 'Laptop';

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD010', product_id, 1, unit_price FROM products WHERE product_name = 'Wireless Mouse';

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD010', product_id, 1, unit_price FROM products WHERE product_name = 'Mechanical Keyboard';

-- ORD011: Microphone
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD011', product_id, 1, unit_price FROM products WHERE product_name = 'Microphone';

-- ORD012: Notebook Pack (3 units)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD012', product_id, 3, unit_price FROM products WHERE product_name = 'Notebook Pack';

-- ORD013: Desk Lamp
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD013', product_id, 1, unit_price FROM products WHERE product_name = 'Desk Lamp';

-- ORD014: Pen Set (5 units)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD014', product_id, 5, unit_price FROM products WHERE product_name = 'Pen Set';

-- ORD015: Ergonomic Chair
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD015', product_id, 1, unit_price FROM products WHERE product_name = 'Ergonomic Chair';

-- ORD016: Standing Desk
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD016', product_id, 1, unit_price FROM products WHERE product_name = 'Standing Desk';

-- ORD017: Multiple office items
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD017', product_id, 2, unit_price FROM products WHERE product_name = 'Notebook Pack';

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD017', product_id, 3, unit_price FROM products WHERE product_name = 'Pen Set';

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD017', product_id, 1, unit_price FROM products WHERE product_name = 'Desk Lamp';

-- ORD018: Laptop + Mouse combo
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD018', product_id, 1, unit_price FROM products WHERE product_name = 'Laptop';

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD018', product_id, 1, unit_price FROM products WHERE product_name = 'Wireless Mouse';

-- ORD019: Bulk order - multiple monitors
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD019', product_id, 5, unit_price FROM products WHERE product_name = '27" Monitor';

-- ORD020: Webcam + Microphone
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD020', product_id, 1, unit_price FROM products WHERE product_name = 'Webcam';

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD020', product_id, 1, unit_price FROM products WHERE product_name = 'Microphone';

-- ============================================================================
-- Verify Data Insertion
-- ============================================================================

-- Display summary of inserted data
DO $$
DECLARE
    v_states_count INTEGER;
    v_customers_count INTEGER;
    v_products_count INTEGER;
    v_orders_count INTEGER;
    v_order_items_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_states_count FROM states;
    SELECT COUNT(*) INTO v_customers_count FROM customers;
    SELECT COUNT(*) INTO v_products_count FROM products;
    SELECT COUNT(*) INTO v_orders_count FROM orders;
    SELECT COUNT(*) INTO v_order_items_count FROM order_items;
    
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Seed Data Summary:';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'States inserted: %', v_states_count;
    RAISE NOTICE 'Customers inserted: %', v_customers_count;
    RAISE NOTICE 'Products inserted: %', v_products_count;
    RAISE NOTICE 'Orders inserted: %', v_orders_count;
    RAISE NOTICE 'Order Items inserted: %', v_order_items_count;
    RAISE NOTICE '============================================';
END $$;

-- Display sample data from each table
SELECT 'CUSTOMERS SAMPLE:' AS info;
SELECT customer_id, full_name, email, city, state_code, status 
FROM customers 
LIMIT 5;

SELECT 'PRODUCTS SAMPLE:' AS info;
SELECT product_id, product_name, unit_price, stock_quantity, is_active 
FROM products 
WHERE is_active = TRUE
LIMIT 5;

SELECT 'ORDERS SAMPLE:' AS info;
SELECT order_id, customer_id, order_date, order_status, total_amount 
FROM orders 
LIMIT 5;

SELECT 'ORDER ITEMS SAMPLE:' AS info;
SELECT oi.order_item_id, oi.order_id, p.product_name, oi.quantity, oi.unit_price, oi.line_total
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LIMIT 5;

-- Test views
SELECT 'CUSTOMER ORDER SUMMARY (Top 5):' AS info;
SELECT * FROM vw_customer_order_summary 
ORDER BY total_spent DESC 
LIMIT 5;

-- Re-enable triggers
-- SET session_replication_role = 'origin';

COMMIT;

-- ============================================================================
-- Seed Data Insertion Complete
-- ============================================================================

SELECT 
    '✅ Seed data loaded successfully!' AS status,
    NOW() AS completed_at;
