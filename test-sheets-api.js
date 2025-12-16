/**
 * Google Sheets API Connection Test Script
 * Tests connection to Google Sheets API
 */

require('dotenv').config();
const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

async function testSheetsAPI() {
  console.log('🔍 Testing Google Sheets API connection...\n');
  
  try {
    // Check if credentials file exists
    const credentialsPath = process.env.GOOGLE_SHEETS_CREDENTIALS_PATH || './credentials/google-credentials.json';
    
    if (!fs.existsSync(credentialsPath)) {
      throw new Error(`Credentials file not found at: ${credentialsPath}`);
    }
    
    // Load credentials
    const credentials = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));
    console.log('✅ Successfully loaded Google API credentials\n');
    
    // Authenticate
    const auth = new google.auth.GoogleAuth({
      credentials: credentials,
      scopes: ['https://www.googleapis.com/auth/spreadsheets.readonly']
    });
    
    const authClient = await auth.getClient();
    console.log('✅ Successfully authenticated with Google API\n');
    
    // Initialize Sheets API
    const sheets = google.sheets({ version: 'v4', auth: authClient });
    
    // Test with a sheet ID if provided
    const sheetId = process.env.GOOGLE_SHEET_ID;
    
    if (sheetId) {
      console.log('📊 Testing access to Google Sheet...');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      const response = await sheets.spreadsheets.get({
        spreadsheetId: sheetId
      });
      
      console.log(`Sheet Title: ${response.data.properties.title}`);
      console.log(`Sheet ID: ${sheetId}`);
      console.log(`Number of Sheets: ${response.data.sheets.length}`);
      console.log('\nAvailable Sheets:');
      response.data.sheets.forEach((sheet, index) => {
        console.log(`  ${index + 1}. ${sheet.properties.title}`);
      });
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    } else {
      console.log('⚠️  No GOOGLE_SHEET_ID provided in .env file');
      console.log('   Skipping sheet access test\n');
    }
    
    console.log('✨ Google Sheets API test completed successfully!');
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Google Sheets API test failed!\n');
    console.error('Error Details:');
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.error(`Message: ${error.message}`);
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    console.log('💡 Troubleshooting Tips:');
    console.log('  1. Ensure credentials file exists at:', process.env.GOOGLE_SHEETS_CREDENTIALS_PATH);
    console.log('  2. Verify Google Sheets API is enabled in Google Cloud Console');
    console.log('  3. Check if service account has access to the sheet');
    console.log('  4. Ensure GOOGLE_SHEET_ID is correct in .env file\n');
    
    process.exit(1);
  }
}

// Run the test
testSheetsAPI();
