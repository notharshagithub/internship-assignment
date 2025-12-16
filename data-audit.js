/**
 * Data Audit & Assessment Script
 * Analyzes Google Sheets data for quality issues and migration planning
 */

require('dotenv').config();
const { google } = require('googleapis');
const fs = require('fs');

async function getGoogleSheetsClient() {
  const credentialsPath = process.env.GOOGLE_SHEETS_CREDENTIALS_PATH || './credentials/google-credentials.json';
  const credentials = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));
  
  const auth = new google.auth.GoogleAuth({
    credentials: credentials,
    scopes: ['https://www.googleapis.com/auth/spreadsheets']
  });
  
  const authClient = await auth.getClient();
  return google.sheets({ version: 'v4', auth: authClient });
}

async function readSheetData(sheetId, range = 'Sheet1') {
  const sheets = await getGoogleSheetsClient();
  
  // Get all data from the sheet
  const response = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
    range: range
  });
  
  return response.data.values || [];
}

function analyzeDataQuality(data) {
  if (!data || data.length === 0) {
    return { error: 'No data found' };
  }

  const headers = data[0];
  const rows = data.slice(1);
  
  console.log('\n📊 DATA AUDIT REPORT');
  console.log('═'.repeat(70));
  
  // Basic Statistics
  console.log('\n📈 BASIC STATISTICS:');
  console.log(`   Total Rows: ${rows.length}`);
  console.log(`   Total Columns: ${headers.length}`);
  console.log(`   Headers: ${headers.join(', ')}`);
  
  // Column Analysis
  console.log('\n📋 COLUMN ANALYSIS:');
  console.log('─'.repeat(70));
  
  const columnStats = {};
  
  headers.forEach((header, colIndex) => {
    const values = rows.map(row => row[colIndex] || '');
    const nonEmpty = values.filter(v => v.trim() !== '');
    const empty = values.length - nonEmpty.length;
    const unique = new Set(nonEmpty).size;
    
    columnStats[header] = {
      total: values.length,
      filled: nonEmpty.length,
      empty: empty,
      unique: unique,
      fillRate: ((nonEmpty.length / values.length) * 100).toFixed(2) + '%',
      duplicates: nonEmpty.length - unique,
      sample: nonEmpty.slice(0, 3)
    };
    
    console.log(`\n   Column: "${header}"`);
    console.log(`   ├─ Total Values: ${values.length}`);
    console.log(`   ├─ Filled: ${nonEmpty.length}`);
    console.log(`   ├─ Empty/Missing: ${empty}`);
    console.log(`   ├─ Unique Values: ${unique}`);
    console.log(`   ├─ Fill Rate: ${columnStats[header].fillRate}`);
    console.log(`   ├─ Duplicates: ${columnStats[header].duplicates}`);
    console.log(`   └─ Sample: ${columnStats[header].sample.join(', ').substring(0, 50)}...`);
  });
  
  // Find Complete Duplicates
  console.log('\n🔍 DUPLICATE ROW ANALYSIS:');
  console.log('─'.repeat(70));
  
  const rowHashes = new Map();
  const duplicateRows = [];
  
  rows.forEach((row, index) => {
    const rowString = row.join('|');
    if (rowHashes.has(rowString)) {
      duplicateRows.push({
        originalIndex: rowHashes.get(rowString),
        duplicateIndex: index + 2, // +2 because of header and 0-indexing
        data: row
      });
    } else {
      rowHashes.set(rowString, index + 2);
    }
  });
  
  if (duplicateRows.length > 0) {
    console.log(`   ⚠️  Found ${duplicateRows.length} duplicate row(s)`);
    duplicateRows.slice(0, 5).forEach(dup => {
      console.log(`   Row ${dup.duplicateIndex} duplicates Row ${dup.originalIndex}`);
    });
  } else {
    console.log('   ✅ No complete duplicate rows found');
  }
  
  // Data Type Analysis
  console.log('\n🔢 DATA TYPE INFERENCE:');
  console.log('─'.repeat(70));
  
  headers.forEach((header, colIndex) => {
    const values = rows.map(row => row[colIndex] || '').filter(v => v.trim() !== '');
    
    let types = {
      number: 0,
      date: 0,
      email: 0,
      text: 0
    };
    
    values.forEach(val => {
      if (!isNaN(val) && val.trim() !== '') {
        types.number++;
      } else if (/^\d{4}-\d{2}-\d{2}/.test(val) || /^\d{1,2}\/\d{1,2}\/\d{2,4}/.test(val)) {
        types.date++;
      } else if (/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(val)) {
        types.email++;
      } else {
        types.text++;
      }
    });
    
    const dominant = Object.entries(types).reduce((a, b) => types[a[0]] > types[b[0]] ? a : b)[0];
    console.log(`   "${header}": ${dominant} (${types.number} numbers, ${types.date} dates, ${types.email} emails, ${types.text} text)`);
  });
  
  // Data Quality Issues
  console.log('\n⚠️  DATA QUALITY ISSUES:');
  console.log('─'.repeat(70));
  
  const issues = [];
  
  headers.forEach((header, colIndex) => {
    const stats = columnStats[header];
    
    if (stats.empty > 0) {
      issues.push(`   ⚠️  "${header}": ${stats.empty} missing values (${(100 - parseFloat(stats.fillRate)).toFixed(2)}% missing)`);
    }
    
    if (stats.duplicates > stats.filled * 0.5) {
      issues.push(`   ⚠️  "${header}": High duplicate rate (${stats.duplicates} duplicates in ${stats.filled} values)`);
    }
  });
  
  if (issues.length > 0) {
    issues.forEach(issue => console.log(issue));
  } else {
    console.log('   ✅ No major quality issues detected');
  }
  
  console.log('\n═'.repeat(70));
  console.log('✨ Data Audit Complete!\n');
  
  return {
    headers,
    totalRows: rows.length,
    columnStats,
    duplicateRows,
    dataQualityScore: calculateQualityScore(columnStats, duplicateRows, rows.length)
  };
}

function calculateQualityScore(columnStats, duplicateRows, totalRows) {
  const avgFillRate = Object.values(columnStats).reduce((sum, col) => sum + parseFloat(col.fillRate), 0) / Object.keys(columnStats).length;
  const duplicateRate = (duplicateRows.length / totalRows) * 100;
  const score = (avgFillRate * 0.7) + ((100 - duplicateRate) * 0.3);
  
  return {
    overall: score.toFixed(2) + '%',
    avgFillRate: avgFillRate.toFixed(2) + '%',
    duplicateRate: duplicateRate.toFixed(2) + '%'
  };
}

async function main() {
  console.log('🔍 Starting Data Audit & Assessment...\n');
  
  try {
    const sheetId = process.env.GOOGLE_SHEET_ID;
    
    if (!sheetId || sheetId === 'your_google_sheet_id_here') {
      throw new Error('Please set GOOGLE_SHEET_ID in .env file');
    }
    
    // Get sheet information
    const sheets = await getGoogleSheetsClient();
    const sheetInfo = await sheets.spreadsheets.get({
      spreadsheetId: sheetId
    });
    
    console.log(`📄 Analyzing: "${sheetInfo.data.properties.title}"`);
    console.log(`🔗 Sheet ID: ${sheetId}\n`);
    
    // Analyze each sheet
    for (const sheet of sheetInfo.data.sheets) {
      const sheetName = sheet.properties.title;
      console.log(`\n📊 Analyzing Sheet: "${sheetName}"`);
      console.log('─'.repeat(70));
      
      const data = await readSheetData(sheetId, sheetName);
      const analysis = analyzeDataQuality(data);
      
      console.log('\n📈 DATA QUALITY SCORE:');
      console.log(`   Overall Score: ${analysis.dataQualityScore.overall}`);
      console.log(`   Average Fill Rate: ${analysis.dataQualityScore.avgFillRate}`);
      console.log(`   Duplicate Rate: ${analysis.dataQualityScore.duplicateRate}`);
    }
    
  } catch (error) {
    console.error('\n❌ Error during data audit:', error.message);
    process.exit(1);
  }
}

// Run the audit
if (require.main === module) {
  main();
}

module.exports = { readSheetData, analyzeDataQuality };
