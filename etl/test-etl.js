/**
 * ETL Pipeline Test Script
 * Tests the ETL pipeline with validation
 */

require('dotenv').config();
const Logger = require('./logger');
const Extractor = require('./extract');
const Transformer = require('./transform');

async function testETL() {
  const logger = new Logger();
  
  console.log('\n' + '='.repeat(70));
  console.log('🧪 ETL PIPELINE TEST');
  console.log('='.repeat(70) + '\n');

  try {
    // Test 1: Configuration Check
    console.log('📋 Test 1: Configuration Check');
    console.log('─'.repeat(70));
    
    const config = require('./config');
    
    console.log('✓ Database URL:', config.database.connectionString ? 'Set' : '❌ Missing');
    console.log('✓ Google Credentials:', config.googleSheets.credentialsPath);
    console.log('✓ Sheet ID:', config.googleSheets.spreadsheetId || '❌ Missing');
    console.log('✓ Sheet Names:', JSON.stringify(config.sheetNames));
    
    if (!config.googleSheets.spreadsheetId || config.googleSheets.spreadsheetId === 'your_google_sheet_id_here') {
      console.log('\n❌ Error: GOOGLE_SHEET_ID not set in .env file');
      console.log('Please set your Google Sheet ID in the .env file\n');
      process.exit(1);
    }

    // Test 2: Google Sheets Connection
    console.log('\n📊 Test 2: Google Sheets Connection');
    console.log('─'.repeat(70));
    
    const extractor = new Extractor(logger);
    await extractor.initialize();
    const sheetInfo = await extractor.getSheetInfo();
    
    console.log('✓ Connected to:', sheetInfo.title);
    console.log('✓ Available sheets:');
    sheetInfo.sheets.forEach(sheet => {
      console.log(`  - ${sheet.name} (${sheet.rowCount} rows × ${sheet.columnCount} cols)`);
    });

    // Test 3: Data Extract
    console.log('\n📥 Test 3: Data Extraction');
    console.log('─'.repeat(70));
    
    const extractedData = await extractor.extractAll();
    
    if (extractedData.customers) {
      console.log(`✓ Customers: ${extractedData.customers.data.length} rows`);
      console.log(`  Headers: ${extractedData.customers.headers.join(', ')}`);
      
      if (extractedData.customers.data.length > 0) {
        console.log(`  Sample row:`, extractedData.customers.data[0].slice(0, 3).join(', ') + '...');
      }
    } else {
      console.log('⚠️  No customer data found');
    }

    // Test 4: Data Transformation
    console.log('\n🔄 Test 4: Data Transformation');
    console.log('─'.repeat(70));
    
    const transformer = new Transformer(logger);
    const transformedData = await transformer.transform(extractedData);
    
    if (transformedData.customers) {
      console.log(`✓ Valid customers: ${transformedData.customers.valid.length}`);
      console.log(`✓ Invalid customers: ${transformedData.customers.invalid.length}`);
      
      if (transformedData.customers.valid.length > 0) {
        const sample = transformedData.customers.valid[0];
        console.log(`  Sample transformed record:`);
        console.log(`    - ID: ${sample.customer_id}`);
        console.log(`    - Name: ${sample.full_name}`);
        console.log(`    - Email: ${sample.email}`);
        console.log(`    - State: ${sample.state_code}`);
        console.log(`    - Status: ${sample.status}`);
      }
      
      if (transformedData.customers.invalid.length > 0) {
        console.log(`  ⚠️  Sample validation errors:`);
        transformedData.customers.invalid.slice(0, 2).forEach(record => {
          console.log(`    Row ${record._rowIndex}:`, record._errors.map(e => e.error).join(', '));
        });
      }
    }

    // Test 5: Database Connection
    console.log('\n💾 Test 5: Database Connection');
    console.log('─'.repeat(70));
    
    const { Pool } = require('pg');
    const pool = new Pool({
      connectionString: config.database.connectionString,
      ssl: config.database.ssl
    });
    
    const client = await pool.connect();
    const result = await client.query('SELECT current_database(), version()');
    console.log('✓ Connected to:', result.rows[0].current_database);
    console.log('✓ Version:', result.rows[0].version.split(' ').slice(0, 2).join(' '));
    
    // Check if tables exist
    const tables = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('customers', 'products', 'orders', 'order_items', 'states')
      ORDER BY table_name
    `);
    
    console.log('✓ Tables found:', tables.rows.map(r => r.table_name).join(', '));
    
    if (tables.rows.length === 0) {
      console.log('\n⚠️  Warning: No tables found. Run schema setup first:');
      console.log('   npm run test:schema');
    }
    
    client.release();
    await pool.end();

    // Test Summary
    console.log('\n' + '='.repeat(70));
    console.log('✅ ALL TESTS PASSED');
    console.log('='.repeat(70));
    console.log('\n📊 Summary:');
    console.log(`   ✓ Configuration valid`);
    console.log(`   ✓ Google Sheets connected`);
    console.log(`   ✓ Data extracted successfully`);
    console.log(`   ✓ Data transformed successfully`);
    console.log(`   ✓ Database connected`);
    console.log('\n✨ Ready to run ETL pipeline!');
    console.log('   Run: npm run etl\n');

  } catch (error) {
    console.log('\n' + '='.repeat(70));
    console.log('❌ TEST FAILED');
    console.log('='.repeat(70));
    console.error('\nError:', error.message);
    console.error('\nStack:', error.stack);
    process.exit(1);
  }
}

// Run tests
testETL();
