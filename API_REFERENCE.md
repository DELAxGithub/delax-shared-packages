# CloudKitStarter API Reference

## Overview

Complete API reference for the CloudKitStarter iOS application, covering models, services, views, and CloudKit integration patterns.

## Models

### Note

Primary data model representing a user's note with CloudKit synchronization.

```swift
struct Note: Identifiable, Hashable {
    let id: String
    var title: String
    var content: String
    var createdAt: Date
    var modifiedAt: Date
    var isFavorite: Bool
    var record: CKRecord?
}
```

#### Initializers

```swift
// Standard initializer
init(id: String = UUID().uuidString, 
     title: String, 
     content: String = "", 
     createdAt: Date = Date(), 
     modifiedAt: Date = Date(), 
     isFavorite: Bool = false)

// CloudKit record initializer  
init(from record: CKRecord)
```

#### Methods

```swift
func toCKRecord() -> CKRecord
```
Converts the Note instance to a CloudKit CKRecord for storage.

**Returns**: CKRecord configured with note data and proper field types.

#### CloudKit Field Mapping

| Note Property | CloudKit Field | Type | Queryable | Sortable |
|---------------|----------------|------|-----------|----------|
| `title` | "title" | STRING | ✅ | ✅ |
| `content` | "content" | STRING | ✅ | ❌ |
| `createdAt` | "createdAt" | TIMESTAMP | ✅ | ✅ |
| `modifiedAt` | "modifiedAt" | TIMESTAMP | ✅ | ✅ |
| `isFavorite` | "isFavorite" | INT64 | ✅ | ✅ |

## Services

### CloudKitManagerAlternative

Primary service class providing CloudKit operations without using CKQuery to avoid system field limitations.

```swift
class CloudKitManagerAlternative: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading: Bool = false  
    @Published var errorMessage: String?
}
```

#### Methods

##### loadNotes()
```swift
func loadNotes()
```
Loads all user notes from CloudKit using stored record IDs.

**Behavior**: 
- Retrieves record IDs from UserDefaults
- Fetches records individually using `fetch(withRecordIDs:)`
- Sorts notes with favorites first, then by modification date
- Updates `@Published` properties for SwiftUI binding

##### saveNote(_:)
```swift
func saveNote(_ note: Note)
```
Saves a note to CloudKit and updates local storage.

**Parameters**:
- `note`: Note instance to save

**Behavior**:
- Converts Note to CKRecord using `toCKRecord()`
- Saves to CloudKit private database
- Stores record ID in UserDefaults for future retrieval
- Updates local notes array

##### deleteNote(_:)
```swift
func deleteNote(_ note: Note)
```
Deletes a note from CloudKit and local storage.

**Parameters**:
- `note`: Note instance to delete

**Behavior**:
- Removes record from CloudKit
- Removes record ID from UserDefaults
- Updates local notes array

##### toggleFavorite(_:)
```swift
func toggleFavorite(_ note: Note)
```
Toggles the favorite status of a note.

**Parameters**:
- `note`: Note instance to toggle

**Behavior**:
- Updates `isFavorite` property
- Saves changes to CloudKit
- Re-sorts notes array to reflect new favorite status

#### Error Handling

The service provides comprehensive error handling for common CloudKit scenarios:

- **Network Errors**: Automatic retry with user feedback
- **Authentication Errors**: Guides user to iCloud settings
- **Quota Exceeded**: Displays storage limit information
- **Unknown Items**: Triggers schema setup guidance

### CloudKitSchemaManager (macOS only)

Manages CloudKit schema operations using cktool integration.

```swift
class CloudKitSchemaManager {
    static let shared = CloudKitSchemaManager()
}
```

#### Methods

##### importSchema()
```swift
func importSchema() -> SchemaImportResult
```
Imports CloudKit schema from bundled JSON file.

**Returns**: `SchemaImportResult` enum indicating success/failure

##### exportSchema()
```swift
func exportSchema() -> String?
```
Exports current CloudKit schema as JSON string.

**Returns**: JSON schema string or nil on failure

##### saveToken(_:)
```swift
func saveToken(_ token: String) -> Bool
```
Saves CloudKit Management Token for cktool operations.

**Parameters**:
- `token`: Management token from Apple Developer portal

**Returns**: Boolean indicating save success

## Views

### NoteListViewAlternative

Primary interface displaying user notes with comprehensive functionality.

```swift
struct NoteListViewAlternative: View {
    @StateObject private var cloudKitManager = CloudKitManagerAlternative()
    @State private var showingCreateNote = false
}
```

#### Key Features

- **Pull-to-refresh** functionality
- **Favorites-first sorting** with visual indicators  
- **Empty state handling** with guidance messaging
- **Error display** with retry mechanisms
- **Navigation integration** with create/edit views

#### State Management

```swift
@StateObject private var cloudKitManager: CloudKitManagerAlternative
@State private var showingCreateNote: Bool
```

### CreateNoteView

Interface for creating new notes with real-time validation.

```swift
struct CreateNoteView: View {
    @Binding var isPresented: Bool
    let cloudKitManager: CloudKitManagerAlternative
    @State private var title: String = ""
    @State private var content: String = ""
}
```

#### Features

- **Real-time text editing** with TextEditor
- **Input validation** for title requirements
- **Automatic save** on navigation
- **Keyboard management** for optimal UX

### EditNoteView

Interface for editing existing notes with timestamp display.

```swift
struct EditNoteView: View {
    @Binding var note: Note
    let cloudKitManager: CloudKitManagerAlternative
    @State private var title: String
    @State private var content: String
}
```

#### Features

- **In-place editing** with immediate feedback
- **Timestamp display** for creation/modification dates
- **Automatic save** on content changes  
- **Navigation integration** with proper dismissal

### CloudKitSetupGuideView

Comprehensive setup guidance for CloudKit configuration.

```swift
struct CloudKitSetupGuideView: View {
    let cloudKitManager: CloudKitManagerAlternative
}
```

#### Features

- **Step-by-step instructions** for manual setup
- **Automated setup integration** (macOS only)
- **Interactive validation** of setup progress
- **External link handling** for CloudKit Dashboard

## CloudKit Integration Patterns

### Record Management

#### Avoiding Query Limitations
The alternative implementation uses record ID-based fetching instead of CKQuery to avoid "recordName not queryable" errors:

```swift
// Instead of CKQuery
let recordIDs = getStoredRecordIDs()
database.fetch(withRecordIDs: recordIDs) { result in
    // Handle individual records
}
```

#### Record ID Persistence
Record IDs are stored in UserDefaults for session persistence:

```swift
private func storeRecordID(_ recordID: CKRecord.ID) {
    var storedIDs = UserDefaults.standard.stringArray(forKey: "NoteRecordIDs") ?? []
    let recordName = recordID.recordName
    if !storedIDs.contains(recordName) {
        storedIDs.append(recordName)
        UserDefaults.standard.set(storedIDs, forKey: "NoteRecordIDs")
    }
}
```

### Error Handling Strategies

#### Comprehensive Error Mapping
```swift
private func handleCloudKitError(_ error: Error) -> String {
    if let ckError = error as? CKError {
        switch ckError.code {
        case .notAuthenticated:
            return "iCloudにサインインしてください"
        case .networkUnavailable, .networkFailure:
            return "ネットワーク接続を確認してください"
        case .quotaExceeded:
            return "iCloudストレージの容量が不足しています"
        case .unknownItem:
            return "CloudKitの設定が必要です"
        default:
            return "CloudKitエラー: \\(ckError.localizedDescription)"
        }
    }
    return error.localizedDescription
}
```

### Data Synchronization

#### Automatic Timestamp Management
```swift
func toCKRecord() -> CKRecord {
    let record = self.record ?? CKRecord(recordType: "Note")
    record["title"] = title
    record["content"] = content
    record["createdAt"] = createdAt
    record["modifiedAt"] = Date() // Always update modification time
    record["isFavorite"] = isFavorite ? 1 : 0
    return record
}
```

## Platform Considerations

### iOS vs macOS Differences

#### Conditional Compilation
```swift
#if os(macOS)
// cktool Process integration
func runCKTool() -> String? {
    let process = Process()
    // ... process configuration
}
#else
// iOS fallback
func runCKTool() -> String? {
    return nil // cktool not available on iOS
}
#endif
```

#### API Version Compatibility
```swift
// iOS 17+ onChange API
if #available(iOS 17.0, *) {
    .onChange(of: searchText) { oldValue, newValue in
        // New closure syntax
    }
} else {
    .onChange(of: searchText) { newValue in
        // Legacy syntax
    }
}
```

## Testing Utilities

### CloudKit Testing Helpers

#### Record Validation
```swift
extension Note {
    var isValidForCloudKit: Bool {
        return !title.isEmpty && 
               title.count <= 1000 &&
               content.count <= 10000
    }
}
```

#### Mock Data Generation
```swift
extension Note {
    static var mockData: [Note] {
        return [
            Note(title: "Sample Note", content: "This is a test note"),
            Note(title: "Favorite Note", content: "This note is marked as favorite", isFavorite: true)
        ]
    }
}
```

---

*This API reference covers all public interfaces and integration patterns in the CloudKitStarter project. For implementation details and usage examples, refer to the source code and project documentation.*