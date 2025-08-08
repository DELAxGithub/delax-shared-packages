import Foundation
import CloudKit

class CloudKitSchemaManager: ObservableObject {
    @Published var isProcessing = false
    @Published var statusMessage = ""
    @Published var errorMessage: String?
    
    private let containerIdentifier = "iCloud.Delax.CloudKitStarter"
    
    // Management Token設定の確認
    func checkManagementTokenConfiguration() -> Bool {
        // Management Tokenは環境変数から取得
        let token = ProcessInfo.processInfo.environment["CLOUDKIT_MANAGEMENT_TOKEN"]
        return token != nil && !token!.isEmpty
    }
    
    // cktoolの存在確認
    func checkCKToolInstallation() -> Bool {
        #if os(macOS)
        let fileManager = FileManager.default
        let cktoolPath = "/usr/local/bin/cktool"
        return fileManager.fileExists(atPath: cktoolPath)
        #else
        // iOSではcktoolは使用できません
        return false
        #endif
    }
    
    // スキーマの自動設定
    func setupSchema(completion: @escaping (Result<Void, Error>) -> Void) {
        isProcessing = true
        statusMessage = "スキーマ設定を準備中..."
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            // 1. 事前チェック
            if !self.checkManagementTokenConfiguration() {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.errorMessage = "CloudKit Management Tokenが設定されていません"
                    completion(.failure(SchemaError.missingManagementToken))
                }
                return
            }
            
            if !self.checkCKToolInstallation() {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.errorMessage = "cktoolがインストールされていません"
                    completion(.failure(SchemaError.cktoolNotFound))
                }
                return
            }
            
            // 2. スキーマファイルのパスを取得
            guard let schemaPath = Bundle.main.path(forResource: "schema", ofType: "json") else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.errorMessage = "スキーマファイルが見つかりません"
                    completion(.failure(SchemaError.schemaFileNotFound))
                }
                return
            }
            
            // 3. cktoolコマンドを実行
            DispatchQueue.main.async {
                self.statusMessage = "スキーマを適用中..."
            }
            
            let result = self.executeCKTool(schemaPath: schemaPath)
            
            DispatchQueue.main.async {
                self.isProcessing = false
                
                switch result {
                case .success:
                    self.statusMessage = "スキーマ設定が完了しました"
                    completion(.success(()))
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    // cktoolの実行（macOSのみ）
    private func executeCKTool(schemaPath: String) -> Result<Void, Error> {
        #if os(macOS)
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/local/bin/cktool")
        
        // 引数の設定
        task.arguments = [
            "import-schema",
            "--container-identifier", containerIdentifier,
            "--environment", "development",
            "--file", schemaPath
        ]
        
        // 環境変数の設定
        var environment = ProcessInfo.processInfo.environment
        if let token = ProcessInfo.processInfo.environment["CLOUDKIT_MANAGEMENT_TOKEN"] {
            environment["CLOUDKIT_MANAGEMENT_TOKEN"] = token
        }
        task.environment = environment
        
        // 出力の設定
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                return .success(())
            } else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                return .failure(SchemaError.cktoolExecutionFailed(errorString))
            }
        } catch {
            return .failure(error)
        }
        #else
        // iOSではcktoolは使用できません
        return .failure(SchemaError.cktoolNotAvailableOnIOS)
        #endif
    }
    
    // スキーマ設定手順の取得
    func getSetupInstructions() -> String {
        return """
        CloudKit自動設定の準備:
        
        1. cktoolのインストール:
           - Xcodeがインストールされている必要があります
           - ターミナルで以下を実行:
             xcrun cktool --help
        
        2. Management Tokenの取得:
           - CloudKit Dashboardにアクセス
           - Settings > Tokens > Generate Token
           - トークンをコピー
        
        3. 環境変数の設定:
           - ターミナルで以下を実行:
             export CLOUDKIT_MANAGEMENT_TOKEN="your-token-here"
           - またはXcodeのScheme設定で環境変数を追加
        
        4. アプリを再起動して自動設定を実行
        """
    }
}

// エラー定義
enum SchemaError: LocalizedError {
    case missingManagementToken
    case cktoolNotFound
    case schemaFileNotFound
    case cktoolExecutionFailed(String)
    case cktoolNotAvailableOnIOS
    
    var errorDescription: String? {
        switch self {
        case .missingManagementToken:
            return "CloudKit Management Tokenが設定されていません"
        case .cktoolNotFound:
            return "cktoolがインストールされていません"
        case .schemaFileNotFound:
            return "スキーマファイルが見つかりません"
        case .cktoolExecutionFailed(let message):
            return "cktool実行エラー: \(message)"
        case .cktoolNotAvailableOnIOS:
            return "cktoolはiOSでは使用できません。CloudKit Dashboardで手動設定してください。"
        }
    }
}