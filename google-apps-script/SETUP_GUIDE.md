# 📖 Google Apps Script Setup Guide

Step-by-step instructions to install and configure the auto-registration system.

---

## 🎯 Prerequisites

Before you begin:
- ✅ Google account with access to Google Sheets
- ✅ Google Sheet with customer data
- ✅ NeonDB database (or API endpoint for registration)
- ✅ Basic understanding of Google Sheets

---

## 📝 Step 1: Prepare Your Google Sheet

### 1.1 Create or Open Sheet

Open your Google Sheet with customer data.

### 1.2 Verify Column Headers

Ensure your sheet has these column headers (exact names):

```
Customer ID | Name | Email | Phone | City | State | Registration Date | Status
```

**Example:**
```
C001 | John Doe | john@email.com | 555-0101 | New York | NY | 2024-01-15 | Active
```

### 1.3 Add Sample Data (Optional)

Add a few test rows to validate the script works.

---

## 🔧 Step 2: Open Apps Script Editor

### 2.1 Access Script Editor

1. In your Google Sheet, click **Extensions** menu
2. Click **Apps Script**
3. A new tab opens with the script editor

### 2.2 Project Name

1. Click on "Untitled project" at the top
2. Rename to "Auto-Registration System"
3. Click "Rename"

---

## 📄 Step 3: Add Script Files

### 3.1 Add Main Script (Code.gs)

1. You'll see a default `Code.gs` file
2. **Delete all existing code** in it
3. Copy the entire content from `google-apps-script/Code.gs`
4. Paste into the editor
5. Click **💾 Save** (or Ctrl+S)

### 3.2 Add JSON Export Script

1. Click the **+** button next to "Files"
2. Select **Script**
3. Name it `JSONExport`
4. Copy content from `google-apps-script/JSONExport.gs`
5. Paste and save

### 3.3 Add Triggers Script

1. Click the **+** button again
2. Select **Script**
3. Name it `Triggers`
4. Copy content from `google-apps-script/Triggers.gs`
5. Paste and save

Your project should now have 3 files:
- Code.gs
- JSONExport.gs
- Triggers.gs

---

## ⚙️ Step 4: Configure Settings

### 4.1 Update Configuration

In `Code.gs`, find the `CONFIG` object (lines 10-30):

```javascript
const CONFIG = {
  API_ENDPOINT: 'YOUR_API_ENDPOINT_HERE',
  API_KEY: 'YOUR_API_KEY_HERE',
  CUSTOMER_SHEET_NAME: 'Sheet1',
  LOG_SHEET_NAME: 'Logs',
  ADMIN_EMAIL: 'admin@example.com',
  SEND_NOTIFICATIONS: true,
  REQUIRED_FIELDS: ['Customer ID', 'Name', 'Email'],
};
```

### 4.2 Update These Values:

| Setting | What to Enter | Example |
|---------|---------------|---------|
| `API_ENDPOINT` | Your API URL (or leave as is for testing) | `https://api.example.com/customers` |
| `API_KEY` | Your API key (if required) | `sk_live_abc123...` |
| `CUSTOMER_SHEET_NAME` | Name of your data sheet | `Sheet1` or `Customers` |
| `ADMIN_EMAIL` | Your email address | `your-email@gmail.com` |

**Note:** For testing without an API, leave `API_ENDPOINT` as `'YOUR_API_ENDPOINT_HERE'`. The script will use mock registration.

### 4.3 Save Changes

Click **💾 Save** (Ctrl+S)

---

## 🔐 Step 5: Authorize the Script

### 5.1 Run Initial Setup

1. In the script editor, select `onOpen` from the function dropdown
2. Click **▶ Run**
3. A dialog appears: "Authorization required"
4. Click **Review permissions**

### 5.2 Grant Permissions

1. Choose your Google account
2. Click **Advanced**
3. Click **Go to Auto-Registration System (unsafe)**
   - Don't worry, this is your own script!
4. Click **Allow**

The script now has permission to:
- Read and modify your spreadsheet
- Send emails on your behalf
- Access Google Drive

---

## 📱 Step 6: Verify Installation

### 6.1 Check Custom Menu

1. Go back to your Google Sheet
2. Refresh the page (F5 or Ctrl+R)
3. Look for **"Auto-Registration"** menu in the menu bar

If you see it, installation is successful! ✅

### 6.2 Test Configuration

1. Click **Auto-Registration** > **Show Configuration**
2. Verify your settings are correct

---

## ⚡ Step 7: Set Up Triggers

### 7.1 Enable Auto-Processing

1. In your sheet, click **Auto-Registration** > **Setup Triggers**
2. Click **OK** in the confirmation dialog
3. Authorize again if prompted

### 7.2 Verify Triggers

1. Click **Auto-Registration** > **List Triggers** (if available)
2. Or go to Apps Script editor > **⏰ Triggers** (left sidebar)
3. You should see 3 triggers:
   - `onEdit` - On edit
   - `processAllRowsScheduled` - Time-driven (hourly)
   - `dailyCleanup` - Time-driven (daily)

---

## 🧪 Step 8: Test the System

### 8.1 Test Single Row Validation

1. Select any data row (not the header)
2. Click **Auto-Registration** > **Test Validation**
3. You should see a validation result

### 8.2 Test Auto-Processing

1. Edit any cell in a data row
2. Wait 1-2 seconds
3. The row should highlight:
   - 🟢 Green = Valid
   - 🔴 Red = Invalid
4. Check the **Status** column for the result

### 8.3 Test Manual Processing

1. Click **Auto-Registration** > **Process All Rows**
2. Wait for processing to complete
3. See summary dialog with results

### 8.4 View Logs

1. Click **Auto-Registration** > **View Logs**
2. A new "Logs" sheet opens
3. See all operations logged with timestamps

---

## 📊 Step 9: Understand the Workflow

### What Happens When You Edit a Row:

1. **You edit a cell** in any data row
2. **onEdit trigger** fires automatically
3. **Script validates** the entire row
4. **Row is highlighted**:
   - Green = Valid ✅
   - Red = Invalid ❌
5. **Status is updated** in the Status column
6. **If invalid**, a comment is added with error details
7. **If valid**, script attempts to register to database
8. **Email notification** sent (if configured)
9. **Operation logged** in Logs sheet

---

## 🔄 Step 10: Configure API Integration (Optional)

If you want to actually register to NeonDB:

### Option A: Use the ETL API

If you've built an API endpoint as part of your ETL:

```javascript
API_ENDPOINT: 'http://your-server.com/api/customers'
API_KEY: 'your-api-key'
```

### Option B: Use Direct NeonDB API

Create a simple API endpoint that accepts POST requests:

```javascript
POST /api/customers
Content-Type: application/json

{
  "customer_id": "C001",
  "full_name": "John Doe",
  "email": "john@email.com",
  ...
}
```

### Option C: Use Mock Mode (Testing)

Leave API_ENDPOINT as default. Script will log registrations but not actually send to database.

---

## 📧 Step 11: Configure Email Notifications

### 11.1 Set Admin Email

In `Code.gs` CONFIG:

```javascript
ADMIN_EMAIL: 'your-email@gmail.com',
SEND_NOTIFICATIONS: true
```

### 11.2 Email Templates

Emails are sent for:
- Invalid entries detected
- Registration failures

Customize email content in `sendNotification()` function.

---

## 🎨 Step 12: Customize (Optional)

### Add Custom Validation Rules

In `Code.gs`, find `validateRowData()` function:

```javascript
// Add custom validation
if (data['Age']) {
  const age = parseInt(data['Age']);
  if (age < 18) {
    errors.push('Must be 18 or older');
  }
}
```

### Change Color Scheme

In CONFIG:

```javascript
COLOR_VALID: '#d9ead3',    // Light green
COLOR_INVALID: '#f4cccc',  // Light red
COLOR_PENDING: '#fff2cc'   // Light yellow
```

### Add More Required Fields

```javascript
REQUIRED_FIELDS: ['Customer ID', 'Name', 'Email', 'Phone']
```

---

## ✅ Verification Checklist

Check off each item:

- [ ] Google Sheet opened
- [ ] Column headers verified
- [ ] Apps Script editor opened
- [ ] All 3 script files added
- [ ] Configuration updated
- [ ] Scripts saved
- [ ] Script authorized
- [ ] Custom menu appears
- [ ] Triggers set up
- [ ] Test validation works
- [ ] Logs sheet created
- [ ] Email notifications configured
- [ ] Auto-processing works on edit

---

## 🐛 Common Issues & Solutions

### Issue: Custom menu doesn't appear

**Solution:**
- Refresh the page
- Run `onOpen` function manually
- Clear browser cache

### Issue: "Script not authorized"

**Solution:**
- Run `onOpen` again
- Go through authorization process
- Check Google account permissions

### Issue: Triggers don't fire

**Solution:**
- Delete all triggers
- Run "Setup Triggers" again
- Check triggers in Apps Script editor

### Issue: Script runs slow

**Solution:**
- Reduce trigger frequency
- Process rows in batches
- Optimize validation logic

---

## 📞 Support

If you encounter issues:

1. Check the **Logs** sheet for error details
2. Review **Execution log** in Apps Script editor (View > Logs)
3. Test with a simple sheet first
4. Verify API endpoint is accessible

---

## 🎉 Success!

You're all set! The auto-registration system is now active.

**Next Steps:**
1. Add real data to your sheet
2. Watch it auto-validate and register
3. Monitor the Logs sheet
4. Take screenshots for documentation

---

**Status:** ✅ Setup Complete!
