/**
 * Benchmark Query Performance
 * Tests query performance before and after optimizations
 */

const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL?.includes('neon.tech') ? { rejectUnauthorized: false } : false
});

const queries = [
  {
    name: 'Customer Order Summary',
    sql: `
      SELECT 
        customer_id,
        customer_name,
        COUNT(*) AS order_count,
        SUM(total_amount) AS total_spent
      FROM ecommerce_orders
      GROUP BY customer_id, customer_name
      ORDER BY total_spent DESC
    `
  },
  {
    name: 'Product Revenue Analysis',
    sql: `
      SELECT 
        product_category,
        product_name,
        SUM(quantity) AS total_sold,
        SUM(total_amount) AS total_revenue
      FROM ecommerce_orders
      GROUP BY product_category, product_name
      ORDER BY total_revenue DESC
    `
  },
  {
    name: 'Orders by Status',
    sql: `
      SELECT 
        status,
        COUNT(*) AS count,
        SUM(total_amount) AS revenue
      FROM ecommerce_orders
      GROUP BY status
    `
  },
  {
    name: 'Monthly Sales Trend',
    sql: `
      SELECT 
        DATE_TRUNC('month', order_date) AS month,
        COUNT(*) AS orders,
        SUM(total_amount) AS revenue
      FROM ecommerce_orders
      GROUP BY DATE_TRUNC('month', order_date)
      ORDER BY month
    `
  },
  {
    name: 'Survey Quality Check',
    sql: `
      SELECT 
        COUNT(*) AS total,
        COUNT(CASE WHEN had_quality_issues THEN 1 END) AS with_issues,
        AVG(rating) AS avg_rating
      FROM customer_surveys
    `
  },
  {
    name: 'Complex Join Query',
    sql: `
      SELECT 
        e.customer_id,
        e.customer_name,
        e.customer_email,
        COUNT(DISTINCT e.order_id) AS order_count,
        SUM(e.total_amount) AS total_spent,
        s.rating AS survey_rating
      FROM ecommerce_orders e
      LEFT JOIN customer_surveys s ON e.customer_email = s.email
      GROUP BY e.customer_id, e.customer_name, e.customer_email, s.rating
    `
  }
];

async function runBenchmark(queryObj, iterations = 5) {
  const times = [];
  
  for (let i = 0; i < iterations; i++) {
    const start = Date.now();
    await pool.query(queryObj.sql);
    const duration = Date.now() - start;
    times.push(duration);
  }
  
  const avg = times.reduce((a, b) => a + b, 0) / times.length;
  const min = Math.min(...times);
  const max = Math.max(...times);
  
  return { avg, min, max, times };
}

async function main() {
  console.log('═══════════════════════════════════════════════════════');
  console.log('  QUERY PERFORMANCE BENCHMARK');
  console.log('═══════════════════════════════════════════════════════\n');
  
  const results = [];
  
  for (const query of queries) {
    console.log(`\n📊 Testing: ${query.name}`);
    console.log('─'.repeat(60));
    
    const result = await runBenchmark(query, 5);
    
    console.log(`  Average: ${result.avg.toFixed(2)}ms`);
    console.log(`  Min:     ${result.min}ms`);
    console.log(`  Max:     ${result.max}ms`);
    console.log(`  Runs:    ${result.times.join(', ')}ms`);
    
    results.push({
      query: query.name,
      ...result
    });
  }
  
  console.log('\n═══════════════════════════════════════════════════════');
  console.log('  BENCHMARK SUMMARY');
  console.log('═══════════════════════════════════════════════════════\n');
  
  console.log('Query                          | Avg (ms) | Min (ms) | Max (ms)');
  console.log('─'.repeat(70));
  
  results.forEach(r => {
    const name = r.query.padEnd(30);
    const avg = r.avg.toFixed(2).padStart(8);
    const min = r.min.toString().padStart(8);
    const max = r.max.toString().padStart(8);
    console.log(`${name} | ${avg} | ${min} | ${max}`);
  });
  
  console.log('\n');
  
  await pool.end();
}

main().catch(console.error);
