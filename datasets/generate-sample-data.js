/**
 * Generate Sample Datasets for Practice
 * Creates both clean and messy datasets
 */

const fs = require('fs');
const path = require('path');

// ============================================================================
// CLEAN DATASET: E-commerce Orders (Well-structured)
// ============================================================================

function generateCleanDataset() {
  console.log('Generating clean dataset...');
  
  const products = [
    { name: 'Laptop', price: 999.99, category: 'Electronics' },
    { name: 'Mouse', price: 25.50, category: 'Electronics' },
    { name: 'Keyboard', price: 75.00, category: 'Electronics' },
    { name: 'Monitor', price: 299.99, category: 'Electronics' },
    { name: 'Desk Chair', price: 199.99, category: 'Furniture' },
    { name: 'Desk Lamp', price: 35.00, category: 'Furniture' },
    { name: 'Notebook', price: 12.99, category: 'Office Supplies' },
    { name: 'Pen Set', price: 8.99, category: 'Office Supplies' },
    { name: 'USB Cable', price: 9.99, category: 'Electronics' },
    { name: 'Headphones', price: 79.99, category: 'Electronics' }
  ];
  
  const customers = [
    { id: 'C001', name: 'Alice Johnson', email: 'alice@email.com', city: 'New York', state: 'NY' },
    { id: 'C002', name: 'Bob Smith', email: 'bob@email.com', city: 'Los Angeles', state: 'CA' },
    { id: 'C003', name: 'Carol Davis', email: 'carol@email.com', city: 'Chicago', state: 'IL' },
    { id: 'C004', name: 'David Wilson', email: 'david@email.com', city: 'Houston', state: 'TX' },
    { id: 'C005', name: 'Emma Brown', email: 'emma@email.com', city: 'Phoenix', state: 'AZ' },
    { id: 'C006', name: 'Frank Miller', email: 'frank@email.com', city: 'Seattle', state: 'WA' },
    { id: 'C007', name: 'Grace Lee', email: 'grace@email.com', city: 'Boston', state: 'MA' },
    { id: 'C008', name: 'Henry Taylor', email: 'henry@email.com', city: 'Miami', state: 'FL' }
  ];
  
  const orders = [];
  let orderCounter = 1;
  
  // Generate 100 clean orders
  for (let i = 0; i < 100; i++) {
    const customer = customers[Math.floor(Math.random() * customers.length)];
    const product = products[Math.floor(Math.random() * products.length)];
    const quantity = Math.floor(Math.random() * 5) + 1;
    const orderDate = new Date(2024, Math.floor(Math.random() * 12), Math.floor(Math.random() * 28) + 1);
    const statuses = ['Pending', 'Processing', 'Shipped', 'Delivered'];
    const status = statuses[Math.floor(Math.random() * statuses.length)];
    
    orders.push({
      order_id: `ORD${String(orderCounter).padStart(4, '0')}`,
      customer_id: customer.id,
      customer_name: customer.name,
      customer_email: customer.email,
      customer_city: customer.city,
      customer_state: customer.state,
      product_name: product.name,
      product_category: product.category,
      quantity: quantity,
      unit_price: product.price,
      total_amount: (product.price * quantity).toFixed(2),
      order_date: orderDate.toISOString().split('T')[0],
      status: status,
      created_at: new Date().toISOString()
    });
    
    orderCounter++;
  }
  
  // Convert to CSV
  const headers = Object.keys(orders[0]).join(',');
  const rows = orders.map(order => Object.values(order).map(v => `"${v}"`).join(',')).join('\n');
  const csv = headers + '\n' + rows;
  
  fs.writeFileSync(path.join(__dirname, 'clean', 'ecommerce_orders.csv'), csv);
  console.log(`✓ Created clean dataset: ${orders.length} records`);
  
  return orders;
}

// ============================================================================
// MESSY DATASET: Customer Survey Responses (Real-world issues)
// ============================================================================

function generateMessyDataset() {
  console.log('Generating messy dataset...');
  
  const responses = [];
  
  // Intentional data quality issues
  const messyNames = [
    'John Doe', 'JANE SMITH', 'bob jones', '  Alice  Williams  ', 'Charlie123',
    null, '', 'Mike-O\'Brien', 'Sarah (Sally) Davis', '12345',
    'Emma-Rose Thompson', 'David', 'Ms. Patricia Brown', 'robert', 'MICHAEL JOHNSON'
  ];
  
  const messyEmails = [
    'john@email.com', 'JANE@EMAIL.COM', 'bob@email', 'alice@.com',
    null, '', 'invalid-email', 'mike@domain', 'sarah@@email.com',
    'emma@email.com', 'david@email.com', 'patricia@email.com', 'robert@email.com', 'michael@email.com'
  ];
  
  const messyPhones = [
    '555-0101', '(555) 0102', '555.0103', '5550104',
    null, '', '555-CALL', '1-555-0105', '+1 555 0106',
    '555-0107', '5550108', '(555)0109', '555 0110', '555-0111'
  ];
  
  const messyCities = [
    'New York', 'los angeles', 'CHICAGO', '  Houston  ',
    null, '', 'N/A', 'Phoenix, AZ', 'Philadelphia123',
    'San Antonio', 'sandiego', 'DALLAS', 'San Jose', 'Austin'
  ];
  
  const messyStates = [
    'NY', 'ca', 'IL', 'tx', null, '', 'XX', 'Arizona', 'PA',
    'TX', 'CA', 'TX', 'CA', 'TX'
  ];
  
  const messyDates = [
    '2024-01-15', '01/15/2024', '15-01-2024', '2024/01/15',
    null, '', 'invalid', '2025-12-31', '99-99-9999',
    '2024-02-20', '2024-03-10', '2024-04-05', '2024-05-12', '2024-06-18'
  ];
  
  const messyRatings = [
    '5', '4', '3', 'N/A', '', null, '10', '-1', 'Good', '2',
    '5', '4', '3', '2', '1'
  ];
  
  const messyComments = [
    'Great service!', 'AWFUL EXPERIENCE!!!', null, '', 'n/a',
    '  Good product  ', 'Would recommend', 'Not satisfied', 'Okay', 'Excellent',
    'Meh', 'Five stars!', 'Terrible', 'Amazing!', 'Could be better'
  ];
  
  // Generate 150 messy responses with various issues
  for (let i = 0; i < 150; i++) {
    const idx = i % messyNames.length;
    
    responses.push({
      response_id: i < 100 ? `R${String(i + 1).padStart(3, '0')}` : `R${i + 1}`, // Inconsistent format
      full_name: messyNames[idx],
      email: messyEmails[idx],
      phone_number: messyPhones[idx],
      city: messyCities[idx],
      state: messyStates[idx],
      survey_date: messyDates[idx],
      rating: messyRatings[idx],
      comments: messyComments[idx],
      // Add some duplicate rows
      is_duplicate: i > 0 && i % 20 === 0 ? 'duplicate' : 'original'
    });
  }
  
  // Add some completely duplicate rows
  responses.push(responses[0]); // Exact duplicate
  responses.push(responses[5]); // Another duplicate
  responses.push({...responses[10], response_id: 'R999'}); // Duplicate with different ID
  
  // Convert to CSV with some formatting issues
  const headers = Object.keys(responses[0]).join(',');
  const rows = responses.map((response, i) => {
    // Some rows have different number of columns (data quality issue)
    if (i % 30 === 0 && i > 0) {
      const values = Object.values(response);
      values.pop(); // Remove last field
      return values.map(v => v === null ? '' : `"${v}"`).join(',');
    }
    return Object.values(response).map(v => v === null ? '' : `"${v}"`).join(',');
  }).join('\n');
  
  const csv = headers + '\n' + rows;
  
  fs.writeFileSync(path.join(__dirname, 'messy', 'customer_surveys.csv'), csv);
  console.log(`✓ Created messy dataset: ${responses.length} records (includes duplicates and errors)`);
  
  return responses;
}

// ============================================================================
// GENERATE DATASETS
// ============================================================================

console.log('═══════════════════════════════════════════');
console.log('  Generating Sample Datasets');
console.log('═══════════════════════════════════════════\n');

try {
  const cleanData = generateCleanDataset();
  const messyData = generateMessyDataset();
  
  console.log('\n═══════════════════════════════════════════');
  console.log('  Datasets Generated Successfully!');
  console.log('═══════════════════════════════════════════');
  console.log(`\n📊 Clean Dataset: datasets/clean/ecommerce_orders.csv`);
  console.log(`   - ${cleanData.length} well-structured records`);
  console.log(`   - Ready for standard ETL processing`);
  console.log(`\n📊 Messy Dataset: datasets/messy/customer_surveys.csv`);
  console.log(`   - ${messyData.length} records with quality issues`);
  console.log(`   - Contains: duplicates, nulls, formatting issues`);
  console.log(`   - Requires data cleaning and validation\n`);
  
  // Generate documentation
  const cleanReadme = `# Clean Dataset: E-commerce Orders

## Description
Well-structured e-commerce order data with proper formatting.

## Structure
- **Records:** ${cleanData.length}
- **Format:** CSV
- **Columns:** 13

## Columns
1. order_id - Unique order identifier (ORD####)
2. customer_id - Customer identifier (C###)
3. customer_name - Full customer name
4. customer_email - Email address
5. customer_city - City
6. customer_state - State code (2 letters)
7. product_name - Product name
8. product_category - Product category
9. quantity - Order quantity
10. unit_price - Price per unit
11. total_amount - Total order amount
12. order_date - Order date (YYYY-MM-DD)
13. status - Order status
14. created_at - Record creation timestamp

## Data Quality
- ✅ No missing values
- ✅ Consistent formatting
- ✅ Valid data types
- ✅ No duplicates
- ✅ Proper date formats

## Usage
Standard ETL processing with minimal transformation required.
`;

  const messyReadme = `# Messy Dataset: Customer Survey Responses

## Description
Real-world customer survey data with various data quality issues.

## Structure
- **Records:** ${messyData.length} (includes ${messyData.length - 150} duplicates)
- **Format:** CSV
- **Columns:** 10

## Columns
1. response_id - Survey response ID
2. full_name - Customer name
3. email - Email address
4. phone_number - Phone number
5. city - City name
6. state - State code
7. survey_date - Survey submission date
8. rating - Customer rating
9. comments - Customer comments
10. is_duplicate - Duplicate flag

## Data Quality Issues
- ❌ Missing values (nulls, empty strings)
- ❌ Inconsistent formatting (UPPERCASE, lowercase, Mixed)
- ❌ Invalid email formats
- ❌ Various phone number formats
- ❌ Inconsistent date formats
- ❌ Invalid state codes
- ❌ Duplicate records
- ❌ Extra whitespace
- ❌ Invalid values (e.g., rating = "Good")
- ❌ Inconsistent ID formats

## Challenges
- Requires extensive data cleaning
- Need to handle missing values
- Must standardize formats
- Duplicate detection needed
- Validation rules required

## Usage
Designed to practice:
- Data cleaning techniques
- Handling missing data
- Deduplication
- Format standardization
- Validation logic
`;

  fs.writeFileSync(path.join(__dirname, 'clean', 'README.md'), cleanReadme);
  fs.writeFileSync(path.join(__dirname, 'messy', 'README.md'), messyReadme);
  
  console.log('📝 Documentation files created\n');
  
} catch (error) {
  console.error('Error generating datasets:', error);
  process.exit(1);
}
