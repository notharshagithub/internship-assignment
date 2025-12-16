/**
 * ETL Load Phase
 * Loads transformed data into PostgreSQL/NeonDB
 */

const { Pool } = require('pg');
const config = require('./config');

class Loader {
  constructor(logger) {
    this.logger = logger;
    this.pool = null;
  }

  async initialize() {
    this.logger.info('Initializing database connection...');
    
    this.pool = new Pool({
      connectionString: config.database.connectionString,
      ssl: config.database.ssl
    });
    
    // Test connection
    const client = await this.pool.connect();
    const result = await client.query('SELECT current_database(), version()');
    client.release();
    
    this.logger.success('Database connection established', {
      database: result.rows[0].current_database
    });
  }

  async close() {
    if (this.pool) {
      await this.pool.end();
      this.logger.info('Database connection closed');
    }
  }

  // ============================================================================
  // STATE MANAGEMENT
  // ============================================================================

  async ensureStatesExist(stateCodes) {
    if (!stateCodes || stateCodes.length === 0) {
      return;
    }

    this.logger.info('Ensuring states exist in database...');
    
    const uniqueStates = [...new Set(stateCodes.filter(s => s !== null))];
    
    const stateNames = {
      'NY': 'New York', 'CA': 'California', 'TX': 'Texas', 'FL': 'Florida',
      'IL': 'Illinois', 'PA': 'Pennsylvania', 'OH': 'Ohio', 'GA': 'Georgia',
      'NC': 'North Carolina', 'MI': 'Michigan', 'NJ': 'New Jersey', 'VA': 'Virginia',
      'WA': 'Washington', 'AZ': 'Arizona', 'MA': 'Massachusetts', 'TN': 'Tennessee',
      'IN': 'Indiana', 'MO': 'Missouri', 'MD': 'Maryland', 'WI': 'Wisconsin'
    };

    const client = await this.pool.connect();
    
    try {
      for (const code of uniqueStates) {
        const stateName = stateNames[code] || code;
        
        await client.query(`
          INSERT INTO states (state_code, state_name)
          VALUES ($1, $2)
          ON CONFLICT (state_code) DO NOTHING
        `, [code, stateName]);
      }
      
      this.logger.success(`Ensured ${uniqueStates.length} states exist`);
    } finally {
      client.release();
    }
  }

  // ============================================================================
  // CUSTOMER LOADING
  // ============================================================================

  async getNextCustomerId() {
    const result = await this.pool.query(`
      SELECT customer_id 
      FROM customers 
      WHERE customer_id ~ '^C[0-9]+$'
      ORDER BY CAST(SUBSTRING(customer_id FROM 2) AS INTEGER) DESC 
      LIMIT 1
    `);
    
    if (result.rows.length === 0) {
      return 'C001';
    }
    
    const lastId = result.rows[0].customer_id;
    const number = parseInt(lastId.substring(1)) + 1;
    return `C${number.toString().padStart(3, '0')}`;
  }

  async loadCustomers(customers) {
    this.logger.info('Loading customers into database...');
    
    if (!customers || customers.length === 0) {
      this.logger.warn('No customers to load');
      return { loaded: 0, failed: 0 };
    }

    // Ensure states exist
    const stateCodes = customers.map(c => c.state_code).filter(s => s);
    await this.ensureStatesExist(stateCodes);

    const client = await this.pool.connect();
    let loaded = 0;
    let failed = 0;
    const failedRecords = [];

    try {
      await client.query('BEGIN');

      for (const customer of customers) {
        try {
          // Generate customer_id if missing
          if (!customer.customer_id) {
            customer.customer_id = await this.getNextCustomerId();
            this.logger.info(`Generated customer_id: ${customer.customer_id} for row ${customer._rowIndex}`);
          }

          await client.query(`
            INSERT INTO customers (
              customer_id, full_name, email, phone_number, 
              city, state_code, registered_at, status, email_verified
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            ON CONFLICT (customer_id) 
            DO UPDATE SET
              full_name = EXCLUDED.full_name,
              email = EXCLUDED.email,
              phone_number = EXCLUDED.phone_number,
              city = EXCLUDED.city,
              state_code = EXCLUDED.state_code,
              registered_at = EXCLUDED.registered_at,
              status = EXCLUDED.status,
              updated_at = NOW()
          `, [
            customer.customer_id,
            customer.full_name,
            customer.email,
            customer.phone_number,
            customer.city,
            customer.state_code,
            customer.registered_at,
            customer.status,
            customer.email_verified
          ]);

          loaded++;
          this.logger.updateStats('loaded');
          
        } catch (error) {
          failed++;
          this.logger.error(`Failed to load customer from row ${customer._rowIndex}`, {
            error: error.message,
            customer: customer
          });
          
          failedRecords.push({
            row: customer._rowIndex,
            data: customer,
            error: error.message
          });
          
          if (!config.etl.continueOnError) {
            throw error;
          }
        }
      }

      await client.query('COMMIT');
      this.logger.success(`Loaded ${loaded} customers successfully`);
      
      if (failed > 0) {
        this.logger.warn(`Failed to load ${failed} customers`, {
          sample: failedRecords.slice(0, 3)
        });
      }

    } catch (error) {
      await client.query('ROLLBACK');
      this.logger.error('Transaction rolled back due to error', { error: error.message });
      throw error;
    } finally {
      client.release();
    }

    return { loaded, failed, failedRecords };
  }

  // ============================================================================
  // PRODUCT LOADING
  // ============================================================================

  async loadProducts(products) {
    this.logger.info('Loading products into database...');
    
    if (!products || products.length === 0) {
      this.logger.warn('No products to load');
      return { loaded: 0, failed: 0 };
    }

    const client = await this.pool.connect();
    let loaded = 0;
    let failed = 0;

    try {
      await client.query('BEGIN');

      for (const product of products) {
        try {
          await client.query(`
            INSERT INTO products (
              product_name, description, unit_price, stock_quantity, is_active
            ) VALUES ($1, $2, $3, $4, $5)
            ON CONFLICT (product_name) 
            DO UPDATE SET
              description = EXCLUDED.description,
              unit_price = EXCLUDED.unit_price,
              stock_quantity = EXCLUDED.stock_quantity,
              is_active = EXCLUDED.is_active,
              updated_at = NOW()
          `, [
            product.product_name,
            product.description,
            product.unit_price,
            product.stock_quantity || 0,
            product.is_active !== false
          ]);

          loaded++;
          this.logger.updateStats('loaded');
          
        } catch (error) {
          failed++;
          this.logger.error(`Failed to load product from row ${product._rowIndex}`, {
            error: error.message
          });
          
          if (!config.etl.continueOnError) {
            throw error;
          }
        }
      }

      await client.query('COMMIT');
      this.logger.success(`Loaded ${loaded} products successfully`);

    } catch (error) {
      await client.query('ROLLBACK');
      this.logger.error('Transaction rolled back', { error: error.message });
      throw error;
    } finally {
      client.release();
    }

    return { loaded, failed };
  }

  // ============================================================================
  // ORDER LOADING
  // ============================================================================

  async loadOrders(orders) {
    this.logger.info('Loading orders into database...');
    
    if (!orders || orders.length === 0) {
      this.logger.warn('No orders to load');
      return { loaded: 0, failed: 0 };
    }

    // Orders require customers to exist - will be implemented when order data is available
    this.logger.warn('Order loading not yet implemented - requires customer foreign keys');
    
    return { loaded: 0, failed: 0 };
  }

  // ============================================================================
  // MAIN LOAD METHOD
  // ============================================================================

  async load(transformedData) {
    this.logger.info('Starting data load...');
    
    await this.initialize();
    
    const results = {};
    
    try {
      // Load customers
      if (transformedData.customers && transformedData.customers.valid) {
        results.customers = await this.loadCustomers(transformedData.customers.valid);
      }
      
      // Load products (if available)
      if (transformedData.products && transformedData.products.valid) {
        results.products = await this.loadProducts(transformedData.products.valid);
      }
      
      // Load orders (if available)
      if (transformedData.orders && transformedData.orders.valid) {
        results.orders = await this.loadOrders(transformedData.orders.valid);
      }
      
      this.logger.success('Data load complete');
      
    } finally {
      await this.close();
    }
    
    return results;
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  async getLoadSummary() {
    const client = await this.pool.connect();
    
    try {
      const customers = await client.query('SELECT COUNT(*) FROM customers');
      const products = await client.query('SELECT COUNT(*) FROM products');
      const orders = await client.query('SELECT COUNT(*) FROM orders');
      const orderItems = await client.query('SELECT COUNT(*) FROM order_items');
      
      return {
        customers: parseInt(customers.rows[0].count),
        products: parseInt(products.rows[0].count),
        orders: parseInt(orders.rows[0].count),
        orderItems: parseInt(orderItems.rows[0].count)
      };
    } finally {
      client.release();
    }
  }
}

module.exports = Loader;
