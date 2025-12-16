/**
 * ETL Configuration
 * Central configuration for the ETL pipeline
 */

require('dotenv').config();

module.exports = {
  // Database Configuration
  database: {
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.DATABASE_URL?.includes('neon.tech') ? { rejectUnauthorized: false } : false
  },

  // Google Sheets Configuration
  googleSheets: {
    credentialsPath: process.env.GOOGLE_SHEETS_CREDENTIALS_PATH || './credentials/google-credentials.json',
    spreadsheetId: process.env.GOOGLE_SHEET_ID
  },

  // ETL Configuration
  etl: {
    batchSize: 100,
    logLevel: 'info', // 'debug', 'info', 'warn', 'error'
    continueOnError: false,
    validateBeforeLoad: true,
    deduplicateData: true
  },

  // Logging Configuration
  logging: {
    logsDir: './etl/logs',
    reportsDir: './etl/reports',
    enableConsole: true,
    enableFile: true
  },

  // Sheet Names (customize based on your Google Sheet)
  sheetNames: {
    customers: 'Sheet1',
    orders: 'Orders',
    products: 'Products'
  }
};
