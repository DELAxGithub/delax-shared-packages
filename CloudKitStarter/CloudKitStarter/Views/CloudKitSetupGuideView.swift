import SwiftUI

struct CloudKitSetupGuideView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    @State private var showingAutoSetup = false
    
    let steps = [
        SetupStep(
            title: "CloudKit Dashboardにアクセス",
            description: "SafariでCloudKit Dashboardを開きます",
            action: "https://icloud.developer.apple.com/dashboard",
            imageName: "icloud.circle"
        ),
        SetupStep(
            title: "コンテナを選択",
            description: "「Delax.CloudKitStarter」を選択してください",
            action: nil,
            imageName: "folder.circle"
        ),
        SetupStep(
            title: "レコードタイプを作成",
            description: "Schema > Record Types > 「+」ボタンで「Note」を作成",
            action: nil,
            imageName: "plus.circle"
        ),
        SetupStep(
            title: "フィールドを追加",
            description: "以下のフィールドを追加してください：\n• title (String)",
            action: nil,
            imageName: "list.bullet.circle"
        ),
        SetupStep(
            title: "インデックスを有効化",
            description: "titleフィールドの「Queryable」と「Sortable」にチェック",
            action: nil,
            imageName: "checkmark.circle"
        ),
        SetupStep(
            title: "保存して完了",
            description: "「Save」をクリックして設定を保存",
            action: nil,
            imageName: "arrow.down.circle"
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ProgressView(value: Double(currentStep + 1), total: Double(steps.count))
                    .padding()
                
                TabView(selection: $currentStep) {
                    ForEach(steps.indices, id: \.self) { index in
                        StepView(step: steps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
                
                HStack {
                    Button("前へ") {
                        withAnimation {
                            currentStep = max(0, currentStep - 1)
                        }
                    }
                    .disabled(currentStep == 0)
                    
                    Spacer()
                    
                    if currentStep < steps.count - 1 {
                        Button("次へ") {
                            withAnimation {
                                currentStep = min(steps.count - 1, currentStep + 1)
                            }
                        }
                    } else {
                        Button("完了") {
                            dismiss()
                        }
                        .bold()
                    }
                }
                .padding()
            }
            .navigationTitle("CloudKit設定ガイド")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAutoSetup = true }) {
                        Label("自動設定", systemImage: "wand.and.stars")
                    }
                }
            }
            .sheet(isPresented: $showingAutoSetup) {
                CloudKitAutoSetupView()
            }
        }
    }
}

struct SetupStep {
    let title: String
    let description: String
    let action: String?
    let imageName: String
}

struct StepView: View {
    let step: SetupStep
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: step.imageName)
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text(step.title)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            Text(step.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if let action = step.action {
                Button(action: {
                    if let url = URL(string: action) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("CloudKit Dashboardを開く", systemImage: "safari")
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}