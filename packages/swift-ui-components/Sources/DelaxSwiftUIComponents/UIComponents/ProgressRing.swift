//
//  ProgressRing.swift
//  Myprojects
//
//  Created by Claude on 2025-08-01.
//

import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressRing(progress: 0.3, size: 32)
        ProgressRing(progress: 0.7, size: 48)
        ProgressRing(progress: 1.0, size: 64)
    }
    .padding()
}