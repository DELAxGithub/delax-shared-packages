//
//  ContentView.swift
//  CloudKitStarter
//
//  Created by Hiroshi Kodera on 2025-07-26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // 代替実装を使用（クエリを回避）
        NoteListViewAlternative()
        
        // 通常の実装を使う場合は以下のコメントを解除
        // NoteListView()
    }
}

#Preview {
    ContentView()
}
