//
//  View+Extensions.swift
//  Myprojects
//
//  Created by Claude on 2025-08-01.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension View {
    /// カスタムカードスタイルを適用
    func cardStyle() -> some View {
        self
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    /// 条件付きでViewを表示
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// ハプティックフィードバック付きのタップ
    func hapticTap(action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            #if canImport(UIKit)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            #endif
            action()
        }
    }
    
    /// エラーハンドリング付きのアラート
    func errorAlert(error: Binding<Error?>) -> some View {
        self.alert("Error", isPresented: .constant(error.wrappedValue != nil)) {
            Button("OK") {
                error.wrappedValue = nil
            }
        } message: {
            if let error = error.wrappedValue {
                Text(error.localizedDescription)
            }
        }
    }
}