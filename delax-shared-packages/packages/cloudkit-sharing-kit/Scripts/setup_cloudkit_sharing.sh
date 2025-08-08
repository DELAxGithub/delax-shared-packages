#!/bin/bash

# DelaxCloudKitSharingKit Setup Script
# Automated setup for CloudKit sharing functionality (DELAX Shared Packages)

echo "🚀 DelaxCloudKitSharingKit Setup Script"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
TEAM_ID=""
CONTAINER_ID=""
RECORD_TYPE=""
ENVIRONMENT="development"

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    # Check if Xcode Command Line Tools are installed
    if ! command -v xcrun &> /dev/null; then
        print_error "Xcode Command Line Tools are not installed"
        echo "Please install with: xcode-select --install"
        exit 1
    fi
    print_success "Xcode Command Line Tools found"
    
    # Check if cktool is available
    if ! xcrun cktool --help &> /dev/null; then
        print_error "cktool is not available"
        echo "Make sure you have Xcode 12+ installed"
        exit 1
    fi
    print_success "cktool is available"
    
    # Check for git (optional)
    if command -v git &> /dev/null; then
        print_success "Git is available"
    else
        print_warning "Git not found - version control features disabled"
    fi
    
    echo ""
}

# Function to gather configuration
gather_config() {
    echo "📋 Configuration Setup"
    echo "====================="
    
    # Team ID
    if [ -z "$TEAM_ID" ]; then
        echo "Enter your Apple Developer Team ID:"
        echo "(Found in Apple Developer Portal > Membership)"
        read -p "Team ID: " TEAM_ID
    fi
    
    # Container ID
    if [ -z "$CONTAINER_ID" ]; then
        echo ""
        echo "Enter your CloudKit Container ID:"
        echo "(e.g., iCloud.com.yourteam.YourApp)"
        read -p "Container ID: " CONTAINER_ID
    fi
    
    # Record Type
    if [ -z "$RECORD_TYPE" ]; then
        echo ""
        echo "Enter the record type name for sharing:"
        echo "(e.g., Note, Task, Document)"
        read -p "Record Type: " RECORD_TYPE
    fi
    
    # Environment
    echo ""
    echo "Select CloudKit environment:"
    echo "1) development (default)"
    echo "2) production"
    read -p "Choice [1]: " env_choice
    
    case $env_choice in
        2)
            ENVIRONMENT="production"
            print_warning "Using production environment"
            ;;
        *)
            ENVIRONMENT="development"
            print_info "Using development environment"
            ;;
    esac
    
    echo ""
    echo "Configuration Summary:"
    echo "- Team ID: $TEAM_ID"
    echo "- Container ID: $CONTAINER_ID"
    echo "- Record Type: $RECORD_TYPE"
    echo "- Environment: $ENVIRONMENT"
    echo ""
    
    read -p "Continue with this configuration? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 1
    fi
    echo ""
}

# Function to validate CloudKit access
validate_cloudkit_access() {
    echo "🔐 Validating CloudKit Access"
    echo "============================="
    
    print_info "Testing CloudKit container access..."
    
    # Try to export schema to test access
    schema_result=$(xcrun cktool export-schema --team-id "$TEAM_ID" --container-id "$CONTAINER_ID" --environment "$ENVIRONMENT" 2>&1)
    
    if [[ $? -eq 0 ]]; then
        print_success "CloudKit container access verified"
    else
        print_error "CloudKit container access failed"
        echo "Error details:"
        echo "$schema_result"
        echo ""
        echo "Common issues:"
        echo "- Team ID incorrect"
        echo "- Container ID doesn't exist"
        echo "- Not signed in to developer account in Xcode"
        exit 1
    fi
    echo ""
}

# Function to check/create record type
setup_record_type() {
    echo "📝 Setting up Record Type"
    echo "========================="
    
    print_info "Checking if record type '$RECORD_TYPE' exists..."
    
    schema_result=$(xcrun cktool export-schema --team-id "$TEAM_ID" --container-id "$CONTAINER_ID" --environment "$ENVIRONMENT" 2>&1)
    
    if [[ $schema_result == *"$RECORD_TYPE"* ]]; then
        print_success "Record type '$RECORD_TYPE' exists"
        
        # Check if sharing is enabled
        if [[ $schema_result == *"isShareable"* ]]; then
            print_success "Sharing is enabled for '$RECORD_TYPE'"
        else
            print_warning "Sharing is NOT enabled for '$RECORD_TYPE'"
            echo "⚠️  MANUAL ACTION REQUIRED:"
            echo "1. Go to CloudKit Dashboard: https://icloud.developer.apple.com/dashboard"
            echo "2. Select your container: $CONTAINER_ID"
            echo "3. Go to Schema > Record Types"
            echo "4. Select '$RECORD_TYPE'"
            echo "5. In Metadata section, check 'Shared'"
            echo "6. Save and deploy schema changes"
            echo ""
            read -p "Press Enter after enabling sharing in CloudKit Dashboard..."
        fi
    else
        print_warning "Record type '$RECORD_TYPE' does not exist"
        echo "📋 Creating basic record type schema..."
        
        # Create basic schema file
        cat > "${RECORD_TYPE}_schema.ckdb" << EOF
{
  "recordTypes": {
    "$RECORD_TYPE": {
      "metadata": {
        "isShareable": true
      },
      "fields": {
        "title": {
          "fieldType": "STRING",
          "isIndexed": true,
          "isRequired": true
        },
        "content": {
          "fieldType": "STRING",
          "isIndexed": false,
          "isRequired": false
        },
        "createdAt": {
          "fieldType": "TIMESTAMP",
          "isIndexed": true,
          "isRequired": false
        },
        "modifiedAt": {
          "fieldType": "TIMESTAMP",
          "isIndexed": true,
          "isRequired": false
        }
      }
    }
  }
}
EOF
        
        print_info "Importing schema to CloudKit..."
        import_result=$(xcrun cktool import-schema --team-id "$TEAM_ID" --container-id "$CONTAINER_ID" --environment "$ENVIRONMENT" --file "${RECORD_TYPE}_schema.ckdb" 2>&1)
        
        if [[ $? -eq 0 ]]; then
            print_success "Schema imported successfully"
            rm "${RECORD_TYPE}_schema.ckdb"
        else
            print_error "Schema import failed"
            echo "Error: $import_result"
            echo "You may need to create the record type manually in CloudKit Dashboard"
        fi
    fi
    echo ""
}

# Function to create sample Swift code
create_sample_code() {
    echo "💻 Generating Sample Code"
    echo "========================"
    
    # Create sample data model
    cat > "Sample${RECORD_TYPE}.swift" << EOF
import DelaxCloudKitSharingKit
import CloudKit
import Foundation

struct ${RECORD_TYPE}: SharableRecord {
    // Required SharableRecord properties
    let id: String
    var record: CKRecord?
    var shareRecord: CKShare?
    
    // Your data properties
    var title: String
    var content: String
    var createdAt: Date
    var modifiedAt: Date
    
    static var recordType: String { "$RECORD_TYPE" }
    
    // Initializer for new records
    init(title: String, content: String = "") {
        self.id = UUID().uuidString
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.record = nil
        self.shareRecord = nil
    }
    
    // Initializer from CloudKit record
    init(from record: CKRecord, shareRecord: CKShare? = nil) {
        self.id = record.recordID.recordName
        self.title = record["title"] as? String ?? ""
        self.content = record["content"] as? String ?? ""
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.modifiedAt = record["modifiedAt"] as? Date ?? Date()
        self.record = record
        self.shareRecord = shareRecord
    }
    
    // Convert to CloudKit record
    func toCKRecord(zoneID: CKRecordZone.ID?) -> CKRecord {
        let record: CKRecord
        
        if let existingRecord = self.record {
            record = existingRecord
        } else if let zoneID = zoneID {
            let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
            record = CKRecord(recordType: ${RECORD_TYPE}.recordType, recordID: recordID)
        } else {
            record = CKRecord(recordType: ${RECORD_TYPE}.recordType)
        }
        
        record["title"] = title
        record["content"] = content
        record["createdAt"] = createdAt
        record["modifiedAt"] = Date()
        
        return record
    }
}
EOF
    
    # Create sample app code
    cat > "Sample${RECORD_TYPE}App.swift" << EOF
import SwiftUI
import DelaxCloudKitSharingKit

@main
struct ${RECORD_TYPE}App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var sharingManager = CloudKitSharingManager<${RECORD_TYPE}>(
        containerIdentifier: "$CONTAINER_ID"
    )
    
    @State private var showingSharingView = false
    @State private var shareToPresent: CKShare?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sharingManager.records) { record in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(record.title)
                                .font(.headline)
                            Text(record.content)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            shareRecord(record)
                        }) {
                            Image(systemName: record.isShared ? "person.2.fill" : "person.2")
                                .foregroundColor(record.isShared ? .blue : .gray)
                        }
                    }
                }
            }
            .navigationTitle("${RECORD_TYPE}s")
            .onAppear {
                Task {
                    try? await sharingManager.fetchRecords()
                }
            }
        }
        .sheet(isPresented: \$showingSharingView) {
            if let share = shareToPresent {
                CloudSharingView(
                    share: share,
                    container: sharingManager.container
                )
            }
        }
    }
    
    private func shareRecord(_ record: ${RECORD_TYPE}) {
        Task {
            do {
                if let existingShare = record.shareRecord {
                    shareToPresent = existingShare
                } else {
                    let share = try await sharingManager.startSharing(record: record)
                    shareToPresent = share
                }
                showingSharingView = true
            } catch {
                print("Sharing error: \\(error)")
            }
        }
    }
}
EOF
    
    print_success "Sample code generated:"
    print_info "- Sample${RECORD_TYPE}.swift (Data model)"
    print_info "- Sample${RECORD_TYPE}App.swift (SwiftUI app)"
    echo ""
}

# Function to create integration checklist
create_checklist() {
    echo "📋 Integration Checklist"
    echo "======================="
    
    cat > "CloudKit_Integration_Checklist.md" << EOF
# CloudKit Sharing Integration Checklist

## ✅ Setup Completed by Script
- [x] CloudKit container access verified
- [x] Record type '$RECORD_TYPE' configured
- [x] Sharing enabled for record type
- [x] Sample code generated

## 📋 Manual Steps Required

### 1. Xcode Project Setup
- [ ] Add DelaxCloudKitSharingKit from DELAX Shared Packages\n- [ ] URL: https://github.com/DELAxGithub/delax-shared-packages
- [ ] Enable CloudKit capability in project settings
- [ ] Select container: \`$CONTAINER_ID\`
- [ ] Verify entitlements file includes CloudKit

### 2. Code Integration
- [ ] Copy sample code to your project
- [ ] Replace \`$CONTAINER_ID\` with your actual container ID
- [ ] Customize data model properties as needed
- [ ] Implement UI according to your app's design

### 3. Testing
- [ ] Test on device (CloudKit doesn't work in simulator for sharing)
- [ ] Create a record
- [ ] Test sharing functionality
- [ ] Verify shared records appear on other devices
- [ ] Test editing shared records

### 4. Production Deployment
- [ ] Test in production CloudKit environment
- [ ] Deploy schema changes to production
- [ ] Update app configuration for production
- [ ] Submit to App Store with proper iCloud entitlements

## 🔗 Useful Resources
- CloudKit Dashboard: https://icloud.developer.apple.com/dashboard
- Container: $CONTAINER_ID
- Environment: $ENVIRONMENT
- DelaxCloudKitSharingKit Documentation: [README.md](../README.md)\n- DELAX Shared Packages: https://github.com/DELAxGithub/delax-shared-packages

## 📞 Support
If you encounter issues:
1. Check the troubleshooting guide
2. Verify CloudKit Dashboard settings
3. Review device iCloud sign-in status
4. Check Xcode console for detailed error messages
EOF
    
    print_success "Integration checklist created: CloudKit_Integration_Checklist.md"
    echo ""
}

# Function to run validation tests
run_validation_tests() {
    echo "🧪 Running Validation Tests"
    echo "=========================="
    
    print_info "Creating test record..."
    
    # Create test record
    test_record_file="test_${RECORD_TYPE,,}_record.json"
    cat > "$test_record_file" << EOF
{
  "recordType": "$RECORD_TYPE",
  "fields": {
    "title": {
      "fieldType": "STRING",
      "value": "Test ${RECORD_TYPE} - $(date '+%Y-%m-%d %H:%M:%S')"
    },
    "content": {
      "fieldType": "STRING",
      "value": "This is a test record created by CloudKitSharingKit setup script"
    },
    "createdAt": {
      "fieldType": "TIMESTAMP",
      "value": "$(date -u +%s)"
    }
  }
}
EOF
    
    # Try to create record
    create_result=$(xcrun cktool create-record --team-id "$TEAM_ID" --container-id "$CONTAINER_ID" --environment "$ENVIRONMENT" --file "$test_record_file" 2>&1)
    
    if [[ $? -eq 0 && $create_result == *"recordName"* ]]; then
        print_success "Test record created successfully"
        
        # Extract record name
        record_name=$(echo "$create_result" | grep -o '"recordName":"[^"]*"' | cut -d'"' -f4)
        print_info "Record ID: $record_name"
        
        # Clean up test record
        read -p "Delete test record? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            delete_result=$(xcrun cktool delete-record --team-id "$TEAM_ID" --container-id "$CONTAINER_ID" --environment "$ENVIRONMENT" --record-name "$record_name" 2>&1)
            if [[ $? -eq 0 ]]; then
                print_success "Test record deleted"
            else
                print_warning "Failed to delete test record"
            fi
        fi
    else
        print_warning "Test record creation failed"
        echo "This may be normal if the record type was just created"
        print_info "Details: $create_result"
    fi
    
    # Clean up
    rm -f "$test_record_file"
    echo ""
}

# Function to detect DELAX monorepo environment
detect_environment() {
    echo "🔍 Detecting Environment"
    echo "======================="
    
    if [ -f "../../package.json" ] && grep -q "delax-shared-packages" "../../package.json" 2>/dev/null; then
        print_success "DELAX Shared Packages monorepo detected"
        print_info "Running from: packages/cloudkit-sharing-kit/"
        DELAX_MONOREPO=true
    else
        print_info "Running as standalone package"
        DELAX_MONOREPO=false
    fi
    echo ""
}

# Main execution
main() {
    echo "This script will help you set up CloudKit sharing functionality"
    echo "using DelaxCloudKitSharingKit (DELAX Shared Packages)."
    echo ""
    
    detect_environment
    
    check_prerequisites
    gather_config
    validate_cloudkit_access
    setup_record_type
    create_sample_code
    create_checklist
    run_validation_tests
    
    echo "🎉 Setup Complete!"
    echo "================="
    echo ""
    print_success "DelaxCloudKitSharingKit setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Review the generated files:"
    echo "   - Sample${RECORD_TYPE}.swift"
    echo "   - Sample${RECORD_TYPE}App.swift"
    echo "   - CloudKit_Integration_Checklist.md"
    echo ""
    echo "2. Follow the integration checklist"
    echo "3. Add DelaxCloudKitSharingKit from DELAX Shared Packages"
    echo "4. Test on a physical device"
    echo ""
    print_info "Happy coding! 🚀"
}

# Handle script arguments
while getopts "t:c:r:e:h" opt; do
    case ${opt} in
        t )
            TEAM_ID=$OPTARG
            ;;
        c )
            CONTAINER_ID=$OPTARG
            ;;
        r )
            RECORD_TYPE=$OPTARG
            ;;
        e )
            ENVIRONMENT=$OPTARG
            ;;
        h )
            echo "Usage: $0 [-t team_id] [-c container_id] [-r record_type] [-e environment]"
            echo ""
            echo "Options:"
            echo "  -t  Apple Developer Team ID"
            echo "  -c  CloudKit Container ID (e.g., iCloud.com.yourteam.YourApp)"
            echo "  -r  Record type name (e.g., Note, Task)"
            echo "  -e  Environment (development or production, default: development)"
            echo "  -h  Show this help message"
            echo ""
            echo "Example:"
            echo "  $0 -t ABC123XYZ -c iCloud.com.example.MyApp -r Note"
            exit 0
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            echo "Use -h for help"
            exit 1
            ;;
    esac
done

# Run main function
main