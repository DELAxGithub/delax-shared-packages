# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Build and Run
- Open the project in Xcode: `open CloudKitStarter/CloudKitStarter.xcodeproj`
- Build: Press Cmd+B in Xcode or use `xcodebuild -project CloudKitStarter/CloudKitStarter.xcodeproj -scheme CloudKitStarter -configuration Debug build`
- Run: Press Cmd+R in Xcode to run on selected simulator/device
- Clean: Press Cmd+Shift+K in Xcode or use `xcodebuild clean`

### Testing
- Run tests: Press Cmd+U in Xcode or use `xcodebuild test -project CloudKitStarter/CloudKitStarter.xcodeproj -scheme CloudKitStarter -destination 'platform=iOS Simulator,name=iPhone 15'`
- Run specific test: In Xcode, click the diamond next to individual test methods

### Code Quality
- SwiftLint (if integrated): `swiftlint` in project root
- Format code: Use Xcode's Ctrl+I for indentation

## Architecture

This is a SwiftUI-based iOS application starter template for CloudKit integration:

- **CloudKitStarterApp.swift**: Main app entry point using SwiftUI App protocol
- **ContentView.swift**: Primary view controller for the application UI
- **Project Structure**: Standard Xcode project with SwiftUI lifecycle
- **Deployment Target**: iOS 18.5
- **Swift Version**: 5.0
- **Development Team**: Z88477N5ZU
- **Bundle Identifier**: Delax.CloudKitStarter

The project is set up for CloudKit integration but currently contains only the basic SwiftUI template. Key architectural decisions for CloudKit implementation should consider:
- CloudKit container configuration
- Public vs Private database usage
- Record types and schemas
- Subscription and notification handling
- Offline capability and sync strategies


description: "spec-driven development"
---

Claude Codeを用いたspec-driven developmentを行います。

## spec-driven development とは

spec-driven development は、以下の5つのフェーズからなる開発手法です。

### 1. 事前準備フェーズ

- ユーザーがClaude Codeに対して、実行したいタスクの概要を伝える
- このフェーズで !`mkdir -p ./.cckiro/specs`  を実行します
- `./cckiro/specs` 内にタスクの概要から適切な spec 名を考えて、その名前のディレクトリを作成します
    - たとえば、「記事コンポーネントを作成する」というタスクなら `./cckiro/specs/create-article-component` という名前のディレクトリを作成します
- 以下ファイルを作成するときはこのディレクトリの中に作成します

### 2. 要件フェーズ

- Claude Codeがユーザーから伝えられたタスクの概要に基づいて、タスクが満たすべき「要件ファイル」を作成する
- Claude Codeがユーザーに対して「要件ファイル」を提示し、問題がないかを尋ねる
- ユーザーが「要件ファイル」を確認し、問題があればClaude Codeに対してフィードバックする
- ユーザーが「要件ファイル」を確認し、問題がないと答えるまで「要件ファイル」に対して修正を繰り返す

### 3. 設計フェーズ

- Claude Codeは、「要件ファイル」に記載されている要件を満たすような設計を記述した「設計ファイル」を作成する
- Claude Codeがユーザーに対して「設計ファイル」を提示し、問題がないかを尋ねる
- ユーザーが「設計ファイル」を確認し、問題があればClaude Codeに対してフィードバックする
- ユーザーが「設計ファイル」を確認し、問題がないと答えるまで「要件ファイル」に対して修正を繰り返す

### 4. 実装計画フェーズ

- Claude Codeは、「設計ファイル」に記載されている設計を実装するための「実装計画ファイル」を作成する
- Claude Codeがユーザーに対して「実装計画ファイル」を提示し、問題がないかを尋ねる
- ユーザーが「実装計画ファイル」を確認し、問題があればClaude Codeに対してフィードバックする
- ユーザーが「実装計画ファイル」を確認し、問題がないと答えるまで「要件ファイル」に対して修正を繰り返す

### 5. 実装フェーズ

- Claude Codeは、「実装計画ファイル」に基づいて実装を開始する
- 実装するときは「要件ファイル」「設計ファイル」に記載されている内容を守りながら実装してください