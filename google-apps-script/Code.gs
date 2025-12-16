/**
 * Google Apps Script - Auto-Registration System
 * Automatically validates and registers new entries to NeonDB
 */

// ============================================================================
// CONFIGURATION
// ============================================================================

const CONFIG = {
  // NeonDB API endpoint (you'll need to create this or use direct connection)
  API_ENDPOINT: 'YOUR_API_ENDPOINT_HERE', // e.g., https://your-api.com/api/customers
  API_KEY: 'YOUR_API_KEY_HERE',
  
  // Sheet configuration
  CUSTOMER_SHEET_NAME: 'Sheet1',
  LOG_SHEET_NAME: 'Logs',
  
  // Email notification
  ADMIN_EMAIL: 'admin@example.com',
  SEND_NOTIFICATIONS: true,
  
  // Validation rules
  REQUIRED_FIELDS: ['Customer ID', 'Name', 'Email'],
  
  // Colors for status highlighting
  COLOR_VALID: '#d9ead3',    // Light green
  COLOR_INVALID: '#f4cccc',  // Light red
  COLOR_PENDING: '#fff2cc'   // Light yellow
};

// ============================================================================
// MAIN TRIGGER FUNCTIONS
// ============================================================================

/**
 * Trigger: Runs when sheet is edited
 * Validates and processes new rows automatically
 */
function onEdit(e) {
  try {
    const sheet = e.source.getActiveSheet();
    const range = e.range;
    
    // Only process edits in the customer sheet
    if (sheet.getName() !== CONFIG.CUSTOMER_SHEET_NAME) {
      return;
    }
    
    // Only process row edits (not header)
    if (range.getRow() === 1) {
      return;
    }
    
    // Get the edited row
    const row = range.getRow();
    
    Logger.log(`Row ${row} edited, validating...`);
    
    // Validate and process the row
    processRow(sheet, row);
    
  } catch (error) {
    logError('onEdit', error);
  }
}

/**
 * Trigger: Runs when new row is added via form submission
 */
function onFormSubmit(e) {
  try {
    const sheet = e.range.getSheet();
    const row = e.range.getRow();
    
    Logger.log(`New form submission at row ${row}`);
    
    // Process the new row
    processRow(sheet, row);
    
  } catch (error) {
    logError('onFormSubmit', error);
  }
}

/**
 * Manual trigger: Process all unprocessed rows
 * Run this from the menu: Custom > Process All Rows
 */
function processAllRows() {
  try {
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(CONFIG.CUSTOMER_SHEET_NAME);
    const lastRow = sheet.getLastRow();
    
    let processed = 0;
    let validated = 0;
    let failed = 0;
    
    // Start from row 2 (skip header)
    for (let row = 2; row <= lastRow; row++) {
      const statusCell = sheet.getRange(row, getColumnIndex(sheet, 'Status'));
      const currentStatus = statusCell.getValue();
      
      // Skip already processed rows
      if (currentStatus === 'Validated' || currentStatus === 'Registered') {
        continue;
      }
      
      const result = processRow(sheet, row);
      processed++;
      
      if (result.valid) {
        validated++;
      } else {
        failed++;
      }
    }
    
    SpreadsheetApp.getUi().alert(
      `Processing Complete!\n\n` +
      `Processed: ${processed}\n` +
      `Validated: ${validated}\n` +
      `Failed: ${failed}`
    );
    
  } catch (error) {
    logError('processAllRows', error);
    SpreadsheetApp.getUi().alert('Error: ' + error.message);
  }
}

// ============================================================================
// CORE PROCESSING FUNCTIONS
// ============================================================================

/**
 * Process a single row: validate and register
 */
function processRow(sheet, rowNumber) {
  try {
    // Get row data
    const rowData = getRowData(sheet, rowNumber);
    
    // Validate the data
    const validation = validateRowData(rowData, rowNumber);
    
    if (validation.valid) {
      // Mark as validated
      highlightRow(sheet, rowNumber, CONFIG.COLOR_VALID);
      setStatus(sheet, rowNumber, 'Validated');
      
      // Attempt to register to database
      const registered = registerToDatabase(rowData);
      
      if (registered.success) {
        setStatus(sheet, rowNumber, 'Registered');
        logSuccess(rowNumber, rowData);
        return { valid: true, registered: true };
      } else {
        setStatus(sheet, rowNumber, 'Registration Failed');
        addComment(sheet, rowNumber, 'Registration error: ' + registered.error);
        logError('registerToDatabase', registered.error, rowData);
        
        if (CONFIG.SEND_NOTIFICATIONS) {
          sendNotification('Registration Failed', `Row ${rowNumber} validation passed but registration failed: ${registered.error}`);
        }
        
        return { valid: true, registered: false };
      }
      
    } else {
      // Mark as invalid
      highlightRow(sheet, rowNumber, CONFIG.COLOR_INVALID);
      setStatus(sheet, rowNumber, 'Invalid');
      
      // Add validation errors as comment
      const errorMessage = validation.errors.join('\n');
      addComment(sheet, rowNumber, errorMessage);
      
      logValidationError(rowNumber, rowData, validation.errors);
      
      // Send notification for invalid data
      if (CONFIG.SEND_NOTIFICATIONS) {
        sendNotification('Invalid Entry Detected', `Row ${rowNumber} has validation errors:\n${errorMessage}`);
      }
      
      return { valid: false, errors: validation.errors };
    }
    
  } catch (error) {
    highlightRow(sheet, rowNumber, CONFIG.COLOR_INVALID);
    setStatus(sheet, rowNumber, 'Error');
    logError('processRow', error, { row: rowNumber });
    return { valid: false, errors: [error.message] };
  }
}

/**
 * Get data from a row as an object
 */
function getRowData(sheet, rowNumber) {
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const values = sheet.getRange(rowNumber, 1, 1, sheet.getLastColumn()).getValues()[0];
  
  const rowData = {
    rowNumber: rowNumber
  };
  
  headers.forEach((header, index) => {
    rowData[header] = values[index];
  });
  
  return rowData;
}

/**
 * Validate row data according to rules
 */
function validateRowData(data, rowNumber) {
  const errors = [];
  
  // Check required fields
  CONFIG.REQUIRED_FIELDS.forEach(field => {
    if (!data[field] || data[field].toString().trim() === '') {
      errors.push(`${field} is required`);
    }
  });
  
  // Validate Customer ID format
  if (data['Customer ID']) {
    const customerId = data['Customer ID'].toString().trim();
    if (!/^C\d+$/.test(customerId)) {
      errors.push('Customer ID must be in format C### (e.g., C001)');
    }
  }
  
  // Validate Email format
  if (data['Email']) {
    const email = data['Email'].toString().trim();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      errors.push('Invalid email format');
    }
  }
  
  // Validate Phone format (if provided)
  if (data['Phone'] && data['Phone'].toString().trim() !== '') {
    const phone = data['Phone'].toString().replace(/\D/g, '');
    if (phone.length !== 7 && phone.length !== 10) {
      errors.push('Phone must be 7 or 10 digits');
    }
  }
  
  // Validate Status
  if (data['Status']) {
    const validStatuses = ['Active', 'Inactive', 'Pending', 'active', 'inactive', 'pending'];
    if (!validStatuses.includes(data['Status'])) {
      errors.push('Status must be Active, Inactive, or Pending');
    }
  }
  
  // Validate Registration Date (if provided)
  if (data['Registration Date'] && data['Registration Date'].toString().trim() !== '') {
    const date = new Date(data['Registration Date']);
    if (isNaN(date.getTime())) {
      errors.push('Invalid registration date format');
    }
    if (date > new Date()) {
      errors.push('Registration date cannot be in the future');
    }
  }
  
  return {
    valid: errors.length === 0,
    errors: errors
  };
}

/**
 * Register data to NeonDB
 * NOTE: This requires a backend API endpoint or direct database access
 */
function registerToDatabase(data) {
  try {
    // Option 1: Using REST API (recommended)
    if (CONFIG.API_ENDPOINT && CONFIG.API_ENDPOINT !== 'YOUR_API_ENDPOINT_HERE') {
      return registerViaAPI(data);
    }
    
    // Option 2: Mock registration for testing
    Logger.log('Mock registration (no API configured):', data);
    return {
      success: true,
      message: 'Mock registration successful (configure API_ENDPOINT for real registration)'
    };
    
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * Register via REST API
 */
function registerViaAPI(data) {
  try {
    const payload = {
      customer_id: data['Customer ID'],
      full_name: data['Name'],
      email: data['Email'],
      phone_number: data['Phone'] || null,
      city: data['City'] || null,
      state_code: data['State'] || null,
      registered_at: data['Registration Date'] || new Date().toISOString().split('T')[0],
      status: data['Status'] || 'Active',
      email_verified: false
    };
    
    const options = {
      method: 'post',
      contentType: 'application/json',
      headers: {
        'Authorization': 'Bearer ' + CONFIG.API_KEY
      },
      payload: JSON.stringify(payload),
      muteHttpExceptions: true
    };
    
    const response = UrlFetchApp.fetch(CONFIG.API_ENDPOINT, options);
    const responseCode = response.getResponseCode();
    
    if (responseCode === 200 || responseCode === 201) {
      return {
        success: true,
        message: 'Successfully registered to database'
      };
    } else {
      return {
        success: false,
        error: `API returned status ${responseCode}: ${response.getContentText()}`
      };
    }
    
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Get column index by header name
 */
function getColumnIndex(sheet, columnName) {
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const index = headers.indexOf(columnName);
  return index + 1; // Convert to 1-based index
}

/**
 * Highlight a row with a color
 */
function highlightRow(sheet, rowNumber, color) {
  const range = sheet.getRange(rowNumber, 1, 1, sheet.getLastColumn());
  range.setBackground(color);
}

/**
 * Set status in the Status column
 */
function setStatus(sheet, rowNumber, status) {
  const statusColumn = getColumnIndex(sheet, 'Status');
  if (statusColumn > 0) {
    sheet.getRange(rowNumber, statusColumn).setValue(status);
  }
}

/**
 * Add comment to a cell
 */
function addComment(sheet, rowNumber, comment) {
  const range = sheet.getRange(rowNumber, 1);
  range.setNote(comment);
}

/**
 * Send email notification
 */
function sendNotification(subject, body) {
  if (!CONFIG.SEND_NOTIFICATIONS || !CONFIG.ADMIN_EMAIL) {
    return;
  }
  
  try {
    MailApp.sendEmail({
      to: CONFIG.ADMIN_EMAIL,
      subject: `[Auto-Registration] ${subject}`,
      body: body
    });
  } catch (error) {
    Logger.log('Failed to send notification:', error);
  }
}

// ============================================================================
// LOGGING FUNCTIONS
// ============================================================================

/**
 * Log successful registration
 */
function logSuccess(rowNumber, data) {
  const message = `Row ${rowNumber}: Successfully validated and registered`;
  Logger.log(message);
  appendToLogSheet('SUCCESS', message, data);
}

/**
 * Log validation errors
 */
function logValidationError(rowNumber, data, errors) {
  const message = `Row ${rowNumber}: Validation failed - ${errors.join(', ')}`;
  Logger.log(message);
  appendToLogSheet('VALIDATION_ERROR', message, data);
}

/**
 * Log general errors
 */
function logError(functionName, error, additionalData) {
  const message = `Error in ${functionName}: ${error.message || error}`;
  Logger.log(message);
  appendToLogSheet('ERROR', message, additionalData);
}

/**
 * Append to log sheet
 */
function appendToLogSheet(level, message, data) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let logSheet = ss.getSheetByName(CONFIG.LOG_SHEET_NAME);
    
    // Create log sheet if it doesn't exist
    if (!logSheet) {
      logSheet = ss.insertSheet(CONFIG.LOG_SHEET_NAME);
      logSheet.appendRow(['Timestamp', 'Level', 'Message', 'Data']);
    }
    
    const timestamp = new Date().toISOString();
    const dataString = data ? JSON.stringify(data) : '';
    
    logSheet.appendRow([timestamp, level, message, dataString]);
    
  } catch (error) {
    Logger.log('Failed to write to log sheet:', error);
  }
}

// ============================================================================
// MENU AND UI FUNCTIONS
// ============================================================================

/**
 * Create custom menu when spreadsheet opens
 */
function onOpen() {
  const ui = SpreadsheetApp.getUi();
  ui.createMenu('Auto-Registration')
    .addItem('Process All Rows', 'processAllRows')
    .addItem('Export to JSON', 'exportToJSON')
    .addItem('Test Validation', 'testValidation')
    .addItem('View Logs', 'viewLogs')
    .addSeparator()
    .addItem('Setup Triggers', 'setupTriggers')
    .addItem('Show Configuration', 'showConfiguration')
    .addToUi();
}

/**
 * Show current configuration
 */
function showConfiguration() {
  const ui = SpreadsheetApp.getUi();
  const config = `
Current Configuration:

API Endpoint: ${CONFIG.API_ENDPOINT}
Customer Sheet: ${CONFIG.CUSTOMER_SHEET_NAME}
Log Sheet: ${CONFIG.LOG_SHEET_NAME}
Admin Email: ${CONFIG.ADMIN_EMAIL}
Notifications: ${CONFIG.SEND_NOTIFICATIONS ? 'Enabled' : 'Disabled'}

Required Fields: ${CONFIG.REQUIRED_FIELDS.join(', ')}
  `;
  
  ui.alert('Configuration', config, ui.ButtonSet.OK);
}

/**
 * Test validation on current row
 */
function testValidation() {
  const sheet = SpreadsheetApp.getActiveSheet();
  const row = sheet.getActiveCell().getRow();
  
  if (row === 1) {
    SpreadsheetApp.getUi().alert('Please select a data row (not header)');
    return;
  }
  
  const rowData = getRowData(sheet, row);
  const validation = validateRowData(rowData, row);
  
  if (validation.valid) {
    SpreadsheetApp.getUi().alert('Validation Passed', `Row ${row} is valid!`, SpreadsheetApp.getUi().ButtonSet.OK);
  } else {
    SpreadsheetApp.getUi().alert('Validation Failed', `Row ${row} has errors:\n\n${validation.errors.join('\n')}`, SpreadsheetApp.getUi().ButtonSet.OK);
  }
}

/**
 * View recent logs
 */
function viewLogs() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const logSheet = ss.getSheetByName(CONFIG.LOG_SHEET_NAME);
  
  if (!logSheet) {
    SpreadsheetApp.getUi().alert('No logs found. Log sheet will be created when first log entry is made.');
    return;
  }
  
  ss.setActiveSheet(logSheet);
}
