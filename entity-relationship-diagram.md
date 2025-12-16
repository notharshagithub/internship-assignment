# Entity-Relationship Diagram & Schema

## Visual ERD

```
┌─────────────────────────────────────────┐
│             CUSTOMERS                    │
├─────────────────────────────────────────┤
│ PK  customer_id      VARCHAR(20)        │
│     full_name        VARCHAR(100)       │
│ U   email            VARCHAR(255)       │
│     phone_number     VARCHAR(20)        │
│     city             VARCHAR(100)       │
│     state_code       VARCHAR(2)         │
│     registered_at    DATE               │
│     status           VARCHAR(20)        │
│     email_verified   BOOLEAN            │
│     created_at       TIMESTAMP          │
│     updated_at       TIMESTAMP          │
└─────────────────────────────────────────┘
                  │
                  │ 1
                  │
                  │
                  │ N
                  ▼
┌─────────────────────────────────────────┐
│              ORDERS                      │
├─────────────────────────────────────────┤
│ PK  order_id         VARCHAR(20)        │
│ FK  customer_id      VARCHAR(20)        │
│     product_name     VARCHAR(255)       │
│     quantity         INTEGER            │
│     unit_price       DECIMAL(10,2)      │
│     total_amount     DECIMAL(10,2)      │
│     order_date       DATE               │
│     order_status     VARCHAR(20)        │
│     created_at       TIMESTAMP          │
│     updated_at       TIMESTAMP          │
└─────────────────────────────────────────┘
```

## Relationship Details

**Relationship Type:** One-to-Many (1:N)

- **Parent Entity:** Customers
- **Child Entity:** Orders
- **Relationship:** "places" / "belongs to"
- **Cardinality:** 
  - One customer can place zero or many orders
  - One order must belong to exactly one customer

**Foreign Key:**
```sql
orders.customer_id → customers.customer_id
```

## Entity Attributes Table

### Customers Entity

| Attribute | Data Type | Constraints | Description | Example |
|-----------|-----------|-------------|-------------|---------|
| customer_id | VARCHAR(20) | PRIMARY KEY, NOT NULL | Unique customer identifier | C001 |
| full_name | VARCHAR(100) | NOT NULL | Customer's full name | John Doe |
| email | VARCHAR(255) | UNIQUE, NOT NULL | Email address (unique) | john.doe@email.com |
| phone_number | VARCHAR(20) | NULL | Contact phone number | 555-0101 |
| city | VARCHAR(100) | NULL | City of residence | New York |
| state_code | VARCHAR(2) | NULL | Two-letter state code | NY |
| registered_at | DATE | NOT NULL | Registration date | 2023-01-15 |
| status | VARCHAR(20) | NOT NULL, DEFAULT 'Active' | Account status | Active, Inactive, Pending |
| email_verified | BOOLEAN | NOT NULL, DEFAULT FALSE | Email verification flag | TRUE/FALSE |
| created_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | Record creation timestamp | 2024-01-15 10:30:00 |
| updated_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | Last update timestamp | 2024-01-15 10:30:00 |

**Business Rules:**
- Email must be unique and valid format
- Status must be one of: Active, Inactive, Pending
- Customer ID format: C followed by digits (e.g., C001, C002)

### Orders Entity

| Attribute | Data Type | Constraints | Description | Example |
|-----------|-----------|-------------|-------------|---------|
| order_id | VARCHAR(20) | PRIMARY KEY, NOT NULL | Unique order identifier | ORD001 |
| customer_id | VARCHAR(20) | FOREIGN KEY, NOT NULL | Reference to customer | C001 |
| product_name | VARCHAR(255) | NOT NULL | Name of product ordered | Laptop |
| quantity | INTEGER | CHECK (quantity > 0), NOT NULL | Quantity ordered | 2 |
| unit_price | DECIMAL(10,2) | CHECK (unit_price >= 0), NOT NULL | Price per unit | 999.99 |
| total_amount | DECIMAL(10,2) | GENERATED | Calculated: quantity * unit_price | 1999.98 |
| order_date | DATE | NOT NULL | Date order was placed | 2023-06-15 |
| order_status | VARCHAR(20) | NOT NULL, DEFAULT 'Pending' | Current order status | Delivered, Pending |
| created_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | Record creation timestamp | 2024-01-15 10:30:00 |
| updated_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | Last update timestamp | 2024-01-15 10:30:00 |

**Business Rules:**
- Customer ID must reference an existing customer
- Quantity must be a positive integer
- Unit price must be zero or positive
- Order status must be one of: Pending, Processing, Shipped, Delivered, Cancelled
- Order ID format: ORD followed by digits (e.g., ORD001, ORD002)

## Indexes

### Customers Table
```sql
PRIMARY KEY INDEX on customer_id
UNIQUE INDEX on email
INDEX on status (for filtering active/inactive customers)
INDEX on registered_at (for date range queries)
```

### Orders Table
```sql
PRIMARY KEY INDEX on order_id
FOREIGN KEY INDEX on customer_id
INDEX on order_date (for date range queries)
INDEX on order_status (for filtering by status)
INDEX on (customer_id, order_date) (composite for customer order history)
```

## Constraints

### Customers Table Constraints
```sql
-- Primary Key
CONSTRAINT pk_customers PRIMARY KEY (customer_id)

-- Unique Constraint
CONSTRAINT uq_customers_email UNIQUE (email)

-- Check Constraints
CONSTRAINT chk_customers_status 
  CHECK (status IN ('Active', 'Inactive', 'Pending'))

CONSTRAINT chk_customers_state_code 
  CHECK (LENGTH(state_code) = 2 OR state_code IS NULL)
```

### Orders Table Constraints
```sql
-- Primary Key
CONSTRAINT pk_orders PRIMARY KEY (order_id)

-- Foreign Key
CONSTRAINT fk_orders_customer 
  FOREIGN KEY (customer_id) 
  REFERENCES customers(customer_id)
  ON DELETE RESTRICT
  ON UPDATE CASCADE

-- Check Constraints
CONSTRAINT chk_orders_quantity 
  CHECK (quantity > 0)

CONSTRAINT chk_orders_unit_price 
  CHECK (unit_price >= 0)

CONSTRAINT chk_orders_status 
  CHECK (order_status IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'))
```

## Sample Queries

### Get customer with their orders
```sql
SELECT 
  c.customer_id,
  c.full_name,
  c.email,
  COUNT(o.order_id) as total_orders,
  SUM(o.total_amount) as total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.status = 'Active'
GROUP BY c.customer_id, c.full_name, c.email
ORDER BY total_spent DESC;
```

### Get orders with customer details
```sql
SELECT 
  o.order_id,
  o.order_date,
  c.full_name as customer_name,
  c.email,
  o.product_name,
  o.quantity,
  o.unit_price,
  o.total_amount,
  o.order_status
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_date >= '2023-01-01'
ORDER BY o.order_date DESC;
```

### Find customers without orders
```sql
SELECT 
  c.customer_id,
  c.full_name,
  c.email,
  c.registered_at
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
  AND c.status = 'Active';
```
