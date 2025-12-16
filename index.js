/**
 * Main Application Entry Point
 * 
 * This is a starter template for your application.
 * You can import and use database and Google Sheets functionality here.
 */

require('dotenv').config();
const { Pool } = require('pg');
const { google } = require('googleapis');
const fs = require('fs');

// Database connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL?.includes('neon.tech') ? { rejectUnauthorized: false } : false
});

// Google Sheets API setup
async function getGoogleSheetsClient() {
  const credentialsPath = process.env.GOOGLE_SHEETS_CREDENTIALS_PATH || './credentials/google-credentials.json';
  
  if (!fs.existsSync(credentialsPath)) {
    throw new Error('Google credentials file not found');
  }
  
  const credentials = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));
  
  const auth = new google.auth.GoogleAuth({
    credentials: credentials,
    scopes: ['https://www.googleapis.com/auth/spreadsheets']
  });
  
  const authClient = await auth.getClient();
  return google.sheets({ version: 'v4', auth: authClient });
}

// Example: Query database
async function queryDatabase(query, params = []) {
  const client = await pool.connect();
  try {
    const result = await client.query(query, params);
    return result.rows;
  } finally {
    client.release();
  }
}

// Example: Read from Google Sheets
async function readSheet(sheetId, range) {
  const sheets = await getGoogleSheetsClient();
  const response = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
    range: range
  });
  return response.data.values;
}

// Example: Write to Google Sheets
async function writeSheet(sheetId, range, values) {
  const sheets = await getGoogleSheetsClient();
  const response = await sheets.spreadsheets.values.update({
    spreadsheetId: sheetId,
    range: range,
    valueInputOption: 'RAW',
    resource: { values: values }
  });
  return response.data;
}

// Main function
async function main() {
  console.log('🚀 Application started!\n');
  
  try {
    // Example: Test database connection
    console.log('Testing database connection...');
    const dbResult = await queryDatabase('SELECT NOW() as time, current_database() as db');
    console.log('✅ Database connected:', dbResult[0]);
    
    // Example: Test Google Sheets (if configured)
    if (process.env.GOOGLE_SHEET_ID) {
      console.log('\nTesting Google Sheets API...');
      const sheets = await getGoogleSheetsClient();
      const sheetInfo = await sheets.spreadsheets.get({
        spreadsheetId: process.env.GOOGLE_SHEET_ID
      });
      console.log('✅ Google Sheets connected:', sheetInfo.data.properties.title);
    }
    
    console.log('\n✨ All systems operational!\n');
    
    // Add your application logic here
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
  }
}

// Run the application
if (require.main === module) {
  main();
}

// Export functions for use in other modules
module.exports = {
  pool,
  getGoogleSheetsClient,
  queryDatabase,
  readSheet,
  writeSheet
};
