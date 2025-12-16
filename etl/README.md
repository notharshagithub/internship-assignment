# ETL Pipeline Documentation

## Overview

This ETL (Extract, Transform, Load) pipeline migrates data from Google Sheets to PostgreSQL/NeonDB with full validation, transformation, and error handling.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     ETL PIPELINE                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────┐      ┌───────────┐      ┌──────────┐        │
│  │ EXTRACT  │ ───> │ TRANSFORM │ ───> │   LOAD   │        │
│  └──────────┘      └───────────┘      └──────────┘        │
│       │                  │                   │             │
│   Google            Validate            PostgreSQL         │
│   Sheets            Dedupe              NeonDB             │
│                     Normalize                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Features

✅ **Extract Phase**
- Reads data from multiple Google Sheets tabs
- Handles missing or empty sheets gracefully
- Converts rows to structured objects

✅ **Transform Phase**
- **Validation**: Email format, phone format, date format, ID format
- **Normalization**: State codes, phone numbers, customer IDs
- **Deduplication**: Removes duplicate records by email/ID
- **Type Conversion**: String to date, numeric, boolean
- **Default Values**: Fills missing required fields

✅ **Load Phase**
- Transactional inserts (all-or-nothing)
- Upsert support (ON CONFLICT)
- Foreign key validation
- Auto-generation of missing IDs
- Error recovery and rollback

✅ **Error Handling**
- Detailed logging to files
- Validation reports
- Continue-on-error mode
- Row-level error tracking

✅ **Reporting**
- Execution summary
- Statistics (extracted, transformed, loaded)
- Error reports
- Database state summary

## File Structure

```
etl/
├── etl.js              # Main pipeline orchestrator
├── config.js           # Configuration settings
├── logger.js           # Logging and reporting
├── extract.js          # Extract phase
├── transform.js        # Transform phase
├── load.js             # Load phase
├── README.md           # This file
├── logs/               # Log files (auto-generated)
│   ├── etl_*.log
│   └── errors_*.log
└── reports/            # Validation reports (auto-generated)
    └── report_*.json
```

## Configuration

Edit `etl/config.js` to customize:

```javascript
module.exports = {
  etl: {
    batchSize: 100,              // Records per batch
    continueOnError: false,      // Continue if individual record fails
    validateBeforeLoad: true,    // Validate before inserting
    deduplicateData: true        // Remove duplicates
  },
  sheetNames: {
    customers: 'Sheet1',         // Sheet name for customer data
    orders: 'Orders',            // Sheet name for orders
    products: 'Products'         // Sheet name for products
  }
};
```

## Usage

### Basic Usage

```bash
# Run full ETL pipeline
npm run etl

# Or directly
node etl/etl.js
```

### Advanced Options

```bash
# Dry run (no database loading)
node etl/etl.js --dry-run

# Continue on individual record errors
node etl/etl.js --continue-on-error

# Skip deduplication
node etl/etl.js --no-dedupe

# Skip validation
node etl/etl.js --no-validate

# Show help
node etl/etl.js --help
```

## Data Transformations

### Customer Data

| Field | Transformation |
|-------|---------------|
| `customer_id` | Uppercase, remove special chars, ensure C prefix |
| `full_name` | Trim whitespace, normalize spaces |
| `email` | Lowercase, validate format, ensure unique |
| `phone_number` | Standardize to XXX-XXXX or 10 digits |
| `city` | Trim whitespace |
| `state_code` | Convert full name to 2-letter code, uppercase |
| `registered_at` | Parse multiple date formats, validate not future |
| `status` | Map variants to standard values (Active/Inactive/Pending) |

### Validation Rules

- **Customer ID**: Must match pattern `C###`
- **Email**: Must be valid RFC 5322 format
- **Phone**: 7 or 10 digits
- **Registration Date**: Not in future
- **State Code**: Valid 2-letter US state code

## Error Handling

The pipeline handles errors at multiple levels:

1. **Row-level errors**: Skip invalid rows, log details
2. **Transaction errors**: Rollback on failure
3. **Connection errors**: Retry logic
4. **Validation errors**: Report before load

## Logs and Reports

### Log Files

Located in `etl/logs/`:

- `etl_TIMESTAMP.log` - Full execution log
- `errors_TIMESTAMP.log` - Error-only log

### Report Files

Located in `etl/reports/`:

- `report_TIMESTAMP.json` - Execution summary with statistics

## Incremental Loading

To enable incremental loading (only new/changed records):

1. Add a `last_sync` timestamp column to tables
2. Modify extract phase to filter by date
3. Use upsert logic in load phase

## Troubleshooting

### Common Issues

**Issue**: "Google credentials file not found"
- **Solution**: Ensure `GOOGLE_SHEETS_CREDENTIALS_PATH` is set in `.env`

**Issue**: "Database connection failed"
- **Solution**: Check `DATABASE_URL` in `.env` and verify NeonDB is accessible

**Issue**: "Foreign key constraint violation"
- **Solution**: Ensure parent records (customers) are loaded before child records (orders)

**Issue**: "Duplicate key error"
- **Solution**: Enable deduplication or clean source data

## Testing

Before running on production data:

1. **Test with sample data**:
   ```bash
   node etl/etl.js --dry-run
   ```

2. **Verify transformations**:
   - Check logs in `etl/logs/`
   - Review validation reports

3. **Test error handling**:
   ```bash
   node etl/etl.js --continue-on-error
   ```

## Performance

- **Batch processing**: Processes 100 records per batch (configurable)
- **Transaction size**: One transaction per entity type
- **Typical throughput**: ~1000 records/minute (varies by network)

## Next Steps

1. ✅ Test with sample data
2. ✅ Review validation reports
3. ✅ Run full migration
4. 🔄 Schedule incremental syncs (optional)
5. 📊 Create data validation queries

## Support

For issues or questions:
1. Check logs in `etl/logs/`
2. Review error reports
3. Enable debug logging in `config.js`
