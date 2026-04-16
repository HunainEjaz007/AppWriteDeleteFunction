# Debugging Guide - Appwrite Cleanup Function

## How to Test and Debug

### Step 1: Test Connection Locally

Before deploying, test your connection locally:

```bash
# Set your API key
$env:APPWRITE_API_KEY="your_api_key_here"

# Optional: Set project ID if different from config
$env:APPWRITE_FUNCTION_PROJECT_ID="your_project_id"

# Run test
dart lib/test_connection.dart
```

If this works, your credentials and config are correct.

### Step 2: Check Function Logs in Appwrite Console

After deploying and running the function:

1. Go to Appwrite Console → Functions → Your Function
2. Click on the "Executions" tab
3. Click on a specific execution
4. Check the "Logs" section - you'll see detailed JSON logs

### Step 3: Check the Response

The function now returns detailed logs in the response:

```json
{
  "success": true,
  "deleted_count": 10,
  "duration_ms": 1500,
  "was_limited": false,
  "logs": [
    {"timestamp": "...", "level": "INFO", "message": "=== CLOUD FUNCTION STARTED ==="},
    {"timestamp": "...", "level": "INFO", "message": "Context type: RuntimeContext"},
    {"timestamp": "...", "level": "INFO", "message": "Available env vars: [...]"},
    {"timestamp": "...", "level": "INFO", "message": "Project ID: SET"},
    {"timestamp": "...", "level": "INFO", "message": "API Key: SET (standard_...)"},
    {"timestamp": "...", "level": "INFO", "message": "Database connection successful"},
    {"timestamp": "...", "level": "INFO", "message": "Querying ALL documents", "context": {"found_documents": 10}},
    {"timestamp": "...", "level": "INFO", "message": "Deleting document", "context": {"document_id": "..."}},
    ...
  ]
}
```

### Common Issues and Solutions

#### Issue: "Missing APPWRITE_FUNCTION_PROJECT_ID or APPWRITE_API_KEY"

**Cause:** Environment variables not set in Appwrite function.

**Solution:**
1. Go to Appwrite Console → Functions → Your Function
2. Click "Settings" tab
3. Under "Environment Variables", add:
   - `APPWRITE_API_KEY` = your API key (must have database.delete permission)
   - `APPWRITE_FUNCTION_PROJECT_ID` = your project ID

#### Issue: "Database connection failed"

**Cause:** Wrong database/collection ID or permissions.

**Solution:**
1. Verify `databaseId` and `collectionId` in `lib/src/config.dart`
2. Check that your API key has permission to read/delete from this collection
3. Verify collection exists in Appwrite Console

#### Issue: "No documents found to delete" but documents exist

**Cause:** 
- API key can't read documents (permission issue)
- Wrong database/collection ID

**Solution:**
Check the logs - if "Querying ALL documents" shows 0 found but you see documents in the console, it's a permissions issue.

#### Issue: "Failed to delete document"

**Cause:**
- API key doesn't have delete permission
- Collection permissions don't allow function to delete

**Solution:**
1. Update your API key scope to include `databases.write` and `collections.write`
2. Check collection permissions in Appwrite Console:
   - Go to Database → Collection → Settings
   - Under "Permissions", ensure the function's API key role has "Delete" permission

### Quick Permission Check

In Appwrite Console:
1. API Keys → Your Key → Scopes
   - Must have: `databases.read`, `databases.write`, `collections.read`, `collections.write`, `documents.read`, `documents.write`

2. Database → Collection → Settings → Permissions
   - Must allow "Delete" for your API key's role (or "Any" for testing)

### Testing with LIMIT_ROWS

To test safely without deleting everything:

```
CUTOFF_TIME_MINUTES=1
LIMIT_ROWS=1
```

This will only delete 1 document.

### Still Not Working?

1. Check the execution logs in Appwrite Console (Functions → Executions → click execution)
2. Look for the first ERROR log
3. Share that error message for debugging
