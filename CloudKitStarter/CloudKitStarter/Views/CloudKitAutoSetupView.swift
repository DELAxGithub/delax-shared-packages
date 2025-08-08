import SwiftUI

struct CloudKitAutoSetupView: View {
    @StateObject private var schemaManager = CloudKitSchemaManager()
    @Environment(\.dismiss) var dismiss
    @State private var showingInstructions = false
    @State private var setupStatus: SetupStatus = .notStarted
    
    enum SetupStatus {
        case notStarted
        case checking
        case ready
        case inProgress
        case success
        case failed
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // ヘッダー
                VStack(spacing: 10) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("CloudKit自動設定")
                        .font(.title)
                        .bold()
                    
                    Text("cktoolを使用してスキーマを自動設定します")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // ステータス表示
                VStack(spacing: 20) {
                    StatusRow(
                        title: "cktoolの確認",
                        status: schemaManager.checkCKToolInstallation()
                    )
                    
                    StatusRow(
                        title: "Management Tokenの確認",
                        status: schemaManager.checkManagementTokenConfiguration()
                    )
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // メッセージ表示
                if !schemaManager.statusMessage.isEmpty {
                    Text(schemaManager.statusMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if let error = schemaManager.errorMessage {
                    Text(error)
                        .font(.body)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // アクションボタン
                VStack(spacing: 15) {
                    #if os(macOS)
                    if schemaManager.checkCKToolInstallation() && schemaManager.checkManagementTokenConfiguration() {
                        Button(action: executeSetup) {
                            if schemaManager.isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("スキーマを設定")
                                    .bold()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(schemaManager.isProcessing)
                    }
                    #else
                    Text("自動設定はmacOSでのみ利用可能です")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    #endif
                    
                    Button(action: { showingInstructions = true }) {
                        Label("設定手順を表示", systemImage: "info.circle")
                    }
                    .foregroundColor(.accentColor)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingInstructions) {
                InstructionsView(instructions: schemaManager.getSetupInstructions())
            }
            .alert("設定完了", isPresented: .constant(setupStatus == .success)) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("CloudKitスキーマの設定が完了しました。アプリを再起動してください。")
            }
        }
    }
    
    private func executeSetup() {
        schemaManager.setupSchema { result in
            switch result {
            case .success:
                setupStatus = .success
            case .failure:
                setupStatus = .failed
            }
        }
    }
}

struct StatusRow: View {
    let title: String
    let status: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            Spacer()
            Image(systemName: status ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(status ? .green : .red)
        }
    }
}

struct InstructionsView: View {
    let instructions: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text(instructions)
                        .font(.body)
                        .padding()
                    
                    // ターミナルコマンドの例
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ターミナルでの実行例:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        CodeBlock(text: "cd /path/to/delaxcloudkit\n./setup_cloudkit.sh")
                    }
                    .padding(.vertical)
                    
                    // 追加の説明
                    VStack(alignment: .leading, spacing: 10) {
                        Text("注意事項:")
                            .font(.headline)
                        
                        Text("• Management Tokenは安全に保管してください")
                        Text("• トークンをGitにコミットしないでください")
                        Text("• .envファイルは.gitignoreに追加してください")
                    }
                    .padding()
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("設定手順")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CodeBlock: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(.body, design: .monospaced))
            .padding()
            .background(Color.black.opacity(0.8))
            .foregroundColor(.green)
            .cornerRadius(8)
            .padding(.horizontal)
    }
}