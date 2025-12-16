-- ============================================================================
-- Schema for Public Datasets Practice
-- ============================================================================

-- Drop existing tables
DROP TABLE IF EXISTS ecommerce_orders CASCADE;
DROP TABLE IF EXISTS customer_surveys CASCADE;
DROP TABLE IF EXISTS survey_analytics CASCADE;

-- ============================================================================
-- TABLE: ecommerce_orders (Clean Dataset)
-- ============================================================================

CREATE TABLE ecommerce_orders (
    id SERIAL PRIMARY KEY,
    order_id VARCHAR(20) UNIQUE NOT NULL,
    customer_id VARCHAR(20) NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    customer_email VARCHAR(255) NOT NULL,
    customer_city VARCHAR(100),
    customer_state VARCHAR(2),
    product_name VARCHAR(255) NOT NULL,
    product_category VARCHAR(100),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
    order_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    loaded_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE ecommerce_orders IS 'Clean e-commerce orders dataset';

-- ============================================================================
-- TABLE: customer_surveys (Messy Dataset - Cleaned)
-- ============================================================================

CREATE TABLE customer_surveys (
    id SERIAL PRIMARY KEY,
    response_id VARCHAR(20) UNIQUE NOT NULL,
    full_name VARCHAR(100),
    email VARCHAR(255),
    phone_number VARCHAR(20),
    city VARCHAR(100),
    state VARCHAR(2),
    survey_date DATE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    comments TEXT,
    
    -- Data quality tracking
    original_name VARCHAR(100),
    original_email VARCHAR(255),
    original_phone VARCHAR(50),
    had_quality_issues BOOLEAN DEFAULT FALSE,
    quality_issues TEXT[],
    
    -- Metadata
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    loaded_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE customer_surveys IS 'Cleaned customer survey responses with quality tracking';

-- ============================================================================
-- INDEXES for Performance
-- ============================================================================

-- Ecommerce Orders Indexes
CREATE INDEX idx_ecommerce_orders_customer_id ON ecommerce_orders(customer_id);
CREATE INDEX idx_ecommerce_orders_order_date ON ecommerce_orders(order_date);
CREATE INDEX idx_ecommerce_orders_status ON ecommerce_orders(status);
CREATE INDEX idx_ecommerce_orders_category ON ecommerce_orders(product_category);
CREATE INDEX idx_ecommerce_orders_customer_email ON ecommerce_orders(customer_email);

-- Customer Surveys Indexes
CREATE INDEX idx_surveys_email ON customer_surveys(email);
CREATE INDEX idx_surveys_survey_date ON customer_surveys(survey_date);
CREATE INDEX idx_surveys_rating ON customer_surveys(rating);
CREATE INDEX idx_surveys_state ON customer_surveys(state);
CREATE INDEX idx_surveys_quality_issues ON customer_surveys(had_quality_issues);

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View: Order Summary by Customer
CREATE OR REPLACE VIEW vw_customer_order_summary AS
SELECT 
    customer_id,
    customer_name,
    customer_email,
    customer_state,
    COUNT(*) AS total_orders,
    SUM(total_amount) AS total_spent,
    AVG(total_amount) AS avg_order_value,
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
FROM ecommerce_orders
GROUP BY customer_id, customer_name, customer_email, customer_state;

-- View: Product Performance
CREATE OR REPLACE VIEW vw_product_performance AS
SELECT 
    product_name,
    product_category,
    COUNT(*) AS order_count,
    SUM(quantity) AS total_units_sold,
    SUM(total_amount) AS total_revenue,
    AVG(unit_price) AS avg_price
FROM ecommerce_orders
GROUP BY product_name, product_category
ORDER BY total_revenue DESC;

-- View: Survey Quality Report
CREATE OR REPLACE VIEW vw_survey_quality_report AS
SELECT 
    COUNT(*) AS total_responses,
    COUNT(CASE WHEN email IS NOT NULL AND email != '' THEN 1 END) AS valid_emails,
    COUNT(CASE WHEN phone_number IS NOT NULL THEN 1 END) AS valid_phones,
    COUNT(CASE WHEN had_quality_issues = TRUE THEN 1 END) AS records_with_issues,
    ROUND(COUNT(CASE WHEN had_quality_issues = TRUE THEN 1 END) * 100.0 / COUNT(*), 2) AS quality_issue_rate,
    AVG(rating) AS avg_rating
FROM customer_surveys;

-- ============================================================================
-- MATERIALIZED VIEWS for Heavy Queries
-- ============================================================================

-- Materialized View: Monthly Sales Summary
CREATE MATERIALIZED VIEW mv_monthly_sales AS
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(quantity) AS total_units_sold
FROM ecommerce_orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month DESC;

CREATE INDEX ON mv_monthly_sales(month);

-- Materialized View: Customer Segmentation
CREATE MATERIALIZED VIEW mv_customer_segments AS
SELECT 
    customer_id,
    customer_name,
    customer_email,
    customer_state,
    COUNT(*) AS order_count,
    SUM(total_amount) AS lifetime_value,
    CASE 
        WHEN SUM(total_amount) >= 1000 THEN 'VIP'
        WHEN SUM(total_amount) >= 500 THEN 'Premium'
        WHEN SUM(total_amount) >= 100 THEN 'Regular'
        ELSE 'New'
    END AS segment
FROM ecommerce_orders
GROUP BY customer_id, customer_name, customer_email, customer_state;

CREATE INDEX ON mv_customer_segments(segment);
CREATE INDEX ON mv_customer_segments(lifetime_value DESC);

-- ============================================================================
-- STORED PROCEDURES
-- ============================================================================

-- Procedure: Refresh Materialized Views
CREATE OR REPLACE FUNCTION refresh_all_materialized_views()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW mv_monthly_sales;
    REFRESH MATERIALIZED VIEW mv_customer_segments;
    RAISE NOTICE 'All materialized views refreshed successfully';
END;
$$ LANGUAGE plpgsql;

-- Function: Get Order Statistics
CREATE OR REPLACE FUNCTION get_order_statistics()
RETURNS TABLE (
    metric VARCHAR(50),
    value NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 'Total Orders'::VARCHAR(50), COUNT(*)::NUMERIC FROM ecommerce_orders
    UNION ALL
    SELECT 'Total Revenue', SUM(total_amount) FROM ecommerce_orders
    UNION ALL
    SELECT 'Avg Order Value', AVG(total_amount) FROM ecommerce_orders
    UNION ALL
    SELECT 'Unique Customers', COUNT(DISTINCT customer_id)::NUMERIC FROM ecommerce_orders;
END;
$$ LANGUAGE plpgsql;

-- Function: Get Survey Quality Metrics
CREATE OR REPLACE FUNCTION get_survey_quality_metrics()
RETURNS TABLE (
    metric VARCHAR(50),
    count BIGINT,
    percentage NUMERIC
) AS $$
DECLARE
    total_count BIGINT;
BEGIN
    SELECT COUNT(*) INTO total_count FROM customer_surveys;
    
    RETURN QUERY
    SELECT 
        'Total Responses'::VARCHAR(50),
        total_count,
        100.0::NUMERIC
    UNION ALL
    SELECT 
        'Valid Emails',
        COUNT(*),
        ROUND(COUNT(*) * 100.0 / total_count, 2)
    FROM customer_surveys WHERE email IS NOT NULL AND email ~ '^[^\s@]+@[^\s@]+\.[^\s@]+$'
    UNION ALL
    SELECT 
        'With Quality Issues',
        COUNT(*),
        ROUND(COUNT(*) * 100.0 / total_count, 2)
    FROM customer_surveys WHERE had_quality_issues = TRUE;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Performance Monitoring
-- ============================================================================

-- Track query performance
CREATE TABLE IF NOT EXISTS query_performance_log (
    id SERIAL PRIMARY KEY,
    query_name VARCHAR(100),
    execution_time_ms NUMERIC,
    rows_affected INTEGER,
    executed_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- Schema Setup Complete
-- ============================================================================

SELECT 'Schema created successfully!' AS status;
