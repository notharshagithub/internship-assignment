# 🚀 Environment Setup Guide

## Step-by-Step Instructions

### ✅ Step 1: NeonDB Setup

1. **Create NeonDB Account**
   - Visit: https://neon.tech/
   - Click "Sign up" (free tier available)
   - Sign up with GitHub, Google, or email

2. **Create a Database**
   - After login, click "Create Project"
   - Choose a project name
   - Select a region closest to you
   - Click "Create Project"

3. **Get Connection String**
   - Go to your project dashboard
   - Click on "Connection Details"
   - Copy the connection string (looks like: `postgresql://user:pass@host.neon.tech/dbname`)
   - **Important**: Save this securely!

4. **Whitelist Your IP** (if needed)
   - In NeonDB dashboard, check IP allowlist settings
   - Add your current IP address

### ✅ Step 2: Google Cloud & Sheets API Setup

1. **Create Google Cloud Project**
   - Go to: https://console.cloud.google.com/
   - Click "Select a Project" → "New Project"
   - Enter project name
   - Click "Create"

2. **Enable Google Sheets API**
   - In Cloud Console, go to "APIs & Services" → "Library"
   - Search for "Google Sheets API"
   - Click on it and press "Enable"

3. **Create Service Account**
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "Service Account"
   - Enter a name (e.g., "sheets-api-service")
   - Click "Create and Continue"
   - Skip optional steps, click "Done"

4. **Download Credentials**
   - Click on the service account you just created
   - Go to "Keys" tab
   - Click "Add Key" → "Create new key"
   - Choose "JSON" format
   - Click "Create" - file will download
   - **Save this file securely!**

5. **Create Test Google Sheet**
   - Go to: https://sheets.google.com/
   - Create a new spreadsheet
   - Get the Sheet ID from URL: `https://docs.google.com/spreadsheets/d/{SHEET_ID}/edit`
   - Click "Share" button
   - Add the service account email (found in credentials JSON: `client_email`)
   - Give "Viewer" or "Editor" access

### ✅ Step 3: Project Configuration

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Create credentials folder**
   ```bash
   mkdir credentials
   ```

3. **Move Google credentials**
   - Move your downloaded JSON file to: `credentials/google-credentials.json`

4. **Configure Environment**
   ```bash
   cp .env.example .env
   ```

5. **Edit .env file**
   - Open `.env` in a text editor
   - Add your NeonDB connection string
   - Verify credentials path
   - Add your Google Sheet ID

   Example `.env`:
   ```env
   DATABASE_URL=postgresql://user:pass@ep-xyz.us-east-2.aws.neon.tech/neondb?sslmode=require
   GOOGLE_SHEETS_CREDENTIALS_PATH=./credentials/google-credentials.json
   GOOGLE_SHEET_ID=1a2b3c4d5e6f7g8h9i0j
   ```

### ✅ Step 4: Test Connections

1. **Test Database Connection**
   ```bash
   npm run test:db
   ```
   
   Expected output:
   ```
   ✅ Successfully connected to PostgreSQL/NeonDB!
   📊 Database Information:
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Database: neondb
   User: your_user
   Version: PostgreSQL 15.x
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

2. **Test Google Sheets API**
   ```bash
   npm run test:sheets
   ```
   
   Expected output:
   ```
   ✅ Successfully loaded Google API credentials
   ✅ Successfully authenticated with Google API
   📊 Testing access to Google Sheet...
   ```

3. **Take Screenshots**
   - Screenshot of successful DB connection
   - Screenshot of successful Sheets API connection
   - Save these for documentation

### ✅ Step 5: GitHub Repository Setup

1. **Create GitHub Repository**
   - Go to: https://github.com/new
   - Enter repository name
   - Choose public or private
   - Don't initialize with README (we already have one)
   - Click "Create repository"

2. **Push Your Code**
   ```bash
   git add .
   git commit -m "Initial setup: Node.js environment with NeonDB and Google Sheets API"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
   git push -u origin main
   ```

### ✅ Step 6: Documentation (Optional)

Create a Notion page titled **"Environment Setup"** with:
- Screenshots of successful connections
- Your database URL (remove password)
- Google Sheet ID
- Service account email
- Setup completion date
- Any issues encountered and solutions

## 🎉 Setup Complete!

Your checklist status:

- [x] Node.js environment set up
- [x] Project initialized with dependencies
- [ ] NeonDB account & cluster created *(Do this now)*
- [ ] DB credentials obtained *(From NeonDB dashboard)*
- [ ] DB connection tested *(Run: npm run test:db)*
- [ ] Google Cloud Project setup *(Create at console.cloud.google.com)*
- [ ] Sheets API enabled *(In API Library)*
- [ ] Service account created *(In Credentials)*
- [ ] Credentials downloaded *(Save to credentials/ folder)*
- [ ] Test sheet created & shared *(Share with service account)*
- [ ] Sheets API tested *(Run: npm run test:sheets)*
- [ ] Git repository initialized *(Already done)*
- [ ] GitHub repository created *(Create at github.com/new)*
- [ ] Code pushed to GitHub *(Follow Step 5)*

## 🆘 Need Help?

### Common Issues

**Database Connection Failed**
- Check if DATABASE_URL is correct in `.env`
- Verify your IP is whitelisted in NeonDB
- Ensure database is active (not paused)

**Google Sheets API Failed**
- Verify credentials file path
- Check if Sheet is shared with service account email
- Ensure Google Sheets API is enabled

**Module Not Found Errors**
- Run `npm install` again
- Delete `node_modules` and `package-lock.json`, then reinstall

## 📞 Resources

- [NeonDB Docs](https://neon.tech/docs)
- [Google Sheets API Guide](https://developers.google.com/sheets/api/quickstart/nodejs)
- [Node.js PostgreSQL Tutorial](https://node-postgres.com/)

---

**Next Steps:** After completing setup, you're ready to start building your application! 🚀
