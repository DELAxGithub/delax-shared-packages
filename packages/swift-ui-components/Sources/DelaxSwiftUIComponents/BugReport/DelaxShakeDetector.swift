import SwiftUI

#if os(iOS)
import UIKit
#endif

// MARK: - Shake Detection Extension

#if os(iOS)
public extension UIWindow {
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: DelaxShakeDetector.deviceDidShakeNotification, object: nil)
        }
    }
}
#endif

// MARK: - Shake Detector

public class DelaxShakeDetector: ObservableObject {
    public static let deviceDidShakeNotification = Notification.Name("DelaxDeviceDidShakeNotification")
    
    @Published public var isShakeDetected = false
    
    private var cancellable: Any?
    
    public init() {
        setupShakeDetection()
    }
    
    deinit {
        if let cancellable = cancellable {
            NotificationCenter.default.removeObserver(cancellable)
        }
    }
    
    private func setupShakeDetection() {
        #if os(iOS)
        cancellable = NotificationCenter.default.addObserver(
            forName: DelaxShakeDetector.deviceDidShakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleShake()
        }
        #endif
    }
    
    private func handleShake() {
        DispatchQueue.main.async {
            self.isShakeDetected = true
            
            // Auto-trigger bug report
            DelaxBugReportManager.shared.showBugReportView()
            
            // Reset after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isShakeDetected = false
            }
        }
    }
}

// MARK: - View Modifier

public struct DelaxShakeDetectorModifier: ViewModifier {
    @StateObject private var shakeDetector = DelaxShakeDetector()
    @State private var showBugReport = false
    
    public func body(content: Content) -> some View {
        content
            .onChange(of: shakeDetector.isShakeDetected) { isDetected in
                if isDetected {
                    showBugReport = true
                }
            }
            .sheet(isPresented: $showBugReport) {
                DelaxBugReportView(
                    currentView: "Unknown",
                    preCapuredScreenshot: captureCurrentScreenshot()
                )
            }
    }
    
    private func captureCurrentScreenshot() -> Data? {
        #if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return nil }
        
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { context in
            window.layer.render(in: context.cgContext)
        }
        
        return image.jpegData(compressionQuality: 0.8)
        #else
        return nil
        #endif
    }
}

public extension View {
    /// Adds shake detection to trigger bug reporting
    /// - Returns: View with shake detection capability
    func onShake() -> some View {
        modifier(DelaxShakeDetectorModifier())
    }
}

// MARK: - Manual Shake Trigger (for testing)

public extension DelaxShakeDetector {
    /// Manually trigger shake detection (useful for testing)
    func triggerShake() {
        handleShake()
    }
}