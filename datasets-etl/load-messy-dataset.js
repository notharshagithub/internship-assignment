/**
 * Load Messy Dataset (Customer Surveys)
 * Advanced ETL with data cleaning and validation
 */

const fs = require('fs');
const { Pool } = require('pg');
const config = require('./config');

class MessyDatasetLoader {
  constructor() {
    this.pool = new Pool({
      connectionString: config.database.connectionString,
      ssl: config.database.ssl
    });
    this.stats = {
      extracted: 0,
      transformed: 0,
      loaded: 0,
      failed: 0,
      duplicates: 0,
      cleaned: 0,
      startTime: Date.now()
    };
    this.seenRecords = new Set();
  }

  /**
   * Parse CSV file
   */
  parseCSV(filePath) {
    console.log(`\n📥 Reading CSV file: ${filePath}`);
    const content = fs.readFileSync(filePath, 'utf-8');
    const lines = content.split('\n').filter(line => line.trim());
    
    const headers = lines[0].split(',').map(h => h.replace(/"/g, '').trim());
    const rows = [];
    
    for (let i = 1; i < lines.length; i++) {
      const line = lines[i];
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
      
      // Handle rows with missing columns
      while (values.length < headers.length) {
        values.push(null);
      }
      
      rows.push(values);
    }
    
    this.stats.extracted = rows.length;
    console.log(`✓ Extracted ${rows.length} rows (may include duplicates)`);
    
    return { headers, rows };
  }

  /**
   * Clean and transform data
   */
  transformRow(headers, values) {
    const obj = {};
    headers.forEach((header, index) => {
      let value = values[index];
      if (value === '' || value === null || value === 'null' || value === 'N/A' || value === 'n/a') {
        value = null;
      }
      obj[header] = value;
    });
    
    const issues = [];
    const original = { ...obj };
    
    // Clean response_id
    let response_id = obj.response_id;
    if (!response_id) {
      issues.push('Missing response_id');
    }
    
    // Clean name
    let full_name = obj.full_name;
    if (full_name) {
      const originalName = full_name;
      // Trim whitespace
      full_name = full_name.trim();
      // Normalize multiple spaces
      full_name = full_name.replace(/\s+/g, ' ');
      // Title case
      full_name = full_name.split(' ').map(word => {
        if (word.length > 0) {
          return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
        }
        return word;
      }).join(' ');
      
      if (originalName !== full_name) {
        issues.push('Name formatting fixed');
        this.stats.cleaned++;
      }
      
      // Check for suspicious patterns
      if (/^\d+$/.test(full_name)) {
        issues.push('Name is all digits');
      }
    } else {
      issues.push('Missing name');
    }
    
    // Clean email
    let email = obj.email;
    if (email) {
      const originalEmail = email;
      email = email.toLowerCase().trim();
      
      if (originalEmail !== email) {
        issues.push('Email normalized');
        this.stats.cleaned++;
      }
      
      // Validate email format
      if (!email.match(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)) {
        issues.push('Invalid email format');
        email = null;
      }
    } else {
      issues.push('Missing email');
    }
    
    // Clean phone
    let phone_number = obj.phone_number;
    if (phone_number) {
      const originalPhone = phone_number;
      // Extract digits only
      const digits = phone_number.replace(/\D/g, '');
      
      if (digits.length === 7) {
        phone_number = `${digits.slice(0, 3)}-${digits.slice(3)}`;
      } else if (digits.length === 10) {
        phone_number = digits;
      } else if (digits.length > 0) {
        issues.push('Invalid phone length');
        phone_number = null;
      }
      
      if (originalPhone !== phone_number && phone_number) {
        issues.push('Phone formatted');
        this.stats.cleaned++;
      }
    }
    
    // Clean state
    let state = obj.state;
    if (state) {
      state = state.toUpperCase().trim();
      
      // Validate 2-letter code
      if (state.length !== 2 || !/^[A-Z]{2}$/.test(state)) {
        issues.push('Invalid state code');
        state = null;
      }
    }
    
    // Clean city
    let city = obj.city;
    if (city) {
      city = city.trim();
      // Remove numbers at end
      city = city.replace(/\d+$/, '').trim();
      // Title case
      city = city.split(' ').map(word => 
        word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
      ).join(' ');
    }
    
    // Clean date
    let survey_date = obj.survey_date;
    if (survey_date) {
      // Try to parse different formats
      let date = null;
      
      if (/^\d{4}-\d{2}-\d{2}$/.test(survey_date)) {
        date = new Date(survey_date);
      } else if (/^\d{2}\/\d{2}\/\d{4}$/.test(survey_date)) {
        const [month, day, year] = survey_date.split('/');
        date = new Date(`${year}-${month}-${day}`);
      } else if (/^\d{2}-\d{2}-\d{4}$/.test(survey_date)) {
        const [day, month, year] = survey_date.split('-');
        date = new Date(`${year}-${month}-${day}`);
      }
      
      if (date && !isNaN(date.getTime()) && date <= new Date()) {
        survey_date = date.toISOString().split('T')[0];
      } else {
        issues.push('Invalid date');
        survey_date = null;
      }
    }
    
    // Clean rating
    let rating = obj.rating;
    if (rating) {
      const parsed = parseInt(rating);
      if (!isNaN(parsed) && parsed >= 1 && parsed <= 5) {
        rating = parsed;
      } else {
        issues.push('Invalid rating');
        rating = null;
      }
    }
    
    // Clean comments
    let comments = obj.comments;
    if (comments) {
      comments = comments.trim();
      if (comments.toLowerCase() === 'n/a' || comments.toLowerCase() === 'na') {
        comments = null;
      }
    }
    
    return {
      response_id,
      full_name,
      email,
      phone_number,
      city,
      state,
      survey_date,
      rating,
      comments,
      original_name: original.full_name,
      original_email: original.email,
      original_phone: original.phone_number,
      had_quality_issues: issues.length > 0,
      quality_issues: issues
    };
  }

  /**
   * Check for duplicates
   */
  isDuplicate(record) {
    const key = `${record.response_id}|${record.email}|${record.full_name}`;
    if (this.seenRecords.has(key)) {
      return true;
    }
    this.seenRecords.add(key);
    return false;
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
          // Skip duplicates
          if (this.isDuplicate(record)) {
            this.stats.duplicates++;
            console.log(`  ⚠️  Skipped duplicate: ${record.response_id}`);
            continue;
          }
          
          await client.query(`
            INSERT INTO customer_surveys (
              response_id, full_name, email, phone_number,
              city, state, survey_date, rating, comments,
              original_name, original_email, original_phone,
              had_quality_issues, quality_issues
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
            ON CONFLICT (response_id) DO NOTHING
          `, [
            record.response_id, record.full_name, record.email, record.phone_number,
            record.city, record.state, record.survey_date, record.rating, record.comments,
            record.original_name, record.original_email, record.original_phone,
            record.had_quality_issues, record.quality_issues
          ]);
          
          this.stats.loaded++;
          
        } catch (error) {
          this.stats.failed++;
          console.error(`  ✗ Failed to load ${record.response_id}:`, error.message);
          
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
    console.log('  MESSY DATASET LOADER');
    console.log('  Dataset: Customer Surveys');
    console.log('═══════════════════════════════════════════');
    
    try {
      // Extract
      const { headers, rows } = this.parseCSV(config.datasets.messy);
      
      // Transform
      console.log('\n🔄 Transforming and cleaning data...');
      const transformed = rows.map(row => this.transformRow(headers, row));
      this.stats.transformed = transformed.length;
      console.log(`✓ Transformed ${transformed.length} records`);
      console.log(`✓ Cleaned ${this.stats.cleaned} field values`);
      
      // Load
      await this.loadData(transformed);
      
      // Summary
      const duration = ((Date.now() - this.stats.startTime) / 1000).toFixed(2);
      
      console.log('\n═══════════════════════════════════════════');
      console.log('  LOAD COMPLETE');
      console.log('═══════════════════════════════════════════');
      console.log(`  Extracted:   ${this.stats.extracted}`);
      console.log(`  Transformed: ${this.stats.transformed}`);
      console.log(`  Cleaned:     ${this.stats.cleaned} fields`);
      console.log(`  Duplicates:  ${this.stats.duplicates}`);
      console.log(`  Loaded:      ${this.stats.loaded}`);
      console.log(`  Failed:      ${this.stats.failed}`);
      console.log(`  Duration:    ${duration}s`);
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
  const loader = new MessyDatasetLoader();
  loader.run().catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
}

module.exports = MessyDatasetLoader;
