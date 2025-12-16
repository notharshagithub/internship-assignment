/**
 * Load Clean Dataset (E-commerce Orders)
 * Standard ETL for well-structured data
 */

const fs = require('fs');
const { Pool } = require('pg');
const config = require('./config');

class CleanDatasetLoader {
  constructor() {
    this.pool = new Pool({
      connectionString: config.database.connectionString,
      ssl: config.database.ssl
    });
    this.stats = {
      extracted: 0,
      loaded: 0,
      failed: 0,
      startTime: Date.now()
    };
  }

  /**
   * Parse CSV file
   */
  parseCSV(filePath) {
    console.log(`\n📥 Reading CSV file: ${filePath}`);
    const content = fs.readFileSync(filePath, 'utf-8');
    const lines = content.split('\n').filter(line => line.trim());
    
    const headers = lines[0].split(',').map(h => h.replace(/"/g, '').trim());
    const rows = lines.slice(1).map(line => {
      // Simple CSV parser (handles quoted fields)
      const values = [];
      let current = '';
      let inQuotes = false;
      
      for (let char of line) {
        if (char === '"') {
          inQuotes = !inQuotes;
        } else if (char === ',' && !inQuotes) {
          values.push(current.trim());
          current = '';
        } else {
          current += char;
        }
      }
      values.push(current.trim());
      
      return values;
    });
    
    this.stats.extracted = rows.length;
    console.log(`✓ Extracted ${rows.length} rows`);
    
    return { headers, rows };
  }

  /**
   * Transform data
   */
  transformRow(headers, values) {
    const obj = {};
    headers.forEach((header, index) => {
      obj[header] = values[index] || null;
    });
    
    return {
      order_id: obj.order_id,
      customer_id: obj.customer_id,
      customer_name: obj.customer_name,
      customer_email: obj.customer_email,
      customer_city: obj.customer_city,
      customer_state: obj.customer_state,
      product_name: obj.product_name,
      product_category: obj.product_category,
      quantity: parseInt(obj.quantity),
      unit_price: parseFloat(obj.unit_price),
      total_amount: parseFloat(obj.total_amount),
      order_date: obj.order_date,
      status: obj.status
    };
  }

  /**
   * Load data to database
   */
  async loadData(data) {
    console.log(`\n📤 Loading ${data.length} records to database...`);
    
    const client = await this.pool.connect();
    
    try {
      await client.query('BEGIN');
      
      for (const record of data) {
        try {
          await client.query(`
            INSERT INTO ecommerce_orders (
              order_id, customer_id, customer_name, customer_email,
              customer_city, customer_state, product_name, product_category,
              quantity, unit_price, total_amount, order_date, status
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
            ON CONFLICT (order_id) DO UPDATE SET
              quantity = EXCLUDED.quantity,
              total_amount = EXCLUDED.total_amount,
              status = EXCLUDED.status
          `, [
            record.order_id, record.customer_id, record.customer_name, record.customer_email,
            record.customer_city, record.customer_state, record.product_name, record.product_category,
            record.quantity, record.unit_price, record.total_amount, record.order_date, record.status
          ]);
          
          this.stats.loaded++;
          
        } catch (error) {
          this.stats.failed++;
          console.error(`  ✗ Failed to load ${record.order_id}:`, error.message);
          
          if (!config.etl.continueOnError) {
            throw error;
          }
        }
      }
      
      await client.query('COMMIT');
      console.log(`✓ Loaded ${this.stats.loaded} records successfully`);
      
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('✗ Transaction rolled back:', error.message);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Run full ETL process
   */
  async run() {
    console.log('═══════════════════════════════════════════');
    console.log('  CLEAN DATASET LOADER');
    console.log('  Dataset: E-commerce Orders');
    console.log('═══════════════════════════════════════════');
    
    try {
      // Extract
      const { headers, rows } = this.parseCSV(config.datasets.clean);
      
      // Transform
      console.log('\n🔄 Transforming data...');
      const transformed = rows.map(row => this.transformRow(headers, row));
      console.log(`✓ Transformed ${transformed.length} records`);
      
      // Load
      await this.loadData(transformed);
      
      // Summary
      const duration = ((Date.now() - this.stats.startTime) / 1000).toFixed(2);
      
      console.log('\n═══════════════════════════════════════════');
      console.log('  LOAD COMPLETE');
      console.log('═══════════════════════════════════════════');
      console.log(`  Extracted: ${this.stats.extracted}`);
      console.log(`  Loaded:    ${this.stats.loaded}`);
      console.log(`  Failed:    ${this.stats.failed}`);
      console.log(`  Duration:  ${duration}s`);
      console.log('═══════════════════════════════════════════\n');
      
    } catch (error) {
      console.error('\n✗ ETL Failed:', error.message);
      throw error;
    } finally {
      await this.pool.end();
    }
  }
}

// Run if executed directly
if (require.main === module) {
  const loader = new CleanDatasetLoader();
  loader.run().catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
}

module.exports = CleanDatasetLoader;
