import SwiftUI
import DelaxCloudKitSharingKit

@main
struct SimpleNoteApp: App {
    // ⚠️ このContainer IDを実際のものに変更してください
    // DELAX Shared Packages統合版
    @StateObject private var sharingManager = CloudKitSharingManager<Note>(
        containerIdentifier: "iCloud.com.yourteam.SimpleNoteApp"
    )
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharingManager)
        }
    }
}