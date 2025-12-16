/**
 * JSON Export Functionality
 * Export sheet data to JSON for ETL ingestion
 */

/**
 * Export current sheet to JSON
 */
function exportToJSON() {
  try {
    const sheet = SpreadsheetApp.getActiveSheet();
    const ui = SpreadsheetApp.getUi();
    
    // Get all data
    const data = sheet.getDataRange().getValues();
    const headers = data[0];
    const rows = data.slice(1);
    
    // Convert to JSON array
    const jsonData = rows.map(row => {
      const obj = {};
      headers.forEach((header, index) => {
        obj[header] = row[index];
      });
      return obj;
    });
    
    // Create JSON string
    const jsonString = JSON.stringify(jsonData, null, 2);
    
    // Display in dialog
    const htmlOutput = HtmlService
      .createHtmlOutput(`
        <h3>JSON Export</h3>
        <p>Records: ${jsonData.length}</p>
        <textarea style="width:100%; height:400px; font-family:monospace; font-size:12px;">${jsonString}</textarea>
        <br><br>
        <button onclick="google.script.host.close()">Close</button>
      `)
      .setWidth(600)
      .setHeight(500);
    
    ui.showModalDialog(htmlOutput, 'JSON Export');
    
    // Also save to Drive
    saveJSONToDrive(jsonData, sheet.getName());
    
    Logger.log(`Exported ${jsonData.length} records to JSON`);
    
  } catch (error) {
    logError('exportToJSON', error);
    SpreadsheetApp.getUi().alert('Export Error: ' + error.message);
  }
}

/**
 * Export validated records only
 */
function exportValidatedToJSON() {
  try {
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(CONFIG.CUSTOMER_SHEET_NAME);
    const data = sheet.getDataRange().getValues();
    const headers = data[0];
    const statusIndex = headers.indexOf('Status');
    
    // Filter only validated/registered records
    const validatedRows = data.slice(1).filter(row => {
      const status = row[statusIndex];
      return status === 'Validated' || status === 'Registered';
    });
    
    // Convert to JSON
    const jsonData = validatedRows.map(row => {
      const obj = {};
      headers.forEach((header, index) => {
        obj[header] = row[index];
      });
      return obj;
    });
    
    const jsonString = JSON.stringify(jsonData, null, 2);
    
    // Save to Drive
    const fileName = `validated_customers_${new Date().toISOString().split('T')[0]}.json`;
    const file = DriveApp.createFile(fileName, jsonString, MimeType.PLAIN_TEXT);
    
    SpreadsheetApp.getUi().alert(
      'Export Complete',
      `Exported ${jsonData.length} validated records to:\n${file.getUrl()}`,
      SpreadsheetApp.getUi().ButtonSet.OK
    );
    
    return file.getUrl();
    
  } catch (error) {
    logError('exportValidatedToJSON', error);
    throw error;
  }
}

/**
 * Save JSON to Google Drive
 */
function saveJSONToDrive(jsonData, sheetName) {
  try {
    const fileName = `${sheetName}_export_${new Date().toISOString().split('T')[0]}.json`;
    const jsonString = JSON.stringify(jsonData, null, 2);
    
    // Create or update file
    const files = DriveApp.getFilesByName(fileName);
    let file;
    
    if (files.hasNext()) {
      file = files.next();
      file.setContent(jsonString);
    } else {
      file = DriveApp.createFile(fileName, jsonString, MimeType.PLAIN_TEXT);
    }
    
    Logger.log(`JSON saved to Drive: ${file.getUrl()}`);
    return file.getUrl();
    
  } catch (error) {
    Logger.log('Failed to save JSON to Drive:', error);
    return null;
  }
}

/**
 * Generate JSON for ETL pipeline
 * Formats data according to ETL expectations
 */
function generateETLJSON() {
  try {
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(CONFIG.CUSTOMER_SHEET_NAME);
    const data = sheet.getDataRange().getValues();
    const headers = data[0];
    const rows = data.slice(1);
    
    // Map to ETL format
    const etlData = rows.map(row => {
      return {
        customer_id: row[headers.indexOf('Customer ID')],
        full_name: row[headers.indexOf('Name')],
        email: row[headers.indexOf('Email')],
        phone_number: row[headers.indexOf('Phone')] || null,
        city: row[headers.indexOf('City')] || null,
        state_code: row[headers.indexOf('State')] || null,
        registered_at: row[headers.indexOf('Registration Date')] || new Date().toISOString().split('T')[0],
        status: row[headers.indexOf('Status')] || 'Active',
        email_verified: false
      };
    });
    
    // Filter out invalid entries
    const validData = etlData.filter(record => 
      record.customer_id && record.full_name && record.email
    );
    
    const jsonString = JSON.stringify({
      source: 'google_sheets',
      exported_at: new Date().toISOString(),
      record_count: validData.length,
      data: validData
    }, null, 2);
    
    // Save to Drive
    const fileName = `etl_import_${new Date().toISOString().split('T')[0]}.json`;
    const file = DriveApp.createFile(fileName, jsonString, MimeType.PLAIN_TEXT);
    
    SpreadsheetApp.getUi().alert(
      'ETL JSON Generated',
      `Created ETL import file with ${validData.length} records:\n${file.getUrl()}\n\nDownload this file and place it in your ETL import folder.`,
      SpreadsheetApp.getUi().ButtonSet.OK
    );
    
    return file.getUrl();
    
  } catch (error) {
    logError('generateETLJSON', error);
    throw error;
  }
}

/**
 * Export statistics
 */
function exportStatistics() {
  try {
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(CONFIG.CUSTOMER_SHEET_NAME);
    const data = sheet.getDataRange().getValues();
    const headers = data[0];
    const statusIndex = headers.indexOf('Status');
    
    const stats = {
      total_rows: data.length - 1,
      validated: 0,
      registered: 0,
      invalid: 0,
      pending: 0,
      error: 0
    };
    
    data.slice(1).forEach(row => {
      const status = row[statusIndex];
      if (status === 'Validated') stats.validated++;
      else if (status === 'Registered') stats.registered++;
      else if (status === 'Invalid') stats.invalid++;
      else if (status === 'Pending') stats.pending++;
      else if (status === 'Error') stats.error++;
    });
    
    const statsText = `
Sheet Statistics:
─────────────────────────────────
Total Rows: ${stats.total_rows}
Validated: ${stats.validated}
Registered: ${stats.registered}
Invalid: ${stats.invalid}
Pending: ${stats.pending}
Errors: ${stats.error}

Success Rate: ${((stats.validated + stats.registered) / stats.total_rows * 100).toFixed(1)}%
    `;
    
    SpreadsheetApp.getUi().alert('Statistics', statsText, SpreadsheetApp.getUi().ButtonSet.OK);
    
    return stats;
    
  } catch (error) {
    logError('exportStatistics', error);
  }
}
