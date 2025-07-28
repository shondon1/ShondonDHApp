# DreamHouse Radio - Main App Files

## 📁 **WORKING FILES (Keep These)**

### **Core App Files:**
- `ContentView.swift` - Main app interface with navigation
- `ShondonDHAppApp.swift` - App entry point
- `UploadViewModel.swift` - Upload logic

### **Working Views:**
- `UploadView.swift` - Upload audio, video, YouTube content
- `RadioFlowView.swift` - Manage radio playlist order
- `RadioAdminView.swift` - Control radio content
- `ScheduleView.swift` - Schedule content

## 🗑️ **FILES SAFE TO REMOVE**

### **Enhanced Files (Not Used):**
- `main/EnhancedUploadView.swift` - Not used, replaced by simple UploadView
- `main/EnhancedUploadViewModel.swift` - Not used
- `main/TickerControlView.swift` - Complex version, not needed
- `main/QuickMessageView.swift` - Complex version, not needed
- `main/RadioStatusView.swift` - Complex version, not needed
- `main/DreamHouseRadioEnhanced.swift` - Not used in main app

### **Old/Unused Files:**
- `main/radiofeature.swift` - Old radio feature file
- `main/RadioFlowListView.swift` - Old version
- `main/ScheduleListView.swift` - Old version
- `ShondonDHApp/RadioBlock.swift` - Not used
- `ShondonDHApp/View/FilePickerView.swift` - Not used
- `ShondonDHApp/View/Content+Item.swift` - Not used

### **Radio App Files (Keep Separate):**
- `main/DHradio.swift` - This is for your main radio app, NOT the uploader app

## 📋 **CURRENT APP STRUCTURE**

```
mainapp/
├── ContentView.swift          # Main navigation
├── ShondonDHAppApp.swift     # App entry point
├── UploadView.swift          # Upload interface
├── UploadViewModel.swift     # Upload logic
├── RadioFlowView.swift       # Playlist management
├── RadioAdminView.swift      # Radio control
└── ScheduleView.swift        # Content scheduling
```

## 🎯 **WHAT THE APP DOES**

### **Upload Content:**
- Audio files (.mp3, .m4a, etc.)
- Video files (.mp4, .mov, etc.)
- YouTube URLs
- Saves to Firebase Storage & Firestore

### **Control Radio:**
- Set radio content URL
- Control content type (audio/video/YouTube)
- Update radio state in real-time

### **Manage Playlist:**
- View radio flow content
- Reorder playlist items
- Delete unwanted content

### **Add Ticker Messages:**
- Quick message addition
- Priority levels (Normal/High/Urgent)
- Real-time ticker updates

### **Schedule Content:**
- Add scheduled items
- Set date and time
- Manage active/inactive items

## 🔧 **FIREBASE COLLECTIONS USED**

- `radioFlow` - Main playlist content
- `tickerMessages` - Scrolling ticker messages
- `radioState` - Current radio state
- `scheduledContent` - Scheduled items

## 🚀 **HOW TO USE**

1. **Upload Content:** Tap "Upload New Content"
2. **Control Radio:** Tap "Radio Admin"
3. **Manage Playlist:** Tap "Radio Flow"
4. **Add Messages:** Tap "Quick Ticker Message"
5. **Schedule:** Tap "Schedule Management"

## ⚠️ **IMPORTANT NOTES**

- The `main/DHradio.swift` file is for your main radio app
- This mainapp folder contains only the uploader/control app
- All files in mainapp are working and tested
- Remove the files listed in "FILES SAFE TO REMOVE" to clean up

---

**DreamHouse Radio** - Your 24/7 Vibe Station 🎵 