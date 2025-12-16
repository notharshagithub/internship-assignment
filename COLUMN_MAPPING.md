# Column Mapping Document

**Project:** Data Migration - Google Sheets to PostgreSQL/NeonDB  
**Version:** 1.0  
**Date:** 2024

---

## Overview

This document provides detailed mapping between source Google Sheets columns and target PostgreSQL database schema, including all data transformations, validation rules, and handling of edge cases.

---

## Table 1: Customers Mapping

### Source: Google Sheets "Sheet1"
### Target: PostgreSQL `customers` table

| # | Source Column | Target Column | Source Type | Target Type | Required | Transformation | Validation Rule | Default Value | Notes |
|---|---------------|---------------|-------------|-------------|----------|----------------|-----------------|---------------|-------|
| 1 | Customer ID | customer_id | Text | VARCHAR(20) | Yes | Uppercase, remove special chars, standardize format | Must match pattern: ^C\d+$ | - | Primary Key |
| 2 | Name | full_name | Text | VARCHAR(100) | Yes | Trim whitespace, handle special chars (UTF-8) | Length >= 1 | - | Support international characters |
| 3 | Email | email | Text | VARCHAR(255) | Yes | Lowercase, trim whitespace | Valid email format (RFC 5322) | - | Must be unique |
| 4 | Phone | phone_number | Text | VARCHAR(20) | No | Standardize format or store digits only | Valid phone pattern or NULL | NULL | Multiple formats accepted |
| 5 | City | city | Text | VARCHAR(100) | No | Trim whitespace, title case | Length >= 1 or NULL | NULL | - |
| 6 | State | state_code | Text | VARCHAR(2) | No | Convert to 2-letter code, uppercase | Valid US state code or NULL | NULL | Map full names to codes |
| 7 | Registration Date | registered_at | Text | DATE | Yes | Parse multiple date formats to ISO 8601 | Valid date, not future | CURRENT_DATE | Parse: YYYY-MM-DD, MM/DD/YYYY, DD-MM-YYYY |
| 8 | Status | status | Text | VARCHAR(20) | Yes | Title case, standardize variants | Must be: Active, Inactive, Pending | 'Active' | Map all variants to standard |
| - | - | email_verified | - | BOOLEAN | Yes | - | - | FALSE | New column |
| - | - | created_at | - | TIMESTAMP | Yes | - | - | NOW() | Auto-generated |
| - | - | updated_at | - | TIMESTAMP | Yes | - | - | NOW() | Auto-generated |

### Detailed Transformation Rules

#### 1. customer_id Transformation
**Input Examples:**
- `C001` → `C001` ✅
- `c017` → `C017` ✅
- `C-018` → `C018` ✅
- `` (empty) → `C{next_number}` (generate)

**Transformation Logic:**
```javascript
function transformCustomerId(value) {
  if (!value || value.trim() === '') {
    return generateNextCustomerId(); // Generate C001, C002, etc.
  }
  
  // Remove non-alphanumeric, uppercase, ensure C prefix
  let cleaned = value.replace(/[^a-zA-Z0-9]/g, '').toUpperCase();
  
  if (!cleaned.startsWith('C')) {
    cleaned = 'C' + cleaned;
  }
  
  return cleaned;
}
```

#### 2. full_name Transformation
**Input Examples:**
- `John Doe` → `John Doe` ✅
- ` Ivy Chen ` → `Ivy Chen` ✅
- `José García` → `José García` ✅
- `O'Neil Patrick` → `O'Neil Patrick` ✅
- `123` → ⚠️ Flag for review (possibly valid but suspicious)
- `` (empty) → ❌ Required field error

**Transformation Logic:**
```javascript
function transformFullName(value) {
  if (!value || value.trim() === '') {
    throw new ValidationError('Name is required');
  }
  
  // Trim and normalize whitespace
  let cleaned = value.trim().replace(/\s+/g, ' ');
  
  // Flag suspicious patterns (all numbers, too short)
  if (/^\d+$/.test(cleaned)) {
    logWarning('Suspicious name (all digits)', cleaned);
  }
  
  return cleaned;
}
```

#### 3. email Transformation
**Input Examples:**
- `john.doe@email.com` → `john.doe@email.com` ✅
- `CHARLIE.BROWN@EMAIL.COM` → `charlie.brown@email.com` ✅
- `not-an-email` → ❌ Validation error → NULL (quarantine)
- `` (empty) → ❌ Required field error

**Transformation Logic:**
```javascript
function transformEmail(value) {
  if (!value || value.trim() === '') {
    throw new ValidationError('Email is required');
  }
  
  let cleaned = value.trim().toLowerCase();
  
  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(cleaned)) {
    throw new ValidationError('Invalid email format');
  }
  
  return cleaned;
}
```

#### 4. phone_number Transformation
**Input Examples:**
- `555-0101` → `555-0101` ✅
- `(555) 0106` → `555-0106` ✅
- `5550107` → `555-0107` ✅
- `555 0117` → `555-0117` ✅
- `+1-555-0118` → `555-0118` ✅
- `555-CALL` → NULL ⚠️ (invalid, set to NULL)
- `` (empty) → NULL ✅

**Transformation Logic:**
```javascript
function transformPhoneNumber(value) {
  if (!value || value.trim() === '') {
    return null;
  }
  
  // Extract only digits
  let digits = value.replace(/\D/g, '');
  
  // Remove country code if present
  if (digits.startsWith('1') && digits.length === 11) {
    digits = digits.substring(1);
  }
  
  // Validate 10 digits
  if (digits.length !== 10 || !/^\d{10}$/.test(digits)) {
    logWarning('Invalid phone number', value);
    return null;
  }
  
  // Format as XXX-XXXX or keep raw
  return digits.substring(0, 3) + '-' + digits.substring(3);
}
```

#### 5. city Transformation
**Input Examples:**
- `New York` → `New York` ✅
- `Seattle  ` → `Seattle` ✅
- `` (empty) → NULL ✅

**Transformation Logic:**
```javascript
function transformCity(value) {
  if (!value || value.trim() === '') {
    return null;
  }
  
  // Trim whitespace
  return value.trim().replace(/\s+/g, ' ');
}
```

#### 6. state_code Transformation
**Input Examples:**
- `NY` → `NY` ✅
- `CA` → `CA` ✅
- `Pennsylvania` → `PA` ✅
- `ny` → `NY` ✅
- `` (empty) → NULL ✅

**State Mapping Table:**
```javascript
const stateMap = {
  'ALABAMA': 'AL', 'ALASKA': 'AK', 'ARIZONA': 'AZ', 'ARKANSAS': 'AR',
  'CALIFORNIA': 'CA', 'COLORADO': 'CO', 'CONNECTICUT': 'CT', 'DELAWARE': 'DE',
  'FLORIDA': 'FL', 'GEORGIA': 'GA', 'HAWAII': 'HI', 'IDAHO': 'ID',
  'ILLINOIS': 'IL', 'INDIANA': 'IN', 'IOWA': 'IA', 'KANSAS': 'KS',
  'KENTUCKY': 'KY', 'LOUISIANA': 'LA', 'MAINE': 'ME', 'MARYLAND': 'MD',
  'MASSACHUSETTS': 'MA', 'MICHIGAN': 'MI', 'MINNESOTA': 'MN', 'MISSISSIPPI': 'MS',
  'MISSOURI': 'MO', 'MONTANA': 'MT', 'NEBRASKA': 'NE', 'NEVADA': 'NV',
  'NEW HAMPSHIRE': 'NH', 'NEW JERSEY': 'NJ', 'NEW MEXICO': 'NM', 'NEW YORK': 'NY',
  'NORTH CAROLINA': 'NC', 'NORTH DAKOTA': 'ND', 'OHIO': 'OH', 'OKLAHOMA': 'OK',
  'OREGON': 'OR', 'PENNSYLVANIA': 'PA', 'RHODE ISLAND': 'RI', 'SOUTH CAROLINA': 'SC',
  'SOUTH DAKOTA': 'SD', 'TENNESSEE': 'TN', 'TEXAS': 'TX', 'UTAH': 'UT',
  'VERMONT': 'VT', 'VIRGINIA': 'VA', 'WASHINGTON': 'WA', 'WEST VIRGINIA': 'WV',
  'WISCONSIN': 'WI', 'WYOMING': 'WY'
};

function transformStateCode(value) {
  if (!value || value.trim() === '') {
    return null;
  }
  
  let cleaned = value.trim().toUpperCase();
  
  // If already 2-letter code
  if (cleaned.length === 2) {
    return cleaned;
  }
  
  // Look up full state name
  if (stateMap[cleaned]) {
    return stateMap[cleaned];
  }
  
  logWarning('Unknown state', value);
  return null;
}
```

#### 7. registered_at Transformation
**Input Examples:**
- `2023-01-15` → `2023-01-15` ✅ (ISO format)
- `03/15/2023` → `2023-03-15` ✅ (US format)
- `01-15-2024` → `2024-01-15` ✅ (Dash format)
- `2024/01/20` → `2024-01-20` ✅ (Slash format)
- `invalid-date` → CURRENT_DATE ⚠️ (default)
- `yesterday` → CURRENT_DATE ⚠️ (default)
- `` (empty) → CURRENT_DATE ⚠️ (default)

**Transformation Logic:**
```javascript
function transformRegisteredDate(value) {
  if (!value || value.trim() === '') {
    logWarning('Missing registration date, using current date');
    return new Date().toISOString().split('T')[0];
  }
  
  const cleaned = value.trim();
  
  // Try ISO format (YYYY-MM-DD)
  if (/^\d{4}-\d{2}-\d{2}$/.test(cleaned)) {
    return cleaned;
  }
  
  // Try US format (MM/DD/YYYY)
  const usMatch = cleaned.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (usMatch) {
    const [, month, day, year] = usMatch;
    return `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
  }
  
  // Try dash format (DD-MM-YYYY or MM-DD-YYYY)
  const dashMatch = cleaned.match(/^(\d{1,2})-(\d{1,2})-(\d{4})$/);
  if (dashMatch) {
    const [, first, second, year] = dashMatch;
    // Assume US format if first > 12
    if (parseInt(first) > 12) {
      return `${year}-${second.padStart(2, '0')}-${first.padStart(2, '0')}`;
    } else {
      return `${year}-${first.padStart(2, '0')}-${second.padStart(2, '0')}`;
    }
  }
  
  // Try slash format (YYYY/MM/DD)
  const slashMatch = cleaned.match(/^(\d{4})\/(\d{1,2})\/(\d{1,2})$/);
  if (slashMatch) {
    const [, year, month, day] = slashMatch;
    return `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
  }
  
  // Unable to parse
  logWarning('Unable to parse date, using current date', value);
  return new Date().toISOString().split('T')[0];
}
```

#### 8. status Transformation
**Input Examples:**
- `Active` → `Active` ✅
- `active` → `Active` ✅
- `ACTIVE` → `Active` ✅
- `Inactive` → `Inactive` ✅
- `Pending` → `Pending` ✅
- `Unknown` → `Active` ⚠️ (default)
- `` (empty) → `Active` ⚠️ (default)

**Transformation Logic:**
```javascript
const validStatuses = ['Active', 'Inactive', 'Pending'];

function transformStatus(value) {
  if (!value || value.trim() === '') {
    return 'Active'; // Default
  }
  
  // Title case
  const cleaned = value.trim().toLowerCase();
  const titleCase = cleaned.charAt(0).toUpperCase() + cleaned.slice(1);
  
  // Validate against allowed values
  if (validStatuses.includes(titleCase)) {
    return titleCase;
  }
  
  logWarning('Unknown status, defaulting to Active', value);
  return 'Active';
}
```

---

## Table 2: Orders Mapping

### Source: Google Sheets "Orders"
### Target: PostgreSQL `orders` table

| # | Source Column | Target Column | Source Type | Target Type | Required | Transformation | Validation Rule | Default Value | Notes |
|---|---------------|---------------|-------------|-------------|----------|----------------|-----------------|---------------|-------|
| 1 | Order ID | order_id | Text | VARCHAR(20) | Yes | Uppercase, standardize format | Must match pattern: ^ORD\d+$ | - | Primary Key |
| 2 | Customer ID | customer_id | Text | VARCHAR(20) | Yes | Same as customers.customer_id | Must reference valid customer | - | Foreign Key |
| 3 | Product | product_name | Text | VARCHAR(255) | Yes | Trim whitespace | Length >= 1 | - | - |
| 4 | Quantity | quantity | Text/Number | INTEGER | Yes | Parse as integer, validate positive | Must be > 0 | - | - |
| 5 | Price | unit_price | Text/Number | DECIMAL(10,2) | Yes | Remove currency symbols, parse | Must be >= 0 | - | - |
| 6 | Order Date | order_date | Text | DATE | Yes | Parse multiple date formats to ISO 8601 | Valid date | CURRENT_DATE | Same logic as registration date |
| 7 | Status | order_status | Text | VARCHAR(20) | Yes | Title case, standardize variants | Must be valid order status | 'Pending' | Different values than customer status |
| - | - | total_amount | - | DECIMAL(10,2) | Yes | Calculate: quantity * unit_price | - | - | Calculated field |
| - | - | created_at | - | TIMESTAMP | Yes | - | - | NOW() | Auto-generated |
| - | - | updated_at | - | TIMESTAMP | Yes | - | - | NOW() | Auto-generated |

### Detailed Transformation Rules

#### 1. order_id Transformation
**Input Examples:**
- `ORD001` → `ORD001` ✅
- `ord002` → `ORD002` ✅
- `ORD-003` → `ORD003` ✅

**Transformation Logic:**
```javascript
function transformOrderId(value) {
  if (!value || value.trim() === '') {
    throw new ValidationError('Order ID is required');
  }
  
  let cleaned = value.replace(/[^a-zA-Z0-9]/g, '').toUpperCase();
  
  if (!cleaned.startsWith('ORD')) {
    cleaned = 'ORD' + cleaned;
  }
  
  return cleaned;
}
```

#### 2. customer_id (Foreign Key) Transformation
**Input Examples:**
- `C001` → `C001` ✅ (if customer exists)
- `C999` → ❌ Validation error (customer doesn't exist)
- `` (empty) → ❌ Required field error

**Transformation Logic:**
```javascript
async function transformCustomerId(value, customersMap) {
  if (!value || value.trim() === '') {
    throw new ValidationError('Customer ID is required');
  }
  
  const cleaned = transformCustomerId(value); // Use same logic as customers table
  
  // Validate that customer exists
  if (!customersMap.has(cleaned)) {
    throw new ValidationError('Customer does not exist: ' + cleaned);
  }
  
  return cleaned;
}
```

#### 3. product_name Transformation
**Input Examples:**
- `Laptop` → `Laptop` ✅
- `  USB Cable  ` → `USB Cable` ✅
- `` (empty) → ❌ Required field error

**Transformation Logic:**
```javascript
function transformProductName(value) {
  if (!value || value.trim() === '') {
    throw new ValidationError('Product name is required');
  }
  
  return value.trim().replace(/\s+/g, ' ');
}
```

#### 4. quantity Transformation
**Input Examples:**
- `1` → `1` ✅
- `2` → `2` ✅
- `5` → `5` ✅
- `-1` → ❌ Validation error (negative)
- `N/A` → ❌ Validation error (not a number)
- `` (empty) → ❌ Required field error

**Transformation Logic:**
```javascript
function transformQuantity(value) {
  if (!value || value.toString().trim() === '') {
    throw new ValidationError('Quantity is required');
  }
  
  const parsed = parseInt(value, 10);
  
  if (isNaN(parsed)) {
    throw new ValidationError('Quantity must be a number');
  }
  
  if (parsed <= 0) {
    throw new ValidationError('Quantity must be positive');
  }
  
  return parsed;
}
```

#### 5. unit_price Transformation
**Input Examples:**
- `999.99` → `999.99` ✅
- `25.50` → `25.50` ✅
- `$15.99` → `15.99` ✅
- `150` → `150.00` ✅
- `-50.00` → ❌ Validation error (negative)
- `free` → ❌ Validation error (not a number)

**Transformation Logic:**
```javascript
function transformUnitPrice(value) {
  if (!value || value.toString().trim() === '') {
    throw new ValidationError('Price is required');
  }
  
  // Remove currency symbols and whitespace
  let cleaned = value.toString().replace(/[$,\s]/g, '');
  
  const parsed = parseFloat(cleaned);
  
  if (isNaN(parsed)) {
    throw new ValidationError('Price must be a number');
  }
  
  if (parsed < 0) {
    throw new ValidationError('Price cannot be negative');
  }
  
  return parsed.toFixed(2);
}
```

#### 6. order_date Transformation
Same logic as `registered_at` from customers table.

#### 7. order_status Transformation
**Input Examples:**
- `Pending` → `Pending` ✅
- `delivered` → `Delivered` ✅
- `SHIPPED` → `Shipped` ✅
- `Unknown` → `Pending` ⚠️ (default)

**Transformation Logic:**
```javascript
const validOrderStatuses = ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

function transformOrderStatus(value) {
  if (!value || value.trim() === '') {
    return 'Pending'; // Default
  }
  
  // Title case
  const cleaned = value.trim().toLowerCase();
  const titleCase = cleaned.charAt(0).toUpperCase() + cleaned.slice(1);
  
  // Validate against allowed values
  if (validOrderStatuses.includes(titleCase)) {
    return titleCase;
  }
  
  logWarning('Unknown order status, defaulting to Pending', value);
  return 'Pending';
}
```

#### 8. total_amount Calculation
**Calculation:**
```javascript
function calculateTotalAmount(quantity, unitPrice) {
  return (quantity * parseFloat(unitPrice)).toFixed(2);
}
```

---

## Error Handling Strategy

### 1. Fatal Errors (Stop Processing)
- Missing required fields (customer_id, order_id, email, etc.)
- Invalid foreign key references
- Duplicate primary keys

**Action:** Log error, add to quarantine table, skip record

### 2. Validation Warnings (Continue with Defaults/NULL)
- Invalid date formats → Use default date
- Invalid phone numbers → Set to NULL
- Unknown status values → Use default status
- Missing optional fields → Set to NULL

**Action:** Log warning, apply transformation, continue processing

### 3. Data Quality Alerts
- Suspicious patterns (numeric names, very old dates)
- High duplicate rates
- Inconsistent formats

**Action:** Log alert, process normally, flag for manual review

---

## Validation Summary Table

| Validation Type | Field(s) | Action on Failure |
|-----------------|----------|-------------------|
| Primary Key Uniqueness | customer_id, order_id | REJECT - Fatal Error |
| Foreign Key Integrity | orders.customer_id | REJECT - Fatal Error |
| Email Uniqueness | email | REJECT - Fatal Error |
| Email Format | email | REJECT - Fatal Error |
| Required Fields | All NOT NULL columns | REJECT - Fatal Error |
| Positive Integer | quantity | REJECT - Fatal Error |
| Non-Negative Decimal | unit_price | REJECT - Fatal Error |
| Date Format | registered_at, order_date | ACCEPT - Use default |
| Phone Format | phone_number | ACCEPT - Set to NULL |
| Status Values | status, order_status | ACCEPT - Use default |
| State Code | state_code | ACCEPT - Set to NULL |

---

## Testing Scenarios

### Test Case 1: Clean Record
**Input:** Valid data in standard format  
**Expected:** Direct mapping, no transformations needed

### Test Case 2: Format Variations
**Input:** Multiple date/phone formats  
**Expected:** All normalized to standard format

### Test Case 3: Missing Optional Fields
**Input:** Records with empty optional fields  
**Expected:** NULL values stored correctly

### Test Case 4: Missing Required Fields
**Input:** Records with empty required fields  
**Expected:** Rejected, logged in quarantine table

### Test Case 5: Invalid References
**Input:** Orders with non-existent customer IDs  
**Expected:** Rejected due to foreign key violation

### Test Case 6: Duplicates
**Input:** Duplicate customer_id or order_id  
**Expected:** First occurrence accepted, duplicates rejected

### Test Case 7: Special Characters
**Input:** Names with accents, apostrophes  
**Expected:** Properly stored with UTF-8 encoding

### Test Case 8: Edge Cases
**Input:** Very long strings, boundary numbers  
**Expected:** Validated against max lengths and ranges

---

## Migration Checklist

- [ ] Create target tables with proper schema
- [ ] Implement all transformation functions
- [ ] Set up validation rules and constraints
- [ ] Create quarantine table for rejected records
- [ ] Test each transformation with sample data
- [ ] Run dry-run migration with logging
- [ ] Verify data counts and quality
- [ ] Review quarantine records
- [ ] Execute final migration
- [ ] Validate foreign key relationships
- [ ] Run post-migration quality checks

---

**Document Version:** 1.0  
**Last Updated:** 2024  
**Next Review:** After ETL implementation
