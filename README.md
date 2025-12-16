# Development Environment Setup

This project provides a complete Node.js development environment with PostgreSQL/NeonDB and Google Sheets API integration.

## 📋 Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- Git
- NeonDB account OR PostgreSQL Docker instance
- Google Cloud Project with Sheets API enabled

## 🚀 Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment Variables

Copy the example environment file and fill in your credentials:

```bash
cp .env.example .env
```

Edit `.env` file with your actual credentials:

```env
DATABASE_URL=postgresql://username:password@host:5432/database_name
GOOGLE_SHEETS_CREDENTIALS_PATH=./credentials/google-credentials.json
GOOGLE_SHEET_ID=your_google_sheet_id_here
```

### 3. Set Up Google Sheets API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable Google Sheets API
4. Create Service Account credentials
5. Download credentials JSON file
6. Create `credentials` folder and save the file as `google-credentials.json`

```bash
mkdir credentials
# Move your downloaded credentials file to credentials/google-credentials.json
```

### 4. Set Up NeonDB

**Option A: Using NeonDB (Recommended for cloud)**

1. Go to [NeonDB](https://neon.tech/)
2. Sign up for free tier
3. Create a new project
4. Create a database
5. Copy the connection string from the dashboard
6. Paste it into your `.env` file as `DATABASE_URL`

**Option B: Using Local PostgreSQL with Docker**

```bash
docker run --name postgres-dev \
  -e POSTGRES_PASSWORD=yourpassword \
  -e POSTGRES_USER=youruser \
  -e POSTGRES_DB=yourdb \
  -p 5432:5432 \
  -d postgres:15
```

Then set your `DATABASE_URL` in `.env`:
```
DATABASE_URL=postgresql://youruser:yourpassword@localhost:5432/yourdb
```

## 🧪 Testing

### Test Database Connection

```bash
npm run test:db
```

Expected output:
```
✅ Successfully connected to PostgreSQL/NeonDB!
```

### Test Google Sheets API

```bash
npm run test:sheets
```

Expected output:
```
✅ Successfully authenticated with Google API
```

## 📁 Project Structure

```
.
├── package.json              # Project dependencies and scripts
├── .env.example              # Example environment variables
├── .env                      # Your actual environment variables (gitignored)
├── .gitignore               # Git ignore rules
├── test-db-connection.js    # Database connection test script
├── test-sheets-api.js       # Google Sheets API test script
├── credentials/             # Google API credentials (gitignored)
│   └── google-credentials.json
└── README.md                # This file
```

## 📦 Dependencies

- `pg` - PostgreSQL client for Node.js
- `dotenv` - Environment variable management
- `googleapis` - Google APIs client library

## ✅ Checklist

- [ ] Node.js environment set up
- [ ] NeonDB account & cluster created
- [ ] DB credentials obtained and configured in `.env`
- [ ] DB connection tested successfully
- [ ] Google Cloud Project created
- [ ] Google Sheets API enabled
- [ ] Service account credentials downloaded
- [ ] Sheets API connection tested successfully
- [ ] Git repository initialized
- [ ] GitHub repository created (optional)

## 🔧 Troubleshooting

### Database Connection Issues

1. **Connection timeout**: Check if your IP is whitelisted in NeonDB dashboard
2. **Authentication failed**: Verify your credentials in `.env`
3. **SSL errors**: Ensure SSL is properly configured for NeonDB

### Google Sheets API Issues

1. **Credentials not found**: Check path in `GOOGLE_SHEETS_CREDENTIALS_PATH`
2. **Permission denied**: Share the sheet with the service account email
3. **API not enabled**: Enable Google Sheets API in Cloud Console

## 📚 Additional Resources

- [NeonDB Documentation](https://neon.tech/docs)
- [Google Sheets API Documentation](https://developers.google.com/sheets/api)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Node.js pg Library](https://node-postgres.com/)

## 🤝 Next Steps

After completing the setup:

1. Take a screenshot of successful database connection
2. Take a screenshot of successful Google Sheets API connection
3. Document your setup in Notion
4. Push your code to GitHub (remember: `.env` and credentials are gitignored!)

## 📝 Notes

- Never commit `.env` file or credentials to Git
- Keep your credentials secure
- Use environment variables for all sensitive data
- Consider using a password manager for credentials
