# CloudKitStarter Quick Start Guide

## 🚀 Getting Started in 5 Minutes

This guide will get you up and running with CloudKitStarter, a SwiftUI-based notes app with CloudKit integration.

## Prerequisites

- Xcode 15.0+ installed
- Apple Developer account (free tier works)
- iOS device or simulator running iOS 18.5+
- Active iCloud account

## Step 1: Clone and Open Project

```bash
# Clone the repository
git clone https://github.com/DELAxGithub/delaxcloudkit.git
cd delaxcloudkit

# Open in Xcode
open CloudKitStarter/CloudKitStarter.xcodeproj
```

## Step 2: Configure CloudKit (Choose One Method)

### Method A: Manual Setup (Recommended for First-Time Users)

1. **Open CloudKit Dashboard**
   - Visit [icloud.developer.apple.com/dashboard](https://icloud.developer.apple.com/dashboard)
   - Sign in with your Apple Developer account
   - Select your team ID: `Z88477N5ZU`

2. **Create Container**
   - If "iCloud.Delax.CloudKitStarter" doesn't exist, it will be created automatically when you first build the app

3. **Create Record Type**
   - Go to Schema → Record Types
   - Click "+" to add new record type
   - Name: `Note`

4. **Add Fields to Note Record Type**
   ```
   Field Name: title
   Type: String
   ✅ Queryable
   ✅ Sortable
   
   Field Name: content  
   Type: String
   ✅ Queryable
   ❌ Sortable
   
   Field Name: isFavorite
   Type: Int(64)
   ✅ Queryable
   ✅ Sortable
   ```

5. **Deploy to Production** (Optional)
   - Click "Deploy Schema Changes"
   - Deploy to Production Database

### Method B: Automated Setup (macOS Only)

```bash
# Get Management Token from Apple Developer Portal
export CLOUDKIT_MANAGEMENT_TOKEN="your_token_here"

# Run automated setup
./setup_cloudkit.sh
```

## Step 3: Build and Run

1. **Select Target**
   - In Xcode, select an iOS simulator (iPhone 15 recommended)
   - Or connect a physical iOS device

2. **Build Project**
   ```bash
   # Command line (optional)
   xcodebuild -project CloudKitStarter/CloudKitStarter.xcodeproj \
              -scheme CloudKitStarter \
              -configuration Debug build
   ```

3. **Run App**
   - Press `Cmd+R` in Xcode
   - Or click the Run button

## Step 4: Test Basic Functionality

### First Launch
1. **Sign into iCloud** (if prompted)
   - Go to iOS Settings → [Your Name] → iCloud
   - Ensure iCloud Drive is enabled

2. **Create Your First Note**
   - Tap the "+" button in the app
   - Enter a title: "My First Note"
   - Add some content: "This is a test of CloudKit integration"
   - Tap "Save"

3. **Verify CloudKit Sync**
   - Force close the app
   - Reopen - your note should still be there
   - Check CloudKit Dashboard → Data → Default Zone → Note records

### Test Advanced Features
1. **Favorites**
   - Tap the heart icon next to any note
   - Favorite notes appear at the top of the list

2. **Editing**
   - Tap on any note to edit
   - Changes save automatically

3. **Multi-line Content**
   - Create a note with multiple paragraphs
   - TextEditor supports rich text input

## Troubleshooting

### Common Issues

#### "CloudKit Error: Field 'recordName' is not marked queryable"
✅ **Solved**: This app uses an alternative implementation that avoids this error.

#### "Not authenticated" Error
**Solution**: Sign into iCloud on your device
- Settings → [Your Name] → Sign In
- Ensure iCloud Drive is enabled

#### Empty Note List
**Causes**:
- CloudKit schema not set up → Follow Step 2 above
- iCloud not signed in → Sign into iCloud
- Network connection issues → Check internet connectivity

**Quick Test**:
```bash
# Test CloudKit connectivity (macOS only)
xcrun cktool list --team-id "Z88477N5ZU" \
                  --container-id "iCloud.Delax.CloudKitStarter" \
                  --environment "development" \
                  --record-type "Note"
```

#### Build Errors
1. **"Process not available"**: This is expected on iOS (feature is macOS-only)
2. **Missing entitlements**: Ensure `CloudKitStarter.entitlements` is properly configured
3. **Team ID mismatch**: Update team ID in project settings if using different developer account

## Key Files to Understand

### Essential Code Files
```
CloudKitStarter/
├── Models/Note.swift                    # Core data model
├── Services/CloudKitManagerAlternative.swift  # CloudKit operations
├── Views/NoteListViewAlternative.swift  # Main interface
├── ContentView.swift                    # App entry point
└── Resources/schema.json                # CloudKit schema
```

### Configuration Files
- `CloudKitStarter.entitlements` - CloudKit capabilities
- `CLAUDE.md` - Build commands and architecture notes
- `progress.md` - Detailed development journey

## Next Steps

### Explore Features
1. **Create Multiple Notes** - Test the list interface
2. **Toggle Favorites** - See sorting behavior
3. **Edit Existing Notes** - Test the editing interface
4. **Force Quit and Reopen** - Verify CloudKit persistence

### Customize the App
1. **Modify Note Model** - Add new fields (see `Note.swift`)
2. **Update CloudKit Schema** - Add corresponding fields in Dashboard
3. **Enhance UI** - Customize views in the `Views/` folder
4. **Add Features** - Images, tags, search functionality

### Learn More
- Read `PROJECT_INDEX.md` for comprehensive documentation
- Check `API_REFERENCE.md` for detailed API information  
- Review `progress.md` for development insights and lessons learned

## Performance Notes

### What's Optimized
- **Query-Free Implementation**: Avoids CloudKit system field limitations
- **Local Caching**: Uses UserDefaults for record ID persistence
- **Automatic Sorting**: Favorites first, then by modification date
- **Error Recovery**: Comprehensive error handling with user guidance

### Production Considerations
- Current implementation optimized for personal note-taking (< 1000 notes)
- For larger datasets, consider implementing CKQuery with proper field indexing
- Add Core Data layer for complex local data management
- Implement CloudKit subscriptions for real-time multi-device sync

---

**🎉 Congratulations!** You now have a fully functional CloudKit-integrated notes app. The app demonstrates best practices for iOS development, CloudKit integration, and error handling.

For advanced usage and customization, explore the comprehensive documentation and source code.