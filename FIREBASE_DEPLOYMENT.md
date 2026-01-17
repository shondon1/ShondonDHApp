# Firebase Rules Deployment Guide

## 🔥 Quick Fix for Permission Denied Errors

Your app was getting permission denied errors because:
1. **Missing collections** in Firestore rules (`content_blocks`, `radio_updates`, `radioState`, `scheduledContent`)
2. **Anonymous auth mismatch** - App uses anonymous auth, but rules required admin email

## ✅ What's Fixed

### New Firestore Rules (`firestore.rules`)
- ✅ Added missing collections: `content_blocks`, `radio_updates`, `radioState`, `scheduledContent`
- ✅ Anonymous users can now upload and manage content
- ✅ Admin-only collections still protected (`tickerMessages`, `liveStatus`, etc.)
- ✅ Public sync system still works (`radioClock`, `radioPlayhead`)

### New Storage Rules (`storage.rules`)
- ✅ Anonymous users can upload audio/video
- ✅ File size limits: Audio (100MB), Video (500MB), Thumbnails (10MB)
- ✅ Content type validation (audio/*, video/*, image/*)

---

## 🚀 Deployment Instructions

### Option 1: Firebase Console (Easiest)

#### Deploy Firestore Rules:
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Firestore Database** → **Rules** tab
4. Copy contents from `firestore.rules` file
5. Paste into the rules editor
6. Click **Publish**

#### Deploy Storage Rules:
1. Go to **Storage** → **Rules** tab
2. Copy contents from `storage.rules` file
3. Paste into the rules editor
4. Click **Publish**

### Option 2: Firebase CLI (Recommended)

#### First-time Setup:
```bash
# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in this directory
firebase init

# When prompted, select:
# - Firestore (Database Rules and Indexes)
# - Storage
# - Use existing project (select your DreamHouse project)
# - Keep default file names
```

#### Deploy Rules:
```bash
# Deploy only Firestore rules
firebase deploy --only firestore:rules

# Deploy only Storage rules
firebase deploy --only storage:rules

# Deploy both at once
firebase deploy --only firestore:rules,storage:rules

# Deploy everything (rules + indexes)
firebase deploy
```

---

## 🔒 Security Model

### Collection Access Levels

| Collection | Read | Write | Notes |
|------------|------|-------|-------|
| `radioFlow` | Public | Admin only | Main playlist |
| `radioClock` | Public | Public | Sync system |
| `radioPlayhead` | Public | Public | Legacy sync |
| `radioState` | Public | Authenticated | Current state |
| `content_blocks` | Public | Authenticated | Upload metadata |
| `radio_updates` | Public | Authenticated | Trigger updates |
| `scheduledContent` | Public | Authenticated | Programming |
| `tickerMessages` | Public | Admin only | Scrolling messages |
| `liveStatus` | Public | Admin only | Live stream status |
| `Updates` | Public | Admin only | Community updates |
| `latestVideo` | Public | Admin only | Featured video |
| `contributors` | Public | Admin only | Contributors list |

### Authentication Levels

1. **Public** (`if true`)
   - No authentication required
   - Used for reading data and sync operations

2. **Authenticated** (`if request.auth != null`)
   - Anonymous authentication required
   - App automatically signs in users anonymously
   - Can upload content and manage schedules

3. **Admin Only** (`if isAdmin()`)
   - Requires email authentication as `rashyslop@outlook.com`
   - Full access to all collections
   - For sensitive operations

---

## 🧪 Testing After Deployment

### 1. Verify Rules Deployment
```bash
# Check Firestore rules
firebase firestore:rules:get

# Check Storage rules
firebase storage:rules:get
```

### 2. Test Upload Functionality
1. Open your app
2. Try uploading audio/video content
3. Should see: "Upload successful!" ✅
4. If still failing, check Firebase Console → Usage → Authentication logs

### 3. Verify Anonymous Auth
In your app logs, you should see:
```
✅ Anonymous user authenticated: <USER_ID>
✅ Upload succeeded
```

---

## 🛠️ Troubleshooting

### Still Getting Permission Denied?

#### Check 1: Authentication Enabled
1. Firebase Console → Authentication → Sign-in method
2. Verify **Anonymous** is **Enabled** ✅

#### Check 2: Rules Deployed
1. Firebase Console → Firestore → Rules tab
2. Check "Last deployed" timestamp
3. Should show recent deployment

#### Check 3: App Check
If you enabled App Check, verify it's configured:
```swift
// In ShondonDHAppApp.swift
#if targetEnvironment(simulator)
    let providerFactory = AppCheckDebugProviderFactory()
#else
    let providerFactory = DeviceCheckProviderFactory()
#endif
AppCheck.setAppCheckProviderFactory(providerFactory)
```

#### Check 4: Collection Names
Verify your code uses exact collection names:
- ✅ `content_blocks` (not `contentBlocks`)
- ✅ `radio_updates` (not `radioUpdates`)
- ✅ `scheduledContent` (not `scheduled_content`)

### Need Admin Access?

To perform admin-only operations (ticker messages, live status):

1. **Enable Email Authentication:**
   - Firebase Console → Authentication → Sign-in method
   - Enable **Email/Password** ✅

2. **Create Admin Account:**
   ```bash
   # In Firebase Console → Authentication → Users
   # Add user with email: rashyslop@outlook.com
   ```

3. **Update App Code:**
   ```swift
   // Replace anonymous sign-in with email sign-in for admin
   Auth.auth().signIn(withEmail: "rashyslop@outlook.com", password: "your-password")
   ```

---

## 📊 Monitoring & Security

### Enable Monitoring
1. Firebase Console → Firestore → Usage tab
2. Monitor read/write operations
3. Set up budget alerts

### Security Best Practices
- ✅ Keep admin email up to date in rules
- ✅ Monitor unusual upload patterns
- ✅ Enable App Check for production
- ✅ Add rate limiting via Cloud Functions (optional)
- ✅ Regular security audits

### Optional: Add Rate Limiting
Create Cloud Function to limit uploads:
```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.rateLimit = functions.firestore
  .document('content_blocks/{docId}')
  .onCreate(async (snap, context) => {
    const userId = snap.data().userId;
    const now = Date.now();

    // Check uploads in last hour
    const recentUploads = await admin.firestore()
      .collection('content_blocks')
      .where('userId', '==', userId)
      .where('timestamp', '>', now - 3600000)
      .get();

    if (recentUploads.size > 10) {
      // Delete if over limit
      await snap.ref.delete();
      console.log(`Rate limit exceeded for user ${userId}`);
    }
  });
```

---

## 📝 Next Steps

1. ✅ Deploy the new rules (see instructions above)
2. ✅ Test upload functionality in your app
3. ✅ Verify anonymous authentication is working
4. ✅ Monitor Firebase Console for errors
5. ✅ (Optional) Set up admin email authentication for admin features

---

## 🆘 Need Help?

- **Firebase Documentation**: https://firebase.google.com/docs/firestore/security
- **Rules Simulator**: Firebase Console → Firestore → Rules → Playground
- **Support**: Check Firebase Console → Help → Support

---

## 📋 File Checklist

Make sure these files exist in your project:

- ✅ `firestore.rules` - Firestore security rules
- ✅ `storage.rules` - Storage security rules
- ✅ `firebase.json` - Firebase project configuration
- ✅ `firestore.indexes.json` - Database indexes
- ✅ `.firebaserc` - Project aliases (created by `firebase init`)

---

**Last Updated**: 2026-01-17
**Branch**: `claude/fix-firebase-permissions-AW6jG`
