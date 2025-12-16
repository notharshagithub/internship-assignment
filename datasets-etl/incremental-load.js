/**
 * Incremental/Batch Ingestion
 * Loads only new or updated records
 */

const fs = require('fs');
const { Pool } = require('pg');
const config = require('./config');

class IncrementalLoader {
  constructor() {
    this.pool = new Pool({
      connectionString: config.database.connectionString,
      ssl: config.database.ssl
    });
  }

  /**
   * Get last loaded timestamp
   */
  async getLastLoadTime(tableName) {
    const result = await this.pool.query(`
      SELECT MAX(loaded_at) as last_load 
      FROM ${tableName}
    `);
    return result.rows[0].last_load || new Date(0);
  }

  /**
   * Load new records only (incremental)
   */
  async loadIncremental(filePath, tableName) {
    console.log(`\n📊 Incremental Load: ${tableName}`);
    console.log('─'.repeat(60));
    
    const lastLoad = await this.getLastLoadTime(tableName);
    console.log(`Last load: ${lastLoad}`);
    
    // In real scenario, you'd filter CSV by timestamp
    // For demo, we'll simulate by checking existing records
    
    const content = fs.readFileSync(filePath, 'utf-8');
    const lines = content.split('\n').filter(line => line.trim());
    const headers = lines[0].split(',').map(h => h.replace(/"/g, '').trim());
    
    let newRecords = 0;
    let updatedRecords = 0;
    let skippedRecords = 0;
    
    console.log(`\n📥 Processing ${lines.length - 1} records...`);
    
    // Simulate incremental load
    for (let i = 1; i < Math.min(lines.length, 11); i++) { // Process first 10 for demo
      // In real scenario, check if record exists and is newer
      const exists = await this.pool.query(`
        SELECT id FROM ${tableName} LIMIT 1
      `);
      
      if (exists.rows.length === 0) {
        newRecords++;
      } else {
        skippedRecords++;
      }
    }
    
    console.log(`\n✓ New records: ${newRecords}`);
    console.log(`✓ Updated: ${updatedRecords}`);
    console.log(`✓ Skipped: ${skippedRecords}`);
    
    return { newRecords, updatedRecords, skippedRecords };
  }

  /**
   * Batch load with batching
   */
  async loadBatch(records, tableName, batchSize = 50) {
    console.log(`\n📦 Batch Load: ${records.length} records in batches of ${batchSize}`);
    
    const batches = [];
    for (let i = 0; i < records.length; i += batchSize) {
      batches.push(records.slice(i, i + batchSize));
    }
    
    console.log(`Created ${batches.length} batches`);
    
    let loaded = 0;
    for (let i = 0; i < batches.length; i++) {
      console.log(`  Processing batch ${i + 1}/${batches.length}...`);
      // Simulate batch insert
      loaded += batches[i].length;
    }
    
    console.log(`✓ Loaded ${loaded} records in ${batches.length} batches`);
    
    return loaded;
  }

  async close() {
    await this.pool.end();
  }
}

async function main() {
  console.log('═══════════════════════════════════════════════════════');
  console.log('  INCREMENTAL/BATCH INGESTION DEMO');
  console.log('═══════════════════════════════════════════════════════');
  
  const loader = new IncrementalLoader();
  
  try {
    // Demo: Incremental load
    await loader.loadIncremental(
      config.datasets.clean,
      'ecommerce_orders'
    );
    
    // Demo: Batch load
    const mockRecords = Array(100).fill({});
    await loader.loadBatch(mockRecords, 'ecommerce_orders', 25);
    
    console.log('\n═══════════════════════════════════════════════════════');
    console.log('  Demo Complete!');
    console.log('═══════════════════════════════════════════════════════\n');
    
  } finally {
    await loader.close();
  }
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = IncrementalLoader;
