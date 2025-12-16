#!/usr/bin/env node
/**
 * Main ETL Pipeline Script
 * Orchestrates Extract, Transform, and Load phases
 */

const Logger = require('./logger');
const Extractor = require('./extract');
const Transformer = require('./transform');
const Loader = require('./load');
const config = require('./config');

class ETLPipeline {
  constructor() {
    this.logger = new Logger();
    this.extractor = new Extractor(this.logger);
    this.transformer = new Transformer(this.logger);
    this.loader = new Loader(this.logger);
  }

  async run() {
    console.log('\n' + '='.repeat(70));
    console.log('🚀 ETL PIPELINE STARTED');
    console.log('='.repeat(70) + '\n');

    try {
      // ========================================================================
      // PHASE 1: EXTRACT
      // ========================================================================
      console.log('📥 PHASE 1: EXTRACT');
      console.log('─'.repeat(70));
      
      const extractedData = await this.extractor.extractAll();
      
      console.log('\n✅ Extraction complete\n');

      // ========================================================================
      // PHASE 2: TRANSFORM
      // ========================================================================
      console.log('🔄 PHASE 2: TRANSFORM');
      console.log('─'.repeat(70));
      
      const transformedData = await this.transformer.transform(extractedData);
      
      console.log('\n✅ Transformation complete\n');

      // ========================================================================
      // PHASE 3: LOAD
      // ========================================================================
      console.log('📤 PHASE 3: LOAD');
      console.log('─'.repeat(70));
      
      const loadResults = await this.loader.load(transformedData);
      
      console.log('\n✅ Load complete\n');

      // ========================================================================
      // SUMMARY
      // ========================================================================
      await this.printSummary(transformedData, loadResults);
      
      // Generate final report
      const report = this.logger.generateReport();
      
      console.log('✨ ETL Pipeline completed successfully!\n');
      
      return { success: true, report };
      
    } catch (error) {
      console.log('\n' + '='.repeat(70));
      console.log('❌ ETL PIPELINE FAILED');
      console.log('='.repeat(70));
      console.error('\nError:', error.message);
      console.error('\nStack trace:', error.stack);
      
      this.logger.error('ETL Pipeline failed', { 
        error: error.message, 
        stack: error.stack 
      });
      
      this.logger.generateReport();
      
      process.exit(1);
    }
  }

  async printSummary(transformedData, loadResults) {
    console.log('📊 PIPELINE SUMMARY');
    console.log('─'.repeat(70));
    
    // Customers
    if (transformedData.customers) {
      const validCount = transformedData.customers.valid.length;
      const invalidCount = transformedData.customers.invalid.length;
      const loadedCount = loadResults.customers?.loaded || 0;
      const failedCount = loadResults.customers?.failed || 0;
      
      console.log('\n👥 Customers:');
      console.log(`   ├─ Valid: ${validCount}`);
      console.log(`   ├─ Invalid: ${invalidCount}`);
      console.log(`   ├─ Loaded: ${loadedCount}`);
      console.log(`   └─ Failed: ${failedCount}`);
    }
    
    // Products
    if (transformedData.products) {
      const validCount = transformedData.products.valid.length;
      const invalidCount = transformedData.products.invalid.length;
      const loadedCount = loadResults.products?.loaded || 0;
      
      console.log('\n📦 Products:');
      console.log(`   ├─ Valid: ${validCount}`);
      console.log(`   ├─ Invalid: ${invalidCount}`);
      console.log(`   └─ Loaded: ${loadedCount}`);
    }
    
    // Orders
    if (transformedData.orders) {
      const validCount = transformedData.orders.valid.length;
      const invalidCount = transformedData.orders.invalid.length;
      const loadedCount = loadResults.orders?.loaded || 0;
      
      console.log('\n📋 Orders:');
      console.log(`   ├─ Valid: ${validCount}`);
      console.log(`   ├─ Invalid: ${invalidCount}`);
      console.log(`   └─ Loaded: ${loadedCount}`);
    }
    
    // Database summary
    try {
      await this.loader.initialize();
      const dbSummary = await this.loader.getLoadSummary();
      await this.loader.close();
      
      console.log('\n💾 Database Totals:');
      console.log(`   ├─ Customers: ${dbSummary.customers}`);
      console.log(`   ├─ Products: ${dbSummary.products}`);
      console.log(`   ├─ Orders: ${dbSummary.orders}`);
      console.log(`   └─ Order Items: ${dbSummary.orderItems}`);
    } catch (error) {
      console.log('\n⚠️  Could not fetch database summary');
    }
    
    console.log('\n');
  }
}

// ============================================================================
// CLI EXECUTION
// ============================================================================

async function main() {
  const args = process.argv.slice(2);
  
  // Display help
  if (args.includes('--help') || args.includes('-h')) {
    console.log(`
ETL Pipeline - Google Sheets to PostgreSQL/NeonDB

Usage:
  node etl/etl.js [options]

Options:
  --help, -h          Show this help message
  --dry-run           Run without loading data to database
  --continue-on-error Continue processing even if some records fail
  --no-dedupe         Skip deduplication step
  --no-validate       Skip validation step

Examples:
  node etl/etl.js                    # Run full ETL pipeline
  node etl/etl.js --dry-run          # Test without loading to DB
  node etl/etl.js --continue-on-error # Continue on individual record errors

Configuration:
  Edit etl/config.js to customize settings
  Set environment variables in .env file
    `);
    process.exit(0);
  }
  
  // Handle CLI options
  if (args.includes('--continue-on-error')) {
    config.etl.continueOnError = true;
    console.log('⚙️  Option: Continue on error enabled\n');
  }
  
  if (args.includes('--no-dedupe')) {
    config.etl.deduplicateData = false;
    console.log('⚙️  Option: Deduplication disabled\n');
  }
  
  if (args.includes('--no-validate')) {
    config.etl.validateBeforeLoad = false;
    console.log('⚙️  Option: Validation disabled\n');
  }
  
  // Run pipeline
  const pipeline = new ETLPipeline();
  await pipeline.run();
}

// Run if executed directly
if (require.main === module) {
  main().catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
}

module.exports = ETLPipeline;
