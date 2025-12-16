# Messy Dataset: Customer Survey Responses

## Description
Real-world customer survey data with various data quality issues.

## Structure
- **Records:** 153 (includes 3 duplicates)
- **Format:** CSV
- **Columns:** 10

## Columns
1. response_id - Survey response ID
2. full_name - Customer name
3. email - Email address
4. phone_number - Phone number
5. city - City name
6. state - State code
7. survey_date - Survey submission date
8. rating - Customer rating
9. comments - Customer comments
10. is_duplicate - Duplicate flag

## Data Quality Issues
- ❌ Missing values (nulls, empty strings)
- ❌ Inconsistent formatting (UPPERCASE, lowercase, Mixed)
- ❌ Invalid email formats
- ❌ Various phone number formats
- ❌ Inconsistent date formats
- ❌ Invalid state codes
- ❌ Duplicate records
- ❌ Extra whitespace
- ❌ Invalid values (e.g., rating = "Good")
- ❌ Inconsistent ID formats

## Challenges
- Requires extensive data cleaning
- Need to handle missing values
- Must standardize formats
- Duplicate detection needed
- Validation rules required

## Usage
Designed to practice:
- Data cleaning techniques
- Handling missing data
- Deduplication
- Format standardization
- Validation logic
