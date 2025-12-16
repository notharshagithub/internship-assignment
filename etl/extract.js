/**
 * ETL Extract Phase
 * Extracts data from Google Sheets
 */

const { google } = require('googleapis');
const fs = require('fs');
const config = require('./config');

class Extractor {
  constructor(logger) {
    this.logger = logger;
    this.sheetsClient = null;
  }

  async initialize() {
    this.logger.info('Initializing Google Sheets client...');
    
    const credentialsPath = config.googleSheets.credentialsPath;
    
    if (!fs.existsSync(credentialsPath)) {
      throw new Error(`Google credentials file not found at: ${credentialsPath}`);
    }
    
    const credentials = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));
    
    const auth = new google.auth.GoogleAuth({
      credentials: credentials,
      scopes: ['https://www.googleapis.com/auth/spreadsheets.readonly']
    });
    
    const authClient = await auth.getClient();
    this.sheetsClient = google.sheets({ version: 'v4', auth: authClient });
    
    this.logger.success('Google Sheets client initialized');
  }

  async getSheetInfo() {
    const spreadsheetId = config.googleSheets.spreadsheetId;
    
    const response = await this.sheetsClient.spreadsheets.get({
      spreadsheetId: spreadsheetId
    });
    
    return {
      title: response.data.properties.title,
      sheets: response.data.sheets.map(s => ({
        name: s.properties.title,
        index: s.properties.index,
        rowCount: s.properties.gridProperties.rowCount,
        columnCount: s.properties.gridProperties.columnCount
      }))
    };
  }

  async extractSheet(sheetName) {
    this.logger.info(`Extracting data from sheet: "${sheetName}"...`);
    
    const spreadsheetId = config.googleSheets.spreadsheetId;
    
    try {
      const response = await this.sheetsClient.spreadsheets.values.get({
        spreadsheetId: spreadsheetId,
        range: sheetName
      });
      
      const values = response.data.values || [];
      
      if (values.length === 0) {
        this.logger.warn(`No data found in sheet: "${sheetName}"`);
        return { headers: [], data: [] };
      }
      
      const headers = values[0];
      const data = values.slice(1);
      
      this.logger.success(`Extracted ${data.length} rows from "${sheetName}"`);
      this.logger.updateStats('extracted', data.length);
      
      return { headers, data };
      
    } catch (error) {
      this.logger.error(`Failed to extract data from "${sheetName}"`, { error: error.message });
      throw error;
    }
  }

  async extractAll() {
    this.logger.info('Starting extraction of all configured sheets...');
    
    await this.initialize();
    
    const sheetInfo = await this.getSheetInfo();
    this.logger.info(`Spreadsheet: "${sheetInfo.title}"`, { 
      sheets: sheetInfo.sheets.map(s => s.name) 
    });
    
    const extractedData = {};
    
    // Extract customers (main sheet)
    if (config.sheetNames.customers) {
      extractedData.customers = await this.extractSheet(config.sheetNames.customers);
    }
    
    // Extract orders (if configured)
    if (config.sheetNames.orders) {
      try {
        extractedData.orders = await this.extractSheet(config.sheetNames.orders);
      } catch (error) {
        this.logger.warn('Orders sheet not found or empty, skipping...');
      }
    }
    
    // Extract products (if configured)
    if (config.sheetNames.products) {
      try {
        extractedData.products = await this.extractSheet(config.sheetNames.products);
      } catch (error) {
        this.logger.warn('Products sheet not found or empty, skipping...');
      }
    }
    
    return extractedData;
  }

  // Convert raw sheet data to objects
  parseRowsToObjects(headers, rows) {
    return rows.map((row, index) => {
      const obj = { _rowIndex: index + 2 }; // +2 because of header and 0-indexing
      headers.forEach((header, colIndex) => {
        obj[header] = row[colIndex] || null;
      });
      return obj;
    });
  }
}

module.exports = Extractor;
