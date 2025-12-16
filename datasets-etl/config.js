/**
 * Dataset ETL Configuration
 */

require('dotenv').config();

module.exports = {
  // Database Configuration
  database: {
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.DATABASE_URL?.includes('neon.tech') ? { rejectUnauthorized: false } : false
  },

  // Dataset Paths
  datasets: {
    clean: '../datasets/clean/ecommerce_orders.csv',
    messy: '../datasets/messy/customer_surveys.csv'
  },

  // ETL Configuration
  etl: {
    batchSize: 50,
    continueOnError: true,
    validateBeforeLoad: true,
    deduplicateData: true
  },

  // Logging
  logging: {
    logsDir: './datasets-etl/logs',
    enableConsole: true,
    enableFile: true
  }
};
