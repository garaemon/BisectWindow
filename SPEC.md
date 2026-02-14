# **BisectWindow 開発仕様書 & ロードマップ**

**Version:** 2.0

**Date:** 2026-02-07

**Project Name:** BisectWindow

## **1\. プロジェクト概要**

### **1.1 コンセプト**

**「思考を止めないウインドウ操作」**

BisectWindowは、エンジニアやキーボード愛好家向けに設計されたmacOS用ウインドウマネージャです。Emacsのようなキーバインド思想を取り入れ、コンテキスト（現在のウインドウ状態）に応じた連続操作によって、複雑なレイアウトを直感的に実現します。

操作中は視覚的なインジケータにより、現在のモード（入力待ち状態）を即座に把握できます。

### **1.2 ターゲットユーザー**

* マウス操作のためにキーボードから手を離したくないエンジニア。  
* Emacs/Vimのキーバインドに慣れ親しんでいるユーザー。  
* 既存のウインドウ管理アプリの挙動（特にマルチモニタ移動）に不満がある層。

### **1.3 配布形態**

* **形式:** 非Mac App Store（Developer ID署名付き野良アプリ）  
* **必須権限:** Accessibility API (AXUIElement)  
* **OS要件:** macOS 14.0 (Sonoma) 以上推奨

## **2\. 機能要件 (Functional Requirements)**

### **2.1 コア・アクション**

ユーザーは「Prefix Key (修飾キー)」を押したまま、矢印キーなどを入力して操作を行います。

* **Prefix Key:** ユーザー定義可能（初期値: Command \+ Control）
* **操作方法:** Prefix Keyを押しながら以下のキーを入力。
* **基本操作:**
  * Right: ウインドウを右半分にリサイズ＆移動。
  * Left: ウインドウを左半分にリサイズ＆移動。
  * Up: ウインドウを上半分にリサイズ＆移動。
  * Down: ウインドウを下半分にリサイズ＆移動。
  * F: 最大化（Zoom）。Dock/Menuバーを除いた全画面領域へ展開。

### **2.2 コンテキスト・アウェアネス (Context Awareness)**

BisectWindowの最大の特徴は、「現在の状態」を見て次の挙動を変える点です。この状態（Pending State）は、Prefix Keyが押されている間維持されます。

#### **判定ロジック詳細**

* **Tolerance (許容誤差):** ウインドウ位置の判定には、数ピクセル（例: 10px）の誤差を許容します。ユーザーが手動で配置した場合でも、概ねの位置が合っていれば検知します。

#### **ケースA: 四分の一分割 (Quarter Tiling)**

* **シナリオ:** 画面を田の字に分割したい。
* **ロジック:**
  1. ユーザーが Prefix \+ Right を入力（Prefixは押しっぱなし） → ウインドウが**右半分**になる。
  2. ユーザーが続けて Up を入力（Prefixは依然として押しっぱなし）。
  3. アプリは「現在ウインドウは右半分にある」と検知。
  4. 通常の「上半分」ではなく、**「右上1/4」** にリサイズする。
  5. Prefix Keyを離すと、Pending Stateが終了し、確定する。
  * **制限:** 1/4状態からのさらなる分割（1/8など）は行いません。

#### **ケースB: スクリーンジャンプ (Screen Traversal)**

* **シナリオ:** デュアルモニタ環境でウインドウを隣の画面に飛ばしたい。
* **ロジック:**
  1. ユーザーが Prefix \+ Right を入力 → ウインドウが**右半分**になる。
  2. ユーザーが再度 Right を入力（Prefixは押しっぱなし）。
  3. アプリは「現在ウインドウは右半分にある」かつ「右端に接している」と検知。
  4. **「次のスクリーン（幾何学的配置で右にある画面）」** へウインドウを移動させる。
  * **順序:** macOSのDisplay ID順ではなく、左上から右下への配置順を採用します。
  * **境界:** 右端のスクリーンで更に右へ移動しようとした場合、何もしません（ラップアラウンドなし）。
  * **制限:** 上下方向のスクリーン移動はVersion 2.0では対象外とします。

#### **ケースC: 固定サイズ・特殊ウインドウ**

* **固定サイズ:** リサイズ不可の場合、移動のみを行います。
* **フルスクリーン/最小化:** macOSネイティブのフルスクリーンや最小化状態のウインドウは**操作対象外**とします。

### **2.3 視覚的フィードバック (Visual Feedback)**

Prefixキー（修飾キー）が押されている間（Pending State）、ユーザーに視覚的なヒントを与えます。

* **インジケータ:** 画面の隅（デフォルトは右下）に小さなアイコンまたはドットを表示。
* **状態表現:**
  * **Prefix Key Down:** インジケータを表示（Pending State開始）。
  * **Prefix Key Up:** インジケータを消去（Pending State終了）。
* **デザイン:** 邪魔にならないミニマルなHUD（Head-Up Display）。

### **2.4 設定機能 (Configuration)**

GUIによる設定画面を提供します。

* **General:**
  * ログイン時の自動起動設定。
  * メニューバーアイコンの表示/非表示。
* **Key Bindings:**
  * **Prefix Key:** ショートカットレコーダーを用いて任意の修飾キーの組み合わせに変更可能。
* **Behavior:**
  * **Overlay:** インジケータの表示位置とオン/オフ。

## **3\. アーキテクチャ設計 (Testable Architecture)**

アクセシビリティAPIに依存する部分、計算ロジック、そしてUIを分離します。

### **3.1 レイヤー構造**

1. **Domain Layer (Core Logic)**  
   * **責務:** 座標計算、状態遷移、コマンド判定。  
   * **依存:** Pure Swift。  
2. **Interface Layer (Protocols)**  
   * **責務:** OS機能、設定保存、UI表示の抽象化。  
   * **主要プロトコル:** SystemStateProtocol, WindowActionProtocol, ConfigRepositoryProtocol, OverlayProtocol。  
3. **Infrastructure Layer (Implementation)**  
   * **責務:** AXUIElement, UserDefaults, SwiftUI の実実装。  
4. **Presentation Layer (UI)**  
   * **責務:** 設定画面、オーバーレイの描画 (SwiftUI)。

### **3.2 データモデル**

```swift
struct Rect: Equatable {
    var x: Double, y: Double, width: Double, height: Double
    // Infrastructure層でCGRectと相互変換を行う
}

struct WindowInfo: Equatable {
    let id: Int // AXUIElement hash or pid
    let frame: Rect
    let screenId: UInt32 // CGDirectDisplayID
    let isResizable: Bool
}

struct AppConfig: Codable {
    var prefixKeyModifiers: UInt // NSEvent.ModifierFlags.rawValue (修飾キーのみ)
    var isOverlayEnabled: Bool
}

enum AppState {
    case idle
    case pendingInput // インジケータ表示。Prefix Key押下中＝連続入力可能状態
}
```

## **4\. 開発環境と構成**

### **4.1 プロジェクト管理**

**XcodeGen** を採用。

### **4.2 ディレクトリ構成**

```text
BisectWindow/
├── Makefile            <-- generate, test コマンド
├── project.yml         <-- XcodeGen設定
├── Tests/
│   └── LogicTests/     <-- XCTest (Domain Layer Logic)
└── Sources/
    ├── App/
    │   ├── Main.swift
    │   └── AppState.swift
    ├── Domain/ (Core Logic)
    │   ├── Models/
    │   └── BisectEngine.swift
    ├── Interface/ (Protocols)
    │   └── Protocols.swift
    ├── Infrastructure/ (Implementation)
    │   ├── Accessibility/
    │   └── Persistence/
    └── UI/ (Presentation)
        ├── Settings/
        └── Overlay/
```

## **5\. 開発ロードマップ**

### **Phase 1: Project Bootstrap (Day 1\)**

* Git初期化、XcodeGen (project.yml) セットアップ。  
* テスト環境の構築。

### **Phase 2: Core Logic Implementation (Day 2-3)**

* **TDD実践。** BisectEngine の実装。  
* AppConfig モデルの定義とロジックへの反映（タイムアウト処理など）。

### **Phase 3: Infrastructure Integration (Day 4-5)**

* AXClient (アクセシビリティ), HotKeyManager (入力監視) の実装。  
* UserDefaults を使った設定の永続化実装。

### **Phase 4: UI Implementation (Day 6-7)**

* **Overlay:** NSPanel (または NSWindow) を使用したクリックスルー可能な透明ウインドウの実装。ステート変化に合わせて表示/非表示を切り替え。  
* **Settings:** SwiftUIを使った設定画面の実装。SettingsView から AppConfig を更新できるようにする。

### **Phase 5: Polish & Release (Day 8\~)**

* 権限リクエストフロー。  
* アイコン、ドキュメント整備。