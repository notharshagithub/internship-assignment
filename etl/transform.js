/**
 * ETL Transform Phase
 * Transforms, validates, deduplicates, and normalizes data
 */

const config = require('./config');

class Transformer {
  constructor(logger) {
    this.logger = logger;
    this.validationErrors = [];
    this.stateMapping = {
      'New York': 'NY', 'California': 'CA', 'Texas': 'TX', 'Florida': 'FL',
      'Illinois': 'IL', 'Pennsylvania': 'PA', 'Ohio': 'OH', 'Georgia': 'GA',
      'North Carolina': 'NC', 'Michigan': 'MI', 'New Jersey': 'NJ', 'Virginia': 'VA',
      'Washington': 'WA', 'Arizona': 'AZ', 'Massachusetts': 'MA', 'Tennessee': 'TN',
      'Indiana': 'IN', 'Missouri': 'MO', 'Maryland': 'MD', 'Wisconsin': 'WI'
    };
  }

  // ============================================================================
  // CUSTOMER TRANSFORMATIONS
  // ============================================================================

  transformCustomerId(value, rowIndex) {
    if (!value || value.trim() === '') {
      this.logger.warn(`Row ${rowIndex}: Empty customer_id, will need to be generated`);
      return null; // Will be generated during load
    }
    
    // Remove non-alphanumeric, uppercase, ensure C prefix
    let cleaned = value.replace(/[^a-zA-Z0-9]/g, '').toUpperCase();
    
    if (!cleaned.startsWith('C')) {
      cleaned = 'C' + cleaned;
    }
    
    // Validate format
    if (!/^C\d+$/.test(cleaned)) {
      this.validationErrors.push({
        row: rowIndex,
        field: 'customer_id',
        value: value,
        error: 'Invalid format, must be C followed by numbers'
      });
      return null;
    }
    
    return cleaned;
  }

  transformFullName(value, rowIndex) {
    if (!value || value.trim() === '') {
      this.validationErrors.push({
        row: rowIndex,
        field: 'full_name',
        value: value,
        error: 'Name is required'
      });
      return null;
    }
    
    // Trim and normalize whitespace
    let cleaned = value.trim().replace(/\s+/g, ' ');
    
    // Flag suspicious patterns
    if (/^\d+$/.test(cleaned)) {
      this.logger.warn(`Row ${rowIndex}: Suspicious name (all digits): "${cleaned}"`);
    }
    
    return cleaned;
  }

  transformEmail(value, rowIndex) {
    if (!value || value.trim() === '') {
      this.validationErrors.push({
        row: rowIndex,
        field: 'email',
        value: value,
        error: 'Email is required'
      });
      return null;
    }
    
    // Lowercase and trim
    let cleaned = value.trim().toLowerCase();
    
    // Validate email format
    const emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
    if (!emailRegex.test(cleaned)) {
      this.validationErrors.push({
        row: rowIndex,
        field: 'email',
        value: value,
        error: 'Invalid email format'
      });
      return null;
    }
    
    return cleaned;
  }

  transformPhone(value, rowIndex) {
    if (!value || value.trim() === '') {
      return null;
    }
    
    // Remove all non-digits
    let digits = value.replace(/\D/g, '');
    
    // Format as XXX-XXXX if 7 digits or keep as-is if 10 digits
    if (digits.length === 7) {
      return `${digits.slice(0, 3)}-${digits.slice(3)}`;
    } else if (digits.length === 10) {
      return digits;
    } else {
      this.logger.warn(`Row ${rowIndex}: Invalid phone format: "${value}"`);
      return null;
    }
  }

  transformCity(value, rowIndex) {
    if (!value || value.trim() === '') {
      return null;
    }
    
    // Trim and title case
    return value.trim();
  }

  transformStateCode(value, rowIndex) {
    if (!value || value.trim() === '') {
      return null;
    }
    
    let cleaned = value.trim();
    
    // If already 2-letter code, return uppercase
    if (cleaned.length === 2) {
      return cleaned.toUpperCase();
    }
    
    // Try to map full name to code
    const mapped = this.stateMapping[cleaned];
    if (mapped) {
      return mapped;
    }
    
    this.logger.warn(`Row ${rowIndex}: Unknown state: "${value}"`);
    return null;
  }

  transformRegisteredAt(value, rowIndex) {
    if (!value || value.trim() === '') {
      return new Date().toISOString().split('T')[0]; // Default to today
    }
    
    let date;
    
    // Try parsing different formats
    // Format 1: YYYY-MM-DD
    if (/^\d{4}-\d{2}-\d{2}$/.test(value)) {
      date = new Date(value);
    }
    // Format 2: MM/DD/YYYY
    else if (/^\d{1,2}\/\d{1,2}\/\d{4}$/.test(value)) {
      const [month, day, year] = value.split('/');
      date = new Date(`${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`);
    }
    // Format 3: DD-MM-YYYY
    else if (/^\d{1,2}-\d{1,2}-\d{4}$/.test(value)) {
      const [day, month, year] = value.split('-');
      date = new Date(`${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`);
    }
    else {
      this.logger.warn(`Row ${rowIndex}: Invalid date format: "${value}", using current date`);
      return new Date().toISOString().split('T')[0];
    }
    
    // Check if date is valid
    if (isNaN(date.getTime())) {
      this.logger.warn(`Row ${rowIndex}: Invalid date value: "${value}", using current date`);
      return new Date().toISOString().split('T')[0];
    }
    
    // Validate date is not in future
    if (date > new Date()) {
      this.logger.warn(`Row ${rowIndex}: Future registration date: "${value}"`);
    }
    
    return date.toISOString().split('T')[0];
  }

  transformStatus(value, rowIndex) {
    if (!value || value.trim() === '') {
      return 'Active'; // Default
    }
    
    const cleaned = value.trim();
    const statusMap = {
      'active': 'Active',
      'inactive': 'Inactive',
      'pending': 'Pending',
      'yes': 'Active',
      'no': 'Inactive',
      '1': 'Active',
      '0': 'Inactive'
    };
    
    const mapped = statusMap[cleaned.toLowerCase()];
    if (mapped) {
      return mapped;
    }
    
    // Default to Active if unknown
    this.logger.warn(`Row ${rowIndex}: Unknown status "${value}", defaulting to Active`);
    return 'Active';
  }

  // ============================================================================
  // PRODUCT TRANSFORMATIONS
  // ============================================================================

  transformProductName(value, rowIndex) {
    if (!value || value.trim() === '') {
      this.validationErrors.push({
        row: rowIndex,
        field: 'product_name',
        value: value,
        error: 'Product name is required'
      });
      return null;
    }
    
    return value.trim();
  }

  transformUnitPrice(value, rowIndex) {
    if (!value || value.trim() === '') {
      this.validationErrors.push({
        row: rowIndex,
        field: 'unit_price',
        value: value,
        error: 'Unit price is required'
      });
      return null;
    }
    
    // Remove currency symbols and commas
    let cleaned = value.toString().replace(/[$,]/g, '').trim();
    
    const price = parseFloat(cleaned);
    
    if (isNaN(price) || price < 0) {
      this.validationErrors.push({
        row: rowIndex,
        field: 'unit_price',
        value: value,
        error: 'Invalid price format or negative value'
      });
      return null;
    }
    
    return price.toFixed(2);
  }

  transformQuantity(value, rowIndex, fieldName = 'quantity') {
    if (!value || value.trim() === '') {
      return 0;
    }
    
    const quantity = parseInt(value);
    
    if (isNaN(quantity) || quantity < 0) {
      this.logger.warn(`Row ${rowIndex}: Invalid ${fieldName}: "${value}"`);
      return 0;
    }
    
    return quantity;
  }

  // ============================================================================
  // ORDER TRANSFORMATIONS
  // ============================================================================

  transformOrderId(value, rowIndex) {
    if (!value || value.trim() === '') {
      this.logger.warn(`Row ${rowIndex}: Empty order_id, will need to be generated`);
      return null;
    }
    
    let cleaned = value.replace(/[^a-zA-Z0-9]/g, '').toUpperCase();
    
    if (!cleaned.startsWith('ORD')) {
      cleaned = 'ORD' + cleaned;
    }
    
    if (!/^ORD\d+$/.test(cleaned)) {
      this.validationErrors.push({
        row: rowIndex,
        field: 'order_id',
        value: value,
        error: 'Invalid format, must be ORD followed by numbers'
      });
      return null;
    }
    
    return cleaned;
  }

  transformOrderDate(value, rowIndex) {
    return this.transformRegisteredAt(value, rowIndex); // Same logic as registration date
  }

  transformOrderStatus(value, rowIndex) {
    const statusMap = {
      'pending': 'Pending',
      'processing': 'Processing',
      'shipped': 'Shipped',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
      'canceled': 'Cancelled'
    };
    
    const cleaned = (value || 'pending').trim().toLowerCase();
    return statusMap[cleaned] || 'Pending';
  }

  // ============================================================================
  // MAIN TRANSFORM FUNCTIONS
  // ============================================================================

  transformCustomers(rawData) {
    this.logger.info('Transforming customer data...');
    
    const { headers, data } = rawData;
    const transformed = [];
    
    data.forEach((row, index) => {
      const rowIndex = index + 2;
      
      const customer = {
        customer_id: this.transformCustomerId(row[0], rowIndex),
        full_name: this.transformFullName(row[1], rowIndex),
        email: this.transformEmail(row[2], rowIndex),
        phone_number: this.transformPhone(row[3], rowIndex),
        city: this.transformCity(row[4], rowIndex),
        state_code: this.transformStateCode(row[5], rowIndex),
        registered_at: this.transformRegisteredAt(row[6], rowIndex),
        status: this.transformStatus(row[7], rowIndex),
        email_verified: false,
        _rowIndex: rowIndex
      };
      
      transformed.push(customer);
    });
    
    this.logger.success(`Transformed ${transformed.length} customer records`);
    this.logger.updateStats('transformed', transformed.length);
    
    return transformed;
  }

  // ============================================================================
  // DEDUPLICATION
  // ============================================================================

  deduplicateCustomers(customers) {
    if (!config.etl.deduplicateData) {
      return customers;
    }
    
    this.logger.info('Deduplicating customers...');
    
    const seen = new Map();
    const duplicates = [];
    const unique = [];
    
    customers.forEach(customer => {
      const key = customer.email || customer.customer_id;
      
      if (!key) {
        this.logger.warn(`Row ${customer._rowIndex}: Cannot deduplicate, missing key fields`);
        unique.push(customer);
        return;
      }
      
      if (seen.has(key)) {
        duplicates.push({
          row: customer._rowIndex,
          duplicateOf: seen.get(key),
          key: key
        });
        this.logger.updateStats('skipped');
      } else {
        seen.set(key, customer._rowIndex);
        unique.push(customer);
      }
    });
    
    if (duplicates.length > 0) {
      this.logger.warn(`Found ${duplicates.length} duplicate customer(s)`, {
        duplicates: duplicates.slice(0, 5)
      });
    }
    
    this.logger.success(`${unique.length} unique customers after deduplication`);
    
    return unique;
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================

  validate(data) {
    this.logger.info('Validating transformed data...');
    
    const valid = [];
    const invalid = [];
    
    data.forEach(record => {
      // Check if record has critical validation errors
      const recordErrors = this.validationErrors.filter(e => e.row === record._rowIndex);
      
      if (recordErrors.length > 0) {
        invalid.push({ ...record, _errors: recordErrors });
        this.logger.updateStats('skipped');
      } else {
        valid.push(record);
      }
    });
    
    if (invalid.length > 0) {
      this.logger.warn(`${invalid.length} record(s) failed validation`, {
        sample: invalid.slice(0, 3).map(r => ({
          row: r._rowIndex,
          errors: r._errors
        }))
      });
    }
    
    this.logger.success(`${valid.length} record(s) passed validation`);
    
    return { valid, invalid };
  }

  // ============================================================================
  // MAIN TRANSFORM METHOD
  // ============================================================================

  async transform(extractedData) {
    this.logger.info('Starting data transformation...');
    this.validationErrors = [];
    
    const transformed = {};
    
    // Transform customers
    if (extractedData.customers) {
      let customers = this.transformCustomers(extractedData.customers);
      customers = this.deduplicateCustomers(customers);
      
      if (config.etl.validateBeforeLoad) {
        const { valid, invalid } = this.validate(customers);
        transformed.customers = { valid, invalid };
      } else {
        transformed.customers = { valid: customers, invalid: [] };
      }
    }
    
    // TODO: Add transform for orders and products when needed
    
    this.logger.success('Data transformation complete');
    
    return transformed;
  }
}

module.exports = Transformer;
