/**
 * Trigger Setup and Management
 * Handles automatic execution triggers
 */

/**
 * Setup all triggers for auto-registration
 * Run this once to enable automatic processing
 */
function setupTriggers() {
  try {
    // Delete existing triggers first
    deleteAllTriggers();
    
    const ss = SpreadsheetApp.getActive();
    
    // 1. On Edit Trigger - fires when any cell is edited
    ScriptApp.newTrigger('onEdit')
      .forSpreadsheet(ss)
      .onEdit()
      .create();
    
    // 2. On Form Submit Trigger - fires when form is submitted
    // Uncomment if using Google Forms
    // ScriptApp.newTrigger('onFormSubmit')
    //   .forSpreadsheet(ss)
    //   .onFormSubmit()
    //   .create();
    
    // 3. Time-driven Trigger - process all rows periodically
    ScriptApp.newTrigger('processAllRowsScheduled')
      .timeBased()
      .everyHours(1)  // Run every hour
      .create();
    
    // 4. Daily cleanup trigger
    ScriptApp.newTrigger('dailyCleanup')
      .timeBased()
      .atHour(2)  // Run at 2 AM
      .everyDays(1)
      .create();
    
    SpreadsheetApp.getUi().alert(
      'Triggers Setup Complete',
      'The following triggers have been created:\n\n' +
      '✓ On Edit (validates when you edit cells)\n' +
      '✓ Hourly Processing (processes all unvalidated rows)\n' +
      '✓ Daily Cleanup (cleans old logs)\n\n' +
      'Auto-registration is now active!',
      SpreadsheetApp.getUi().ButtonSet.OK
    );
    
    Logger.log('Triggers setup complete');
    
  } catch (error) {
    logError('setupTriggers', error);
    SpreadsheetApp.getUi().alert('Error setting up triggers: ' + error.message);
  }
}

/**
 * Delete all existing triggers
 */
function deleteAllTriggers() {
  const triggers = ScriptApp.getProjectTriggers();
  triggers.forEach(trigger => {
    ScriptApp.deleteTrigger(trigger);
  });
  Logger.log(`Deleted ${triggers.length} existing triggers`);
}

/**
 * List all active triggers
 */
function listTriggers() {
  const triggers = ScriptApp.getProjectTriggers();
  
  let message = `Active Triggers: ${triggers.length}\n\n`;
  
  triggers.forEach((trigger, index) => {
    message += `${index + 1}. ${trigger.getHandlerFunction()}\n`;
    message += `   Type: ${trigger.getEventType()}\n`;
    message += `   Source: ${trigger.getTriggerSource()}\n\n`;
  });
  
  if (triggers.length === 0) {
    message = 'No triggers are currently active.\n\nRun "Setup Triggers" from the menu to enable auto-registration.';
  }
  
  SpreadsheetApp.getUi().alert('Active Triggers', message, SpreadsheetApp.getUi().ButtonSet.OK);
}

/**
 * Scheduled function: Process all unvalidated rows
 * Runs automatically via time-based trigger
 */
function processAllRowsScheduled() {
  try {
    Logger.log('Starting scheduled processing...');
    
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(CONFIG.CUSTOMER_SHEET_NAME);
    const lastRow = sheet.getLastRow();
    
    let processed = 0;
    
    // Process only unvalidated rows
    for (let row = 2; row <= lastRow; row++) {
      const statusCell = sheet.getRange(row, getColumnIndex(sheet, 'Status'));
      const currentStatus = statusCell.getValue();
      
      // Skip already processed rows
      if (currentStatus === 'Validated' || currentStatus === 'Registered') {
        continue;
      }
      
      processRow(sheet, row);
      processed++;
      
      // Add delay to avoid rate limits
      if (processed % 10 === 0) {
        Utilities.sleep(1000); // 1 second pause every 10 rows
      }
    }
    
    Logger.log(`Scheduled processing complete. Processed ${processed} rows.`);
    
    // Log to sheet
    appendToLogSheet('SCHEDULED', `Processed ${processed} rows`, { scheduled: true });
    
  } catch (error) {
    logError('processAllRowsScheduled', error);
  }
}

/**
 * Daily cleanup function
 * Removes old logs and performs maintenance
 */
function dailyCleanup() {
  try {
    Logger.log('Starting daily cleanup...');
    
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const logSheet = ss.getSheetByName(CONFIG.LOG_SHEET_NAME);
    
    if (logSheet) {
      const lastRow = logSheet.getLastRow();
      
      // Keep only last 1000 log entries
      if (lastRow > 1000) {
        const rowsToDelete = lastRow - 1000;
        logSheet.deleteRows(2, rowsToDelete);
        Logger.log(`Deleted ${rowsToDelete} old log entries`);
      }
    }
    
    // Could add more cleanup tasks here:
    // - Archive old data
    // - Generate daily reports
    // - Clear temporary data
    
    Logger.log('Daily cleanup complete');
    
  } catch (error) {
    logError('dailyCleanup', error);
  }
}

/**
 * Manual trigger management
 */
function manageTriggers() {
  const ui = SpreadsheetApp.getUi();
  const response = ui.alert(
    'Trigger Management',
    'What would you like to do?',
    ui.ButtonSet.YES_NO_CANCEL
  );
  
  // User clicked "Yes" - Setup triggers
  if (response == ui.Button.YES) {
    setupTriggers();
  }
  // User clicked "No" - Delete triggers
  else if (response == ui.Button.NO) {
    deleteAllTriggers();
    ui.alert('All triggers have been deleted. Auto-registration is now disabled.');
  }
  // User clicked "Cancel" or X - List triggers
  else {
    listTriggers();
  }
}
