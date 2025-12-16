/**
 * ETL Logger
 * Handles logging to console and files
 */

const fs = require('fs');
const path = require('path');
const config = require('./config');

class Logger {
  constructor() {
    this.logsDir = config.logging.logsDir;
    this.reportsDir = config.logging.reportsDir;
    
    // Ensure directories exist
    if (!fs.existsSync(this.logsDir)) {
      fs.mkdirSync(this.logsDir, { recursive: true });
    }
    if (!fs.existsSync(this.reportsDir)) {
      fs.mkdirSync(this.reportsDir, { recursive: true });
    }

    this.logFile = path.join(this.logsDir, `etl_${this.getTimestamp()}.log`);
    this.errorFile = path.join(this.logsDir, `errors_${this.getTimestamp()}.log`);
    this.stats = {
      startTime: new Date(),
      endTime: null,
      extracted: 0,
      transformed: 0,
      loaded: 0,
      errors: 0,
      warnings: 0,
      skipped: 0
    };
  }

  getTimestamp() {
    return new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
  }

  formatMessage(level, message, data = null) {
    const timestamp = new Date().toISOString();
    let formatted = `[${timestamp}] [${level}] ${message}`;
    if (data) {
      formatted += `\n${JSON.stringify(data, null, 2)}`;
    }
    return formatted;
  }

  log(level, message, data = null) {
    const formatted = this.formatMessage(level, message, data);
    
    // Console output
    if (config.logging.enableConsole) {
      const icons = { debug: '🔍', info: 'ℹ️', warn: '⚠️', error: '❌', success: '✅' };
      console.log(`${icons[level] || 'ℹ️'} ${message}`);
      if (data) console.log(data);
    }

    // File output
    if (config.logging.enableFile) {
      fs.appendFileSync(this.logFile, formatted + '\n');
      if (level === 'error') {
        fs.appendFileSync(this.errorFile, formatted + '\n');
      }
    }
  }

  debug(message, data) { this.log('debug', message, data); }
  info(message, data) { this.log('info', message, data); }
  warn(message, data) { this.log('warn', message, data); this.stats.warnings++; }
  error(message, data) { this.log('error', message, data); this.stats.errors++; }
  success(message, data) { this.log('success', message, data); }

  updateStats(key, count = 1) {
    this.stats[key] += count;
  }

  generateReport() {
    this.stats.endTime = new Date();
    const duration = (this.stats.endTime - this.stats.startTime) / 1000;

    const report = {
      summary: {
        startTime: this.stats.startTime.toISOString(),
        endTime: this.stats.endTime.toISOString(),
        duration: `${duration.toFixed(2)} seconds`,
        status: this.stats.errors === 0 ? 'SUCCESS' : 'COMPLETED_WITH_ERRORS'
      },
      statistics: {
        extracted: this.stats.extracted,
        transformed: this.stats.transformed,
        loaded: this.stats.loaded,
        skipped: this.stats.skipped,
        errors: this.stats.errors,
        warnings: this.stats.warnings
      }
    };

    const reportFile = path.join(this.reportsDir, `report_${this.getTimestamp()}.json`);
    fs.writeFileSync(reportFile, JSON.stringify(report, null, 2));

    // Print summary
    console.log('\n' + '='.repeat(70));
    console.log('📊 ETL PIPELINE SUMMARY');
    console.log('='.repeat(70));
    console.log(`⏱️  Duration: ${report.summary.duration}`);
    console.log(`📥 Extracted: ${report.statistics.extracted} records`);
    console.log(`🔄 Transformed: ${report.statistics.transformed} records`);
    console.log(`📤 Loaded: ${report.statistics.loaded} records`);
    console.log(`⏭️  Skipped: ${report.statistics.skipped} records`);
    console.log(`⚠️  Warnings: ${report.statistics.warnings}`);
    console.log(`❌ Errors: ${report.statistics.errors}`);
    console.log(`📋 Status: ${report.summary.status}`);
    console.log('='.repeat(70));
    console.log(`📄 Full report saved to: ${reportFile}\n`);

    return report;
  }
}

module.exports = Logger;
