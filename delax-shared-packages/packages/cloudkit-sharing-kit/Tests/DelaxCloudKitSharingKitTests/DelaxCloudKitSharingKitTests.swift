import XCTest
@testable import DelaxCloudKitSharingKit
import CloudKit

final class DelaxCloudKitSharingKitTests: XCTestCase {
    
    // MARK: - SharableRecord Protocol Tests
    
    func testSharableRecordProtocolDefaultImplementations() {
        let mockRecord = MockSharableRecord()
        
        // Test default isShared implementation
        XCTAssertFalse(mockRecord.isShared)
        
        // Test with shareRecord
        var recordWithShare = MockSharableRecord()
        recordWithShare.shareRecord = CKShare(rootRecord: CKRecord(recordType: "Test"))
        XCTAssertTrue(recordWithShare.isShared)
    }
    
    // MARK: - DelaxCloudKitSharingKitInfo Tests
    
    func testPackageInfo() {
        XCTAssertEqual(DelaxCloudKitSharingKitInfo.version, "1.0.0")
        XCTAssertEqual(DelaxCloudKitSharingKitInfo.minimumIOSVersion, "16.0")
        XCTAssertEqual(DelaxCloudKitSharingKitInfo.author, "DELAX - Claude Code")
        XCTAssertEqual(DelaxCloudKitSharingKitInfo.license, "MIT")
        XCTAssertEqual(DelaxCloudKitSharingKitInfo.repositoryURL, "https://github.com/DELAxGithub/delax-shared-packages")
    }
    
    // MARK: - CloudKitSharingManager Tests
    
    func testCloudKitSharingManagerInitialization() {
        let manager = CloudKitSharingManager<MockSharableRecord>(
            containerIdentifier: "iCloud.com.test.TestApp"
        )
        
        XCTAssertNotNil(manager.container)
        XCTAssertEqual(manager.container.containerIdentifier, "iCloud.com.test.TestApp")
        XCTAssertTrue(manager.records.isEmpty)
    }
    
    // MARK: - CloudKitSharingError Tests
    
    func testCloudKitSharingErrorCases() {
        let errors: [CloudKitSharingError] = [
            .invalidRecord,
            .sharingNotSupported,
            .alreadyShared,
            .shareNotFound,
            .customZoneNotFound,
            .operationFailed(NSError(domain: "test", code: 1, userInfo: nil))
        ]
        
        for error in errors {
            XCTAssertNotNil(error.localizedDescription)
        }
    }
    
    // MARK: - Performance Tests
    
    func testSharableRecordPerformance() {
        let records = (0..<1000).map { _ in MockSharableRecord() }
        
        measure {
            for record in records {
                _ = record.isShared
                _ = record.toCKRecord(zoneID: nil)
            }
        }
    }
}

// MARK: - Mock Types for Testing

struct MockSharableRecord: SharableRecord, Identifiable {
    let id = UUID().uuidString
    var record: CKRecord?
    var shareRecord: CKShare?
    
    static var recordType: String { "MockRecord" }
    
    var title: String = "Test Record"
    var content: String = "Test Content"
    
    init() {}
    
    init(from record: CKRecord, shareRecord: CKShare? = nil) {
        self.record = record
        self.shareRecord = shareRecord
        self.title = record["title"] as? String ?? "Test Record"
        self.content = record["content"] as? String ?? "Test Content"
    }
    
    func toCKRecord(zoneID: CKRecordZone.ID?) -> CKRecord {
        let record: CKRecord
        
        if let existingRecord = self.record {
            record = existingRecord
        } else if let zoneID = zoneID {
            let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
            record = CKRecord(recordType: MockSharableRecord.recordType, recordID: recordID)
        } else {
            record = CKRecord(recordType: MockSharableRecord.recordType)
        }
        
        record["title"] = title
        record["content"] = content
        
        return record
    }
}