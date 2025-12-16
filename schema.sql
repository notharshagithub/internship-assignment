-- ============================================================================
-- Database Schema for Customer Order Management System
-- Author: Development Team
-- Date: December 2024
-- Database: PostgreSQL 15+ / NeonDB
-- Normalization: 3NF (Third Normal Form)
-- ============================================================================

-- Drop existing tables if they exist (for clean recreate)
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS states CASCADE;

-- Drop custom types if they exist
DROP TYPE IF EXISTS customer_status_enum CASCADE;
DROP TYPE IF EXISTS order_status_enum CASCADE;

-- ============================================================================
-- ENUM TYPES for Status Fields (ensures data consistency)
-- ============================================================================

CREATE TYPE customer_status_enum AS ENUM ('Active', 'Inactive', 'Pending');
CREATE TYPE order_status_enum AS ENUM ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled');

-- ============================================================================
-- TABLE: states
-- Purpose: Reference table for US states (Normalization: eliminates redundancy)
-- ============================================================================

CREATE TABLE states (
    state_code VARCHAR(2) PRIMARY KEY,
    state_name VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE states IS 'US States reference table for normalization';
COMMENT ON COLUMN states.state_code IS 'Two-letter state abbreviation (e.g., NY, CA)';
COMMENT ON COLUMN states.state_name IS 'Full state name (e.g., New York, California)';

-- ============================================================================
-- TABLE: customers
-- Purpose: Customer master data
-- Normalization: 3NF (no transitive dependencies, state normalized to separate table)
-- ============================================================================

CREATE TABLE customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone_number VARCHAR(20),
    city VARCHAR(100),
    state_code VARCHAR(2),
    registered_at DATE NOT NULL DEFAULT CURRENT_DATE,
    status customer_status_enum NOT NULL DEFAULT 'Active',
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    -- Foreign Key Constraints
    CONSTRAINT fk_customers_state 
        FOREIGN KEY (state_code) 
        REFERENCES states(state_code)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT chk_customer_id_format 
        CHECK (customer_id ~ '^C[0-9]+$'),
    
    CONSTRAINT chk_email_format 
        CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    
    CONSTRAINT chk_phone_format 
        CHECK (phone_number IS NULL OR phone_number ~ '^[0-9]{3}-[0-9]{4}$' OR phone_number ~ '^[0-9]{10}$'),
    
    CONSTRAINT chk_registered_date 
        CHECK (registered_at <= CURRENT_DATE)
);

COMMENT ON TABLE customers IS 'Customer master data with contact information';
COMMENT ON COLUMN customers.customer_id IS 'Unique customer identifier (format: C###)';
COMMENT ON COLUMN customers.email IS 'Customer email address (unique, required)';
COMMENT ON COLUMN customers.email_verified IS 'Email verification status';
COMMENT ON COLUMN customers.status IS 'Account status: Active, Inactive, or Pending';

-- ============================================================================
-- TABLE: products
-- Purpose: Product catalog (normalized from order data)
-- Normalization: Separates product info from orders (eliminates update anomalies)
-- ============================================================================

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    unit_price DECIMAL(10,2) NOT NULL,
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    -- Check Constraints
    CONSTRAINT chk_unit_price_positive 
        CHECK (unit_price >= 0),
    
    CONSTRAINT chk_stock_quantity_non_negative 
        CHECK (stock_quantity >= 0)
);

COMMENT ON TABLE products IS 'Product catalog with pricing and inventory';
COMMENT ON COLUMN products.product_id IS 'Auto-generated unique product identifier';
COMMENT ON COLUMN products.unit_price IS 'Current price per unit';
COMMENT ON COLUMN products.stock_quantity IS 'Available inventory quantity';

-- ============================================================================
-- TABLE: orders
-- Purpose: Order header information
-- Normalization: 3NF (order details separated to order_items table)
-- ============================================================================

CREATE TABLE orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    order_status order_status_enum NOT NULL DEFAULT 'Pending',
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    -- Foreign Key Constraints
    CONSTRAINT fk_orders_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT chk_order_id_format 
        CHECK (order_id ~ '^ORD[0-9]+$'),
    
    CONSTRAINT chk_total_amount_non_negative 
        CHECK (total_amount >= 0),
    
    CONSTRAINT chk_order_date_valid 
        CHECK (order_date <= CURRENT_DATE + INTERVAL '1 day')
);

COMMENT ON TABLE orders IS 'Order header information';
COMMENT ON COLUMN orders.order_id IS 'Unique order identifier (format: ORD###)';
COMMENT ON COLUMN orders.total_amount IS 'Total order amount (calculated from order_items)';
COMMENT ON COLUMN orders.order_status IS 'Current status of the order';

-- ============================================================================
-- TABLE: order_items
-- Purpose: Order line items (supports multiple products per order)
-- Normalization: 3NF (separates product details from orders, enables N:M relationship)
-- ============================================================================

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id VARCHAR(20) NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(10,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    -- Foreign Key Constraints
    CONSTRAINT fk_order_items_order 
        FOREIGN KEY (order_id) 
        REFERENCES orders(order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_order_items_product 
        FOREIGN KEY (product_id) 
        REFERENCES products(product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT chk_quantity_positive 
        CHECK (quantity > 0),
    
    CONSTRAINT chk_unit_price_non_negative 
        CHECK (unit_price >= 0),
    
    -- Unique Constraint (prevent duplicate product in same order)
    CONSTRAINT uq_order_product 
        UNIQUE (order_id, product_id)
);

COMMENT ON TABLE order_items IS 'Individual line items for each order';
COMMENT ON COLUMN order_items.line_total IS 'Calculated field: quantity × unit_price';
COMMENT ON COLUMN order_items.unit_price IS 'Price at time of order (historical pricing)';

-- ============================================================================
-- INDEXES for Performance Optimization
-- ============================================================================

-- Customers table indexes
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_status ON customers(status) WHERE status = 'Active';
CREATE INDEX idx_customers_registered_at ON customers(registered_at DESC);
CREATE INDEX idx_customers_state ON customers(state_code);
CREATE INDEX idx_customers_name ON customers(full_name);

-- Products table indexes
CREATE INDEX idx_products_name ON products(product_name);
CREATE INDEX idx_products_active ON products(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_products_price ON products(unit_price);

-- Orders table indexes
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date DESC);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date DESC);

-- Order items table indexes
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- ============================================================================
-- TRIGGERS for Automatic Timestamp Updates
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for customers table
CREATE TRIGGER trigger_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for products table
CREATE TRIGGER trigger_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for orders table
CREATE TRIGGER trigger_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- FUNCTION: Update order total amount
-- Purpose: Automatically calculate and update order total when items change
-- ============================================================================

CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE orders
    SET total_amount = (
        SELECT COALESCE(SUM(line_total), 0)
        FROM order_items
        WHERE order_id = COALESCE(NEW.order_id, OLD.order_id)
    )
    WHERE order_id = COALESCE(NEW.order_id, OLD.order_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Triggers to update order total when order_items change
CREATE TRIGGER trigger_order_items_insert
    AFTER INSERT ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION update_order_total();

CREATE TRIGGER trigger_order_items_update
    AFTER UPDATE ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION update_order_total();

CREATE TRIGGER trigger_order_items_delete
    AFTER DELETE ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION update_order_total();

-- ============================================================================
-- VIEWS for Common Queries
-- ============================================================================

-- View: Customer order summary
CREATE OR REPLACE VIEW vw_customer_order_summary AS
SELECT 
    c.customer_id,
    c.full_name,
    c.email,
    c.status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS total_spent,
    MAX(o.order_date) AS last_order_date,
    MIN(o.order_date) AS first_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name, c.email, c.status;

COMMENT ON VIEW vw_customer_order_summary IS 'Summary of customer orders and spending';

-- View: Order details with customer info
CREATE OR REPLACE VIEW vw_order_details AS
SELECT 
    o.order_id,
    o.order_date,
    o.order_status,
    c.customer_id,
    c.full_name AS customer_name,
    c.email AS customer_email,
    c.city,
    s.state_name,
    o.total_amount,
    COUNT(oi.order_item_id) AS item_count
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN states s ON c.state_code = s.state_code
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.order_date, o.order_status, c.customer_id, 
         c.full_name, c.email, c.city, s.state_name, o.total_amount;

COMMENT ON VIEW vw_order_details IS 'Complete order information with customer details';

-- View: Product sales summary
CREATE OR REPLACE VIEW vw_product_sales_summary AS
SELECT 
    p.product_id,
    p.product_name,
    p.unit_price AS current_price,
    COUNT(oi.order_item_id) AS times_ordered,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.line_total) AS total_revenue
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.unit_price;

COMMENT ON VIEW vw_product_sales_summary IS 'Product sales performance metrics';

-- ============================================================================
-- GRANT PERMISSIONS (adjust based on your user roles)
-- ============================================================================

-- Grant read-only access to views for reporting users (example)
-- GRANT SELECT ON vw_customer_order_summary TO reporting_user;
-- GRANT SELECT ON vw_order_details TO reporting_user;
-- GRANT SELECT ON vw_product_sales_summary TO reporting_user;

-- ============================================================================
-- Schema Creation Complete
-- ============================================================================

-- Display table summary
SELECT 
    'Schema created successfully!' AS status,
    COUNT(*) AS table_count
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE';
