/**
 * Database Connection Test Script
 * Tests connection to PostgreSQL/NeonDB
 */

require('dotenv').config();
const { Pool } = require('pg');

// Connection configuration
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL?.includes('neon.tech') ? { rejectUnauthorized: false } : false
});

async function testConnection() {
  console.log('🔍 Testing database connection...\n');
  
  try {
    // Test connection
    const client = await pool.connect();
    console.log('✅ Successfully connected to PostgreSQL/NeonDB!\n');
    
    // Get database information
    const result = await client.query('SELECT version(), current_database(), current_user');
    const dbInfo = result.rows[0];
    
    console.log('📊 Database Information:');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`Database: ${dbInfo.current_database}`);
    console.log(`User: ${dbInfo.current_user}`);
    console.log(`Version: ${dbInfo.version.split(',')[0]}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    // Test a simple query
    const testQuery = await client.query('SELECT NOW() as current_time');
    console.log(`⏰ Server Time: ${testQuery.rows[0].current_time}\n`);
    
    console.log('✨ Connection test completed successfully!');
    
    client.release();
    await pool.end();
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Database connection failed!\n');
    console.error('Error Details:');
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.error(`Message: ${error.message}`);
    console.error(`Code: ${error.code || 'N/A'}`);
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    console.log('💡 Troubleshooting Tips:');
    console.log('  1. Check if DATABASE_URL is set in .env file');
    console.log('  2. Verify your database credentials');
    console.log('  3. Ensure your IP is whitelisted (for NeonDB)');
    console.log('  4. Check if the database server is running\n');
    
    process.exit(1);
  }
}

// Run the test
testConnection();
