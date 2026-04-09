---
name: swiftui-development
description: >
  SwiftUI + Swift 6.2 + Xcode 26 + Apple Intelligence 生产级开发知识包（iOS 26+ / iPadOS 26+ / macOS Tahoe 26+ / visionOS 26+ / watchOS 26+ / tvOS 26+）—— 声明式 UI、Liquid Glass、Foundation Models on-device AI、App Intents、SwiftData、WidgetKit、HealthKit、CloudKit、RealityKit、Apple Pay、CoreBluetooth、NaturalLanguage、CoreMotion、AVFoundation、CoreML、Vision、ARKit、CoreImage、SafariServices、EventKit、Contacts、BackgroundTasks、CreateML、SpriteKit、Passkeys、DocumentGroup、Layout 协议、Accessibility、Localization、Combine、Network Framework、CoreLocation、CoreData、Authentication Services、watchOS Extended Runtime、tvOS Focus Engine、visionOS Room Tracking、App Store Connect API 等 45+ 框架完整覆盖。

  包含 1000+ 代码示例、90+ 生产级坑点、WWDC25/26 最佳实践。涵盖 MVVM+Repository+UseCase 架构模式、依赖注入、分页/无限滚动、图片缓存、深度链接路由、统一错误处理等完整生产模式。专为 Claude Code、Cursor、Windsurf、Xcode Coding Intelligence 等 AI 工具设计。

  Trigger keywords (EN): SwiftUI, Swift 6.2, Xcode 26, Apple Intelligence, Foundation Models, LanguageModelSession, @Generable, Guided Generation, Liquid Glass, glassEffect, GlassEffectContainer, glassEffectID, NavigationStack, zoom transition, @Observable, @Model, SwiftData, Observations AsyncSequence, WebView, Rich TextEditor, WidgetKit, Live Activities, App Intents, AppEntity, EntityQuery, AppShortcuts, HealthKit, CloudKit, RealityKit, RealityView, CoreBluetooth, NaturalLanguage, CoreMotion, Apple Pay, PassKit, Sign in with Apple, Passkeys, StoreKit 2, Xcode Cloud, DocC, Swift Testing, SF Symbols, visionOS, spatial layout, AVFoundation, AVPlayer, AVCaptureSession, CoreML, Vision, VNRecognizeTextRequest, ARKit, CoreImage, CIFilter, SafariServices, ASWebAuthenticationSession, EventKit, Contacts, ContactAccessButton, NWPathMonitor, NWConnection, BackgroundTasks, BGTaskScheduler, CoreData migration, CreateML, SpriteKit, SpriteView, DocumentGroup, FileDocument, Layout protocol, @AppStorage, @SceneStorage, Keychain, Codable, Accessibility, VoiceOver, Localization, Commands, openWindow, Combine, Publisher, Subscriber, FocusFilter, CLMonitor, CLBeaconRegion, iBeacon, geofencing, MKOverlay, MKClusterAnnotation, UNNotificationAction, INSendMessageIntent, ParticleEmitterComponent, CustomMaterial, VNDetectTrajectoriesRequest, VNGeneratePersonInstanceMaskRequest, ARObjectScanningConfiguration, sceneReconstruction, HKWorkoutRouteBuilder, NSPersistentHistoryTracking, Security Key, Credential Provider, MVVM, Repository pattern, dependency injection, pagination, infinite scroll, image cache, deep link routing, Router, NavigationPath, AppError, typed throws, WKExtendedRuntimeSession, GCController, RoomTrackingProvider, App Store Connect API, JWT, TestFlight, APNs HTTP/2, ASan, TSan, UBSan, Instruments, MetricKit, dSYM

  触发关键词（中文）: SwiftUI, Swift 6.2, Xcode 26, 苹果智能, Foundation Models, Liquid Glass, SwiftData, WidgetKit, App Intents, HealthKit, CloudKit, RealityKit, 蓝牙, 自然语言, Apple Pay, Passkeys 无密码登录, StoreKit 内购, 音视频, 相机拍摄, 文字识别 OCR, 人脸检测, AR 增强现实, 图像滤镜, OAuth 登录, 日历提醒, 通讯录, 网络监控, 后台任务, 数据迁移, 机器学习, 2D 游戏, 文档型 App, 多窗口, 菜单命令, 无障碍, 本地化, iOS 26 开发, 多平台适配, Combine 响应式, NWConnection 网络连接, iBeacon 信标, 地理围栏, 地图叠加层, 通知操作按钮, 通信通知, 粒子系统, 自定义着色器, 轨迹检测, 实例分割, 3D 对象扫描, 场景重建, 运动路线, 历史追踪, ObjC 互操作, 安全密钥, MVVM 架构, Repository 模式, 依赖注入, 分页加载, 无限滚动, 图片缓存, 深度链接路由, 统一错误处理, watchOS 扩展运行时, tvOS 焦点引擎, visionOS 房间追踪, App Store Connect API, JWT 令牌, TestFlight 自动化, APNs 推送, 地址消毒器, 线程消毒器, Instruments 性能分析, MetricKit 诊断, 崩溃符号化
---

# SwiftUI Development - Production Knowledge Base（2026 年 4 月完整版）

专注 **iOS 26+ / Swift 6.2 / Xcode 26** 现代应用开发。覆盖 SwiftUI、Apple Intelligence、Liquid Glass、SwiftData、WidgetKit、App Intents、HealthKit、CloudKit、RealityKit、Apple Pay、AVFoundation、CoreML、Vision、ARKit、CoreImage、EventKit、Contacts、Passkeys、BackgroundTasks、SpriteKit、CreateML、DocumentGroup、Layout 协议、Accessibility、Localization、Combine、Network Framework、CoreLocation 高级、CoreData、Authentication Services、watchOS、tvOS、visionOS、App Store Connect API 等 **45+ 框架**，100+ 章节，1000+ 代码示例。

## 平台快照
| 项目 | 值 |
|------|-----|
| OS | iOS 26 / iPadOS 26 / macOS Tahoe 26 / visionOS 26 |
| 语言 | **Swift 6.2**（严格并发 + Observations AsyncSequence） |
| UI 框架 | **SwiftUI** + **Liquid Glass** 设计语言 |
| AI 框架 | **Foundation Models**（on-device LLM，2026.02 更新） |
| 数据持久化 | **SwiftData**（推荐）|
| 状态管理 | **Observation 框架**（@Observable + Observations AsyncSequence） |
| IDE | **Xcode 26**（Coding Intelligence + SwiftUI Performance Instrument） |

## 项目结构
```
MyApp/
├─ MyApp.swift          # @main App 入口
├─ ContentView.swift
├─ Models/              # @Model / @Observable 类
├─ Views/               # SwiftUI Views
├─ Services/            # Network、AI Session、HealthKit 等
├─ Intents/             # App Intents
├─ Widgets/             # WidgetKit Extension
└─ Preview Content/     # Preview 数据
```

## Liquid Glass 设计语言（iOS 26）
Liquid Glass：半透明、折射环境光、动态流体效果。

```swift
// 基础效果
.background(.ultraThinMaterial)
.glassEffect()                         // 边框折射 + 光感
.clipShape(.rect(cornerRadius: 24, style: .continuous))

// 多个效果必须用 GlassEffectContainer（性能关键）
GlassEffectContainer(spacing: 40) {
    HStack(spacing: 40) {
        Image(systemName: "star.fill").glassEffect()
        Text("Featured").glassEffect(.regular.tint(.orange).interactive())
    }
}

// glassEffectID + @Namespace 实现形状 morphing 过渡
@Namespace private var ns
Image("icon")
    .glassEffect()
    .glassEffectID("icon", in: ns)
    .glassEffectTransition(.materialize)  // 或 .matchedGeometry
```

**Toolbar + Liquid Glass**：
```swift
.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
```

**HIG 要点**：多个 glassEffect 必须包在 `GlassEffectContainer` 中，否则性能下降；自动适配 Dark Mode。

## SwiftUI 基础（Swift 6.2）
```swift
@Observable
class CounterViewModel {
    var count = 0
    func increment() { count += 1 }
}

struct CounterView: View {
    @State private var vm = CounterViewModel()
    var body: some View {
        VStack(spacing: 20) {
            Text("Count: \(vm.count)").font(.largeTitle)
            Button("Increment", action: vm.increment).buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Counter")
    }
}
#Preview { NavigationStack { CounterView() } }
```

## 状态管理（Observation 框架）
```swift
// Swift 6.2 Observations AsyncSequence（transactional 快照）
@Observable class ShoppingCart {
    var items: [String] = []
    var total: Decimal = 0
}
let cart = ShoppingCart()

Task {
    for await _ in Observations(of: cart) {
        // 批量同步变更后发出一致快照，适合持久化/日志
        print("Cart: \(cart.items.count) items, \(cart.total)")
    }
}

// 单属性观察
for await newTotal in Observations { cart.total } {
    print("Total: \(newTotal)")
}
```

## SwiftData
```swift
@Model
final class Item {
    @Attribute(.unique) var id: String   // 唯一约束
    var title: String
    var timestamp: Date
    var isCompleted: Bool = false
    var category: Category?

    init(title: String) {
        self.id = UUID().uuidString
        self.title = title
        self.timestamp = .now
    }
}

@Model
final class Category {
    @Attribute(.unique) var name: String
    @Relationship(deleteRule: .cascade, inverse: \Item.category)
    var items: [Item] = []
    init(name: String) { self.name = name }
}

// App 入口
@main struct MyApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
            .modelContainer(for: [Item.self, Category.self])
    }
}

// View 中使用
@Query(sort: \Item.timestamp, order: .reverse) private var items: [Item]
@Environment(\.modelContext) private var context

func addItem(_ title: String) {
    context.insert(Item(title: title))
}

// Preview
#Preview {
    ItemListView()
        .modelContainer(for: Item.self, inMemory: true)
}
```

**SwiftData iOS 26 新特性**：支持模型继承（`@Model class BusinessTrip: Trip {}`）。

## Apple Intelligence & Foundation Models
on-device 30 亿参数 LLM，无需 API Key，隐私安全。

### Context Management
```swift
let model = SystemLanguageModel()
let contextSize = model.contextSize
let tokenCount = try await model.tokenCount(for: prompt)
guard tokenCount < contextSize else { /* 截断或分块 */ return }
```

### Streaming + Liquid Glass UI
```swift
struct AIChatView: View {
    @State private var session = LanguageModelSession()
    @State private var response = ""
    @State private var isGenerating = false

    var body: some View {
        VStack {
            ScrollView {
                Text(response).textSelection(.enabled)
            }
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 20, style: .continuous))

            HStack {
                TextField("Ask AI...", text: $prompt)
                    .textFieldStyle(.roundedBorder)
                Button("Send") { Task { await stream() } }
                    .disabled(isGenerating)
            }
        }
        .task { await session.prewarm() }
    }

    private func stream() async {
        isGenerating = true; response = ""
        do {
            for try await chunk in session.streamResponse(to: prompt) {
                withAnimation(.easeIn(duration: 0.1)) { response += chunk }
            }
        } catch { response = "Error: \(error.localizedDescription)" }
        isGenerating = false
    }
}
```

### Guided Generation（强类型输出）
```swift
@Generable
struct TripSuggestion {
    var title: String
    var landmarks: [String]
    @Guide(description: "简短摘要") var summary: String  // 摘要放最后提升质量
}

let result = try await session.respond(to: prompt, generating: TripSuggestion.self)
```

### Tool Calling
```swift
let session = LanguageModelSession(tools: [SearchItemTool.self])
let result = try await session.respond(to: "Find my Tokyo photos")
```

**最佳实践**：始终 `prewarm()`；`tokenCount + contextSize` 动态管理上下文；属性顺序影响质量；摘要类字段放最后。

## App Intents（Siri / Spotlight / Apple Intelligence）
```swift
// 基础 Intent
struct AddItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Item"
    @Parameter(title: "Title") var title: String

    func perform() async throws -> some IntentResult {
        return .result(value: "Added: \(title)")
    }
}

// AppEntity（让系统理解 App 数据）
struct TrailEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Trail"
    static var defaultQuery = TrailEntityQuery()
    var id: String
    var name: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct TrailEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [TrailEntity] { [] }
    func suggestedEntities() async throws -> [TrailEntity] { [] }
}

// App Shortcuts（Siri 语音触发）
struct MyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: AddItemIntent(), phrases: ["Add item to \(.applicationName)"])
    }
}

// Assistant Schemas（Apple Intelligence 深度集成）
@AppIntent(schema: .system.search)
struct SearchIntent: AppIntent { ... }

// Spotlight 索引
CSSearchableIndex.default().indexAppEntities(entities)
```

## WidgetKit（Widget + Live Activities）
```swift
// Timeline Provider
struct GameStatusProvider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entry = GameStatusEntry(date: .now, status: "Active")
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
    func placeholder(in context: Context) -> GameStatusEntry { GameStatusEntry(date: .now, status: "—") }
    func getSnapshot(in context: Context, completion: @escaping (GameStatusEntry) -> Void) {
        completion(GameStatusEntry(date: .now, status: "Active"))
    }
}

// 交互式 Widget（iOS 17+）
Button(intent: SuperChargeIntent()) {
    Image(systemName: "bolt.fill")
}

// Smart Stack 相关性
TimelineEntryRelevance(score: 10, duration: 3600)

// 刷新 Widget
WidgetCenter.shared.reloadTimelines(ofKind: "GameStatus")
```

## 导航（NavigationStack + Zoom 过渡 + TabView）
```swift
// Zoom 过渡（iOS 18+，列表→详情的丝滑动画）
@Namespace private var ns

struct ItemList: View {
    var body: some View {
        NavigationStack {
            List(items) { item in
                NavigationLink(value: item) {
                    ItemRow(item: item)
                        .matchedTransitionSource(id: item.id, in: ns)
                }
            }
            .navigationDestination(for: Item.self) { item in
                DetailView(item: item)
                    .navigationTransition(.zoom(sourceID: item.id, in: ns))
            }
        }
    }
}

// TabView（iOS 18+ 新 Tab API）
TabView {
    Tab("Home", systemImage: "house") {
        NavigationStack { HomeView() }
    }
    Tab("Search", systemImage: "magnifyingglass") {
        NavigationStack { SearchView() }
    }
    Tab("Profile", systemImage: "person") {
        NavigationStack { ProfileView() }
    }
}
.tabViewStyle(.tabBarOnly)   // 或 .sidebarAdaptable（iPad 自适应侧栏）

// 编程式切换 Tab
@State private var selectedTab = 0
TabView(selection: $selectedTab) {
    Tab("Home", systemImage: "house", value: 0) { HomeView() }
    Tab("Settings", systemImage: "gear", value: 1) { SettingsView() }
}

// badge
Tab("Inbox", systemImage: "tray") { InboxView() }
    .badge(unreadCount)
```

## 搜索界面
```swift
@State private var searchText = ""
@State private var suggestions = ["Swift", "SwiftUI", "Xcode"]

NavigationStack {
    List(filteredItems) { item in Text(item.name) }
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Search items") {
            ForEach(suggestions, id: \.self) { s in
                Text(s).searchCompletion(s)
            }
        }
        .navigationTitle("Items")
}

var filteredItems: [Item] {
    searchText.isEmpty ? items : items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
}
```

## 拖拽（Drag & Drop + Transferable）
```swift
// Transferable 协议
extension Contact: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .contact)
        ProxyRepresentation(exportingAs: .plainText) { "\($0.name)" }
    }
}

// 拖拽源
ContactRow(contact: contact).draggable(contact)

// 拖放目标
List { ... }
    .dropDestination(for: Contact.self) { contacts, _ in
        self.contacts.append(contentsOf: contacts)
        return true
    }
```

## 手势
```swift
// @GestureState 临时状态
@GestureState private var isDetecting = false

let longPress = LongPressGesture(minimumDuration: 1)
    .updating($isDetecting) { state, gestureState, _ in gestureState = state }
    .onEnded { _ in print("Long press ended") }

// 拖拽手势
@State private var offset = CGSize.zero
let drag = DragGesture()
    .onChanged { value in offset = value.translation }
    .onEnded { _ in withAnimation { offset = .zero } }

// 手势组合
view.gesture(longPress.simultaneously(with: drag))
```

## 动画
```swift
// 弹簧动画
withAnimation(.spring(duration: 0.5, bounce: 0.3)) { isExpanded.toggle() }

// 多阶段 Phase Animator
Text("Hello").phaseAnimator([false, true]) { content, phase in
    content.scaleEffect(phase ? 1.2 : 1.0).opacity(phase ? 1.0 : 0.8)
}

// 共享元素 matchedGeometryEffect
@Namespace private var animation
Image(item.image).matchedGeometryEffect(id: item.id, in: animation)
```

## HealthKit
```swift
let healthStore = HKHealthStore()

// 请求权限
let readTypes: Set<HKSampleType> = [
    HKObjectType.quantityType(forIdentifier: .heartRate)!,
    HKObjectType.quantityType(forIdentifier: .stepCount)!
]
try await healthStore.requestAuthorization(toShare: [], read: readTypes)

// 查询数据
let query = HKSampleQuery(
    sampleType: HKObjectType.quantityType(forIdentifier: .heartRate)!,
    predicate: nil, limit: 100,
    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
) { _, samples, _ in
    DispatchQueue.main.async {
        guard let samples = samples as? [HKQuantitySample] else { return }
        self.heartRates = samples.map { $0.quantity.doubleValue(for: .init(from: "count/min")) }
    }
}
healthStore.execute(query)

// 后台交付（数据变化时唤醒 App）
healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { _, _ in }
```

## CloudKit
```swift
let container = CKContainer.default()
let db = container.privateCloudDatabase

// 保存记录
let record = CKRecord(recordType: "TodoItem")
record["title"] = "Buy groceries"
record["dueDate"] = Date()
// 加密字段（iOS 15+）
record.encryptedValues["sensitiveNote"] = "Private content"

db.save(record) { _, error in
    if let error { print("Save error: \(error)") }
}

// 查询
let predicate = NSPredicate(value: true)
let query = CKQuery(recordType: "TodoItem", predicate: predicate)
let (results, _) = try await db.records(matching: query)

// CloudKit + SwiftData 同步：.modelContainer 设置 cloudKitContainerIdentifier
.modelContainer(for: Item.self, configurations: [
    ModelConfiguration(cloudKitDatabase: .automatic)
])
```

**注意**：Schema 一旦部署到生产只能新增，不能删除字段；加密字段不支持 CKAsset。

## Sign in with Apple
```swift
import AuthenticationServices

struct SignInView: View {
    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            switch result {
            case .success(let auth):
                if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                    let userID = credential.user
                    let email = credential.email
                    // 存入 Keychain
                }
            case .failure(let error):
                print("Auth failed: \(error)")
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
    }
}
```

## Push Notifications
```swift
// 请求权限
let center = UNUserNotificationCenter.current()
try await center.requestAuthorization(options: [.alert, .sound, .badge])

// 本地通知
let content = UNMutableNotificationContent()
content.title = "Reminder"
content.body = "Time to check in!"
content.sound = .default

let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
try await center.add(request)

// 前台展示
func userNotificationCenter(_ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void) {
    handler([.banner, .sound, .badge])
}
```

## Apple Pay（PassKit）
```swift
import PassKit

// 检查是否支持
guard PKPaymentAuthorizationController.canMakePayments() else { return }

let request = PKPaymentRequest()
request.merchantIdentifier = "merchant.com.example.app"
request.supportedNetworks = [.visa, .masterCard, .amex]
request.merchantCapabilities = .capability3DS
request.countryCode = "CN"
request.currencyCode = "CNY"
request.paymentSummaryItems = [
    PKPaymentSummaryItem(label: "Pro Subscription", amount: NSDecimalNumber(string: "68.00"))
]

let controller = PKPaymentAuthorizationController(paymentRequest: request)
controller.delegate = self
controller.present()

// 授权完成
func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
    didAuthorizePayment payment: PKPayment,
    handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
    // 发送 payment.token 到服务器验证
    completion(PKPaymentAuthorizationResult(status: .success))
}
```

## NaturalLanguage
```swift
import NaturalLanguage

// 语言识别
let recognizer = NLLanguageRecognizer()
recognizer.processString("Hello, SwiftUI world!")
print(recognizer.dominantLanguage?.rawValue ?? "unknown")  // "en"

// 词性标注
let tagger = NLTagger(tagSchemes: [.lexicalClass])
tagger.string = "Apple ships Swift 6."
tagger.enumerateTags(in: tagger.string!.startIndex..., unit: .word,
    scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, range in
    print("\(tagger.string![range]): \(tag?.rawValue ?? "")")
    return true
}

// 命名实体识别
let nerTagger = NLTagger(tagSchemes: [.nameType])
// 识别 .personalName / .placeName / .organizationName

// 语义相似度（词嵌入）
if let embedding = NLEmbedding.wordEmbedding(for: .english) {
    let distance = embedding.distance(between: "bicycle", and: "motorcycle")
    // distance 越小越相似
}
```

## CoreMotion
```swift
import CoreMotion

class MotionManager: ObservableObject {
    private let manager = CMMotionManager()
    @Published var pitch: Double = 0
    @Published var roll: Double = 0

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            self?.pitch = data.attitude.pitch
            self?.roll = data.attitude.roll
        }
    }

    func stop() { manager.stopDeviceMotionUpdates() }
}

// 计步器
let pedometer = CMPedometer()
if CMPedometer.isStepCountingAvailable() {
    pedometer.startUpdates(from: .now) { data, _ in
        guard let data else { return }
        print("Steps: \(data.numberOfSteps)")
    }
}
```
**注意**：visionOS 中 motion 数据只在 immersive space 开启时可用；用完立即停止以节省电量。

## CoreBluetooth（BLE）
```swift
import CoreBluetooth

class BLEManager: NSObject, CBCentralManagerDelegate, ObservableObject {
    private var centralManager: CBCentralManager!
    @Published var discoveredDevices: [CBPeripheral] = []

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: [myServiceUUID],
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard RSSI.intValue >= -50 else { return }  // 信号强度过滤
        discoveredDevices.append(peripheral)
        central.connect(peripheral)
    }
}

// 外设（Peripheral）模式
let characteristic = CBMutableCharacteristic(
    type: myCharacteristicUUID,
    properties: [.notify, .writeWithoutResponse],
    value: nil, permissions: [.readable, .writeable]
)
```

## RealityKit（AR / visionOS）
```swift
import RealityKit
import SwiftUI

// RealityView（iOS 18+ / visionOS）
struct ARSceneView: View {
    @State private var entity: ModelEntity?

    var body: some View {
        RealityView { content in
            // 加载 3D 模型
            if let model = try? await ModelEntity(named: "robot.usdz") {
                model.generateCollisionShapes(recursive: true)
                content.add(model)
                entity = model
            }
        } update: { content in
            entity?.transform.rotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
        }
        .gesture(TapGesture().targetedToAnyEntity().onEnded { _ in
            entity?.model?.materials = [SimpleMaterial(color: .orange, isMetallic: true)]
        })
    }
}

// ECS（Entity Component System）
struct RotationComponent: Component { var speed: Float = 1.0 }

class RotationSystem: System {
    static let query = EntityQuery(where: .has(RotationComponent.self))
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            let speed = entity.components[RotationComponent.self]?.speed ?? 1
            entity.setOrientation(
                simd_quatf(angle: speed * Float(context.deltaTime), axis: [0,1,0]),
                relativeTo: entity)
        }
    }
}

// PBR 材质
var material = PhysicallyBasedMaterial()
material.baseColor.tint = .systemBlue
material.roughness = .init(floatLiteral: 0.3)
material.metallic = .init(floatLiteral: 0.8)
```

## WebKit（WKWebView 集成）
```swift
import WebKit
import SwiftUI

struct WebView: UIViewRepresentable {
    let url: URL
    var onNavigate: ((URL) -> Void)?

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView
        init(_ parent: WebView) { self.parent = parent }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let url = webView.url { parent.onNavigate?(url) }
        }
    }
}
```

## StoreKit 2（内购 / 订阅）
```swift
import StoreKit

// 加载商品
let products = try await Product.products(for: ["com.app.pro.monthly"])

// 购买
let result = try await products.first?.purchase()
switch result {
case .success(let verification):
    let transaction = try verification.payloadValue
    await transaction.finish()
case .userCancelled, .pending: break
default: break
}

// 验证当前权益
for await result in Transaction.currentEntitlements {
    if case .verified(let transaction) = result {
        // 激活对应功能
        print("Entitled: \(transaction.productID)")
    }
}

// 监听交易更新
for await result in Transaction.updates {
    if case .verified(let transaction) = result {
        await transaction.finish()
    }
}

// 恢复购买
try await AppStore.sync()
```

## URLSession（现代网络请求）
```swift
// async/await 方式（推荐）
func fetchData<T: Decodable>(from url: URL, as type: T.Type) async throws -> T {
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw URLError(.badServerResponse)
    }
    return try JSONDecoder().decode(T.self, from: data)
}

// 带进度的下载
private lazy var session: URLSession = {
    let config = URLSessionConfiguration.default
    config.waitsForConnectivity = true
    return URLSession(configuration: config, delegate: self, delegateQueue: nil)
}()

// 后台下载
let bgConfig = URLSessionConfiguration.background(withIdentifier: "com.app.download")
bgConfig.sessionSendsLaunchEvents = true
let bgSession = URLSession(configuration: bgConfig, delegate: self, delegateQueue: nil)
```

## CoreLocation + MapKit
```swift
// CoreLocation（async 方式，iOS 17+）
@MainActor class LocationManager: ObservableObject {
    @Published var location: CLLocation?
    private let manager = CLLocationManager()

    func start() {
        manager.requestWhenInUseAuthorization()
        Task {
            for try await update in CLLocationUpdate.liveUpdates() {
                location = update.location
            }
        }
    }
}

// SwiftUI Map
import MapKit
struct MapView: View {
    var body: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.9, longitude: 116.4),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )))
    }
}
```

## 性能优化（Xcode 26）
```swift
// LazyVStack：仅在 100+ 元素且 profiling 证明需要时使用
ScrollView {
    LazyVStack {
        ForEach(largeData) { item in ItemRow(item: item) }
    }
}

// 提取子 View（SwiftUI 细粒度更新）
struct ItemRow: View {
    let item: Item  // let 防止不必要更新
    var body: some View {
        HStack {
            Text(item.title)
            Spacer()
            Text(item.timestamp, style: .relative)
        }
    }
}

// .task 替代 onAppear
.task { data = await fetchData() }
.refreshable { data = await fetchData() }

// Actor（线程安全缓存）
actor DataCache {
    private var cache: [String: Data] = [:]
    func get(_ key: String) -> Data? { cache[key] }
    func set(_ key: String, value: Data) { cache[key] = value }
}
```

**Xcode 26 SwiftUI Performance Instrument**：打开 Instruments → SwiftUI 模板 → 查看 View Body Updates 和 Timeline，定位频繁重绘。

## UIKit 互操作
```swift
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ p: CameraView) { self.parent = p }
        func imagePickerController(_ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true)
        }
    }
}
```

## SwiftUI 新特性（iOS 26 / WWDC25）
```swift
// WebView（原生，无需 UIViewRepresentable）
WebView(url: URL(string: "https://developer.apple.com")!)

// Rich TextEditor
@State private var text = AttributedString("Hello **SwiftUI**!")
RichTextEditor($text).padding()

// Section Index Titles
List { ... }.sectionIndexTitles(sections.map(\.title))

// visionOS Spatial Layout
WindowGroup { ContentView() }.windowStyle(.volumetric)
ImmersiveSpace(id: "main") { ImmersiveView() }
```

## Xcode 工具
**DocC 注释**：
```swift
/// 简短描述。
///
/// 详细说明。
/// - Parameters:
///   - input: 输入说明
/// - Returns: 返回值说明
/// - Throws: 错误类型
func process(_ input: String) throws -> Result
```

**Xcode Cloud**：在 Xcode → Product → Xcode Cloud 配置 CI/CD 工作流（Build / Test / Archive），支持 PR 触发、多设备测试、TestFlight 自动分发。

## 测试（Swift Testing 完整指南）

### 基础断言
```swift
import Testing
@testable import MyApp

@Test("创建 Item 默认值正确")
func itemDefaults() {
    let item = Item(title: "Test")
    #expect(item.isCompleted == false)
    #expect(!item.id.isEmpty)
}

// #require：失败立即终止（unwrap Optional）
@Test func loadConfig() throws {
    let config = try #require(Config.load("app.json"))  // nil 则抛错终止
    #expect(config.version >= 2)
}

// async 测试
@Test func fetchData() async throws {
    let data = try await DataService().fetch(url: testURL)
    #expect(!data.isEmpty)
}
```

### @Suite 测试套件
```swift
@Suite("购物车测试")
struct ShoppingCartTests {
    var cart: ShoppingCart  // 每个 @Test 前自动调用 init

    init() {
        cart = ShoppingCart()
        cart.add(Item(name: "Apple", price: 1.5))
    }

    @Test func totalIsCorrect() {
        #expect(cart.total == 1.5)
    }

    @Test func addMultipleItems() {
        cart.add(Item(name: "Banana", price: 2.0))
        #expect(cart.items.count == 2)
        #expect(cart.total == 3.5)
    }
}
```

### 参数化测试（多组输入）
```swift
// 单参数
@Test(arguments: ["Swift", "SwiftUI", "Xcode"])
func titleNotEmpty(title: String) {
    #expect(!Item(title: title).title.isEmpty)
}

// 多参数笛卡尔积
@Test(arguments: [1, 2, 3], ["a", "b"])
func combo(number: Int, letter: String) {
    #expect(!"\(number)\(letter)".isEmpty)
}

// zip 配对（非笛卡尔积）
@Test(arguments: zip([1, 2, 3], ["one", "two", "three"]))
func paired(number: Int, word: String) {
    #expect(!word.isEmpty)
}

// 枚举参数
enum Theme: CaseIterable { case light, dark, auto }
@Test(arguments: Theme.allCases)
func themeApplies(theme: Theme) {
    let view = ThemedView(theme: theme)
    #expect(view.isValid)
}
```

### 测试标签（Tag）与过滤
```swift
extension Tag {
    @Tag static var critical: Self
    @Tag static var network: Self
    @Tag static var slow: Self
}

@Test(.tags(.critical))
func paymentProcessing() { /* ... */ }

@Test(.tags(.network, .slow))
func uploadLargeFile() async throws { /* ... */ }

@Suite(.tags(.critical))  // 套件内所有测试继承标签
struct PaymentTests { /* ... */ }

// 命令行过滤：swift test --filter tag:critical
```

### Exit Tests（验证致命错误）
```swift
@Test func divisionByZeroTraps() async {
    await #expect(exitsWith: .failure) {
        _ = divide(10, by: 0)  // 预期 fatalError / preconditionFailure
    }
}

@Test func exitCodeValidation() async {
    await #expect(exitsWith: .exitCode(1)) {
        exit(1)
    }
}
```

### withKnownIssue（已知问题标记）
```swift
@Test func featureUnderDevelopment() {
    withKnownIssue("服务端 API 尚未就绪") {
        let result = try api.fetchNewEndpoint()
        #expect(result.isValid)
    }  // 失败不标红，通过反而提醒移除标记
}

// 条件性已知问题
@Test(arguments: Platform.allCases)
func crossPlatform(platform: Platform) {
    withKnownIssue("visionOS 暂不支持", isIntermittent: false) {
        #expect(feature.isSupported(on: platform))
    } when: {
        platform == .visionOS  // 仅 visionOS 标记为已知问题
    }
}
```

### 测试 Traits（条件 & 运行控制）
```swift
// 条件启用/禁用
@Test(.enabled(if: ProcessInfo.processInfo.environment["CI"] != nil))
func ciOnlyTest() { /* 仅 CI 运行 */ }

@Test(.disabled("等待 #123 修复"))
func blockedByBug() { /* 跳过 */ }

// 超时控制
@Test(.timeLimit(.minutes(2)))
func longRunningTest() async throws { /* ... */ }

// Bug 关联
@Test(.bug("https://github.com/org/repo/issues/42", "购物车总价计算"))
func cartTotalWithDiscount() { /* ... */ }
```

### Attachments（测试附件）
```swift
@Test func imageProcessingOutput() throws {
    let processed = try processImage(input)
    let data = try JSONEncoder().encode(processed.metadata)
    // 测试失败时自动收集附件用于调试
    Attachment(data, named: "processed_metadata.json", contentType: .json)
    #expect(processed.width == 800)
}
```

### 并行 & 串行控制
```swift
@Suite(.serialized)  // 套件内测试串行执行（共享资源时）
struct DatabaseTests {
    @Test func insert() { /* ... */ }
    @Test func query() { /* ... */ }  // 等 insert 完成后执行
}

// 默认：所有 @Test 并行执行（Swift Testing 默认行为）
```

### XCTest 互操作
```swift
// Swift Testing 和 XCTest 可在同一 target 共存
// XCTest 用于：UI 测试（XCUITest）、性能基准（measure）
// Swift Testing 用于：单元测试、集成测试（推荐新代码使用）

// XCTest 性能测试
class PerformanceTests: XCTestCase {
    func testSortPerformance() {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = largeArray.sorted()
        }
    }
}
```


## AVFoundation（音视频完整指南）

### 视频播放（Observation 框架，iOS 26）
```swift
import AVKit

// 全局开启 Observation 支持（必须在创建播放器之前）
AVPlayer.isObservationEnabled = true

struct PlayerView: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                TransportControls(player: player)
            } else { ProgressView() }
        }
        .task { player = AVPlayer(url: url) }  // 延迟创建
    }
}

// 直接在 SwiftUI 中观察播放状态（无需 KVO）
struct TransportControls: View {
    let player: AVPlayer
    private var isPlaying: Bool { player.timeControlStatus == .playing }
    var body: some View {
        Button {
            isPlaying ? player.pause() : player.play()
        } label: {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
        }
        .disabled(player.currentItem?.status != .readyToPlay)
    }
}
```

### 播放进度监控
```swift
// 周期性时间观察（驱动进度条 UI）
let interval = CMTime(value: 1, timescale: 2)  // 每 0.5 秒
timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
    self?.currentTime = time.seconds
    self?.duration = player.currentItem?.duration.seconds ?? 0
}

// 边界时间观察（里程碑事件）
let times = quarterTimes.map { NSValue(time: $0) }
timeObserver = player.addBoundaryTimeObserver(forTimes: times, queue: .main) {
    updateQuarterProgress()
}

// 必须配对移除
player.removeTimeObserver(timeObserver)

// Seeking
await player.seek(to: CMTime(seconds: 30, preferredTimescale: 600))
// 精确 seeking（帧级精度）
await player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
```

### 相机拍摄完整架构（AVCam 模式）
```swift
import AVFoundation

// CaptureService 用 actor 隔离，确保不阻塞主线程
actor CaptureService {
    let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var activeVideoInput: AVCaptureDeviceInput?

    // 设备查找
    private func defaultCamera() throws -> AVCaptureDevice {
        if let dual = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) { return dual }
        if let wide = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) { return wide }
        throw CameraError.noDevice
    }

    func setUp() throws {
        let camera = try defaultCamera()
        let videoInput = try AVCaptureDeviceInput(device: camera)
        let audioDevice = AVCaptureDevice.default(for: .audio)
        let audioInput = audioDevice.flatMap { try? AVCaptureDeviceInput(device: $0) }

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        captureSession.sessionPreset = .photo
        if captureSession.canAddInput(videoInput) { captureSession.addInput(videoInput) }
        if let audioInput, captureSession.canAddInput(audioInput) { captureSession.addInput(audioInput) }
        if captureSession.canAddOutput(photoOutput) { captureSession.addOutput(photoOutput) }
        activeVideoInput = videoInput
    }

    // 切换前后摄像头
    func switchCamera(to device: AVCaptureDevice) throws {
        guard let current = activeVideoInput else { return }
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        captureSession.removeInput(current)
        let newInput = try AVCaptureDeviceInput(device: device)
        if captureSession.canAddInput(newInput) {
            captureSession.addInput(newInput)
            activeVideoInput = newInput
        } else {
            captureSession.addInput(current)  // 失败时恢复
        }
    }

    // 切换拍照/录像模式
    func setCaptureMode(_ mode: CaptureMode) throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        switch mode {
        case .photo:
            captureSession.sessionPreset = .photo
            captureSession.removeOutput(movieOutput)
        case .video:
            captureSession.sessionPreset = .high
            if captureSession.canAddOutput(movieOutput) { captureSession.addOutput(movieOutput) }
        }
    }
}

// 相机权限
var isAuthorized: Bool {
    get async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        var authorized = status == .authorized
        if status == .notDetermined { authorized = await AVCaptureDevice.requestAccess(for: .video) }
        return authorized
    }
}

// SwiftUI 预览层（AVCaptureVideoPreviewLayer）
class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    func setSession(_ session: AVCaptureSession) { previewLayer.session = session }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> PreviewView {
        let preview = PreviewView()
        preview.setSession(session)
        return preview
    }
    func updateUIView(_ view: PreviewView, context: Context) {}
}
```

### 照片捕获（Depth / Live Photo / RAW）
```swift
// 带深度数据的照片
let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
photoSettings.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
photoOutput.capturePhoto(with: photoSettings, delegate: captureDelegate)

// 深度数据在 delegate 中获取
func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    if let depthData = photo.depthData {
        let depthMap = depthData.depthDataMap  // CVPixelBuffer
    }
    if let photoData = photo.fileDataRepresentation() {
        saveToPhotosLibrary(photoData)  // 自动嵌入深度数据
    }
}

// Live Photo 拍摄（需要音频输入 + livePhotoMovieFileURL）
photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
let liveSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
liveSettings.livePhotoMovieFileURL = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).mov")
photoOutput.capturePhoto(with: liveSettings, delegate: delegate)

// 保存 Live Photo 到相册（静态图 + 配对视频）
PHPhotoLibrary.shared().performChanges {
    let request = PHAssetCreationRequest.forAsset()
    request.addResource(with: .photo, data: stillImageData, options: nil)
    let options = PHAssetResourceCreationOptions()
    options.shouldMoveFile = true
    request.addResource(with: .pairedVideo, fileURL: movieURL, options: options)
}

// Apple ProRAW 拍摄
photoOutput.isAppleProRAWEnabled = photoOutput.isAppleProRAWSupported
let rawFormat = photoOutput.availableRawPhotoPixelFormatTypes.first {
    AVCapturePhotoOutput.isAppleProRAWPixelFormat($0)
}!
let rawSettings = AVCapturePhotoSettings(rawPixelFormatType: rawFormat,
    processedFormat: [AVVideoCodecKey: AVVideoCodecType.hevc])
// photo.fileDataRepresentation() 返回 DNG 格式数据

// 包围曝光（Bracketed Capture）
let exposureValues: [Float] = [-2, 0, +2]
let bracketSettings = exposureValues.map {
    AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(exposureTargetBias: $0)
}
let bracketPhotoSettings = AVCapturePhotoBracketSettings(rawPixelFormatType: 0,
    processedFormat: [AVVideoCodecKey: AVVideoCodecType.hevc], bracketedSettings: bracketSettings)
bracketPhotoSettings.isLensStabilizationEnabled = photoOutput.isLensStabilizationDuringBracketedCaptureSupported
```

### LiDAR 深度相机
```swift
// 检查 LiDAR 支持（iPhone 12 Pro+）
guard let device = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) else { return }

// 查找支持深度的格式
guard let format = device.formats.last(where: {
    $0.formatDescription.dimensions.width == 1920 &&
    !$0.isVideoBinned && !$0.supportedDepthDataFormats.isEmpty
}), let depthFormat = format.supportedDepthDataFormats.last(where: {
    CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_DepthFloat16
}) else { return }

try device.lockForConfiguration()
device.activeFormat = format
device.activeDepthDataFormat = depthFormat
device.unlockForConfiguration()

// 同步视频 + 深度输出
let videoOutput = AVCaptureVideoDataOutput()
let depthOutput = AVCaptureDepthDataOutput()
depthOutput.isFilteringEnabled = true
session.addOutput(videoOutput)
session.addOutput(depthOutput)

let synchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [videoOutput, depthOutput])
synchronizer.setDelegate(self, queue: videoQueue)

// 同步回调
func dataOutputSynchronizer(_ sync: AVCaptureDataOutputSynchronizer,
                            didOutput collection: AVCaptureSynchronizedDataCollection) {
    guard let syncedDepth = collection.synchronizedData(for: depthOutput) as? AVCaptureSynchronizedDepthData,
          let syncedVideo = collection.synchronizedData(for: videoOutput) as? AVCaptureSynchronizedSampleBufferData
    else { return }
    let depthMap = syncedDepth.depthData.depthDataMap  // CVPixelBuffer，每像素距离（米）
    let videoBuffer = syncedVideo.sampleBuffer.imageBuffer!
}
```

### Camera Control（iPhone 16 硬件按钮）
```swift
// 系统预设控件
let zoomSlider = AVCaptureSystemZoomSlider(device: device) { zoomFactor in
    let displayZoom = device.displayVideoZoomFactorMultiplier * zoomFactor
}
let biasSlider = AVCaptureSystemExposureBiasSlider(device: device)

// 自定义控件
let focusSlider = AVCaptureSlider("Focus", symbolName: "scope", in: 0...1)
focusSlider.setActionQueue(sessionQueue) { lensPosition in
    try? device.lockForConfiguration()
    device.setFocusModeLocked(lensPosition: lensPosition)
    device.unlockForConfiguration()
}

let filterPicker = AVCaptureIndexPicker("Filters", symbolName: "camera.filters",
    localizedIndexTitles: filters.map(\.localizedTitle))

// 添加到 Capture Session
guard captureSession.supportsControls else { return }
captureSession.beginConfiguration()
for control in [zoomSlider, biasSlider, focusSlider, filterPicker] {
    if captureSession.canAddControl(control) { captureSession.addControl(control) }
}
captureSession.commitConfiguration()

// 代理响应控件激活
extension CaptureService: AVCaptureSessionControlsDelegate {
    func sessionControlsDidBecomeActive(_ session: AVCaptureSession) { }
    func sessionControlsWillEnterFullscreenAppearance(_ session: AVCaptureSession) { /* 隐藏 UI */ }
    func sessionControlsWillExitFullscreenAppearance(_ session: AVCaptureSession) { /* 恢复 UI */ }
    func sessionControlsDidBecomeInactive(_ session: AVCaptureSession) { }
}
```

### Smart Framing（iPhone 17，智能构图）
```swift
// 查找支持 Smart Framing 的设备
let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera], mediaType: .video, position: .front)
guard let device = session.devices.first,
      let format = device.formats.first(where: \.isSmartFramingSupported) else { return }
try device.lockForConfiguration()
device.activeFormat = format
device.unlockForConfiguration()

// 配置并启动监控
guard let monitor = device.smartFramingMonitor else { return }
monitor.enabledFramings = monitor.supportedFramings

framingObservation = monitor.observe(\.recommendedFraming, options: [.new]) { monitor, _ in
    guard let framing = monitor.recommendedFraming else { return }
    Task { await applyFraming(framing) }
}
try monitor.startMonitoring()

// 应用推荐构图（先设宽高比，再设缩放）
func applyFraming(_ framing: AVCaptureFraming) async {
    try? device.lockForConfiguration()
    try? await device.setDynamicAspectRatio(framing.aspectRatio)
    device.videoZoomFactor = CGFloat(framing.zoomFactor)
    device.unlockForConfiguration()
}
```

### 空间 / 3D 视频（MV-HEVC）
```swift
// 检查立体视频轨道
let track = try await asset.loadTracks(withMediaCharacteristic: .containsStereoMultiviewVideo).first

// 读取 MV-HEVC 的左右眼图像
let output = AVAssetReaderTrackOutput(track: track!, outputSettings: nil)
reader.add(output)
reader.startReading()
while let sampleBuffer = output.copyNextSampleBuffer() {
    guard let taggedBuffers = sampleBuffer.taggedBuffers else { continue }
    for taggedBuffer in taggedBuffers {
        if case .pixelBuffer(let buffer) = taggedBuffer.buffer {
            if taggedBuffer.tags.contains(.stereoView(.leftEye)) { /* 左眼 */ }
            if taggedBuffer.tags.contains(.stereoView(.rightEye)) { /* 右眼 */ }
        }
    }
}

// Side-by-Side → MV-HEVC 转码
let compressionProps: [CFString: Any] = [
    kVTCompressionPropertyKey_MVHEVCVideoLayerIDs: [0, 1],
    kVTCompressionPropertyKey_MVHEVCViewIDs: [0, 1],
    kVTCompressionPropertyKey_MVHEVCLeftAndRightViewIDs: [0, 1],
    kVTCompressionPropertyKey_HasLeftStereoEyeView: true,
    kVTCompressionPropertyKey_HasRightStereoEyeView: true
]
let outputSettings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.hevc,
    AVVideoWidthKey: eyeWidth, AVVideoHeightKey: eyeHeight,
    AVVideoCompressionPropertiesKey: compressionProps
]
let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
let adaptor = AVAssetWriterInputTaggedPixelBufferGroupAdaptor(assetWriterInput: writerInput)

// 使用 VTPixelTransferSession 裁切左右眼并写入
let leftTags: [CMTag] = [.videoLayerID(0), .stereoView(.leftEye)]
let rightTags: [CMTag] = [.videoLayerID(1), .stereoView(.rightEye)]
let taggedBuffers = [CMTaggedBuffer(tags: leftTags, buffer: .pixelBuffer(leftBuffer)),
                     CMTaggedBuffer(tags: rightTags, buffer: .pixelBuffer(rightBuffer))]
adaptor.appendTaggedBuffers(taggedBuffers, withPresentationTime: pts)
```

### 文字转语音
```swift
let utterance = AVSpeechUtterance(string: "Hello, SwiftUI!")
utterance.rate = 0.57
utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
AVSpeechSynthesizer().speak(utterance)
```

## CoreML + Vision

### CoreML 推理
```swift
import CoreML

// 编译并缓存模型（下载后执行一次）
let compiledURL = try await MLModel.compileModel(at: downloadedModelURL)
let model = try MLModel(contentsOf: compiledURL)
let prediction = try model.prediction(from: input)
```

### Vision 文字识别（OCR）
```swift
import Vision

func recognizeText(in image: UIImage) async throws -> [String] {
    guard let cgImage = image.cgImage else { return [] }
    return try await withCheckedThrowingContinuation { continuation in
        let request = VNRecognizeTextRequest { req, error in
            if let error { continuation.resume(throwing: error); return }
            let strings = (req.results as? [VNRecognizedTextObservation] ?? [])
                .compactMap { $0.topCandidates(1).first?.string }
            continuation.resume(returning: strings)
        }
        request.recognitionLevel = .accurate
        try? VNImageRequestHandler(cgImage: cgImage).perform([request])
    }
}
```

### Vision 人脸检测
```swift
let request = VNDetectFaceRectanglesRequest { req, _ in
    guard let faces = req.results as? [VNFaceObservation] else { return }
    for face in faces {
        print("Face bounding box: \(face.boundingBox)")
    }
}
try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up).perform([request])
```

### Vision + CoreML（图像分类）
```swift
let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
let request = VNCoreMLRequest(model: visionModel) { req, _ in
    guard let results = req.results as? [VNRecognizedObjectObservation] else { return }
    let top = results.first?.labels.first
    print("\(top?.identifier ?? "unknown") (\(top?.confidence ?? 0))")
}
try VNImageRequestHandler(cgImage: cgImage).perform([request])
```

## ARKit
```swift
import ARKit
import RealityKit

// 基础世界追踪 + 平面检测
let config = ARWorldTrackingConfiguration()
config.planeDetection = [.horizontal, .vertical]
config.environmentTexturing = .automatic
arView.session.run(config)

// 协同 AR（多人共享空间）
config.isCollaborationEnabled = true
func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
    let encoded = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true)
    multipeerSession.sendToAllPeers(encoded, reliably: data.priority == .critical)
}

// 面部追踪（前置摄像头）
guard ARWorldTrackingConfiguration.supportsUserFaceTracking else { return }
var faceConfig = ARWorldTrackingConfiguration()
faceConfig.userFaceTrackingEnabled = true
// 读取混合形状（表情驱动）
let blendShapes = faceAnchor.blendShapes
let eyeBlink = blendShapes[.eyeBlinkLeft] as? Float ?? 0
```

## CoreImage（图像处理）
```swift
import CoreImage.CIFilterBuiltins

// CIContext 创建一次，全局复用（昂贵操作）
let ciContext = CIContext()

// 滤镜链（自动合并优化）
func applyFilters(to image: UIImage) -> UIImage? {
    guard let ciImage = CIImage(image: image) else { return nil }

    let sepia = CIFilter.sepiaTone()
    sepia.inputImage = ciImage
    sepia.intensity = 0.9

    let bloom = CIFilter.bloom()
    bloom.inputImage = sepia.outputImage
    bloom.intensity = 1.0
    bloom.radius = 10

    guard let output = bloom.outputImage,
          let cgImage = ciContext.createCGImage(output, from: output.extent) else { return nil }
    return UIImage(cgImage: cgImage)
}

// SwiftUI Canvas 自定义绘制
Canvas { context, size in
    context.fill(Path(ellipseIn: CGRect(origin: .zero, size: size)), with: .color(.blue))
    context.stroke(Path { p in p.move(to: .zero); p.addLine(to: CGPoint(x: size.width, y: size.height)) },
                   with: .color(.red), lineWidth: 2)
}
```

## SafariServices + OAuth
```swift
import SafariServices
import AuthenticationServices

// SFSafariViewController（保持用户 cookie/session）
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}

// ASWebAuthenticationSession（OAuth 登录）
func startOAuth() {
    let authURL = URL(string: "https://provider.com/oauth/authorize?client_id=xxx")!
    let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "myapp") { url, error in
        guard let url else { return }
        // 从 url 提取 code，换取 token
    }
    session.presentationContextProvider = self
    session.prefersEphemeralWebBrowserSession = true
    session.start()
}
```

## EventKit（日历 / 提醒）
```swift
import EventKit

let eventStore = EKEventStore()

// iOS 17+ 三种权限级别
func requestCalendarAccess() async throws {
    // 写入权限（低打扰）
    try await eventStore.requestWriteOnlyAccessToEvents()
}

// 创建事件
func createEvent(title: String, start: Date, end: Date) throws {
    let event = EKEvent(eventStore: eventStore)
    event.calendar = eventStore.defaultCalendarForNewEvents
    event.title = title
    event.startDate = start
    event.endDate = end
    try eventStore.save(event, span: .thisEvent)
}

// 监听日历变更
for await _ in NotificationCenter.default.notifications(named: .EKEventStoreChanged) {
    // 重新获取事件
}
```

## Contacts（通讯录）
```swift
import Contacts
import ContactsUI

// iOS 18+ ContactAccessButton（无需完整权限）
ContactAccessButton(queryString: searchText) { identifiers in
    // 用户选择的联系人 identifier
}

// 获取联系人
func fetchContacts() throws -> [CNContact] {
    let store = CNContactStore()
    let request = CNContactFetchRequest(keysToFetch: [
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor
    ] as [CNKeyDescriptor])
    var contacts: [CNContact] = []
    try store.enumerateContacts(with: request) { contact, _ in contacts.append(contact) }
    return contacts
}
```

## Network（连接监控）
```swift
import Network

// 网络状态监控
let monitor = NWPathMonitor()
monitor.pathUpdateHandler = { path in
    DispatchQueue.main.async {
        let isConnected = path.status == .satisfied
        let isWifi = path.usesInterfaceType(.wifi)
        let isCellular = path.usesInterfaceType(.cellular)
    }
}
monitor.start(queue: .global(qos: .background))

// 不需要时取消
// monitor.cancel()
```

## BackgroundTasks
```swift
import BackgroundTasks

// 注册（在 App init 或 didFinishLaunching 中调用）
BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.app.refresh", using: nil) { task in
    guard let task = task as? BGAppRefreshTask else { return }
    Task {
        do {
            try await refreshContent()
            task.setTaskCompleted(success: true)
        } catch {
            task.setTaskCompleted(success: false)
        }
    }
    task.expirationHandler = { task.setTaskCompleted(success: false) }
}

// 调度刷新
func scheduleAppRefresh() throws {
    let request = BGAppRefreshTaskRequest(identifier: "com.app.refresh")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
    try BGTaskScheduler.shared.submit(request)
}

// 长任务（带进度显示）
let continuedRequest = BGContinuedProcessingTaskRequest(
    identifier: "com.app.export",
    title: "Exporting",
    subtitle: "Starting..."
)
try BGTaskScheduler.shared.submit(continuedRequest)

// Xcode 调试命令
// e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.app.refresh"]
```

## CoreData → SwiftData 迁移
```swift
// 共存：两个框架操作同一个 SQLite 文件
// CoreData 端：开启持久历史追踪
if let desc = container.persistentStoreDescriptions.first {
    desc.url = sharedStoreURL
    desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
}

// SwiftData 端：指向同一 URL
let modelConfig = ModelConfiguration(url: sharedStoreURL)
let modelContainer = try ModelContainer(for: Trip.self, configurations: modelConfig)

// 检测 Widget 写入的变更
func findWidgetTransactions(after token: DefaultHistoryToken?) -> [DefaultHistoryTransaction] {
    var desc = HistoryDescriptor<DefaultHistoryTransaction>()
    if let token { desc.token = token }
    desc.predicate = #Predicate { $0.author == "widget" }
    return (try? modelContext.fetchHistory(desc)) ?? []
}
```

## CreateML（训练本地模型）
```swift
import CreateML

// 图像分类器
let trainingData = try MLImageClassifier.DataSource.labeledImages(fromDirectory: trainURL)
let classifier = try MLImageClassifier(
    trainingData: trainingData,
    parameters: MLImageClassifier.ModelParameters(
        augmentationOptions: .all,
        algorithm: .transferLearning(.mobilenet)
    )
)
try classifier.write(to: outputURL, metadata: MLModelMetadata(author: "MyApp", version: "1.0"))

// 文本分类器
let textClassifier = try MLTextClassifier(
    trainingData: trainingData,
    textColumn: "text",
    labelColumn: "label",
    parameters: .init(algorithm: .transferLearning(.bertEmbedding, revision: 1), language: .english)
)
// 导出后在 App 中用 NLModel 包装使用
let nlModel = try NLModel(mlModel: textClassifier.model)
print(nlModel.predictedLabel(for: "This is great!") ?? "unknown")
```


## Foundation 常用模式

### @AppStorage / UserDefaults
```swift
// @AppStorage 自动绑定 UserDefaults
@AppStorage("username") var username = ""
@AppStorage("isDarkMode") var isDarkMode = false

// 手动访问
UserDefaults.standard.set(true, forKey: "onboarded")
let onboarded = UserDefaults.standard.bool(forKey: "onboarded")

// 注册默认值（App 启动时调用）
UserDefaults.standard.register(defaults: [
    "theme": "light",
    "fontSize": 16
])
```

### Keychain（安全存储凭证）
```swift
import Security

func saveToKeychain(key: String, value: String) {
    let data = value.data(using: .utf8)!
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecValueData as String: data,
        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
    ]
    SecItemDelete(query as CFDictionary)  // 先删除旧值
    SecItemAdd(query as CFDictionary, nil)
}

func loadFromKeychain(key: String) -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecReturnData as String: true
    ]
    var result: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
          let data = result as? Data else { return nil }
    return String(data: data, encoding: .utf8)
}
```

### Codable / JSONDecoder
```swift
struct User: Codable {
    let id: Int
    let name: String
    let email: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, email
        case createdAt = "created_at"  // 映射 snake_case
    }
}

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
decoder.keyDecodingStrategy = .convertFromSnakeCase  // 自动转换

let user = try decoder.decode(User.self, from: jsonData)

let encoder = JSONEncoder()
encoder.keyEncodingStrategy = .convertToSnakeCase
let data = try encoder.encode(user)
```

### FileManager
```swift
// 获取 Documents 目录
let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let fileURL = docs.appendingPathComponent("data.json")

// 写入 / 读取
try data.write(to: fileURL, options: .atomic)
let loaded = try Data(contentsOf: fileURL)

// APFS 零拷贝克隆
try FileManager.default.copyItem(at: sourceURL, to: destURL)

// 检查磁盘空间
let attributes = try FileManager.default.attributesOfFileSystem(forPath: docs.path)
let freeSpace = attributes[.systemFreeSize] as? Int64 ?? 0
```

## Accessibility（无障碍）
```swift
// 基础标签、值、提示
Image(systemName: "heart.fill")
    .accessibilityLabel("Favorite")
    .accessibilityAddTraits(.isButton)

Text("\(score)")
    .accessibilityLabel("Score: \(score)")
    .accessibilityValue("\(score) points")
    .accessibilityHint("Double tap to reset")

// 自定义操作
view.accessibilityAction(named: "Delete") { deleteItem() }

// 焦点管理（VoiceOver 自动聚焦）
@AccessibilityFocusState private var focused: Bool
Button("Submit") { focused = true }
    .accessibilityFocused($focused)

// 合并子视图（把卡片作为整体播报）
VStack { ... }.accessibilityElement(children: .combine)

// 动态字体支持（自动，无需额外代码）
Text("Title").font(.headline)  // 随系统字体大小缩放
```

## Custom Layout（Layout 协议）
```swift
struct RadialLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let radius = min(bounds.width, bounds.height) / 2
        let angle = (2 * Double.pi) / Double(subviews.count)
        for (index, subview) in subviews.enumerated() {
            let x = bounds.midX + radius * cos(Double(index) * angle)
            let y = bounds.midY + radius * sin(Double(index) * angle)
            subview.place(at: CGPoint(x: x, y: y), anchor: .center, proposal: .unspecified)
        }
    }
}

// 使用
RadialLayout {
    ForEach(items) { item in Circle().fill(item.color).frame(width: 30) }
}

// ViewThatFits：自动选择合适的布局变体
ViewThatFits {
    HStack { content }   // 优先尝试横排
    VStack { content }   // 不够宽则降级竖排
}
```

## 文档型 App（DocumentGroup）
```swift
import UniformTypeIdentifiers

extension UTType {
    static let myDocument = UTType(exportedAs: "com.example.mydoc")
}

struct MyDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.myDocument, .plainText] }
    var text: String = ""

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        .init(regularFileWithContents: Data(text.utf8))
    }
}

@main
struct WritingApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MyDocument()) { file in
            EditorView(document: file.$document)
        }
    }
}
```

## 多窗口 + 状态恢复
```swift
// 多窗口（iPad / macOS）
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }

        // 以数据值驱动的辅助窗口
        WindowGroup("Detail", for: Item.ID.self) { $id in
            DetailView(itemID: id)
        }
    }
}

// 打开辅助窗口
@Environment(\.openWindow) private var openWindow
Button("Open Detail") { openWindow(value: item.id) }

// @SceneStorage：每个 scene 独立持久化
@SceneStorage("selectedTab") private var selectedTab = 0
@SceneStorage("scrollPosition") private var position: String?

// Handoff / NSUserActivity
.userActivity("com.app.viewItem") { activity in
    activity.typedPayload = selectedItem
} onContinue: { activity in
    selectedItem = try? activity.typedPayload(Item.self)
}
```

## macOS 菜单命令（Commands）
```swift
// 定义命令
struct AppCommands: Commands {
    @FocusedValue(DataModel.self) private var model: DataModel?

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Message") { model?.addMessage() }
                .keyboardShortcut("m", modifiers: [.command, .shift])
                .disabled(model == nil)
        }
        CommandMenu("Tools") {
            Button("Export") { model?.export() }
            Divider()
            Toggle("Show Inspector", isOn: $showInspector)
        }
    }
}

// 注册到 App
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup { ContentView().focusedSceneValue(dataModel) }
            .commands { AppCommands() }
    }
}
```

## Passkeys（无密码登录）
```swift
import AuthenticationServices

// 注册 Passkey
func registerPasskey(for username: String, challengeData: Data) {
    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
        relyingPartyIdentifier: "example.com"
    )
    let request = provider.createCredentialRegistrationRequest(
        clientDataHash: challengeData,
        name: username,
        userID: Data(username.utf8)
    )
    let controller = ASAuthorizationController(authorizationRequests: [request])
    controller.delegate = self
    controller.performRequests()
}

// 验证 Passkey
func authenticateWithPasskey(challengeData: Data) {
    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
        relyingPartyIdentifier: "example.com"
    )
    let assertionRequest = provider.createCredentialAssertionRequest(
        clientDataHash: challengeData
    )
    let controller = ASAuthorizationController(authorizationRequests: [assertionRequest])
    controller.delegate = self
    controller.performRequests()
}

// 委托回调
func authorizationController(controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization) {
    if let credential = authorization.credential
        as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
        // 发送 credential.rawAuthenticatorData 到服务器验证
    }
}
```

## 本地化（Localization）
```swift
// 推荐：String(localized:) 带 comment
let title = String(localized: "Welcome", comment: "App welcome screen title")

// SwiftUI 自动识别 LocalizedStringKey
Text("Add Item")  // 自动查找 Localizable.strings

// 数字 / 货币 / 日期格式化（自动本地化）
Text(price.formatted(.currency(code: "USD")))
Text(date.formatted(.dateTime.year().month().day()))
Text(count.formatted(.number))

// 复数规则（.stringsdict 或内联 inflection）
Button("Add ^[\(count) item](inflect: true)") { }
// 中文：需在 Localizable.stringsdict 配置 NSStringLocalizedFormatKey

// 支持从右到左（RTL）布局
// SwiftUI 自动处理，避免使用 .leading/.trailing，改用 .leading（语义化）
HStack { ... }  // 自动翻转 RTL
```

## SpriteKit（2D 游戏）
```swift
import SpriteKit
import SwiftUI

class GameScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.gravity = CGVector(dx: 0, dy: -5)

        let sprite = SKSpriteNode(imageNamed: "player")
        sprite.position = CGPoint(x: frame.midX, y: frame.midY)
        sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        sprite.physicsBody?.isDynamic = true
        addChild(sprite)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let moveAction = SKAction.move(to: location, duration: 0.5)
        children.first?.run(moveAction)
    }

    override func update(_ currentTime: TimeInterval) { /* 每帧逻辑 */ }
}

// 在 SwiftUI 中嵌入
struct GameView: View {
    var scene: SKScene {
        let s = GameScene()
        s.scaleMode = .resizeFill
        return s
    }
    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
    }
}
```


## SwiftUI 进阶模式

### @Bindable（iOS 17+，Observable 模型绑定）
```swift
@Observable class Recipe {
    var name = ""
    var rating = 0
}

struct RecipeEditor: View {
    @Bindable var recipe: Recipe   // 直接投射 $binding
    var body: some View {
        TextField("Name", text: $recipe.name)
        Stepper("Rating: \(recipe.rating)", value: $recipe.rating, in: 0...5)
    }
}
```

### AnyLayout（运行时切换布局，带动画）
```swift
let layout = isGrid ? AnyLayout(HStackLayout()) : AnyLayout(VStackLayout())

layout {
    ForEach(items) { item in ItemView(item: item) }
}
.animation(.default, value: isGrid)  // 布局切换自动动画
```

### KeyframeAnimator（多轨道关键帧动画）
```swift
struct AnimationValues {
    var scale = 1.0
    var yOffset = 0.0
    var angle = Angle.zero
}

Text("🎉")
    .keyframeAnimator(initialValue: AnimationValues(), trigger: trigger) { content, value in
        content
            .scaleEffect(value.scale)
            .offset(y: value.yOffset)
            .rotationEffect(value.angle)
    } keyframes: { _ in
        KeyframeTrack(\.scale) {
            SpringKeyframe(1.5, duration: 0.4, spring: .bouncy)
            SpringKeyframe(1.0, spring: .bouncy)
        }
        KeyframeTrack(\.yOffset) {
            LinearKeyframe(-60, duration: 0.2)
            SpringKeyframe(0, duration: 0.6, spring: .bouncy)
        }
        KeyframeTrack(\.angle) {
            LinearKeyframe(.degrees(15), duration: 0.2)
            SpringKeyframe(.zero, spring: .bouncy)
        }
    }
```

### AsyncImage（异步加载远程图片）
```swift
AsyncImage(url: URL(string: "https://example.com/photo.jpg")) { phase in
    switch phase {
    case .empty: ProgressView()
    case .success(let image):
        image.resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 200, height: 200)
            .clipped()
    case .failure: Image(systemName: "photo").foregroundStyle(.secondary)
    @unknown default: EmptyView()
    }
}

// 图片缩放模式
Image("photo")
    .resizable()
    .aspectRatio(contentMode: .fit)    // 完整显示，可能留白
    .frame(width: 300, height: 200)

Image("photo")
    .resizable()
    .aspectRatio(contentMode: .fill)   // 填满，可能裁切
    .frame(width: 300, height: 200)
    .clipped()                          // 必须加 clipped 防溢出
```

### onChange（监听值变化）
```swift
@State private var searchText = ""

TextField("Search", text: $searchText)
    .onChange(of: searchText) { oldValue, newValue in   // iOS 17+ 双参数
        filterResults(query: newValue)
    }
```

### PreferenceKey（子视图向父视图传数据）
```swift
struct HeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// 子视图上报高度
ChildView()
    .background(GeometryReader { geo in
        Color.clear.preference(key: HeightKey.self, value: geo.size.height)
    })

// 父视图接收
.onPreferenceChange(HeightKey.self) { height in
    containerHeight = height
}
```

### Table（macOS / iPadOS 多列表格）
```swift
@State private var sortOrder = [KeyPathComparator(\Person.name)]

Table(people, selection: $selectedID, sortOrder: $sortOrder) {
    TableColumn("Name", value: \.name)
    TableColumn("Age", value: \.age) { Text("\($0.age)") }
    TableColumn("Email", value: \.email)
}
.onChange(of: sortOrder) { _, newOrder in
    people.sort(using: newOrder)
}
```

### AttributedString（富文本渲染）
```swift
var styled: AttributedString {
    var str = AttributedString("Welcome to ")
    var bold = AttributedString("SwiftUI")
    bold.font = .body.bold()
    bold.foregroundColor = .blue
    str += bold
    return str
}

Text(styled).textSelection(.enabled)
```

## WebKit JS 桥接（双向通信）
```swift
import WebKit

struct WebBridgeView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "nativeHandler")
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.load(URLRequest(url: URL(string: "https://example.com")!))
        return webView
    }
    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, WKScriptMessageHandler {
        // JS 调用 Swift：window.webkit.messageHandlers.nativeHandler.postMessage("hello")
        func userContentController(_ controller: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            print("From JS: \(message.body)")
        }
    }
}

// Swift 调用 JS
webView.evaluateJavaScript("document.title") { result, error in
    if let title = result as? String { print(title) }
}
```

## HealthKit 进阶查询

### HKStatisticsQuery（聚合统计）
```swift
let stepsType = HKQuantityType(.stepCount)
let today = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: .now), end: .now)

let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: today, options: .cumulativeSum) {
    _, stats, _ in
    let totalSteps = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
    DispatchQueue.main.async { self.steps = Int(totalSteps) }
}
healthStore.execute(query)
```

### HKAnchoredObjectQuery（增量同步，iOS 17+ Descriptor）
```swift
let descriptor = HKAnchoredObjectQueryDescriptor(
    predicates: [.quantitySample(type: HKQuantityType(.heartRate))],
    anchor: savedAnchor
)
let results = try await descriptor.result(for: healthStore)
let newSamples = results.addedSamples      // 新增样本
let deletedObjects = results.deletedObjects // 已删除
let newAnchor = results.newAnchor           // 保存用于下次增量
```

### 临床记录（FHIR，需 Clinical Health Records 权限）
```swift
let allergyType = HKObjectType.clinicalType(forIdentifier: .allergyRecord)!
let query = HKSampleQuery(sampleType: allergyType, predicate: nil, limit: 100, sortDescriptors: nil) {
    _, samples, _ in
    let records = samples as? [HKClinicalRecord] ?? []
    for record in records {
        if let fhir = record.fhirResource {
            let json = try? JSONSerialization.jsonObject(with: fhir.data) as? [String: Any]
            // 解析 FHIR Condition / Medication / Procedure
        }
    }
}
healthStore.execute(query)
```

## CloudKit 订阅 + 批量操作

### CKSubscription（远程变更推送通知）
```swift
let subscription = CKQuerySubscription(
    recordType: "TodoItem",
    predicate: NSPredicate(value: true),
    subscriptionID: "all-todos",
    options: [.firesOnRecordCreation, .firesOnRecordUpdate]
)
let info = CKSubscription.NotificationInfo()
info.shouldSendContentAvailable = true   // 静默推送触发后台刷新
subscription.notificationInfo = info
try await database.save(subscription)
```

### CKQueryOperation（游标分页）
```swift
let query = CKQuery(recordType: "Item", predicate: NSPredicate(value: true))
let operation = CKQueryOperation(query: query)
operation.resultsLimit = 50

var allRecords: [CKRecord] = []
operation.recordMatchedBlock = { _, result in
    if case .success(let record) = result { allRecords.append(record) }
}
operation.queryResultBlock = { result in
    if case .success(let cursor) = result, let cursor {
        // 还有更多数据，用 cursor 继续查询
        let nextOp = CKQueryOperation(cursor: cursor)
        // ... 递归或循环
    }
}
database.add(operation)
```


## Modal 弹出（Sheet / FullScreenCover / Alert / Popover）
```swift
@State private var showSheet = false
@State private var showAlert = false

// Sheet（半屏）
Button("Show Sheet") { showSheet = true }
    .sheet(isPresented: $showSheet) {
        DetailView()
            .presentationDetents([.medium, .large])   // 可拖拽高度
            .presentationDragIndicator(.visible)
    }

// FullScreenCover（全屏）
.fullScreenCover(isPresented: $showFull) { FullView() }

// Alert
Button("Delete") { showAlert = true }
    .alert("Are you sure?", isPresented: $showAlert) {
        Button("Delete", role: .destructive) { delete() }
        Button("Cancel", role: .cancel) { }
    } message: {
        Text("This action cannot be undone.")
    }

// Confirmation Dialog（操作表）
.confirmationDialog("Options", isPresented: $showOptions) {
    Button("Share") { }
    Button("Delete", role: .destructive) { }
}

// Popover（iPad / Mac 弹出气泡）
.popover(isPresented: $showPopover, arrowEdge: .top) {
    Text("Popover content").padding()
}
```

## NavigationSplitView（iPad / Mac 分栏导航）
```swift
@State private var selectedCategory: Category?
@State private var selectedItem: Item?

NavigationSplitView {
    List(categories, selection: $selectedCategory) { category in
        Label(category.name, systemImage: category.icon)
    }
    .navigationTitle("Categories")
} content: {
    if let category = selectedCategory {
        List(category.items, selection: $selectedItem) { item in
            Text(item.title)
        }
    }
} detail: {
    if let item = selectedItem {
        DetailView(item: item)
    } else {
        ContentUnavailableView("Select an Item", systemImage: "tray")
    }
}
.navigationSplitViewStyle(.balanced)
```

## ContentUnavailableView（空状态）
```swift
// 系统预设搜索空状态
ContentUnavailableView.search(text: searchText)

// 自定义空状态
ContentUnavailableView {
    Label("No Items", systemImage: "tray")
} description: {
    Text("Add items to get started.")
} actions: {
    Button("Add Item") { addItem() }
}
```

## Swift Charts（数据可视化）
```swift
import Charts

struct SalesData: Identifiable {
    let id = UUID()
    let month: String
    let revenue: Double
}

struct SalesChart: View {
    let data: [SalesData]
    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Month", item.month),
                y: .value("Revenue", item.revenue)
            )
            .foregroundStyle(.blue.gradient)
        }
        .chartYAxis { AxisMarks(preset: .aligned) }
        .frame(height: 200)
    }
}

// 折线图
Chart(data) { item in
    LineMark(x: .value("Month", item.month), y: .value("Revenue", item.revenue))
        .interpolationMethod(.catmullRom)
    AreaMark(x: .value("Month", item.month), y: .value("Revenue", item.revenue))
        .foregroundStyle(.blue.opacity(0.1))
}
```

## PhotosPicker（照片选择器）
```swift
import PhotosUI

@State private var selectedPhoto: PhotosPickerItem?
@State private var image: Image?

PhotosPicker("Select Photo", selection: $selectedPhoto, matching: .images)
    .onChange(of: selectedPhoto) { _, newItem in
        Task {
            if let data = try? await newItem?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                image = Image(uiImage: uiImage)
            }
        }
    }

// 多选
@State private var selectedPhotos: [PhotosPickerItem] = []
PhotosPicker("Select Photos", selection: $selectedPhotos, maxSelectionCount: 5, matching: .images)
```

## ShareLink（系统分享）
```swift
ShareLink(item: URL(string: "https://example.com")!) {
    Label("Share", systemImage: "square.and.arrow.up")
}

// 自定义 Transferable
ShareLink(item: myDocument, preview: SharePreview(myDocument.title, image: myDocument.thumbnail))
```

## TipKit（上下文提示）
```swift
import TipKit

struct FavoriteTip: Tip {
    var title: Text { Text("Save as Favorite") }
    var message: Text? { Text("Tap the heart to save this item.") }
    var image: Image? { Image(systemName: "heart") }
}

struct ItemView: View {
    let tip = FavoriteTip()
    var body: some View {
        Button { } label: { Image(systemName: "heart") }
            .popoverTip(tip)          // 气泡提示
        // 或 TipView(tip)            // 内联提示
    }
}

// App 入口配置
@main
struct MyApp: App {
    init() { try? Tips.configure() }
}
```

## LazyVGrid / LazyHGrid（网格布局）
```swift
let columns = [
    GridItem(.adaptive(minimum: 100)),  // 自适应列数
]

LazyVGrid(columns: columns, spacing: 16) {
    ForEach(items) { item in
        ItemCard(item: item)
    }
}

// 固定列
let fixedColumns = [
    GridItem(.fixed(120)),
    GridItem(.fixed(120)),
    GridItem(.flexible()),
]
```

## Shape / Path / Gradient（自定义绘图）
```swift
// 自定义形状
struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            // 绘制五角星路径...
            path.move(to: CGPoint(x: center.x, y: rect.minY))
            // ...
        }
    }
}

Star().fill(.yellow).frame(width: 100, height: 100)

// 渐变
LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
RadialGradient(colors: [.white, .black], center: .center, startRadius: 0, endRadius: 100)
AngularGradient(colors: [.red, .yellow, .green, .blue, .red], center: .center)
```

## EnvironmentKey 自定义环境值
```swift
// 定义
struct ThemeKey: EnvironmentKey {
    static var defaultValue: Theme = .light
}
extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// Swift 6 简写（@Entry 宏）
extension EnvironmentValues {
    @Entry var appAccentColor: Color = .blue
}

// 注入
ContentView().environment(\.theme, .dark)

// 读取
@Environment(\.theme) private var theme
```

## OSLog / Logger（结构化日志）
```swift
import os

let logger = Logger(subsystem: "com.app.myapp", category: "networking")

logger.info("Request started: \(url.absoluteString)")
logger.debug("Response: \(data.count) bytes")
logger.error("Failed: \(error.localizedDescription, privacy: .public)")
logger.fault("Critical failure")   // 最高级别

// 在 Instruments 中用 os_signpost 追踪性能区间
let signposter = OSSignposter(logger: logger)
let state = signposter.beginInterval("loadData")
// ... 执行操作
signposter.endInterval("loadData", state)
```

## Live Activities（ActivityKit 实时活动）
```swift
import ActivityKit

// 定义 Attributes
struct DeliveryAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String
        var estimatedArrival: Date
    }
    var orderNumber: String
}

// 启动 Live Activity
let attributes = DeliveryAttributes(orderNumber: "12345")
let state = DeliveryAttributes.ContentState(status: "On the way", estimatedArrival: .now.addingTimeInterval(1800))
let activity = try Activity.request(attributes: attributes, content: .init(state: state, staleDate: nil))

// 更新
let newState = DeliveryAttributes.ContentState(status: "Delivered", estimatedArrival: .now)
await activity.update(.init(state: newState, staleDate: nil))

// 结束
await activity.end(.init(state: newState, staleDate: nil), dismissalPolicy: .after(.now + 3600))
```

## TimelineView（定时刷新 View）
```swift
// 每秒刷新（时钟等场景）
TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
    Text(timeline.date.formatted(.dateTime.hour().minute().second()))
        .font(.largeTitle.monospacedDigit())
}
```


## Deep Link / Universal Links
```swift
// URL Scheme（自定义协议）
// Info.plist: CFBundleURLSchemes = ["myapp"]
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in   // myapp://item/123
                    if let id = parseItemID(from: url) { navigate(to: id) }
                }
        }
    }
}

// Universal Links（HTTPS 域名关联）
// apple-app-site-association 文件放在域名 /.well-known/ 下
// {"applinks":{"apps":[],"details":[{"appIDs":["TEAMID.com.app.id"],"paths":["/item/*"]}]}}

// 打开外部 URL
@Environment(\.openURL) private var openURL
Button("Open Website") { openURL(URL(string: "https://example.com")!) }
```

## App 发布必备

### Privacy Manifest（PrivacyInfo.xcprivacy，App Store 强制）
```xml
<!-- 声明使用的隐私 API 和数据类型 -->
<dict>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array><string>CA92.1</string></array>
        </dict>
    </array>
    <key>NSPrivacyCollectedDataTypes</key>
    <array><!-- 声明收集的数据类型 --></array>
</dict>
```

### App Tracking Transparency（IDFA 追踪授权）
```swift
import AppTrackingTransparency

func requestTrackingPermission() {
    ATTrackingManager.requestTrackingAuthorization { status in
        switch status {
        case .authorized: print("Tracking allowed")
        case .denied, .restricted: print("Tracking denied")
        case .notDetermined: break
        @unknown default: break
        }
    }
}
// Info.plist 必须添加 NSUserTrackingUsageDescription
```

### In-App Review（请求评分）
```swift
import StoreKit
@Environment(\.requestReview) private var requestReview

// 在合适时机触发（用户完成关键操作后）
requestReview()
// 系统自动限制弹出频率，无需手动节流
```

### Info.plist 常用配置
```xml
NSCameraUsageDescription        <!-- 相机权限说明 -->
NSMicrophoneUsageDescription    <!-- 麦克风 -->
NSLocationWhenInUseUsageDescription  <!-- 位置 -->
NSPhotoLibraryUsageDescription  <!-- 相册 -->
NSHealthShareUsageDescription   <!-- HealthKit 读取 -->
NSFaceIDUsageDescription        <!-- Face ID -->
NSUserTrackingUsageDescription  <!-- 追踪 -->
UIBackgroundModes               <!-- 后台模式 -->
```

## App Groups + iCloud KV Store
```swift
// App Groups（App / Widget / Extension 共享数据）
let sharedDefaults = UserDefaults(suiteName: "group.com.app.shared")
sharedDefaults?.set("value", forKey: "key")

// 共享文件目录
let groupURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.com.app.shared"
)!

// iCloud Key-Value Store（跨设备小数据同步，限 1MB）
let kvStore = NSUbiquitousKeyValueStore.default
kvStore.set("value", forKey: "key")
kvStore.synchronize()
// 监听远程变更
NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
    object: kvStore, queue: .main) { _ in /* 刷新 UI */ }
```

## Spotlight 索引（CoreSpotlight）
```swift
import CoreSpotlight
import MobileCoreServices

// 索引内容
let item = CSSearchableItem(
    uniqueIdentifier: "item-\(id)",
    domainIdentifier: "com.app.items",
    attributeSet: {
        let attrs = CSSearchableItemAttributeSet(contentType: .text)
        attrs.title = "My Item"
        attrs.contentDescription = "Description"
        attrs.thumbnailData = thumbnailData
        return attrs
    }()
)
CSSearchableIndex.default().indexSearchableItems([item])

// 处理点击搜索结果
.onContinueUserActivity(CSSearchableItemActionType) { activity in
    if let id = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
        navigate(to: id)
    }
}
```

## Home Screen Quick Actions
```swift
// Info.plist 静态快捷方式
// UIApplicationShortcutItems: [{UIApplicationShortcutItemType: "newItem", UIApplicationShortcutItemTitle: "New Item", UIApplicationShortcutItemIconType: "UIApplicationShortcutIconTypeAdd"}]

// 动态快捷方式
UIApplication.shared.shortcutItems = [
    UIApplicationShortcutItem(type: "search", localizedTitle: "Search", localizedSubtitle: nil,
        icon: UIApplicationShortcutIcon(systemImageName: "magnifyingglass"))
]

// 处理
.onContinueUserActivity("newItem") { _ in showNewItem = true }
```

## Widget 进阶（WidgetFamily / Dynamic Island / Lock Screen）
```swift
import WidgetKit

struct MyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "myWidget", provider: MyProvider()) { entry in
            MyWidgetView(entry: entry)
        }
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,    // 主屏幕
            .accessoryCircular, .accessoryRectangular,    // Lock Screen
            .accessoryInline                               // Lock Screen 单行
        ])
    }
}

// 根据 family 适配布局
@Environment(\.widgetFamily) var family
switch family {
case .systemSmall: CompactView()
case .accessoryCircular: Gauge(value: progress) { Image(systemName: "bolt") }
default: FullView()
}
```

## Extensions（扩展类型）
```swift
// Share Extension：接收系统分享内容
// 新建 Target → Share Extension，在 SLComposeServiceViewController 中处理

// Notification Service Extension：修改推送内容（加密解密、附件下载）
class NotificationService: UNNotificationServiceExtension {
    override func didReceive(_ request: UNNotificationRequest,
        withContentHandler handler: @escaping (UNNotificationContent) -> Void) {
        let content = request.content.mutableCopy() as! UNMutableNotificationContent
        content.title = "Modified: \(content.title)"
        // 下载附件、解密内容等
        handler(content)
    }
}
```

## 常用修饰符速查
```swift
// List 样式
.listStyle(.plain)              // 或 .insetGrouped, .sidebar, .grouped
.listRowBackground(Color.clear) // 自定义行背景
.listRowSeparator(.hidden)      // 隐藏分隔线

// 外观
.preferredColorScheme(.dark)    // 强制深色
.tint(.orange)                  // 控件着色
.foregroundStyle(.secondary)    // 文字层级
.labelStyle(.titleAndIcon)      // Label 样式
.toggleStyle(.switch)           // Toggle 样式
.buttonStyle(.borderedProminent)

// 布局
.fixedSize()                    // 不压缩内容
.fixedSize(horizontal: false, vertical: true)  // 仅垂直不压缩
.layoutPriority(1)              // 布局优先级

// 视觉
.blur(radius: 10)               // 模糊
.shadow(color: .black.opacity(0.2), radius: 8, y: 4)
.rotation3DEffect(.degrees(15), axis: (x: 1, y: 0, z: 0))
.mask { LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom) }
.compositingGroup()             // 合并子视图后再应用效果
.drawingGroup()                 // Metal 加速渲染（大量图层时）

// 交互
.disabled(isLoading)
.allowsHitTesting(false)        // 穿透点击
.opacity(isVisible ? 1 : 0)
.hidden()                       // 隐藏但保留空间

// 编辑
@Environment(\.editMode) private var editMode
EditButton()                    // 切换编辑模式
@Environment(\.undoManager) private var undoManager
undoManager?.registerUndo(withTarget: self) { $0.undo() }

// 搜索增强
.searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
.searchSuggestions {
    ForEach(suggestions) { s in Text(s.title).searchCompletion(s.query) }
}
.searchScopes($scope) {
    Text("All").tag(SearchScope.all)
    Text("Recent").tag(SearchScope.recent)
}

// 多平台条件编译
#if os(iOS)
// iPhone / iPad
#elseif os(macOS)
// Mac
#elseif os(watchOS)
// Apple Watch
#elseif os(tvOS)
// Apple TV
#elseif os(visionOS)
// Vision Pro
#endif
```


## 常用控件速查

### 表单控件
```swift
Form {
    Section("Account") {
        TextField("Username", text: $username)
            .textContentType(.username)
            .onSubmit { login() }              // 键盘回车触发
            .submitLabel(.done)                 // 回车键文字

        SecureField("Password", text: $password)
            .textContentType(.password)

        DatePicker("Birthday", selection: $date, displayedComponents: .date)
        MultiDatePicker("Dates", selection: $dates)

        ColorPicker("Theme", selection: $color, supportsOpacity: false)

        Stepper("Quantity: \(qty)", value: $qty, in: 1...99)

        Picker("Language", selection: $lang) {
            Text("English").tag("en")
            Text("中文").tag("zh")
        }
        .pickerStyle(.menu)   // 或 .segmented, .wheel, .navigationLink

        Toggle("Notifications", isOn: $notifyOn)
        Slider(value: $volume, in: 0...1) { Text("Volume") }

        LabeledContent("Version", value: "2.1.0")
    }

    Section("Status") {
        Gauge(value: progress) { Text("Progress") }
            .gaugeStyle(.accessoryCircular)
        ProgressView(value: 0.7)
    }
}
```

### ZStack / overlay
```swift
ZStack(alignment: .bottomTrailing) {
    Image("photo").resizable().scaledToFill()
    Text("Badge").padding(6).background(.red).clipShape(Capsule())
}

// overlay 等效写法
Image("photo")
    .overlay(alignment: .bottomTrailing) {
        Text("Badge").padding(6).background(.red).clipShape(Capsule())
    }
```

### ToolbarItem
```swift
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button("Save", action: save)
    }
    ToolbarItem(placement: .cancellationAction) {
        Button("Cancel", role: .cancel) { dismiss() }
    }
    ToolbarItemGroup(placement: .bottomBar) {
        Spacer()
        Text("\(items.count) items")
        Spacer()
    }
    ToolbarItem(placement: .keyboard) {
        Button("Done") { focusedField = nil }  // 键盘上方按钮
    }
}
```

### ContextMenu + swipeActions
```swift
// 长按菜单
Text(item.title)
    .contextMenu {
        Button("Copy", systemImage: "doc.on.doc") { copy(item) }
        Button("Delete", systemImage: "trash", role: .destructive) { delete(item) }
    } preview: {
        ItemPreview(item: item)   // 自定义预览
    }

// 列表滑动操作
List {
    ForEach(items) { item in
        Text(item.title)
            .swipeActions(edge: .trailing) {
                Button("Delete", role: .destructive) { delete(item) }
                Button("Archive") { archive(item) }.tint(.orange)
            }
            .swipeActions(edge: .leading) {
                Button("Pin") { pin(item) }.tint(.yellow)
            }
    }
}
```

### ScrollViewReader + scrollTo
```swift
ScrollViewReader { proxy in
    ScrollView {
        LazyVStack {
            ForEach(messages) { msg in
                MessageRow(msg).id(msg.id)
            }
        }
    }
    .onChange(of: messages.count) { _, _ in
        withAnimation {
            proxy.scrollTo(messages.last?.id, anchor: .bottom)
        }
    }
}

// iOS 17+ scrollPosition
@State private var scrollPosition: Int?
ScrollView {
    LazyVStack { ForEach(0..<100) { i in Text("Item \(i)").id(i) } }
}
.scrollPosition(id: $scrollPosition)
.scrollTargetBehavior(.viewAligned)   // 吸附对齐
.scrollTargetLayout()                  // 配合使用
```

### GeometryReader
```swift
GeometryReader { proxy in    // proxy: GeometryProxy
    let width = proxy.size.width
    let height = proxy.size.height
    let safeTop = proxy.safeAreaInsets.top

    HStack(spacing: 0) {
        Color.red.frame(width: width * 0.3)
        Color.blue.frame(width: width * 0.7)
    }
}
```

### DisclosureGroup / OutlineGroup / GroupBox
```swift
// 折叠展开
DisclosureGroup("Advanced Settings") {
    Toggle("Debug Mode", isOn: $debug)
}

// 多级树形结构
OutlineGroup(data, children: \.children) { item in
    Text(item.name)
}

// 带标题的分组框
GroupBox("Statistics") {
    LabeledContent("Total", value: "\(total)")
    LabeledContent("Average", value: "\(average)")
}
```

## @FocusState + 文件导入导出
```swift
// 焦点管理
enum Field: Hashable { case email, password }
@FocusState private var focusedField: Field?

TextField("Email", text: $email)
    .focused($focusedField, equals: .email)
SecureField("Password", text: $password)
    .focused($focusedField, equals: .password)
Button("Login") { focusedField = nil }  // 收起键盘

// 文件导入
.fileImporter(isPresented: $showImporter, allowedContentTypes: [.json, .plainText]) { result in
    switch result {
    case .success(let url):
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        let data = try Data(contentsOf: url)
    case .failure(let error): print(error)
    }
}

// 文件导出
.fileExporter(isPresented: $showExporter, document: myDoc, contentType: .json) { result in
    // handle result
}
```

## SF Symbols 效果 + 触觉反馈
```swift
// symbolEffect 动画
Image(systemName: "wifi")
    .symbolEffect(.variableColor.iterative)      // 循环变色
Image(systemName: "arrow.down.circle")
    .symbolEffect(.bounce, value: downloadCount)  // 值变化时弹跳
Image(systemName: "heart.fill")
    .symbolRenderingMode(.multicolor)              // 多色渲染
    .contentTransition(.symbolEffect(.replace))    // 符号切换动画

// 触觉反馈（iOS 17+）
Button("Tap") { action() }
    .sensoryFeedback(.impact(weight: .medium), trigger: tapCount)
// 可选：.success, .warning, .error, .selection, .impact, .increase, .decrease
```

## 隐私 + Sheet 控制 + 安全区域
```swift
// 敏感内容遮盖
Text(bankBalance)
    .privacySensitive()        // 锁屏 Widget 自动遮盖
    .redacted(reason: .placeholder)  // 占位效果（加载中）

// 禁止下拉关闭 Sheet
.sheet(isPresented: $show) {
    EditView()
        .interactiveDismissDisabled(hasUnsavedChanges)
}

// 安全区域扩展
.safeAreaInset(edge: .bottom) {
    HStack { Button("Save") { } }.padding().background(.bar)
}
.safeAreaPadding(.horizontal, 20)

// 容器相对尺寸（iOS 17+）
Image("photo")
    .containerRelativeFrame(.horizontal) { length, _ in length * 0.8 }
```

## ImageRenderer（View 导出为图片）
```swift
let renderer = ImageRenderer(content: MyChartView())
renderer.scale = UIScreen.main.scale   // Retina 适配
if let uiImage = renderer.uiImage {
    UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
}
// 也支持导出 PDF
if let data = renderer.render { _, renderer in renderer.addPages() } { }
```

## MapKit 标注
```swift
import MapKit

Map {
    Marker("Apple Park", coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090))
        .tint(.red)
    Annotation("Custom", coordinate: coord) {
        Image(systemName: "star.fill").foregroundStyle(.yellow)
            .padding(6).background(.blue).clipShape(Circle())
    }
    MapPolyline(coordinates: routeCoords).stroke(.blue, lineWidth: 3)
}
.mapStyle(.standard(elevation: .realistic))
```

## Swift 并发进阶
```swift
// async let 并行
async let profile = fetchProfile()
async let posts = fetchPosts()
async let friends = fetchFriends()
let (p, ps, f) = try await (profile, posts, friends)  // 并行等待

// TaskGroup
let results = try await withThrowingTaskGroup(of: Data.self) { group in
    for url in urls {
        group.addTask { try await URLSession.shared.data(from: url).0 }
    }
    var allData: [Data] = []
    for try await data in group { allData.append(data) }
    return allData
}

// Continuation 桥接回调
func fetchLegacy() async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
        legacyAPI { result, error in
            if let error { continuation.resume(throwing: error) }
            else { continuation.resume(returning: result!) }
        }
    }
}

// Sendable + nonisolated
struct UserData: Sendable { let name: String }   // 值类型自动 Sendable

actor DataStore {
    var items: [Item] = []
    nonisolated var description: String { "DataStore" }  // 无需 await
}

// 自定义 GlobalActor
@globalActor actor DatabaseActor: GlobalActor {
    static let shared = DatabaseActor()
}
@DatabaseActor func saveToDatabase() { }
```


## SwiftData 进阶（iOS 26 扩展文档）

### Model 继承（iOS 26+）
```swift
@Model class Trip {
    @Attribute(.preserveValueOnDeletion)   // 删除时保留审计记录
    var name: String
    var destination: String
    @Relationship(deleteRule: .cascade, inverse: \BucketListItem.trip)
    var bucketList: [BucketListItem] = []
}

@available(iOS 26, *)
@Model class BusinessTrip: Trip {
    var expenseCode: String
    var perDiemRate: Double
    @Relationship(deleteRule: .cascade, inverse: \DailyMileageRecord.trip)
    var milesDriven: [DailyMileageRecord] = []
}

@available(iOS 26, *)
@Model class PersonalTrip: Trip {
    enum Reason: String, Codable { case family, wellness, reunion }
    var reason: Reason
}

// 基类查询返回所有子类；类型过滤用 #Predicate
@Query var allTrips: [Trip]                     // 包含 Business + Personal
let bizOnly = allTrips.filter { $0 is BusinessTrip }
```

### Undo/Redo 支持
```swift
// App 入口一行启用
.modelContainer(for: Item.self, isUndoEnabled: true)
// 三指滑动自动支持撤销/重做，无需额外代码
```

### CloudKit iCloud 同步
```swift
let config = ModelConfiguration(
    cloudKitDatabase: .private("iCloud.com.example.MyApp")
)
let container = try ModelContainer(for: Trip.self, configurations: config)
// 自动双向同步到 iCloud，无需手动管理 CKRecord
```

## Control Widget（控制中心 / 锁屏 / Action 按钮）
```swift
import WidgetKit
import AppIntents

struct TimerToggle: ControlWidget {
    static let kind = "com.app.timerToggle"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: Self.kind, provider: TimerProvider()) { state in
            ControlWidgetToggle(state.name, isOn: state.isRunning, action: ToggleTimerIntent(timer: state.timer))
        }
        .displayName("Timer")
        .description("Start and stop a timer.")
    }
}

struct ToggleTimerIntent: SetValueIntent {
    static var title: LocalizedStringResource = "Toggle Timer"
    @Parameter(title: "Timer") var timer: TimerEntity
    @Parameter(title: "Running") var value: Bool
    func perform() async throws -> some IntentResult { .result() }
}
```

## App Intents 进阶（扩展文档）

### Entity 属性查询 + Spotlight 索引
```swift
struct LandmarkEntity: AppEntity, IndexedEntity {
    static var defaultQuery = LandmarkEntityQuery()

    @Property(title: "Name")
    var name: String

    // Spotlight 自动索引
    static func updateSpotlightIndex() {
        let entities = LandmarkDataManager.shared.landmarks.map { LandmarkEntity(landmark: $0) }
        CSSearchableIndex.default().indexAppEntities(entities)
    }
}

// 属性查询（Shortcuts 可用 "Find landmarks where name contains ..."）
struct LandmarkEntityQuery: EntityPropertyQuery {
    func entities(matching predicates: [NSPredicate]) async throws -> [LandmarkEntity] {
        // 根据谓词过滤
    }
}
```

### 参数消歧（多个匹配时让用户选择）
```swift
func perform() async throws -> some IntentResult {
    let matches = findMatches(for: location)
    if matches.count > 1 {
        throw $location.needsDisambiguationError(
            among: matches,
            dialog: "Which location did you mean?"
        )
    }
    return .result()
}
```

## UIKit Trait 注册（iOS 17+，替代 traitCollectionDidChange）
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    registerForTraitChanges([
        UITraitHorizontalSizeClass.self,
        UITraitVerticalSizeClass.self
    ]) { (self: Self, previous: UITraitCollection) in
        self.updateLayoutForCurrentTraitCollection()
    }
}
// 类型安全 + 无需手动比较 previousTraitCollection
```

## Vision 进阶（人脸质量评分 + 姿态角）
```swift
import Vision

// 人脸拍摄质量评分（0.0-1.0，综合光照/模糊/遮挡/角度）
let qualityRequest = VNDetectFaceCaptureQualityRequest()
let handler = VNImageRequestHandler(cgImage: cgImage)
try handler.perform([qualityRequest])
let quality = qualityRequest.results?.first?.faceCaptureQuality ?? 0  // 0.0-1.0

// 人脸姿态角（roll/pitch/yaw）
let poseRequest = VNDetectFaceRectanglesRequest()
try handler.perform([poseRequest])
if let face = poseRequest.results?.first {
    let roll = face.roll?.doubleValue ?? 0    // 头部倾斜
    let pitch = face.pitch?.doubleValue ?? 0  // 上下点头
    let yaw = face.yaw?.doubleValue ?? 0      // 左右转头
}
```

## ARKit 4K/HDR 视频捕获
```swift
// 4K 高清 AR 捕获
guard let hiResFormat = ARWorldTrackingConfiguration.recommendedVideoFormatFor4KResolution else { return }
var config = ARWorldTrackingConfiguration()
config.videoFormat = hiResFormat
config.videoHDRAllowed = true
arView.session.run(config)

// 随时捕获高分辨率帧
arView.session.captureHighResolutionFrame { frame, error in
    if let frame { saveHighResFrame(frame) }
}
```


## HLS 流媒体与离线下载
```swift
// 创建后台下载会话
let config = URLSessionConfiguration.background(withIdentifier: "com.app.hlsDownload")
let downloadSession = AVAssetDownloadURLSession(configuration: config, assetDownloadDelegate: self, delegateQueue: .main)

// 配置并启动下载任务
let asset = AVURLAsset(url: hlsURL)
let downloadConfig = AVAssetDownloadConfiguration(asset: asset, title: "My Video")
let qualifier = AVAssetVariantQualifier(predicate: NSPredicate(format: "peakBitRate > 265000"))
downloadConfig.primaryContentConfiguration.variantQualifiers = [qualifier]
let task = downloadSession.makeAssetDownloadTask(downloadConfiguration: downloadConfig)
task.resume()

// 监控下载进度
let observation = task.progress.observe(\.fractionCompleted) { progress, _ in
    print("Downloaded: \(progress.fractionCompleted * 100)%")
}

// 取消下载
task.cancel()

// 删除已下载内容
try FileManager.default.removeItem(at: localAssetURL)

// 播放已下载内容
let localAsset = AVURLAsset(url: localAssetURL)
let playerItem = AVPlayerItem(asset: localAsset)
player.replaceCurrentItem(with: playerItem)
```

## 视频导出与缩略图生成
```swift
// 视频格式转换（AVAssetExportSession）
guard await AVAssetExportSession.compatibility(ofExportPreset: AVAssetExportPresetHEVCHighestQuality,
    with: asset, outputFileType: .mov) else { return }
let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHEVCHighestQuality)!
exportSession.outputFileType = .mov
exportSession.outputURL = outputURL
await exportSession.export()

// 缩略图生成（AVAssetImageGenerator）
let generator = AVAssetImageGenerator(asset: asset)
generator.maximumSize = CGSize(width: 300, height: 0)  // 限制尺寸
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = CMTime(seconds: 2, preferredTimescale: 600)

// 单张
let (image, actualTime) = try await generator.image(at: .zero)

// 批量（异步序列）
let times: [CMTime] = [.zero, CMTime(seconds: 10, preferredTimescale: 600)]
for await result in generator.images(for: times) {
    switch result {
    case .success(_, let image, _): processImage(image)
    case .failure(_, let error): print(error)
    }
}

// 异步加载媒体属性（Swift 6 推荐方式）
let (duration, metadata) = try await asset.load(.duration, .metadata)
let audioTracks = try await asset.loadTracks(withMediaType: .audio)
```

## 协调播放（SharePlay / GroupActivities）
```swift
import GroupActivities

// 定义 Group Activity
struct MovieWatchingActivity: GroupActivity {
    let movie: Movie  // Codable
    var metadata: GroupActivityMetadata {
        var meta = GroupActivityMetadata()
        meta.type = .watchTogether
        meta.title = movie.title
        return meta
    }
}

// 发起共享
let activity = MovieWatchingActivity(movie: selectedMovie)
switch await activity.prepareForActivation() {
case .activationPreferred: _ = try await activity.activate()
case .activationDisabled: playLocally(selectedMovie)
case .cancelled: break
default: break
}

// 监听 Group Session
for await groupSession in MovieWatchingActivity.sessions() {
    groupSession.join()
    // 连接播放协调器
    player.playbackCoordinator.coordinateWithSession(groupSession)
    // 监听活动变化（其他参与者切换内容）
    for await activity in groupSession.$activity.values {
        enqueue(activity.movie)
    }
}

// 自定义播放暂停（不影响其他参与者）
extension AVCoordinatedPlaybackSuspension.Reason {
    static var whatHappened = Self(rawValue: "com.app.whatHappened")
}
let suspension = player.playbackCoordinator.beginSuspension(for: .whatHappened)
player.seek(to: player.currentTime() - CMTime(value: 10, timescale: 1))
player.rate = 2.0
DispatchQueue.main.asyncAfter(deadline: .now() + 10) { suspension.end() }
```

## 媒体元数据与字幕选择
```swift
// 加载元数据
for format in try await asset.load(.availableMetadataFormats) {
    let metadata = try await asset.loadMetadata(for: format)
    let titleItems = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierTitle)
    let title = titleItems.first?.stringValue
}

// 字幕 / 音轨选择
for characteristic in try await asset.load(.availableMediaCharacteristicsWithMediaSelectionOptions) {
    if let group = try await asset.loadMediaSelectionGroup(for: characteristic) {
        for option in group.options { print("\(option.displayName)") }
        // 选择西班牙语字幕
        let locale = Locale(identifier: "es-ES")
        if let option = AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: locale).first {
            playerItem.select(option, in: group)
        }
    }
}

// 章节标记
let languages = Locale.preferredLanguages
let chapters = try await asset.loadChapterMetadataGroups(bestMatchingPreferredLanguages: languages)
for chapter in chapters {
    let title = AVMetadataItem.metadataItems(from: chapter.items, filteredByIdentifier: .commonIdentifierTitle).first?.stringValue
    let timeRange = chapter.timeRange  // 章节时间范围
}
```

## 视频色彩管理
```swift
// 写入时指定色彩空间（HD Rec. 709）
let colorProps = [
    AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
    AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
    AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2
]
let outputSettings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: 1920, AVVideoHeightKey: 1080,
    AVVideoColorPropertiesKey: colorProps
]

// 视频合成色彩空间
let videoComposition = AVMutableVideoComposition()
videoComposition.colorPrimaries = AVVideoColorPrimaries_P3_D65        // P3 宽色域
videoComposition.colorTransferFunction = AVVideoTransferFunction_ITU_R_709_2
videoComposition.colorYCbCrMatrix = AVVideoYCbCrMatrix_ITU_R_709_2

// 检测宽色域视频
let wideGamutTracks = try await asset.loadTracks(withMediaCharacteristic: .usesWideGamutColorSpace)
if !wideGamutTracks.isEmpty { /* 使用宽色域处理 */ }

// 像素缓冲区色彩标记
CVBufferSetAttachment(pixelBuffer, kCVImageBufferColorPrimariesKey, kCVImageBufferColorPrimaries_P3_D65, .shouldPropagate)
CVBufferSetAttachment(pixelBuffer, kCVImageBufferTransferFunctionKey, kCVImageBufferTransferFunction_ITU_R_709_2, .shouldPropagate)
```

## 相机滤镜（Core Image / Metal GPU 渲染）
```swift
// 方式 1：Core Image 滤镜（简单，自动 GPU 加速）
let ciContext = CIContext()
let rosyFilter = CIFilter(name: "CIColorMatrix")!
rosyFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")  // 移除绿色

func applyFilter(to sampleBuffer: CMSampleBuffer) -> CIImage? {
    guard let pixelBuffer = sampleBuffer.imageBuffer else { return nil }
    let input = CIImage(cvPixelBuffer: pixelBuffer)
    rosyFilter.setValue(input, forKey: kCIInputImageKey)
    return rosyFilter.outputImage
}

// 方式 2：Metal Compute Shader（更灵活，完全 GPU 控制）
// RosyEffect.metal:
// kernel void rosyEffect(texture2d<half, access::read> input [[texture(0)]],
//                        texture2d<half, access::write> output [[texture(1)]],
//                        uint2 gid [[thread_position_in_grid]]) {
//     half4 color = input.read(gid);
//     output.write(half4(color.r, 0.0, color.b, 1.0), gid);  // 移除绿色
// }

// 深度 → 灰度可视化（LiDAR / TrueDepth）
func depthToGrayscale(depthBuffer: CVPixelBuffer, cutoff: Float) {
    CVPixelBufferLockBaseAddress(depthBuffer, [])
    let width = CVPixelBufferGetWidth(depthBuffer)
    let height = CVPixelBufferGetHeight(depthBuffer)
    for y in 0..<height {
        let row = CVPixelBufferGetBaseAddress(depthBuffer)! + y * CVPixelBufferGetBytesPerRow(depthBuffer)
        let data = UnsafeMutableBufferPointer<Float32>(start: row.assumingMemoryBound(to: Float32.self), count: width)
        for x in 0..<width {
            data[x] = (data[x] > 0 && data[x] <= cutoff) ? 1.0 : 0.0  // 前景 1，背景 0
        }
    }
    CVPixelBufferUnlockBaseAddress(depthBuffer, [])
}

// 背景替换（CIBlendWithMask）
let alphaMatte = depthMaskImage.clampedToExtent()
    .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 5])
    .applyingFilter("CIGammaAdjust", parameters: ["inputPower": 0.5])
    .cropped(to: depthMaskImage.extent)
let output = videoImage.applyingFilter("CIBlendWithMask",
    parameters: ["inputMaskImage": alphaMatte, "inputBackgroundImage": backgroundImage])
```

## 音频会话配置（AirPlay / 后台播放）
```swift
// 配置音频会话（播放 App 必须）
let session = AVAudioSession.sharedInstance()
try session.setCategory(.playback, mode: .moviePlayback)  // 电影播放
try session.setActive(true)
// 需要 Background Modes → Audio, AirPlay, and Picture in Picture

// AirPlay 配置
try session.setCategory(.playback, mode: .default, policy: .longFormAudio)
// 使用 AVRoutePickerView 或 RoutePickerButton 展示 AirPlay 设备选择器

// Continuity Camera（iPhone 作为 Mac 摄像头）
let discoverySession = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.builtInWideAngleCamera, .externalUnknown],  // .externalUnknown 发现 iPhone
    mediaType: .video, position: .unspecified)
// 自动相机选择
let preferredDevice = AVCaptureDevice.systemPreferredCamera
// 用户偏好持久化
AVCaptureDevice.userPreferredCamera = selectedDevice
```

## AVAudioEngine + AVAudioSession（音频处理）
```swift
import AVFoundation

// 配置音频会话
let audioSession = AVAudioSession.sharedInstance()
try audioSession.setCategory(.playback, mode: .default, policy: .longFormAudio)
try audioSession.setActive(true)

// AVAudioEngine（低延迟音频处理/播放）
let engine = AVAudioEngine()
let playerNode = AVAudioPlayerNode()
engine.attach(playerNode)
engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
try engine.start()

let audioFile = try AVAudioFile(forReading: fileURL)
playerNode.scheduleFile(audioFile, at: nil)
playerNode.play()

// 空间音频（visionOS / AirPods）
try audioSession.setCategory(.playback, mode: .moviePlayback,
    options: [.allowAirPlay, .allowBluetooth])
// visionOS 自动支持空间音频，头部追踪通过 AVAudioSession 配置
```

## 视频编辑（AVMutableComposition + AVAssetWriter）
```swift
import AVFoundation

// 合并多段视频
let composition = AVMutableComposition()
let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!

let asset = AVAsset(url: videoURL)
let assetVideoTrack = try await asset.loadTracks(withMediaType: .video).first!
let duration = try await asset.load(.duration)
try videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: assetVideoTrack, at: .zero)

// AVAssetWriter 自定义输出
let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
let videoSettings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.hevc,
    AVVideoWidthKey: 1920,
    AVVideoHeightKey: 1080
]
let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
writer.add(writerInput)
writer.startWriting()
writer.startSession(atSourceTime: .zero)
```

## Metal / ShaderLibrary（GPU 加速渲染）
```swift
// SwiftUI visualEffect 修饰符（iOS 17+）
Text("Hello")
    .visualEffect { content, proxy in
        content.colorEffect(ShaderLibrary.rainbow(.float(proxy.size.width)))
    }

// SwiftUI + Metal Shader
let shader = ShaderLibrary.myShader(.float(time), .float2(size))
Rectangle()
    .colorEffect(shader)       // 颜色变换
    .distortionEffect(shader)  // 形变效果
    .layerEffect(shader)       // 图层效果

// drawingGroup（Metal 加速复杂视图合成）
VStack { /* 大量图层 */ }
    .drawingGroup()   // 离屏渲染后合成，提升性能
```

## visionOS 手部/平面/场景追踪
```swift
import ARKit

// 手部追踪（visionOS）
let handTracking = HandTrackingProvider()
let session = ARKitSession()
try await session.run([handTracking])
for await update in handTracking.anchorUpdates {
    let hand = update.anchor
    if let indexTip = hand.skeleton.joint(.indexFingerTip) {
        let position = indexTip.anchorFromJointTransform
    }
}

// 平面检测
let planeDetection = PlaneDetectionProvider(alignments: [.horizontal, .vertical])
try await session.run([planeDetection])
for await update in planeDetection.anchorUpdates {
    let plane = update.anchor
    let extent = plane.geometry.extent  // 平面大小
}

// 场景重建（网格）
let sceneReconstruction = SceneReconstructionProvider()
try await session.run([sceneReconstruction])

// 世界追踪
let worldTracking = WorldTrackingProvider()
try await session.run([worldTracking])
```

## RealityKit 物理 + 碰撞
```swift
import RealityKit

// 添加物理体
let entity = ModelEntity(mesh: .generateSphere(radius: 0.1))
entity.components[PhysicsBodyComponent.self] = PhysicsBodyComponent(
    massProperties: .default,
    material: .generate(friction: 0.5, restitution: 0.8),
    mode: .dynamic
)
entity.components[CollisionComponent.self] = CollisionComponent(
    shapes: [.generateSphere(radius: 0.1)]
)

// 施加力/速度
entity.components[PhysicsMotionComponent.self] = PhysicsMotionComponent(
    linearVelocity: [0, 2, 0]   // 向上发射
)

// AnchorEntity（空间锚定）
let anchor = AnchorEntity(.plane(.horizontal, classification: .floor, minimumBounds: [0.5, 0.5]))
anchor.addChild(entity)
arView.scene.addAnchor(anchor)
```

## HKWorkout（运动追踪）
```swift
import HealthKit

// 开始运动会话（watchOS）
let config = HKWorkoutConfiguration()
config.activityType = .running
config.locationType = .outdoor

let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
let builder = session.associatedWorkoutBuilder()
builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)

session.startActivity(with: .now)
try await builder.beginCollection(at: .now)

// 结束运动
session.end()
try await builder.endCollection(at: .now)
let workout = try await builder.finishWorkout()

// 添加运动样本
let energySample = HKQuantitySample(type: .quantityType(forIdentifier: .activeEnergyBurned)!,
    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: 300),
    start: startDate, end: endDate)
try await builder.add([energySample])
```

## Apple Pencil 交互
```swift
// 悬停检测（iPad Pro + Apple Pencil 2）
Rectangle()
    .onPencilHover { phase, location, altitude in
        // phase: .began, .changed, .ended
        // altitude: 笔尖倾斜角度
        hoverLocation = location
    }

// Pencil 双击手势（切换工具）
@Environment(\.pencilPreferredAction) private var preferredAction

// PencilKit 绘图
import PencilKit
struct DrawingView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
        canvasView.drawingPolicy = .anyInput
        return canvasView
    }
    func updateUIView(_ view: PKCanvasView, context: Context) {}
}
```

## App Clip
```swift
// App Clip 入口（轻量版 App，<15MB）
@main
struct MyAppClip: App {
    var body: some Scene {
        WindowGroup {
            AppClipView()
                .appStoreOverlay(isPresented: $showOverlay) {
                    SKOverlay.AppClipConfiguration(position: .bottom)
                }
        }
    }
}

// 处理 App Clip URL
.onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
    guard let url = activity.webpageURL else { return }
    handleAppClipURL(url)
}

// 配置：Xcode → Target → App Clip → Associated Domains
// 需要在 apple-app-site-association 中配置 appclips 字段
```

## Xcode 调试（Debugging 完整指南）

### Runtime Sanitizers（运行时检测工具）
```
Scheme → Edit Scheme → Run/Test → Diagnostics 中开启：

Address Sanitizer (ASan)    → 检测内存越界、use-after-free、栈溢出
  -fsanitize=address (clang) / -sanitize=address (swiftc)
  内存 2-3x，速度 2-5x 减慢；不检测泄漏和未初始化内存

Thread Sanitizer (TSan)     → 检测数据竞争、未初始化锁、线程泄漏
  -fsanitize=thread (clang) / -sanitize=thread (swiftc)
  仅 Simulator + 64 位 macOS；内存 5-10x，速度 2-20x 减慢

Main Thread Checker         → 检测非主线程调用 UI API（默认开启）
  性能影响极小（CPU 1-2%），启动增加 <100ms
  修复：DispatchQueue.main.async { self.label.text = "..." }

Undefined Behavior (UBSan)  → 除零、对齐错误、NULL 解引用、整数溢出
  -fsanitize=undefined (clang)
  仅 C 系语言；平均 20% CPU 开销
```

### 断点（Breakpoints）
```swift
// 条件断点：Control-click 断点 → Edit Breakpoint
// Condition: item.count > 100     // 仅满足条件时暂停
// Ignore: 50                       // 忽略前 50 次命中

// 符号断点（Breakpoint Navigator → + → Symbolic Breakpoint）
// Symbol: UIViewAlertForUnsatisfiableConstraints
// 用于定位 Auto Layout 问题：po [[UIWindow keyWindow] _autolayoutTrace]

// Swift Error 断点：捕获 throw 位置而非 try! 崩溃位置
// Breakpoint Navigator → + → Swift Error Breakpoint

// Objective-C Exception 断点：捕获 NSException 真正抛出位置
// Breakpoint Navigator → + → Exception Breakpoint

// Runtime Issue 断点：配合 Sanitizer 使用
// Breakpoint Navigator → + → Runtime Issue Breakpoint

// 断点动作（不暂停，仅记录）
// Edit Breakpoint → Add Action → Debugger Command → po myVariable
// 勾选 "Automatically continue after evaluating actions"
// 或 Add Action → Sound → 确认代码执行路径而不暂停
```

### LLDB 调试命令
```
// 打印变量（不编译表达式，最快）
(lldb) v self.fruitList.title         // frame variable 别名
(lldb) v self.listData[0]

// 编译表达式（支持函数调用、计算属性）
(lldb) p self.fruitList.calculatedCount    // expression 别名
(lldb) p fruit.fruitName == "Peach"        // 返回 Bool
(lldb) p $R2 + ", " + $R6                  // 引用之前结果

// 对象描述（自定义输出）
(lldb) po fruitList                        // 调用 debugDescription
(lldb) po cell                             // UIView 详情

// 修改变量值（调试中临时修改）
(lldb) po fruitList.title = "Tasty Fruit"

// 协议类型变量用 v（p/po 不支持迭代类型解析）
(lldb) v fruitItem.fruitName               // 正确
// (lldb) po fruitItem.fruitName           // 报错
```

### 内存图调试（Memory Graph）
```
1. 运行 App → 点击 Debug Bar 的 "Debug Memory Graph" 按钮
2. 左侧 Debug Navigator 显示类型列表和实例（nodes）
3. 选择 node → 查看内存引用图，高亮强引用
4. Control-click node → Focus on Node / Quick Look / Print Description

// 诊断 Retain Cycle：
// - 观察 Memory gauge，导航时内存只增不减
// - Memory Graph 中找到双向强引用
// - 将一方改为 weak 或移除依赖

// 诊断 Abandoned Memory：
// - App 不再需要但仍有引用的对象
// - 在合适的生命周期时机移除引用
```

### View Debugger（界面调试）
```
1. 点击 Debug Bar 的 "Debug View Hierarchy" 按钮
2. 拖拽查看 3D 分层视图
3. 选择 view → Inspector 查看属性和约束

// visionOS 可视化调试
// Debug Visualizations 按钮：
//   Anchoring   → 锚点
//   Axes        → 坐标轴
//   Bounds      → 包围盒
//   Collision Shapes → 碰撞形状（对所有 Shared Space 实体生效）
//   Occlusion Mesh   → 遮挡网格
//   Surfaces         → 检测到的表面

// 环境覆盖（Environmental Overrides）
// Debug Bar → Environment Overrides：
//   Interface Style（Light/Dark）
//   Dynamic Type Size
//   Accessibility 选项
```

## Xcode 性能分析（Performance 完整指南）

### 启动时间优化
```swift
// 启动类型：
// Cold Launch  → 重启后/内存被回收后，最慢
// Warm Launch  → 杀掉进程后重新打开
// Resume       → 从后台恢复，最快

// Xcode Organizer → Launches 查看启动时间分析
// MetricKit → MXAppLaunchDiagnostic 提供启动时间直方图

// 减少启动时间的关键：
// 1. 减少第三方 Framework 数量（dyld 加载开销）
// 2. 避免 +load 方法和 __attribute__((constructor))
// 3. 延迟非必要初始化到首次使用时
// 4. 仅加载首屏必要数据
// 5. 简化首屏视图层级
// 6. 使用 Mergeable Libraries（Xcode 15+）减少动态库加载

// Instruments → App Launch 模板分析：
// - dyld Activity: 静态初始化耗时
// - App Life Cycle: 进程初始化 / UIKit 初始化 / 首帧渲染
// - Time Profiler: CPU 热点

// 追踪自定义启动活动
let poiLog = OSLog(subsystem: "com.app.myapp", category: .pointsOfInterest)
os_signpost(.begin, log: poiLog, name: "Startup Activities")
// 准备视图数据...
os_signpost(.end, log: poiLog, name: "Startup Activities")
```

### 内存优化
```
// Xcode Organizer → Memory：峰值内存 + 挂起时内存
// MetricKit → MXMemoryMetric

// 内存超限 → EXC_RESOURCE (MEMORY subtype) 警告
// 继续超限 → Jetsam 终止（用户看到 App 消失）

// 关键概念：
// - 分配内存 ≠ 使用内存（Clean vs Dirty）
// - 只有写入后的内存页（16KB/页）才计入使用量
// - 单字节写入 = 16KB 页分配

// Instruments → Allocations + Leaks 模板
// Debug Memory Graph 按钮 → 查看 retain cycle
```

### 响应性优化（Hitches & Hangs）
```
// Hitch = 帧未及时准备好，滚动/动画卡顿
//   绿色 < 5 ms/s | 黄色 5-10 ms/s | 红色 > 10 ms/s
// Hang = 主线程无响应 > 250ms，严重时 > 1s

// Xcode Organizer：
// - Scrolling 面板 → Hitch Rate（仅 iOS/iPadOS）
// - Hang Rate 面板 → 秒/小时
// - Hang Reports → 堆栈跟踪 + 函数级别归因

// MetricKit → MXAppResponsivenessMetric

// Instruments → Time Profiler 模板：
// - Thread State Trace 查看阻塞原因
// - SwiftUI instrument 查看 View Body Updates

// iOS 设备端 Hang Detection：
// Settings → Developer → Hang Detection → 实时通知
```

### 磁盘写入优化
```
// Xcode Organizer → Disk Writes：MB/天
// Disk Writes Reports → 超阈值异常报告 + 堆栈

// 关键规则：
// 1. 频繁小变更用 SwiftData/CoreData/SQLite，不要用序列化文件
// 2. 避免反复 open/save/close 同一文件
// 3. 避免不必要的 fsync / F_FULLFSYNC（用 F_BARRIERFSYNC）
// 4. 原子写入会产生额外写入（临时文件+重命名），仅在需要时使用
// 5. 批量创建/删除文件会产生大量元数据写入（iOS 每文件 8KB）

// SQLite 最佳实践：
// - 使用 WAL 模式：PRAGMA journal_mode=WAL
// - 使用事务批量操作：BEGIN TRANSACTION ... COMMIT
// - 用 incremental_vacuum 替代 VACUUM
// - 保持连接打开，避免频繁 open/close
// - 使用合适的索引（EXPLAIN QUERY PLAN 分析）

// Instruments → File Activity 模板
// XCTest 性能测试：
func testDiskUse() {
    measure(metrics: [XCTStorageMetric()]) {
        // 写入操作
    }
}
```

### HTTP 流量分析
```
// Instruments → Network 模板 → HTTP Traffic instrument
// 注意：会记录加密和未加密流量！

// 命名 URLSession 便于 Instruments 识别：
let session = URLSession(configuration: .default)
session.sessionDescription = "Main Session"

// HTTP Traffic 层级：
// Process → Session → Domain → Task → Transaction
// Transaction 五阶段：cache lookup → blocked → sending → waiting → receiving

// Points of Interest → 自动标记访问可能追踪用户的域名
// 如果发现追踪域名 → 在 Privacy Manifest 中声明或移除相关代码
```

### Smart Insights（Xcode Organizer 智能洞察）
```
// Xcode Organizer 自动检测性能回归：
// - 对比最近 5 个版本的趋势
// - 火焰图标 = 最大回归的报告
// - 支持 Disk Writes / Hang Rate / Launch Time

// 回归通知：
// Organizer → Notifications 按钮 → 开启
// 条件：最新版本比前 4 版平均值回归 ≥75%
// 频率：每 24 小时最多 1 次/App

// 推荐值：
// Xcode 26 起显示启动时间推荐值（虚线）
// 基于同类 App 和历史数据计算
```

## Xcode 测试完整指南

### 运行测试
```bash
# 运行所有测试
xcodebuild test -scheme SampleApp

# 运行单个测试函数
xcodebuild test -scheme SampleApp \
  -only-testing SampleAppTests/SampleAppTests/testEmptyArray

# 运行测试套件
xcodebuild test -scheme SampleApp \
  -only-testing SampleAppTests/SampleAppTests

# 重复运行直到失败（flaky test 检测）
xcodebuild test -scheme SampleApp \
  -only-testing SampleAppTests/SampleAppTests/testEmptyArray \
  -run-tests-until-failure -test-iterations 20

# 指定模拟器
xcodebuild test -scheme SampleApp \
  -destination "platform=iOS Simulator,name=iPhone 16"
```

### 代码覆盖率（Code Coverage）
```
// 开启：Test Plan → Configurations → Code Coverage → "Gather coverage for"
// 测试后查看：Report Navigator → 选择 Test action → Coverage 面板
// Source Editor 右侧显示每行执行次数
// 红色高亮 = 未覆盖代码

// 注意：
// - 覆盖率收集影响性能（线性影响，不影响对比）
// - Skipped test 不计入覆盖率
// - 高覆盖率 ≠ 高质量测试，需配合断言
```

### 性能测试（XCTest）
```swift
// 默认测量执行时间
func testSortPerformance() {
    measure {
        _ = largeArray.sorted()
    }
}

// 自定义指标
func testMemoryUse() {
    measure(metrics: [XCTMemoryMetric(), XCTClockMetric()]) {
        processData()
    }
}

// 磁盘写入测量
func testDiskUse() {
    measure(metrics: [XCTStorageMetric()]) {
        saveLargeFile()
    }
}

// 设置 Baseline：点击 gutter 图标 → Set Baseline
// Max STDDEV：允许的最大标准偏差
// 超过 baseline + STDDEV → 测试失败

// 性能测试配置（Test Plan）：
// - Build Configuration: Release
// - Debug executable: OFF
// - Code Coverage: OFF
// - Sanitizers: OFF
```

### StoreKit 测试（本地内购测试）
```
// 1. File → New → StoreKit Configuration File
// 2. 添加产品（消耗品/非消耗品/自动续期订阅）
// 3. Scheme → Edit Scheme → Run → Options → StoreKit Configuration
// 4. 选择配置文件 → 运行 App 即可测试内购流程

// Synced 配置：从 App Store Connect 同步产品数据
// Local 配置：手动定义产品（无需 ASC）

// 本地收据验证：
// Editor → Save Public Certificate → 添加到项目
#if DEBUG
let certificate = "StoreKitTestCertificate"
#else
let certificate = "AppleIncRootCertificate"
#endif
```

### 位置模拟（测试 CoreLocation）
```swift
// Test Plan → Configuration → Simulated Location → 选择位置
// 或添加 GPX 文件模拟路线

// UI 测试中模拟位置
func testLocationFeature() throws {
    XCUIDevice.shared.location = XCUILocation(
        location: CLLocation(latitude: 37.334886, longitude: -122.008988))
    // 启动 App 并测试
}

// 单元测试中直接构造 CLLocation
let testLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
myLocationHandler.process(testLocation)
```

### 测试策略（金字塔模型）
```
       ┌──────────┐
       │  UI 测试  │  ← 少量，验证完整用户流程
       │ (XCUITest)│
      ─┼──────────┼─
      │ 集成测试   │  ← 中量，验证组件间连接
      │(Integration)│
     ─┼────────────┼─
     │   单元测试    │  ← 大量，快速验证逻辑
     │(Swift Testing)│
     └──────────────┘

// 可测试性改进：
// 1. 依赖协议化：将具体类型替换为 protocol，测试时用 Stub
// 2. 参数化依赖：singleton → init 参数，测试时注入替代实现
// 3. Metatype 注入：需要创建对象时，用类型变量替代硬编码类型
// 4. 子类覆盖：覆盖 untestable 方法（如系统时钟），测试可控

// 示例：依赖协议化
protocol URLOpener { func open(_ file: URL) -> Bool }
extension OpaqueService: URLOpener {}  // 生产代码
class StubService: URLOpener {          // 测试代码
    var isSuccessful = true
    func open(_ file: URL) -> Bool { isSuccessful }
}
```

## Xcode 开发者工具速查

### 崩溃报告分析
```
// Instruments 常用工具
Time Profiler     → CPU 热点定位
Allocations       → 内存增长分析
Leaks             → 内存泄漏检测
Network           → 网络请求分析
SwiftUI           → View Body Updates（Xcode 26 新增）

// 崩溃日志符号化
xcrun atos -o MyApp.dSYM/Contents/Resources/DWARF/MyApp -arch arm64 -l 0x100000000 0x1000012AB

// Xcode Cloud Webhook（CI/CD 集成外部服务）
// 最多 5 个 webhook / 产品，触发事件：build 创建/开始/完成
// POST payload 包含 build 状态、commit、artifact 信息
```

### 代码签名 + 配置文件
```
// 自动管理签名：Xcode → Signing & Capabilities → Automatically manage signing
// 手动管理：配置 provisioning profile + 证书
// Entitlements：HealthKit、App Groups、Push Notifications 等需在此添加

// TestFlight：Archive → Distribute → TestFlight → 上传 → App Store Connect 管理
```

### DocC 文档
```swift
/// 计算两个数的和。
///
/// 使用此方法执行基本加法运算。
///
/// ```swift
/// let result = add(2, 3) // returns 5
/// ```
///
/// - Parameters:
///   - a: 第一个数字。
///   - b: 第二个数字。
/// - Returns: 两个参数的和。
/// - Throws: 永不抛出。
func add(_ a: Int, _ b: Int) -> Int { a + b }

// 生成文档：Product → Build Documentation
// 支持 @Tutorial 编写交互式教程
```


## StoreKit 视图组件（iOS 17+）
```swift
import StoreKit

// 单个产品展示
ProductView(id: "com.app.premium") {
    Image(systemName: "crown")
}
.productViewStyle(.large)

// 订阅组展示（自动处理升级/降级）
SubscriptionStoreView(groupID: "premium_group")
    .subscriptionStoreControlStyle(.prominentPicker)
    .subscriptionStoreButtonLabel(.multiline)
    .containerBackground(for: .subscriptionStoreFullHeight) {
        LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
    }

// 实时监听交易更新
Task {
    for await result in Transaction.updates {
        if case .verified(let transaction) = result {
            await transaction.finish()
            unlockContent(for: transaction.productID)
        }
    }
}

// 恢复购买
try await AppStore.sync()
```

## Writing Tools 集成（iOS 26，自定义文本视图）
```swift
import UIKit

// 为自定义文本视图添加 Writing Tools 支持
let coordinator = UIWritingToolsCoordinator(delegate: self)
coordinator.preferredBehavior = .complete   // 或 .limited（仅校对）
coordinator.preferredResultOptions = [.richText, .list]
customTextView.addInteraction(coordinator)

// 实现委托：提供上下文
func writingToolsCoordinator(_ coordinator: UIWritingToolsCoordinator,
    requestsContextsFor scope: UIWritingToolsCoordinator.ContextScope,
    completion: @escaping ([UIWritingToolsCoordinator.Context]) -> Void) {
    switch scope {
    case .userSelection: completion([getSelectionContext()])
    case .fullDocument: completion([getFullDocumentContext()])
    default: completion([])
    }
}
```

## Widget containerBackground
```swift
// iOS 17+ Widget 背景（Smart Stack 自动移除背景）
struct MyWidgetView: View {
    var body: some View {
        VStack { content }
            .containerBackground(for: .widget) {
                LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom)
            }
    }
}
// Lock Screen widget 自动忽略背景
// accessoryWidgetBackground 用于小型锁屏 widget
```

## Vision 身体/手部姿态 + 人物分割 + 条码
```swift
import Vision

// 身体姿态检测
let bodyPoseRequest = VNDetectHumanBodyPoseRequest()
try VNImageRequestHandler(cgImage: image).perform([bodyPoseRequest])
if let observation = bodyPoseRequest.results?.first {
    let points = try observation.recognizedPoints(.torso)
    let neck = points[.neck]   // 各关节点位置 + 置信度
    let hip = points[.root]
}

// 手部姿态检测
let handPoseRequest = VNDetectHumanHandPoseRequest()
handPoseRequest.maximumHandCount = 2
try VNImageRequestHandler(cgImage: image).perform([handPoseRequest])
if let hand = handPoseRequest.results?.first {
    let thumbTip = try hand.recognizedPoint(.thumbTip)
    let indexTip = try hand.recognizedPoint(.indexTip)
    let distance = thumbTip.location.distance(to: indexTip.location)  // 捏合检测
}

// 人物分割（抠图）
let segRequest = VNGeneratePersonSegmentationRequest()
segRequest.qualityLevel = .balanced   // .fast / .balanced / .accurate
try VNImageRequestHandler(cgImage: image).perform([segRequest])
let mask = segRequest.results?.first?.pixelBuffer  // 遮罩 CVPixelBuffer

// 条码识别
let barcodeRequest = VNDetectBarcodesRequest()
barcodeRequest.symbologies = [.qr, .ean13, .code128]
try VNImageRequestHandler(cgImage: image).perform([barcodeRequest])
for barcode in barcodeRequest.results ?? [] {
    print(barcode.payloadStringValue ?? "")  // 条码内容
}
```

## ARKit 图像追踪 + 地理锚定
```swift
// 图像追踪（识别现实中的图片并叠加 AR 内容）
guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else { return }
let config = ARImageTrackingConfiguration()
config.trackingImages = referenceImages
config.maximumNumberOfTrackedImages = 4
arView.session.run(config)

func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    for anchor in anchors.compactMap({ $0 as? ARImageAnchor }) {
        let imageName = anchor.referenceImage.name  // 识别到的图片名
        // 在图片位置放置 3D 内容
    }
}

// 地理锚定（特定 GPS 坐标放置 AR 内容）
ARGeoTrackingConfiguration.checkAvailability { available, _ in
    guard available else { return }
    let config = ARGeoTrackingConfiguration()
    arView.session.run(config)
}
let geoAnchor = ARGeoAnchor(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
arView.session.add(anchor: geoAnchor)
```

## PhotogrammetrySession（3D 物体扫描）
```swift
import RealityKit

// 从照片重建 3D 模型
guard PhotogrammetrySession.isSupported else { return }
let session = try PhotogrammetrySession(input: photoFolderURL,
    configuration: PhotogrammetrySession.Configuration())
let request = PhotogrammetrySession.Request.modelFile(url: outputURL, detail: .full)
try session.process(requests: [request])

// 监听进度
for try await output in session.outputs {
    switch output {
    case .processingComplete: print("Done!")
    case .requestProgress(let request, let fraction): print("\(fraction * 100)%")
    case .requestError(_, let error): print("Error: \(error)")
    default: break
    }
}
```

## ReplayKit（屏幕录制）
```swift
import ReplayKit

// 应用内录屏
let recorder = RPScreenRecorder.shared()
recorder.startRecording { error in
    if let error { print("Recording failed: \(error)") }
}

// 停止并保存
recorder.stopRecording { previewController, error in
    if let preview = previewController {
        present(preview, animated: true)  // 预览/保存/分享
    }
}

// 实时采集（用于直播/AR 串流）
recorder.startCapture { sampleBuffer, bufferType, error in
    switch bufferType {
    case .video: processVideoFrame(sampleBuffer)
    case .audioApp: processAppAudio(sampleBuffer)
    case .audioMic: processMicAudio(sampleBuffer)
    @unknown default: break
    }
}
```

## UI 测试（XCUITest）
```swift
import XCTest

class MyAppUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }

    func testAddItem() {
        // 点击按钮
        app.buttons["Add Item"].tap()

        // 输入文字
        let textField = app.textFields["Item Name"]
        textField.tap()
        textField.typeText("New Item")

        // 验证元素存在
        XCTAssertTrue(app.staticTexts["New Item"].exists)

        // 滑动删除
        let cell = app.cells.containing(.staticText, identifier: "New Item").firstMatch
        cell.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertFalse(app.staticTexts["New Item"].exists)
    }
}

// Swift Testing + XCTest 可共存于同一 test target，逐步迁移
```


## UIKit 现代集合视图（UICollectionView 最佳实践）
```swift
// 1. Compositional Layout（自适应多段布局）
let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                          heightDimension: .fractionalHeight(1.0))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                           heightDimension: .absolute(200))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    return NSCollectionLayoutSection(group: group)
}

// 2. 现代 Cell 注册（替代 register + dequeue）
let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, indexPath, item in
    var config = UIListContentConfiguration.subtitleCell()
    config.text = item.title
    config.secondaryText = item.subtitle
    config.image = item.icon
    cell.contentConfiguration = config
    cell.accessories = [.disclosureIndicator()]
}

// 3. Diffable Data Source（声明式快照更新）
let dataSource = UICollectionViewDiffableDataSource<Section, Item.ID>(collectionView: collectionView) {
    collectionView, indexPath, itemID in
    collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: items[itemID])
}
var snapshot = NSDiffableDataSourceSnapshot<Section, Item.ID>()
snapshot.appendSections([.main])
snapshot.appendItems(itemIDs)
dataSource.apply(snapshot, animatingDifferences: true)
```

## Swift Package Manager（Package.swift）
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyLibrary",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MyLibrary", targets: ["MyLibrary"])
    ],
    dependencies: [
        .package(url: "https://github.com/example/dep.git", from: "1.0.0"),
        .package(path: "../LocalPackage")
    ],
    targets: [
        .target(name: "MyLibrary",
                dependencies: ["dep"],
                resources: [.process("Resources")]),
        .testTarget(name: "MyLibraryTests", dependencies: ["MyLibrary"])
    ]
)

// XCFramework 创建（多平台二进制分发）
// xcodebuild archive -scheme MyLib -destination "generic/platform=iOS" -archivePath archives/iOS
// xcodebuild -create-xcframework -archive archives/iOS.xcarchive -framework MyLib.framework -output MyLib.xcframework
```

## Xcode Cloud 构建脚本
```bash
#!/bin/sh
# ci_post_clone.sh — clone 后执行（安装依赖）
set -e
brew install swiftlint
# 或 CocoaPods: pod install

# ci_pre_xcodebuild.sh — 构建前执行
if [[ -n $CI_PULL_REQUEST_NUMBER ]]; then
    echo "Building PR #$CI_PULL_REQUEST_NUMBER"
fi

# ci_post_xcodebuild.sh — 构建后执行（上传产物等）
if [[ $CI_XCODEBUILD_ACTION == "build-for-testing" ]]; then
    echo "Tests will run next"
fi
```

## Push Notifications 进阶
```swift
import UserNotifications

// 临时授权（静默送达，用户首次看到时选择保留/关闭）
try await UNUserNotificationCenter.current()
    .requestAuthorization(options: [.alert, .sound, .badge, .provisional])

// 自定义操作按钮
let replyAction = UNTextInputNotificationAction(identifier: "REPLY", title: "Reply",
    textInputButtonTitle: "Send", textInputPlaceholder: "Type message...")
let likeAction = UNNotificationAction(identifier: "LIKE", title: "Like")
let category = UNNotificationCategory(identifier: "MESSAGE",
    actions: [replyAction, likeAction], intentIdentifiers: [])
UNUserNotificationCenter.current().setNotificationCategories([category])

// 发送时指定 category
let content = UNMutableNotificationContent()
content.title = "New Message"
content.categoryIdentifier = "MESSAGE"   // 关联操作按钮

// 检查当前通知设置
let settings = await UNUserNotificationCenter.current().notificationSettings()
if settings.authorizationStatus == .authorized { /* 已授权 */ }
```

## App Intents 进阶（Assistant Schemas + SiriTipView）
```swift
import AppIntents

// Assistant Schema（Apple Intelligence 深度集成）
struct OpenPhotoIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Photo"
    // @AssistantSchema(.photos.openAsset) // 匹配系统 schema

    @Parameter(title: "Photo")
    var photo: PhotoEntity

    func perform() async throws -> some IntentResult { .result() }
}

// SiriTipView（教用户语音指令）
SiriTipView(intent: OpenPhotoIntent())
    .siriTipViewStyle(.automatic)

// ShowsSnippetView（Siri 视觉结果卡片）
func perform() async throws -> some IntentResult & ShowsSnippetView {
    .result() {
        MyCustomSnippetView(data: resultData)
    }
}

// EnumerableEntityQuery（小型固定数据集）
struct TrailEntityQuery: EnumerableEntityQuery {
    func allEntities() async throws -> [TrailEntity] {
        TrailDataManager.shared.allTrails.map { TrailEntity(trail: $0) }
    }
}
```

## StoreKit 进阶（促销 + 订阅管理）
```swift
import StoreKit

// App Transaction 版本检查（业务模型迁移）
let appTransaction = try await AppTransaction.shared
if appTransaction.originalAppVersion < "2.0" {
    grantLegacyEntitlements()  // 老用户保留原有权益
}

// 当前有效权益遍历
for await result in Transaction.currentEntitlements {
    if case .verified(let transaction) = result {
        enableFeature(for: transaction.productID)
    }
}

// 处理 App Store 发起的购买（促销页点击）
for await intent in PurchaseIntent.intents {
    let product = try await intent.product
    let result = try await product.purchase()
    // 处理购买结果
}

// 促销产品排序和可见性控制
try await Product.PromotionInfo.updateProductOrder(productIDs)
try await Product.PromotionInfo.updateProductVisibility(.hidden, for: productID)
```

## RealityKit 进阶（交互 + 环境）
```swift
import RealityKit

// 可交互实体（点击/拖拽）
entity.components[InputTargetComponent.self] = InputTargetComponent()
entity.components[CollisionComponent.self] = CollisionComponent(shapes: [.generateBox(size: [0.3, 0.3, 0.3])])

// 打开/关闭沉浸式空间
@Environment(\.openImmersiveSpace) private var openImmersiveSpace
@Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

Button("Enter") { await openImmersiveSpace(id: "immersive") }
Button("Exit") { await dismissImmersiveSpace() }

// 物理原点偏移（大场景）
entity.components[PhysicsSimulationComponent.self] = PhysicsSimulationComponent()
// 使用 PhysicsOriginComponent 定义物理模拟原点

// 后处理回调（Core Image 滤镜叠加 AR）
arView.renderCallbacks.postProcess = { context in
    let ciImage = CIImage(mtlTexture: context.sourceColorTexture)!
    let filtered = ciImage.applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 5])
    let ciContext = CIContext(mtlDevice: context.device)
    ciContext.render(filtered, to: context.compatibleTargetTexture,
                     commandBuffer: context.commandBuffer, bounds: filtered.extent,
                     colorSpace: CGColorSpaceCreateDeviceRGB())
}
```

## Liquid Glass 进阶（glassEffectUnion + 形态变形）
```swift
// glassEffectUnion：合并动态创建的多个玻璃效果为统一形状
ForEach(items) { item in
    Image(item.icon)
        .glassEffect()
        .glassEffectUnion(id: "toolbar", in: namespace)  // 同 ID 的自动合并
}

// glassEffectTransition：视图切换时形态变形动画
Image("pencil")
    .glassEffect()
    .glassEffectID("tool", in: namespace)
    .glassEffectTransition(.materialize)  // 或 .matchedGeometry

// 注意：glassEffectUnion 用于同时存在的多个效果合并
// glassEffectID + glassEffectTransition 用于切换时的变形动画
```


## 自定义字体
```swift
// 1. 将 .ttf/.otf 文件添加到项目
// 2. Info.plist 添加 UIAppFonts（Fonts provided by application）
// 3. 使用
Text("Hello").font(.custom("MyFont-Bold", size: 24))
Text("Body").font(.custom("MyFont-Regular", size: 16, relativeTo: .body))  // 支持 Dynamic Type
```

## Swift Macros + #Preview
```swift
// #Preview 宏（替代 PreviewProvider）
#Preview("Light Mode") { ContentView().preferredColorScheme(.light) }
#Preview("Dark Mode") { ContentView().preferredColorScheme(.dark) }
#Preview(traits: .landscapeLeft) { ContentView() }

// 常用内置宏
@Observable      // 自动追踪属性变化（Observation 框架）
@Model           // SwiftData 持久化
@Generable       // Foundation Models 结构化输出
@Entry           // 自定义 EnvironmentValues / FocusValues / Transaction
#Predicate       // 类型安全谓词（SwiftData 查询）
#Expression      // 可求值表达式

// 宏角色分类（Swift 5.9+）
// @attached 宏（附加到声明上）
@attached(member)           // 添加成员（属性/方法）到类型
@attached(memberAttribute)  // 给现有成员添加属性
@attached(peer)             // 添加同级声明
@attached(accessor)         // 给属性添加 get/set
@attached(extension)        // 添加 extension conformance
@attached(body)             // 提供函数体实现

// @freestanding 宏（独立使用）
@freestanding(expression)   // 产生表达式 → #stringify(x + y)
@freestanding(declaration)  // 产生声明 → #warning("TODO")
```

### 自定义宏实现（Swift Package）
```swift
// 1. Package.swift 声明宏目标
.macro(name: "MyMacros", dependencies: [
    .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
    .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
])

// 2. 宏声明（公开 API）
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(
    module: "MyMacros", type: "StringifyMacro"
)

@attached(member, names: named(init))
public macro AutoInit() = #externalMacro(
    module: "MyMacros", type: "AutoInitMacro"
)

// 3. 宏实现
import SwiftSyntax
import SwiftSyntaxMacros

public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("需要一个参数")
        }
        return "(\(argument), \(literal: argument.description))"
    }
}

// 4. 编译器插件入口
@main
struct MyMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [StringifyMacro.self, AutoInitMacro.self]
}

// 5. 使用
let (result, code) = #stringify(2 + 3)  // (5, "2 + 3")

@AutoInit
struct User {
    let name: String
    let age: Int
    // 自动生成 init(name:age:)
}
```

## Data Race Safety（Swift 6 严格并发）
```swift
// Swift 6 默认开启数据竞争检查
// Build Settings → Swift Language Version → 6

// Sendable：可安全跨并发域传递
struct UserData: Sendable { let name: String }  // 值类型自动 Sendable
class Cache: @unchecked Sendable {              // 手动保证线程安全
    private let lock = NSLock()
    private var storage: [String: Data] = [:]
}

// AsyncSequence / AsyncStream
for await value in someAsyncSequence { process(value) }

// 自定义 AsyncStream
let stream = AsyncStream<Int> { continuation in
    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
        continuation.yield(Int.random(in: 1...100))
    }
    continuation.onTermination = { _ in /* cleanup */ }
}
for await number in stream { print(number) }

// Regex（Swift 5.7+）
let pattern = /\d{4}-\d{2}-\d{2}/        // 正则字面量
if let match = dateString.firstMatch(of: pattern) { print(match.output) }

// RegexBuilder（声明式构建复杂正则）
import RegexBuilder
let emailRegex = Regex {
    OneOrMore(.word)
    "@"
    OneOrMore(.word)
    "."
    Repeat(2...6) { .word }
}
```

## LocalAuthentication（Face ID / Touch ID）
```swift
import LocalAuthentication

func authenticateWithBiometrics() async throws -> Bool {
    let context = LAContext()
    var error: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
        throw error ?? LAError(.biometryNotAvailable)
    }
    return try await context.evaluatePolicy(
        .deviceOwnerAuthenticationWithBiometrics,
        localizedReason: "Unlock your data"
    )
}
// Info.plist: NSFaceIDUsageDescription 必须设置
```

## CryptoKit（加密 / 哈希 / 签名）
```swift
import CryptoKit

// SHA256 哈希
let hash = SHA256.hash(data: data)
let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()

// AES-GCM 对称加密
let key = SymmetricKey(size: .bits256)
let sealedBox = try AES.GCM.seal(plaintext, using: key)
let decrypted = try AES.GCM.open(sealedBox, using: key)

// P256 签名
let privateKey = P256.Signing.PrivateKey()
let signature = try privateKey.signature(for: data)
let isValid = privateKey.publicKey.isValidSignature(signature, for: data)

// HMAC
let authCode = HMAC<SHA256>.authenticationCode(for: data, using: key)
```

## CoreHaptics（自定义触觉反馈）
```swift
import CoreHaptics

let engine = try CHHapticEngine()
try engine.start()

// 自定义触觉模式
let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
let event = CHHapticEvent(eventType: .hapticTransient, parameters: [sharpness, intensity],
                          relativeTime: 0)
let pattern = try CHHapticPattern(events: [event], parameters: [])
let player = try engine.makePlayer(with: pattern)
try player.start(atTime: CHHapticTimeImmediate)

// engine 暂停/恢复
engine.stoppedHandler = { reason in /* 处理引擎停止 */ }
engine.resetHandler = { try self.engine.start() }
```

## UIHostingController（SwiftUI 嵌入 UIKit）
```swift
// SwiftUI View 嵌入 UIKit
let hostingController = UIHostingController(rootView: MySwiftUIView())
addChild(hostingController)
view.addSubview(hostingController.view)
hostingController.view.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
    hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
    hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
])
hostingController.didMove(toParent: self)

// 动态更新 SwiftUI 内容
hostingController.rootView = MySwiftUIView(data: newData)
```

## 画中画（PiP）+ Now Playing 信息
```swift
import AVKit

// 画中画
let pipController = AVPictureInPictureController(playerLayer: playerLayer)
pipController?.delegate = self
if AVPictureInPictureController.isPictureInPictureSupported() {
    pipController?.startPictureInPicture()
}

// Now Playing 信息（锁屏/控制中心显示）
import MediaPlayer
MPNowPlayingInfoCenter.default().nowPlayingInfo = [
    MPMediaItemPropertyTitle: "Song Title",
    MPMediaItemPropertyArtist: "Artist Name",
    MPMediaItemPropertyPlaybackDuration: duration,
    MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime
]

// 远程控制事件
let commandCenter = MPRemoteCommandCenter.shared()
commandCenter.playCommand.addTarget { _ in player.play(); return .success }
commandCenter.pauseCommand.addTarget { _ in player.pause(); return .success }
```

## 其他常用框架速查
```swift
// WeatherKit（天气数据）
import WeatherKit
let weather = try await WeatherService.shared.weather(for: CLLocation(latitude: 37.7749, longitude: -122.4194))
let temp = weather.currentWeather.temperature  // Measurement<UnitTemperature>

// MusicKit（Apple Music 集成）
import MusicKit
let status = await MusicAuthorization.request()
let searchRequest = MusicCatalogSearchRequest(term: "Taylor Swift", types: [Song.self])
let response = try await searchRequest.response()

// MultipeerConnectivity（设备间 P2P 通信）
import MultipeerConnectivity
let peerID = MCPeerID(displayName: UIDevice.current.name)
let session = MCSession(peer: peerID)
let advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "my-service")
advertiser.startAdvertisingPeer()

// DeviceCheck / App Attest（设备验证 / 防欺诈）
import DeviceCheck
let dcDevice = DCDevice.current
if dcDevice.isSupported {
    let token = try await dcDevice.generateToken()  // 发送到服务器验证
}
```


## Swift 6 语言特性
```swift
// Typed Throws（Swift 6+，类型化错误）
enum AppError: Error { case notFound, unauthorized }
func load() throws(AppError) -> Data {
    throw .notFound   // 编译器强制只能抛出 AppError
}
do throws(AppError) {
    let data = try load()
} catch .notFound { /* 精确匹配 */ }

// ~Copyable（不可拷贝类型 / Move-Only）
struct FileHandle: ~Copyable {
    let fd: Int32
    consuming func close() { /* fd 被消费后不可再使用 */ }
    borrowing func read() -> Data { /* 只读借用 */ }
}

// Parameter Packs（变参泛型）
func all<each T: Equatable>(of value: repeat each T, equalTo other: repeat each T) -> Bool {
    for (a, b) in repeat (each value, each other) {
        guard a == b else { return false }
    }
    return true
}
```

## SwiftUI 修饰符补全
```swift
// === Scroll 控制 ===
ScrollView {
    content
}
.scrollIndicators(.hidden)            // 隐藏滚动条
.scrollDismissesKeyboard(.interactively)  // 滚动时渐进收起键盘
.scrollBounceBehavior(.basedOnSize)   // 内容不足时禁止弹跳
.defaultScrollAnchor(.bottom)         // 默认锚定底部（聊天场景）
.contentMargins(.horizontal, 20)      // 内容区域边距

// === Presentation 自定义 ===
.sheet(isPresented: $show) {
    DetailView()
        .presentationBackground(.ultraThinMaterial)   // 半透明背景
        .presentationCornerRadius(24)                  // 圆角
}

// === 文本输入 ===
TextField("Email", text: $email)
    .textContentType(.emailAddress)
    .textInputAutocapitalization(.never)
    .autocorrectionDisabled()

// === 内容形状 ===
Button(action: tap) { content }
    .contentShape(.rect)              // 扩展可点击区域到整个矩形
    .hoverEffect(.lift)               // iPad 指针悬停效果

// === Dynamic Type 限制 ===
Text("Fixed")
    .dynamicTypeSize(.medium ... .xxxLarge)  // 限制字体缩放范围

// === Scene 生命周期 ===
@Environment(\.scenePhase) private var scenePhase
.onChange(of: scenePhase) { _, newPhase in
    switch newPhase {
    case .active: refreshData()
    case .inactive: saveState()
    case .background: scheduleBackgroundTask()
    @unknown default: break
    }
}

// === MeshGradient（iOS 18+，网格渐变）===
MeshGradient(width: 3, height: 3, points: [
    .init(0, 0), .init(0.5, 0), .init(1, 0),
    .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
    .init(0, 1), .init(0.5, 1), .init(1, 1)
], colors: [
    .red, .purple, .indigo,
    .orange, .cyan, .blue,
    .yellow, .green, .mint
])

// === 几何变化监听（iOS 18+）===
.onGeometryChange(for: CGSize.self) { proxy in proxy.size } action: { newSize in
    containerSize = newSize
}

// === Map 进阶 ===
import MapKit
@State private var cameraPosition: MapCameraPosition = .automatic
Map(position: $cameraPosition) {
    UserAnnotation()                   // 当前用户位置
    // Marker, Annotation 等
}
.mapControls {
    MapUserLocationButton()            // 定位按钮
    MapCompass()                        // 指南针
    MapScaleView()                      // 比例尺
}

// === 不等圆角矩形 ===
UnevenRoundedRectangle(topLeadingRadius: 20, bottomTrailingRadius: 20)
    .fill(.blue)

// === 旧式状态管理（迁移参考，新代码用 @Observable）===
// @StateObject → @State + @Observable
// @ObservedObject → 直接传入 @Observable 对象
// @EnvironmentObject → @Environment + @Observable
// @Published → @Observable 类中的普通属性

// === WidgetKit 补充 ===
// widgetURL: 点击 Widget 时打开的 deep link
.widgetURL(URL(string: "myapp://item/\(item.id)")!)
// configurationDisplayName + supportedFamilies 在 Widget 定义中
```


## Foundation Models 安全与高级用法（WWDC25）

### Session Instructions（系统指令，优先于 prompt）
```swift
let instructions = """
    ALWAYS respond in a respectful way. \
    If someone asks you to generate content that might be sensitive, \
    you MUST decline with 'Sorry, I can't do that.'
    """
let session = LanguageModelSession(instructions: instructions)
// instructions 优先级高于 prompt，不要在 instructions 中放用户输入（防 prompt injection）
```

### Guardrail 违规 + 拒绝处理
```swift
do {
    let response = try await session.respond(to: prompt)
} catch LanguageModelSession.GenerationError.guardrailViolation {
    // 输入或输出触发安全护栏 → 重新措辞 prompt
}

// Guided Generation 中的拒绝（无法生成结构化输出时）
do {
    let result = try await session.respond(to: prompt, generating: [String].self)
} catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
    if let message = try? await refusal.explanation {
        showRefusalMessage(message)  // 显示拒绝原因
    }
}
```

### 宽松内容模式（处理敏感源材料）
```swift
// 适用于聊天 App 标签敏感话题、学习 App 讨论敏感内容等场景
let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
let session = LanguageModelSession(model: model)
// 仅对字符串响应生效，Guided Generation 仍走默认护栏
```

### DynamicGenerationSchema（运行时动态 Schema）
```swift
// 当编译时不知道完整 schema 时使用（如餐厅菜单来自服务器）
let menuSchema = DynamicGenerationSchema(
    name: "Menu",
    properties: [
        DynamicGenerationSchema.Property(
            name: "dailySoup",
            schema: DynamicGenerationSchema(name: "dailySoup", anyOf: ["Tomato", "Chicken Noodle", "Clam Chowder"])
        )
    ]
)
let schema = try GenerationSchema(root: menuSchema, dependencies: [])
let response = try await session.respond(to: "Pick a soup", schema: schema)
// response 是 GenerationSchemaOutput，通过 .value(for: "dailySoup") 读取
```

### 安全最佳实践（WWDC25 官方）
```swift
// 1. 限制输入：固定选项 > 格式化包装 > 自由输入
enum TopicOptions { case family, nature, work }

// 2. 限制输出：用 @Generable enum 约束输出为安全预定义选项
@Generable enum Breakfast { case waffles, pancakes, bagels, eggs }
let result = try await session.respond(to: userInput, generating: Breakfast.self)

// 3. 自定义 deny list（禁止词列表，可本地或服务器托管）
func verifyText(_ text: String) -> Bool { !denyList.contains(where: text.contains) }

// 4. 收集用户反馈：session.transcript → JSON → Feedback Assistant
```

## Foundation Models — Instruments 性能分析
```swift
// Instruments → Blank → 添加 "Foundation Models" instrument
// 时间线显示：Asset Loading / Token Usage / Tool Calling / Session 延迟

// 关键优化 1：prewarm with promptPrefix（减少首 token 延迟）
var session = LanguageModelSession()
session.prewarm()                                          // 基础预热
session.prewarm(promptPrefix: "Generate a travel itinerary for")  // 带前缀预热

// 关键优化 2：includeSchemaInPrompt = false（减少 token 消耗）
// 首次请求保留 schema（质量更好），后续请求关闭（省数百 token）
let response = try await session.streamResponse(
    prompt: prompt,
    generable: MyCustomType.self,
    options: .init(includeSchemaInPrompt: false)  // 后续请求关闭
)

// Token 成本：单词 ≈ 1 token，符号/数字（如电话号码）可能 10+ tokens
// 超过 1000 tokens 会显著减慢响应，特别是旧设备
// Instruments → Inference detail area 查看每个 session 的 token 详情
```

## Foundation Models — Prompting 最佳实践
```swift
// === 角色 / 人设（Role / Persona）===
// 用 "you are" 赋予角色，"expert" 增加权威性
let instructions = """
    You are a senior software engineer expert in Swift.
    You are mentoring junior developers with patience and clarity.
    """

// === 多语言支持 ===
// 检查语言支持
if SystemLanguageModel.default.supportsLocale() {
    // 当前 App 语言受支持
}
// 获取所有支持的语言列表
let supported = SystemLanguageModel.default.supportedLanguages

// 设置输出语言（指令中明确指定）
let session = LanguageModelSession(instructions: """
    The person's locale is \(Locale.current.identifier).
    You MUST respond in Italian.
    """)

// === Few-Shot 提示（提供 2-15 个简短示例）===
let prompt = """
    Create an NPC. Examples:
    {name: "Thimblefoot", desc: "A horse with rainbow mane", order: "Something sweet"}
    {name: "Spiderkid", desc: "A furry spider with baseball cap", order: "Iced coffee"}
    """
let npc = try await session.respond(to: prompt, generating: NPC.self).content

// === 推理字段（Reasoning Field）===
// 将推理步骤作为第一个属性，让模型先思考再回答
@Generable
struct ReasonableAnswer {
    var reasoningSteps: String           // 第一个属性：推理过程
    @Guide(description: "The answer only.")
    var answer: MyCustomType             // 最终答案
}

// === 条件提示 → Swift switch 替代 if-else ===
// ❌ 避免：在 prompt 中写 IF/ELSE 条件
// ✅ 推荐：用 Swift switch 定制 prompt，减少模型困惑
var customGreeting = ""
switch role {
case .bard: customGreeting = "This guest is a bard. Ask about music."
case .soldier: customGreeting = "This guest is a soldier. Ask about danger."
default: customGreeting = "This guest is a weary traveler."
}
let instructions = "You are a friendly innkeeper. \(customGreeting)"

// === Prompt 版本管理 ===
// 模型随 OS 更新，prompt 需要版本化
if #available(iOS 26.4, macOS 26.4, *) {
    return String(localized: "summarizer-v1.1", table: "Prompts")
} else {
    return String(localized: "summarizer-v1.0", table: "Prompts")
}
// 或用 Xcode String Catalogs 管理所有 prompt
// 或用服务器下发 prompt（最灵活，支持 A/B 测试和快速回滚）

// === Guardrail 违规时的用户提示 ===
do {
    let response = try await session.respond(to: userInput)
} catch LanguageModelSession.GenerationError.guardrailViolation {
    showMessage("Sorry, this feature isn't designed to handle that kind of input.")
} catch LanguageModelSession.GenerationError.unsupportedLanguage {
    showMessage("This language isn't supported by Apple Intelligence.")
}
```

## AVPlayer + Observation 框架（iOS 26，WWDC25）
```swift
import AVFoundation

// 全局开启（必须在创建播放器之前设置）
AVPlayer.isObservationEnabled = true

struct PlayerView: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                TransportControls(player: player)
            } else { ProgressView() }
        }
        .task { player = AVPlayer(url: url) }  // 延迟创建避免性能问题
    }
}

struct TransportControls: View {
    let player: AVPlayer
    private var isPlaying: Bool { player.timeControlStatus == .playing }

    var body: some View {
        Button {
            isPlaying ? player.pause() : player.play()
        } label: {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
        }
        .disabled(player.currentItem?.status != .readyToPlay)
        // 自动追踪 timeControlStatus / currentItem 变化，无需 KVO
    }
}
```

## Vision 文档表格识别（RecognizeDocumentsRequest，WWDC25）
```swift
import Vision

let request = RecognizeDocumentsRequest()
let observations = try await request.perform(on: imageData)

if let document = observations.first?.document {
    for table in document.tables {
        for row in table.rows {
            for cell in row {
                let text = cell.content.text.transcript
                // 访问检测到的数据（email、phone）
                for data in cell.content.text.detectedData {
                    switch data.match.details {
                    case .emailAddress(let email): print(email.emailAddress)
                    case .phoneNumber(let phone): print(phone.phoneNumber)
                    default: break
                    }
                }
            }
        }
    }
}
```

## AlarmKit（iOS 26 新框架，闹钟调度）
```swift
import AlarmKit

// 请求授权
let alarmManager = AlarmManager.shared
let state = try await alarmManager.requestAuthorization()
// Info.plist: NSAlarmKitUsageDescription

// 创建闹钟
let presentation = AlarmPresentation(alert: .init(title: "Wake Up", stopButton: .stopButton))
let attributes = AlarmAttributes(presentation: presentation, tintColor: .blue)
let config = AlarmConfiguration(
    schedule: .relative(.init(time: .init(hour: 7, minute: 0), repeats: .weekly([.monday, .friday]))),
    attributes: attributes
)
let alarm = try await alarmManager.schedule(id: UUID(), configuration: config)

// 监听闹钟状态更新
for await alarms in alarmManager.alarmUpdates { updateUI(with: alarms) }
```

## Live Activities 进阶（Dynamic Island + 多设备，WWDC25）
```swift
import ActivityKit

// Dynamic Island 展开/紧凑/最小布局
ActivityConfiguration(for: DeliveryAttributes.self) { context in
    // Lock Screen 布局
    DeliveryLockScreenView(context: context)
} dynamicIsland: { context in
    DynamicIsland {
        DynamicIslandExpandedRegion(.leading) { Image(systemName: "box.truck") }
        DynamicIslandExpandedRegion(.center) { Text(context.state.status) }
        DynamicIslandExpandedRegion(.trailing) { Text(context.state.eta) }
    } compactLeading: {
        Image(systemName: "box.truck")
    } compactTrailing: {
        Text(context.state.eta)
    } minimal: {
        Image(systemName: "box.truck")
    }
}
// Apple Watch + CarPlay 自动适配
.supplementalActivityFamilies([.small, .medium])

// 根据 activityFamily 适配布局
@Environment(\.activityFamily) var activityFamily
switch activityFamily {
case .small: CompactView(context: context)   // Watch / CarPlay
case .medium: FullView(context: context)     // Lock Screen
}
```

## Liquid Glass 采用指南（WWDC25 官方最佳实践）
```swift
// 系统组件自动采用 Liquid Glass（控件、导航栏、Sheet、Popover）
// 自定义控件使用标准 button style 代替手动 glassEffect：
Button("Action") { }
    .buttonStyle(.glass)         // 或 .borderedProminent
    .buttonBorderShape(.capsule) // 与硬件圆角呼应

// scroll edge effect（内容滚到控件下方时自动模糊）
ScrollView { content }
    .scrollEdgeEffectStyle(.soft)  // 系统默认对标准 bar 生效

// App Icon：Icon Composer 创建多层图标（前景/中景/背景）
// 系统自动应用反射/折射/高光，支持 light/dark/clear/tinted 变体

// 注意事项：
// - Section header 自动改为 Title Case（不再全大写）
// - Sheet 圆角增大，半屏 Sheet 缩进显示底部内容
// - Action Sheet 从触发控件位置弹出（非底部边缘）
// - 避免在 Liquid Glass 元素上叠加自定义背景
// - 使用 .toolbarBackground(.hidden) 移除自定义工具栏背景
```

## Liquid Glass 进阶采用（Window / Navigation / 背景延伸）
```swift
// 背景延伸效果（图片延伸到 sidebar/inspector 下方，模糊处理）
Image("hero")
    .resizable()
    .aspectRatio(contentMode: .fill)
    .backgroundExtensionEffect(
        BackgroundExtensionEffect(edges: [.leading, .trailing])
    )

// 水平 ScrollView 延伸到 sidebar 下方
ScrollView(.horizontal) {
    LazyHStack { ForEach(items) { item in ItemCard(item: item) } }
}
.scrollClipDisabled()  // 允许内容滚动到 sidebar 下方

// Tab Bar 滚动时自动收起（iOS 26）
TabView {
    Tab("Home", systemImage: "house") { HomeView() }
    Tab("Search", systemImage: "magnifyingglass") { SearchView() }
}
.tabBarMinimizeBehavior(.onScrollDown)  // 下滑收起，反向展开

// Toolbar 分组（相关操作共享 Liquid Glass 背景）
.toolbar {
    ToolbarItemGroup(placement: .primaryAction) {
        Button("Share", systemImage: "square.and.arrow.up") { }
        Button("Favorite", systemImage: "heart") { }
    }
    ToolbarItem(placement: .primaryAction) {
        Spacer()  // 固定间距分隔不同分组
    }
    ToolbarItemGroup(placement: .primaryAction) {
        Button("Settings", systemImage: "gear") { }
    }
}

// iPadOS 窗口连续调整大小（自动 reflow）
// 使用标准 NavigationSplitView API，系统自动提供流畅过渡动画
NavigationSplitView {
    SidebarView()
} detail: {
    DetailView()
}

// 保持旧版外观（Info.plist 添加此 key）
// UIDesignRequiresCompatibility = true
// 用最新 SDK 编译但保留旧版视觉风格
```

### UIKit UIGlassEffect
```swift
import UIKit

// UIKit 自定义视图添加 Liquid Glass
class MyCustomView: UIView {
    private func setupGlassEffect() {
        let glassEffect = UIGlassEffect()
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.frame = bounds
        glassView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(glassView, at: 0)
    }
}

// 系统组件自动获得 Liquid Glass（无需代码）：
// UITabBar, UINavigationBar, UIToolbar, UIAlertController, Sheets, Modal
// 重编译后自动适配
```

### Liquid Glass 可访问性适配
```swift
// 检测 Reduce Transparency 设置，提供 fallback
struct AccessibleGlassView: View {
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.colorSchemeContrast) var contrast

    var body: some View {
        Text("Content")
            .padding()
            .background {
                if reduceTransparency {
                    RoundedRectangle(cornerRadius: 12).fill(.regularMaterial)  // 不透明 fallback
                } else {
                    RoundedRectangle(cornerRadius: 12).glassEffect(.regular)  // Liquid Glass
                }
            }
    }
}

// ✅ 必须测试的辅助功能设置：
// Settings → Accessibility → Display → Reduce Transparency
// Settings → Accessibility → Display → Reduce Motion
// Settings → Accessibility → Display → Increase Contrast

// ❌ 避免：Liquid Glass 背景上叠加浅色文字（对比度不足）
// ❌ 避免：不用 GlassEffectContainer 包裹多个 glass 元素
// ✅ iOS 26 之前用 .background(.ultraThinMaterial) 作为 fallback
```

## SwiftUI 性能优化（Xcode 26 Instruments，WWDC25）
```swift
// Xcode 26 SwiftUI Performance Instrument 使用步骤：
// 1. Product > Profile → 选择 SwiftUI 模板
// 2. 录制 → 交互 → 停止
// 3. 分析 View Body Updates / Hitches / Update Groups

// 常见优化模式：

// ❌ 避免：在 body 中执行昂贵计算
// ✅ 推荐：异步计算 + 缓存结果

// ❌ 避免：闭包捕获 self（导致任何属性变化都重新计算）
// ✅ 推荐：在 init 中调用闭包，只存返回值

// ❌ 避免：GeometryReader 中频繁更新 state
// ✅ 推荐：判断变化幅度超过阈值才更新
.onGeometryChange(for: CGSize.self) { $0.size } action: { newSize in
    if abs(newSize.width - lastSize.width) > 10 { lastSize = newSize }
}

// ❌ 避免：@ObservableObject 广播所有属性变化
// ✅ 推荐：迁移到 @Observable 宏（细粒度追踪）

// 分析因果链：Instruments 中 Show Causes → 查看更新传播路径
// 蓝色节点 = 你的代码，灰色节点 = 系统框架
```

## Combine（响应式编程）
```swift
import Combine

// NotificationCenter → Publisher
var cancellable: AnyCancellable?
cancellable = NotificationCenter.default
    .publisher(for: UIDevice.orientationDidChangeNotification)
    .filter { _ in UIDevice.current.orientation == .portrait }
    .sink { _ in print("切换到竖屏") }

// KVO → Combine
class UserInfo: NSObject {
    @objc dynamic var lastLogin: Date = Date(timeIntervalSince1970: 0)
}
cancellable = UserInfo().publisher(for: \.lastLogin)
    .sink { date in print("上次登录: \(date)") }

// Timer Publisher
cancellable = Timer.publish(every: 1, on: .main, in: .default)
    .autoconnect()
    .receive(on: myDispatchQueue)
    .assign(to: \.lastUpdated, on: myDataModel)

// 搜索框防抖
cancellable = NotificationCenter.default
    .publisher(for: UITextField.textDidChangeNotification, object: searchField)
    .map { ($0.object as! UITextField).text ?? "" }
    .filter { $0.unicodeScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) } }
    .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
    .receive(on: RunLoop.main)
    .assign(to: \.filterString, on: viewModel)

// Future（替代 completion handler）
func fetchData() -> Future<Int, Never> {
    Future { promise in
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            promise(.success(Int.random(in: 1...10)))
        }
    }
}

// Subject（内部触发，外部订阅）
private let _didTap = PassthroughSubject<Void, Never>()
var didTap: AnyPublisher<Void, Never> { _didTap.eraseToAnyPublisher() }
_didTap.send()  // 触发
cancellable = viewController.didTap.sink { print("用户点击了") }

// 自定义 Subscriber（背压控制）
class MySubscriber: Subscriber {
    typealias Input = Date; typealias Failure = Never
    func receive(subscription: Subscription) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { subscription.request(.max(3)) }
    }
    func receive(_ input: Date) -> Subscribers.Demand { print("收到: \(input)"); return .none }
    func receive(completion: Subscribers.Completion<Never>) {}
}
```

## Objective-C / C 互操作
```swift
// ObjC completion handler → Swift async 自动桥接
// ObjC: - (void)presentWithCompletion:(void (^)(BOOL success))completion;
func present() async -> Bool   // 自动生成 async 版本

// ObjC 带 NSError → Swift async throws
// ObjC: - (void)writeData:(NSData *)data timeout:(NSTimeInterval)timeout completionHandler:(void (^)(NSError *_Nullable))completionHandler;
func write(_ data: Data, timeout: TimeInterval) async throws

// 多返回值 → tuple
func sign(_ signData: Data, using pass: PKSecureElementPass) async throws -> (Data, Data)
```

**Importing Swift into ObjC**：
```objc
#import "ProductModuleName-Swift.h"        // App target
#import <ProductName/ProductModuleName-Swift.h>  // Framework target
@class MySwiftClass;                        // 前向声明避免循环引用
```

**KVO in Swift**：
```swift
class MyObjectToObserve: NSObject {
    @objc dynamic var myDate = NSDate(timeIntervalSince1970: 0)
}

class MyObserver: NSObject {
    @objc var objectToObserve: MyObjectToObserve
    var observation: NSKeyValueObservation?
    init(object: MyObjectToObserve) {
        objectToObserve = object; super.init()
        observation = observe(\.objectToObserve.myDate, options: [.old, .new]) { _, change in
            print("changed from: \(change.oldValue!), to: \(change.newValue!)")
        }
    }
}
```

**C 函数互操作**：
```swift
// C 指针参数传递
func takesAPointer(_ p: UnsafePointer<Float>) { }
var x: Float = 0.0
takesAPointer(&x)          // 传变量地址
takesAPointer([1.0, 2.0])  // 传数组

// UnsafeMutablePointer / UnsafeRawPointer 同理
func takesARawPointer(_ p: UnsafeRawPointer?) { }
var y: Int = 0
takesARawPointer(&x); takesARawPointer(&y); takesARawPointer("Hello")
```

## Network Framework 进阶（NWConnection）
```swift
import Network

// TCP + TLS 连接
let tlsOptions = NWProtocolTLS.Options()
sec_protocol_options_set_min_tls_protocol_version(tlsOptions.securityProtocolOptions, .TLSv12)
let params = NWParameters(tls: tlsOptions, tcp: .init())
let connection = NWConnection(to: .hostPort(host: "example.com", port: 4433), using: params)

connection.stateUpdateHandler = { state in
    switch state {
    case .ready: print("Connected")
    case .failed(let error): print("Failed: \(error)")
    default: break
    }
}
connection.start(queue: .global())

// UDP 连接（无 TLS）
let udpConnection = NWConnection(to: .hostPort(host: "example.com", port: 9000),
    using: NWParameters(dtls: nil, udp: .init()))

// 带用户归因（iOS 14.2+，VPN / 代理可区分来源）
let userParams = NWParameters()
userParams.attribution = .user

// NWListener（服务端监听）
let listener = try NWListener(using: params, on: 4433)
listener.newConnectionHandler = { newConnection in
    newConnection.start(queue: .global())
}
listener.start(queue: .global())
```

## CoreLocation 进阶

### 地理围栏（CLMonitor，iOS 17+ 异步 API）
```swift
Task {
    let monitor = await CLMonitor("my_monitor")
    let condition = CLCircularGeographicCondition(center: targetCoord, radius: 200)
    monitor.add(condition, identifier: "store_nearby")
    for try await event in monitor.events {
        if event.state == .satisfied { showNearbyNotification() }
    }
}
```

### iBeacon 测距
```swift
func monitorBeacons() {
    guard CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) else { return }
    let uuid = UUID(uuidString: "39ED98FF-2900-441A-802F-9C398FC199D2")!
    let constraint = CLBeaconIdentityConstraint(uuid: uuid)
    let region = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: uuid.uuidString)
    locationManager.startMonitoring(for: region)
}

func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    if region is CLBeaconRegion { manager.startRangingBeacons(in: region as! CLBeaconRegion) }
}

func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
    guard let nearest = beacons.first else { return }
    switch nearest.proximity {
    case .near, .immediate: displayExhibitInfo(major: nearest.major, minor: nearest.minor)
    default: dismissExhibit()
    }
}
```

### 反向地理编码
```swift
func lookUpCurrentLocation() async -> CLPlacemark? {
    guard let location = locationManager.location else { return nil }
    return try? await CLGeocoder().reverseGeocodeLocation(location).first
}

// 正向地理编码（地址 → 坐标）
let placemarks = try await CLGeocoder().geocodeAddressString("Apple Park, Cupertino")
let coordinate = placemarks.first?.location?.coordinate
```

### 后台位置更新
```swift
@MainActor class LocationsHandler: ObservableObject {
    static let shared = LocationsHandler()
    private let manager = CLLocationManager()
    private var background: CLBackgroundActivitySession?
    @Published var lastLocation = CLLocation()

    func startLocationUpdates() {
        if manager.authorizationStatus == .notDetermined { manager.requestWhenInUseAuthorization() }
        Task {
            for try await update in CLLocationUpdate.liveUpdates() {
                if let loc = update.location { lastLocation = loc }
            }
        }
    }

    func enableBackground() { background = CLBackgroundActivitySession() }
    func disableBackground() { background?.invalidate() }
}
```

## UserNotifications 进阶

### 可操作通知（自定义按钮）
```swift
let replyAction = UNTextInputNotificationAction(identifier: "REPLY", title: "Reply",
    textInputButtonTitle: "Send", textInputPlaceholder: "Type message...")
let likeAction = UNNotificationAction(identifier: "LIKE", title: "Like")
let category = UNNotificationCategory(identifier: "MESSAGE",
    actions: [replyAction, likeAction], intentIdentifiers: [],
    hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
UNUserNotificationCenter.current().setNotificationCategories([category])

// 处理操作响应
func userNotificationCenter(_ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    switch response.actionIdentifier {
    case "REPLY":
        if let textResponse = response as? UNTextInputNotificationResponse {
            sendReply(text: textResponse.userText)
        }
    case "LIKE": likeMessage(id: userInfo["msgID"] as? String)
    default: break
    }
    completionHandler()
}
```

### 通信通知（INSendMessageIntent，支持头像 + Focus）
```swift
import Intents

let handle = INPersonHandle(value: "user-id-1", type: .unknown)
let sender = INPerson(personHandle: handle, nameComponents: nil,
    displayName: "Alice", image: INImage(named: "alice.png"),
    contactIdentifier: nil, customIdentifier: nil)
let intent = INSendMessageIntent(recipients: nil, outgoingMessageType: .outgoingMessageText,
    content: "Message content", speakableGroupName: nil,
    conversationIdentifier: "conv-1", serviceName: nil, sender: sender, attachments: nil)

// Notification Service Extension 中更新
let interaction = INInteraction(intent: intent, response: nil)
interaction.direction = .incoming
try await interaction.donate()
let updatedContent = try request.content.updating(from: intent)
contentHandler(updatedContent)
```

### Critical Alerts（紧急警报，突破静音/勿扰）
```json
{
   "aps": {
      "alert": { "title": "Emergency", "body": "Severe weather warning" },
      "sound": { "critical": 1, "name": "alert.aiff", "volume": 1.0 }
   }
}
```

### APNs 设备注册
```swift
// AppDelegate
func application(_ app: UIApplication, didFinishLaunchingWithOptions opts: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    UIApplication.shared.registerForRemoteNotifications()
    return true
}
func application(_ app: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken token: Data) {
    sendTokenToServer(token)
}

// 静默推送（后台唤醒 App 刷新数据）
// APNs payload: { "aps": { "content-available": 1 } }
```

## MapKit 进阶

### 地图叠加层（Overlays）
```swift
// 多边形
let coords = [CLLocationCoordinate2D(latitude: 37.81, longitude: -122.52),
    CLLocationCoordinate2D(latitude: 37.81, longitude: -122.35),
    CLLocationCoordinate2D(latitude: 37.70, longitude: -122.35),
    CLLocationCoordinate2D(latitude: 37.70, longitude: -122.52)]
let polygon = MKPolygon(coordinates: coords, count: coords.count)
mapView.addOverlay(polygon)

// 圆形 + 折线
let circle = MKCircle(center: sfCenter, radius: 9000)
mapView.addOverlay(circle, level: .aboveLabels)

// 渲染器代理
func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    switch overlay {
    case let o as MKCircle:
        let r = MKCircleRenderer(circle: o); r.lineWidth = 2
        r.strokeColor = .systemBlue; r.fillColor = .systemTeal; r.alpha = 0.5; return r
    case let o as MKPolyline:
        let r = MKPolylineRenderer(polyline: o); r.lineWidth = 2; r.strokeColor = .systemRed; return r
    case let o as MKPolygon:
        let r = MKPolygonRenderer(polygon: o)
        r.fillColor = .systemGreen.withAlphaComponent(0.3); r.strokeColor = .systemGreen; return r
    default: return MKOverlayRenderer(overlay: overlay)
    }
}
```

### 标注聚合（Clustering）
```swift
// 设置 clusteringIdentifier 自动聚合
override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    clusteringIdentifier = "myCluster"
    displayPriority = .defaultHigh
}

// 自定义聚合外观
override func prepareForDisplay() {
    super.prepareForDisplay()
    if let cluster = annotation as? MKClusterAnnotation {
        let count = cluster.memberAnnotations.count
        image = drawClusterImage(count: count)
    }
}
```

### GeoJSON 解码
```swift
if let url = Bundle.main.url(forResource: "event", withExtension: "json") {
    let data = try Data(contentsOf: url)
    let objects = try MKGeoJSONDecoder().decode(data)
    for object in objects {
        if let feature = object as? MKGeoJSONFeature {
            for geo in feature.geometry {
                if let poly = geo as? MKMultiPolygon { mapView.addOverlay(poly) }
                if let point = geo as? MKPointAnnotation { mapView.addAnnotation(point) }
            }
        }
    }
}
```

### 本地搜索 + 自动补全
```swift
let completer = MKLocalSearchCompleter()
completer.resultTypes = .pointOfInterest
completer.queryFragment = "coffee"

// 执行搜索
let request = MKLocalSearch.Request(completion: selectedCompletion)
let search = MKLocalSearch(request: request)
let response = try await search.start()
let mapItems = response.mapItems

// MKMapItem 持久化（通过 identifier）
guard let id = mapItem.identifier else { return }
let savedID = id.rawValue
// 恢复
let restored = try await MKMapItemRequest(mapItemIdentifier: MKMapItem.Identifier(rawValue: savedID)).mapItem
```

## StoreKit 进阶（退款 / Family Sharing / Win-Back）
```swift
@MainActor @Observable
final class Store {
    var consumableCount: Int = 0
    var activeSubscription: String? = nil

    init() {
        // 启动时处理未完成交易 + 当前权益
        Task(priority: .background) {
            for await result in Transaction.unfinished { await handle(result) }
            for await result in Transaction.currentEntitlements { await handle(result) }
        }
        Task(priority: .background) {
            for await result in Transaction.updates { await handle(result) }
        }
    }

    private func handle(_ verificationResult: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = verificationResult else { return }
        if let _ = transaction.revocationDate {
            // 退款/撤销：回收权益
            activeSubscription = nil
        } else if let exp = transaction.expirationDate, exp < Date() {
            activeSubscription = nil  // 过期
        } else {
            activeSubscription = transaction.productID  // 激活
        }
        await transaction.finish()
    }
}

// Win-Back Offers 拦截
.task {
    for await message in StoreKit.Message.messages {
        if message.reason != .winBackOffer { try? displayStoreMessage(message) }
    }
}
```

## HealthKit 进阶（运动路线 / 多运动 / 统计集合）

### Workout Route（HKWorkoutRouteBuilder）
```swift
// 位置更新时添加路线数据
func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let filtered = locations.filter { $0.horizontalAccuracy <= 50.0 }
    guard !filtered.isEmpty else { return }
    routeBuilder.insertRouteData(filtered) { success, error in }
}

// 完成路线
routeBuilder.finishRoute(with: myWorkout, metadata: nil) { newRoute, error in }

// 读取路线位置点（分批返回）
let query = HKWorkoutRouteQuery(route: myRoute) { _, locations, done, error in
    guard let locations else { return }
    // 处理这批位置数据；done == true 时全部返回
}
healthStore.execute(query)
```

### 多运动 Workout（铁人三项等）
```swift
let config = HKWorkoutConfiguration()
config.activityType = .swimBikeRun; config.locationType = .outdoor
let session = try HKWorkoutSession(healthStore: store, configuration: config)
session.startActivity(with: .now)

// 切换到游泳
let swimConfig = HKWorkoutConfiguration()
swimConfig.activityType = .swimming; swimConfig.swimmingLocationType = .openWater
session.beginNewActivity(configuration: swimConfig, date: .now, metadata: nil)

// 过渡阶段
session.endCurrentActivity(on: .now)
let transConfig = HKWorkoutConfiguration(); transConfig.activityType = .transition
session.beginNewActivity(configuration: transConfig, date: .now, metadata: nil)
```

### Statistics Collection（周期统计）
```swift
let interval = DateComponents(day: 7)
let anchorDate = Calendar.current.nextDate(after: Date(), matching:
    DateComponents(hour: 3, minute: 0, weekday: 2), matchingPolicy: .nextTime, direction: .backward)!
let query = HKStatisticsCollectionQuery(quantityType: HKQuantityType(.stepCount),
    quantitySamplePredicate: nil, options: .cumulativeSum, anchorDate: anchorDate, intervalComponents: interval)
query.initialResultsHandler = { _, results, _ in
    let startDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
    results?.enumerateStatistics(from: startDate, to: Date()) { stats, _ in
        let steps = stats.sumQuantity()?.doubleValue(for: .count()) ?? 0
    }
}
healthStore.execute(query)
```

## CoreData 进阶

### Persistent History Tracking
```swift
// 启用历史追踪 + 远程变更通知
let desc = container.persistentStoreDescriptions.first
desc?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
desc?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

// 设置 transactionAuthor
viewContext.transactionAuthor = "addItem"
try viewContext.save()
viewContext.transactionAuthor = nil  // 保存后重置

// 获取历史变更
let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastToken)
let result = try bgContext.execute(request) as? NSPersistentHistoryResult
let transactions = result?.result as? [NSPersistentHistoryTransaction] ?? []

// 合并变更到 viewContext
for txn in transactions {
    viewContext.mergeChanges(fromContextDidSave: txn.objectIDNotification())
    lastToken = txn.token
}

// 清理 7 天前历史
let purge = NSPersistentHistoryChangeRequest.deleteHistory(
    before: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)
try bgContext.execute(purge)
```

### Lightweight Migration + Batch Fetch
```swift
// 自动轻量级迁移
let options = [NSMigratePersistentStoresAutomaticallyOption: true,
               NSInferMappingModelAutomaticallyOption: true]
try coordinator.addPersistentStore(type: .sqlite, at: storeURL, options: options)

// 批量 fetch
let request = NSFetchRequest<ShoppingItem>(entityName: "ShoppingItem")
request.fetchBatchSize = 10  // 每次从 SQLite 加载 10 条

// Query Generation（WAL pinning，隔离并发写入）
try viewContext.setQueryGenerationFrom(.current)
```

## SwiftData 进阶

### History Tracking（变更追踪）
```swift
// 获取 widget 写入的变更
var desc = History.HistoryDescriptor<History.DefaultTransaction>()
desc.predicate = #Predicate { ($0.token > savedToken) && ($0.author == "widget") }
let txns = try context.fetchHistory(desc)

// 过滤特定属性变更
for txn in txns {
    for change in txn.changes where change is History.DefaultUpdateChange<Trip> {
        if change.updatedAttributes.contains(\.flightTime) {
            let trip = try context.fetch(FetchDescriptor<Trip>(
                predicate: #Predicate { $0.persistentModelID == change.changedModelID })).first
        }
    }
}

// preserveValueOnDeletion + Tombstone
@Model final class Trip {
    @Attribute(.preserveValueOnDeletion) var bookingRef: String
}
// 从删除变更中读取保留值
if let deletion = change as? History.DefaultDeleteChange<Trip> {
    let ref = deletion.tombstone[\.bookingRef]
}
```

### Index / Unique 配置
```swift
@Model class Trip {
    #Index<Trip>([\.name], [\.startDate], [\.name, \.startDate, \.endDate])
    #Unique<Trip>([\.name, \.startDate, \.endDate])
    @Attribute(.preserveValueOnDeletion) var name: String
    var destination: String
}
```

### 动态 Query 重建
```swift
init(searchText: String, sortParam: SortParameter, sortOrder: SortOrder) {
    let predicate = #Predicate<Quake> { quake in
        searchText.isEmpty || quake.location.name.contains(searchText)
    }
    switch sortParam {
    case .time: _quakes = Query(filter: predicate, sort: \.time, order: sortOrder)
    case .magnitude: _quakes = Query(filter: predicate, sort: \.magnitude, order: sortOrder)
    }
}
```

## SwiftData + CloudKit 完整同步指南

### 必需 Capabilities
```
// 1. Signing & Capabilities → iCloud → 启用 CloudKit → 选择/创建 Container
// 2. Signing & Capabilities → Background Modes → 启用 "Remote notifications"
//    （系统静默推送通知 SwiftData 有新变更需同步）
```

### Schema 兼容性规则
```swift
// CloudKit 限制：
// - @Attribute(.unique)   → CloudKit 不强制唯一约束（并发同步无法保证）
// - @Relationship          → 必须 optional（iCloud 不保证原子处理关系变更）
// - deleteRule: .cascade  → 不支持（框架不立即同步变更）
// - 必须显式设置 inverse   → CloudKit 处理顺序不确定
// - Schema 推到生产后只能新增，不能删除类型或修改属性

@Model class Trip {
    var name: String
    var destination: String
    @Relationship(inverse: \BucketListItem.trip)  // 必须显式设 inverse
    var bucketList: [BucketListItem]? = []         // 必须 optional
}
```

### Schema 初始化（开发阶段，仅 DEBUG）
```swift
let config = ModelConfiguration()
#if DEBUG
try autoreleasepool {
    let desc = NSPersistentStoreDescription(url: config.url)
    desc.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
        containerIdentifier: "iCloud.com.example.Trips")
    desc.shouldAddStoreAsynchronously = false  // 同步加载，确保完成后再初始化
    if let mom = NSManagedObjectModel.makeManagedObjectModel(for: [Trip.self, Accommodation.self]) {
        let container = NSPersistentCloudKitContainer(name: "Trips", managedObjectModel: mom)
        container.persistentStoreDescriptions = [desc]
        container.loadPersistentStores { _, err in if let err { fatalError(err.localizedDescription) } }
        try container.initializeCloudKitSchema()  // 初始化 CloudKit schema
        if let store = container.persistentStoreCoordinator.persistentStores.first {
            try container.persistentStoreCoordinator.remove(store)  // 卸载，避免与 SwiftData 冲突
        }
    }
}
#endif
modelContainer = try ModelContainer(for: Trip.self, Accommodation.self, configurations: config)
```

### ModelConfiguration 选项
```swift
// 指定 CloudKit 容器（多容器时必须指定）
let config = ModelConfiguration(cloudKitDatabase: .private("iCloud.com.example.Trips"))

// 禁用自动同步（App 已有 CloudKit 使用，避免冲突）
let config = ModelConfiguration(cloudKitDatabase: .none)
```

### 服务器数据本地缓存模式（Upsert）
```swift
// @Attribute(.unique) + modelContext.insert() = 自动 upsert
// 如果 code 已存在 → 更新其他字段；不存在 → 插入新记录
@Model class Quake {
    @Attribute(.unique) var code: String  // 服务器唯一标识
    var magnitude: Double
    var time: Date
    var location: Location               // Codable struct 可直接嵌入
}

// 下载后批量 upsert
for feature in featureCollection.features {
    let quake = Quake(from: feature)
    if quake.magnitude > 0 { modelContext.insert(quake) }
}
// autosave 自动处理 insert + update，无需手动调用 save()
```

### Autosave 行为
```swift
// 默认 autosave = true：ModelContext 定期检查并保存未提交变更
// 手动 save：modelContext.save()（立即保存，不等待 autosave）
// 编辑表单模式：用 @State 变量暂存编辑值，点击 Save 时才写入 Model
// 这样 autosave 不会提前保存未完成的编辑

// 编辑器模式示例：
struct AnimalEditor: View {
    let animal: Animal?  // nil = 新建，非 nil = 编辑
    @State private var name = ""
    @State private var selectedDiet = Animal.Diet.herbivorous

    private func save() {
        if let animal {
            animal.name = name; animal.diet = selectedDiet  // autosave 自动保存
        } else {
            let new = Animal(name: name, diet: selectedDiet)
            modelContext.insert(new)  // autosave 自动保存
        }
    }
}
```

### SwiftData + CloudKit 同步调试
```bash
# Xcode Scheme → Arguments Passed On Launch 添加：
-com.apple.CoreData.CloudKitDebug 1
-com.apple.CoreData.Logging.stderr 1
-com.apple.CoreData.SQLDebug 1
-com.apple.CoreData.MigrationDebug 1
```
```swift
import CoreData

// 监听 CloudKit 同步事件
NotificationCenter.default.addObserver(
    forName: NSPersistentCloudKitContainer.eventChangedNotification,
    object: nil, queue: .main
) { notification in
    guard let event = notification.userInfo?[
        NSPersistentCloudKitContainer.eventNotificationUserInfoKey
    ] as? NSPersistentCloudKitContainer.Event else { return }
    switch event.type {
    case .setup:  print("CloudKit setup: \(event.succeeded)")
    case .import: print("CloudKit import: \(event.succeeded)")
    case .export: print("CloudKit export: \(event.succeeded)")
    @unknown default: break
    }
    if let error = event.error { print("Sync error: \(error)") }
}

// Schema 变更规则（生产环境）：
// ✅ 只能新增 Optional 属性
// ❌ 不能删除/重命名/修改类型/加密字段
// SwiftData 自动处理轻量迁移

// 调试 Checklist：
// □ iCloud 容器 ID 在 Capabilities 中正确配置
// □ 真机测试（模拟器 CloudKit 同步不可靠）
// □ Schema 变更后在 CloudKit Dashboard 重置开发环境
// □ 测试飞行模式 → 恢复网络的同步行为
// □ 验证多设备同步（iPhone + iPad/Mac 同时操作）
// □ 检查 CloudKit Dashboard 记录类型与 Model 一致
// □ App Sandbox 包含 com.apple.security.network.client
```

## Vision 进阶（轨迹检测 / 图像分类 / 3D 姿态 / 实例分割 / 目标追踪）

### 轨迹检测（实时视频帧）
```swift
let request = VNDetectTrajectoriesRequest(frameAnalysisSpacing: .zero, trajectoryLength: 15) { req, _ in
    guard let results = req.results as? [VNTrajectoryObservation] else { return }
    for trajectory in results where trajectory.confidence > 0.9 {
        print("轨迹半径: \(trajectory.movingAverageRadius)")
    }
}
request.objectMinimumNormalizedRadius = 10.0 / 1920.0
request.objectMaximumNormalizedRadius = 30.0 / 1920.0

// AVCaptureVideoDataOutputSampleBufferDelegate 中调用
func captureOutput(_ output: AVCaptureOutput, didOutput buffer: CMSampleBuffer, from conn: AVCaptureConnection) {
    try? VNImageRequestHandler(cmSampleBuffer: buffer).perform([request])
}
```

### 图像分类（Swift 6 异步 API）
```swift
func classifyImage(url: URL) async throws -> [String: Float] {
    let request = ClassifyImageRequest()
    let results = try await request.perform(on: url)
        .filter { $0.hasMinimumPrecision(0.1, forRecall: 0.8) }
    return Dictionary(uniqueKeysWithValues: results.map { ($0.identifier, $0.confidence) })
}
```

### 3D 人体姿态检测
```swift
let request = VNDetectHumanBodyPose3DRequest()
try VNImageRequestHandler(url: imageURL).perform([request])
if let obs = request.results?.first {
    let leftShoulder = try obs.recognizedPoint(.leftShoulder)
    let leftArm = try obs.recognizedPoints(.leftArm)  // 关节组
}
```

### 个体实例分割（每人独立掩码）
```swift
let request = VNGeneratePersonInstanceMaskRequest()
try VNImageRequestHandler(ciImage: image).perform([request])
if let mask = request.results?.first as? VNInstanceMaskObservation {
    for index in mask.allInstances {
        let buffer = try mask.generateScaledMaskForImage(forInstances: [index], from: handler)
        let maskImage = CIImage(cvPixelBuffer: buffer)
    }
}
```

### 多目标追踪
```swift
var inputObservations = [UUID: VNDetectedObjectObservation]()
for rect in objectsToTrack {
    let obs = VNDetectedObjectObservation(boundingBox: rect.boundingBox)
    inputObservations[obs.uuid] = obs
}
// 逐帧追踪
for (_, obs) in inputObservations {
    let request = VNTrackObjectRequest(detectedObjectObservation: obs)
    request.trackingLevel = .accurate
    try sequenceHandler.perform([request], on: frame, orientation: orientation)
    if let result = request.results?.first as? VNDetectedObjectObservation {
        inputObservations[result.uuid] = result
    }
}
```

## ARKit 进阶（LiDAR 深度 / 3D 对象扫描 / 场景重建 / 持久化世界地图）

### LiDAR 场景深度
```swift
guard ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) else { return }
let config = ARWorldTrackingConfiguration()
config.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
arSession.run(config)

func session(_ session: ARSession, didUpdate frame: ARFrame) {
    guard let depth = frame.smoothedSceneDepth ?? frame.sceneDepth else { return }
    let depthMap: CVPixelBuffer = depth.depthMap           // 每像素距离（米）
    let confidenceMap: CVPixelBuffer? = depth.confidenceMap
}
```

### 3D 对象扫描与检测
```swift
// 扫描阶段
let scanConfig = ARObjectScanningConfiguration()
scanConfig.planeDetection = .horizontal
sceneView.session.run(scanConfig, options: .resetTracking)

// 提取参考对象
sceneView.session.createReferenceObject(transform: box.simdWorldTransform,
    center: SIMD3<Float>(), extent: box.extent) { object, error in
    if let ref = object { ref.name = "myObject" }
}

// 检测阶段
let detectConfig = ARWorldTrackingConfiguration()
detectConfig.detectionObjects = ARReferenceObject.referenceObjects(inGroupNamed: "gallery", bundle: nil)!
sceneView.session.run(detectConfig)
```

### 场景重建 + 语义分类
```swift
let config = ARWorldTrackingConfiguration()
config.sceneReconstruction = .meshWithClassification
config.planeDetection = [.horizontal, .vertical]
arView.session.run(config)

arView.environment.sceneUnderstanding.options.insert(.occlusion)  // 真实物体遮挡虚拟内容
arView.environment.sceneUnderstanding.options.insert(.physics)    // 虚拟物体与真实网格碰撞
```

### 持久化世界地图
```swift
// 保存
sceneView.session.getCurrentWorldMap { map, _ in
    guard let map else { return }
    let data = try! NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
    try! data.write(to: mapSaveURL, options: .atomic)
}

// 加载恢复
let data = try Data(contentsOf: mapSaveURL)
let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)!
let config = ARWorldTrackingConfiguration()
config.initialWorldMap = worldMap
sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
```

### 多用户共享 AR（MultipeerConnectivity）
```swift
// 发送世界地图
sceneView.session.getCurrentWorldMap { map, _ in
    guard let map, let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
    else { return }
    multipeerSession.sendToAllPeers(data)
}

// 接收并应用
if let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
    let config = ARWorldTrackingConfiguration()
    config.initialWorldMap = worldMap
    sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
}
```

## RealityKit 进阶（粒子系统 / 自定义着色器 / 动画 / IBL 光照）

### 粒子发射器
```swift
var emitter = ParticleEmitterComponent.Presets.fireworks  // 或 ParticleEmitterComponent()
emitter.speed = 0.2
emitter.mainEmitter.birthRate = 150

// 颜色渐变（生命周期内变化）
typealias PC = ParticleEmitterComponent.ParticleEmitter.ParticleColor
let c1 = ParticleEmitterComponent.ParticleEmitter.Color(.red)
let c2 = ParticleEmitterComponent.ParticleEmitter.Color(.blue)
emitter.mainEmitter.color = PC.evolving(start: .single(c1), end: .single(c2))

// 自定义粒子图像
if let tex = try? TextureResource.generate(from: cgImage, options: .init(semantic: .raw)) {
    emitter.mainEmitter.image = tex
}
entity.components.set(emitter)
```

### 自定义 Metal 着色器（CustomMaterial）
```swift
let library = MTLCreateSystemDefaultDevice()!.makeDefaultLibrary()!
let surfaceShader = CustomMaterial.SurfaceShader(named: "mySurfaceShader", in: library)
let geoModifier = CustomMaterial.GeometryModifier(named: "waveModifier", in: library)
let material = try CustomMaterial(surfaceShader: surfaceShader, geometryModifier: geoModifier, lightingModel: .lit)
let entity = ModelEntity(mesh: .generateSphere(radius: 0.5), materials: [material])

// 从已有 USDZ 材质创建（保留纹理）
guard var modelComp = robot.components[ModelComponent.self] else { return }
modelComp.materials = try modelComp.materials.map { try CustomMaterial(from: $0, surfaceShader: surfaceShader) }
robot.components[ModelComponent.self] = modelComp
```

### IBL 环境光照
```swift
if let resource = try? EnvironmentResource.generate(fromEquirectangular: myHDRImage) {
    rootNode.components.set(ImageBasedLightComponent(environment: resource, intensityExponent: 10.0))
}
```

## App Intents 进阶（FocusFilter / 交互式 Snippets / 参数提供器）

### FocusFilter（焦点过滤）
```swift
struct ExampleFocusFilter: SetFocusFilterIntent {
    @Parameter(title: "Use Dark Mode", default: false) var alwaysUseDarkMode: Bool
    @Parameter(title: "Status Message") var status: String?
    @Parameter(title: "Selected Account") var account: AccountEntity?

    var appContext: FocusFilterAppContext {
        let predicate: NSPredicate = account != nil
            ? NSPredicate(format: "SELF IN %@", [account!.id])
            : NSPredicate(value: true)
        return FocusFilterAppContext(notificationFilterPredicate: predicate)
    }
}
```

### 交互式 Snippets
```swift
// 返回带 SwiftUI View 的结果
func perform() async throws -> some IntentResult & ShowsSnippetView {
    .result(view: LandmarkView(landmark: landmark, isFavorite: isFavorite))
}

// Snippet 序列 + 确认
try await requestConfirmation(actionName: .search,
    snippetIntent: TicketRequestSnippetIntent(searchRequest: request))
```

### 动态参数选项
```swift
struct LocationOptionsProvider: DynamicOptionsProvider {
    @Dependency private var trailManager: TrailDataManager
    func results() async throws -> [String] {
        trailManager.uniqueLocations.sorted(using: KeyPathComparator(\.self, comparator: .localizedStandard))
    }
}

// 条件参数摘要
static var parameterSummary: some ParameterSummary {
    When(\.$location, .hasAnyValue) {
        Summary("Find trails within \(\.$searchRadius) of \(\.$location)")
    } otherwise: {
        Summary("Find trails from \(\.$trailCollection)")
    }
}
```

## Foundation 进阶（后台下载 / 认证挑战 / Handoff）

### 后台 URLSession 下载
```swift
private lazy var urlSession: URLSession = {
    let config = URLSessionConfiguration.background(withIdentifier: "MySession")
    config.isDiscretionary = true
    config.sessionSendsLaunchEvents = true
    return URLSession(configuration: config, delegate: self, delegateQueue: nil)
}()

let task = urlSession.downloadTask(with: url)
task.earliestBeginDate = Date().addingTimeInterval(3600)
task.countOfBytesClientExpectsToReceive = 500 * 1024
task.resume()

// AppDelegate 保存系统回调
func application(_ app: UIApplication, handleEventsForBackgroundURLSession id: String,
                 completionHandler: @escaping () -> Void) {
    backgroundCompletionHandler = completionHandler
}

// 下载完成
func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                didFinishDownloadingTo location: URL) {
    let dest = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        .appendingPathComponent(location.lastPathComponent)
    try? FileManager.default.moveItem(at: location, to: dest)
}
```

### 认证挑战（HTTP Basic / Server Trust）
```swift
// HTTP Basic 认证
func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic else {
        completionHandler(.performDefaultHandling, nil); return
    }
    let credential = URLCredential(user: username, password: password, persistence: .forSession)
    completionHandler(.useCredential, credential)
}

// 服务器证书验证
guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
      let serverTrust = challenge.protectionSpace.serverTrust else {
    completionHandler(.performDefaultHandling, nil); return
}
completionHandler(.useCredential, URLCredential(trust: serverTrust))
```

### Handoff / NSUserActivity
```swift
let activity = NSUserActivity(activityType: "com.app.viewItem")
activity.isEligibleForHandoff = true
activity.title = "Viewing Item"
activity.addUserInfoEntries(from: ["itemID": item.id])

// 接收端
func application(_ app: UIApplication, continue userActivity: NSUserActivity,
                 restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    guard let itemID = userActivity.userInfo?["itemID"] as? String else { return false }
    navigate(to: itemID)
    return true
}
```

## Authentication Services 进阶（Security Key / 凭证扩展）

### Security Key 认证（物理密钥）
```swift
let provider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider("example.com")
let request = provider.createCredentialRegistrationRequest(
    challenge: challenge, displayName: "Anne", name: "anne@icloud.com", userID: "anne")
request.credentialParameters = [ASAuthorizationPublicKeyCredentialParameters(algorithm: .ES256)]
let controller = ASAuthorizationController(authorizationRequests: [request])
controller.delegate = self; controller.performRequests()

// 断言（验证）
let assertionRequest = provider.createCredentialAssertionRequestWithChallenge(challenge)
```

### Credential Provider Extension（密码自动升级）
```swift
class AccountAuthModVC: ASAccountAuthenticationModificationViewController {
    override func changePasswordWithoutUserInteraction(
        for serviceID: ASCredentialServiceIdentifier,
        existingCredential: ASPasswordCredential, newPassword: String, userInfo: [AnyHashable: Any]?) {
        // 向服务器验证并更新密码
        let newCredential = ASPasswordCredential(user: existingCredential.user, password: newPassword)
        extensionContext.completeChangePasswordRequest(updatedCredential: newCredential)
    }
}

// 升级为 Sign in with Apple
extensionContext.getSignInWithAppleUpgradeAuthorization(state: myState, nonce: myNonce) { credential, error in
    guard let credential else { return }
    let userID = credential.user
    // 向服务器提交转换
    self.extensionContext.completeUpgradeToSignInWithApple()
}
```

## watchOS 开发（Extended Runtime + 后台执行）

### Extended Runtime Sessions
```swift
import WatchKit

// 启用：WatchKit Extension → Background Modes → 选择 session 类型
// 每个 App 只能支持一种 Extended Runtime Session 类型

let session = WKExtendedRuntimeSession()
session.delegate = self
session.start()  // 必须在 .active 状态时启动

// Smart Alarm 可预约（其他类型立即启动）
session.start(at: scheduledDate)  // 最多提前 36 小时

// 结束
session.invalidate()

// Delegate
func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) { }
func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {
    // 清理工作，即将到期
}
func extendedRuntimeSession(_ session: WKExtendedRuntimeSession,
    didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) { }
```

**Session 类型对比**：
| 类型 | 运行位置 | 可预约 | 时间限制 |
|------|---------|--------|---------|
| Self Care | 前台 | 否 | 10 分钟 |
| Mindfulness | 前台 | 否 | 1 小时 |
| Physical Therapy | 后台 | 否 | 1 小时 |
| Smart Alarm | 后台 | 是（36h内）| 30 分钟 |

### 后台执行模式
```swift
// watchOS 后台任务（BackgroundTask modifier）
@main struct MyWatchApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
            .backgroundTask(.appRefresh("refresh")) {
                await refreshContent()
            }
    }
}

// 持续后台会话（需对应 Background Mode）：
// - HKWorkoutSession     → 运动追踪
// - AVAudioSession        → 音频播放
// - CLBackgroundActivitySession → 位置更新

// 注意：ClockKit 已在 watchOS 10 废弃
// 迁移到 WidgetKit 创建表盘复杂功能
// 有活跃 Complication 的 App 会获得更多后台刷新机会
```

## tvOS 开发（Focus Engine + Game Controller）
```swift
// === Focus Engine ===
// tvOS 所有交互基于焦点系统（Siri Remote 遥控器）
// SwiftUI 自动支持焦点；UIKit 用标准 focus API

// 自定义焦点外观（tvOS Liquid Glass 自动适用于标准控件）
Button("Play") { startPlayback() }
    .focusable()
    .focused($isFocused)

// === Game Controller ===
import GameController

// 检测已连接的控制器
NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { note in
    guard let controller = note.object as? GCController else { return }
    if let gamepad = controller.extendedGamepad {
        gamepad.buttonA.pressedChangedHandler = { _, _, pressed in
            if pressed { jump() }
        }
        gamepad.leftThumbstick.valueChangedHandler = { _, xValue, yValue in
            movePlayer(x: xValue, y: yValue)
        }
    }
}

// Siri Remote 作为 micro gamepad
if let remote = GCController.current?.microGamepad {
    remote.dpad.valueChangedHandler = { _, xValue, yValue in
        navigate(x: xValue, y: yValue)
    }
}
```

## visionOS 进阶（3D 内容 / Room Tracking / 隐私）

### Windows vs Volumes vs Immersive Spaces
```swift
// Window（2D 为主 + 深度效果）
WindowGroup { ContentView() }

// Volume（3D 内容，固定缩放，物理单位）
WindowGroup(id: "globe") { Globe() }
    .windowStyle(.volumetric)
    .defaultSize(width: 1, height: 1, depth: 1, in: .meters)  // 1 立方米

// Immersive Space（无限空间，控制放置位置）
ImmersiveSpace(id: "solar") { SolarSystemView() }
    .immersionStyle(selection: $style, in: .mixed, .full)
// .mixed = 与现实共存  .full = 完全沉浸（隐藏其他 App）

// 打开沉浸式空间
@Environment(\.openImmersiveSpace) var openImmersiveSpace
Button("Enter") {
    Task { let result = await openImmersiveSpace(id: "solar") }
}
// 注意：同一时间只能有一个 Immersive Space
```

### Room Tracking
```swift
import ARKit

let session = ARKitSession()
let roomTracking = RoomTrackingProvider()
try await session.run([roomTracking])

for await update in roomTracking.anchorUpdates {
    let roomAnchor = update.anchor
    switch update.event {
    case .added, .updated:
        if roomAnchor.isCurrentRoom {
            // 当前房间 → 更新内容
            let mesh = roomAnchor.geometry.asMeshResource()
        }
    case .removed:
        // 房间不再有效
        break
    }
}
// Info.plist: NSWorldSensingUsageDescription 必须设置
```

### visionOS 隐私
```swift
// 系统自动处理眼睛/手部追踪用于交互，App 无需获取原始数据
// 仅在确实需要时请求 ARKit 数据（如手部位置绑定 3D 内容）
let auth = await ARKitSession().queryAuthorization(for: [.worldSensing, .handTracking])
guard auth[.worldSensing] != .denied else { return }

// 必需 Info.plist keys：
// NSWorldSensingUsageDescription  → 世界追踪
// NSHandTrackingUsageDescription  → 手部追踪
// 其他隐私 key 同 iOS（CoreLocation 等）
```

## App Store Connect API
```swift
// === JWT Token 生成（ES256）===
// Header: { "alg": "ES256", "kid": "<Key ID>", "typ": "JWT" }
// Payload（Team Key）:
// {
//   "iss": "<Issuer ID>",           // Users and Access → Integrations
//   "iat": 1528407600,              // UNIX 时间戳
//   "exp": 1528408800,              // 最长 20 分钟（部分 GET 可 6 个月）
//   "aud": "appstoreconnect-v1",
//   "scope": ["GET /v1/apps?filter[platform]=IOS"]  // 可选，限制请求范围
// }
// 用私钥签名后在请求中使用：
// Authorization: Bearer <signed-token>

// API Key 类型：
// Team Key   → 访问所有 App，需 Admin 创建
// Individual → 绑定用户权限和 App 范围

// 私钥只能下载一次，Apple 不保存副本！

// === 常用 API ===
// GET  /v1/apps                        → 获取 App 列表
// POST /v1/subscriptionGroups          → 创建订阅组
// POST /v1/subscriptionGroupLocalizations → 添加订阅组本地化
// GET  /v1/salesReports                → 销售报告
// GET  /v1/financeReports              → 财务报告

// TestFlight 自动化：
// 邀请测试员、管理构建版本、创建公开链接、提交外部测试审核
```

## App 发布分发流程
```
1. Product → Archive（选择 scheme + 目标设备类型）
2. Window → Organizer → 选择 Archive → Validate App
3. Distribute App → 选择分发方式：
   - TestFlight（内/外部测试）
   - App Store（正式发布）
   - Ad Hoc（注册设备，有设备数限制）
   - Developer ID（macOS 公证分发，非 App Store）
   - Enterprise（企业内部分发）

4. 代码签名：Automatically manage signing（推荐）或手动
5. dSYM 管理：
   - Build Settings → Debug Information Format → DWARF with dSYM File
   - 上传到 App Store Connect 时包含 Symbols
   - 保留每个分发版本的 Xcode Archive（dSYM 需匹配 build UUID）

// Mac Catalyst：iPad 和 Mac 版本需分别 Archive
// Xcode 15+：模拟器目标也可 Archive
```

## APNs HTTP/2 推送请求格式
```
// 连接：api.push.apple.com:443 (生产) / api.sandbox.push.apple.com:443 (开发)
// 也可用 port 2197

POST /3/device/<device_token>

// 必需 Headers：
:method        = POST
:path          = /3/device/<hex_device_token>
apns-topic     = com.example.MyApp           // Bundle ID
apns-push-type = alert                        // alert/background/voip/complication 等

// 可选 Headers：
authorization   = bearer <JWT>                // Token 认证
apns-id         = <UUID>                      // 唯一通知 ID
apns-expiration = 0                           // 0=仅尝试一次，非0=存储重试
apns-priority   = 10                          // 10=立即, 5=省电, 1=最省电
apns-collapse-id = <string max 64bytes>       // 合并通知

// Body（JSON，最大 4KB，VoIP 5KB）
{ "aps": { "alert": { "title": "Hello", "body": "World" }, "sound": "default" } }

// 最佳实践：
// - 每次连接前 DNS 查询（分散负载到所有服务器）
// - 复用连接（数小时~数天），空闲 1h 后发 HTTP/2 PING
// - HPACK 压缩：:path 和 authorization 用 literal without indexing
// - 创建唯一 apns-id 便于调试
```

### 本地通知调度
```swift
// 日历触发（每周二 14:00）
var dateComponents = DateComponents()
dateComponents.weekday = 3; dateComponents.hour = 14
let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

// 时间间隔触发（60 秒后）
let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)

// 位置触发
let region = CLCircularRegion(center: coord, radius: 200, identifier: "office")
region.notifyOnEntry = true
let trigger = UNLocationNotificationTrigger(region: region, repeats: false)

let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
try await UNUserNotificationCenter.current().add(request)

// 取消通知
UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
```

## 深度链接路由（完整架构）

### 路由定义（URL Scheme + Universal Links 统一）
```swift
enum AppRoute: Hashable {
    case home
    case articleDetail(id: String)
    case userProfile(username: String)
    case settings(section: String?)
    case search(query: String)

    init?(url: URL) {
        let path = url.pathComponents.dropFirst()  // 去掉 "/"
        let params = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.reduce(into: [:]) { $0[$1.name] = $1.value } ?? [:]
        switch path.first {
        case "articles": guard let id = path.dropFirst().first else { return nil }; self = .articleDetail(id: String(id))
        case "users": guard let u = path.dropFirst().first else { return nil }; self = .userProfile(username: String(u))
        case "settings": self = .settings(section: params["section"])
        case "search": self = .search(query: params["q"] ?? "")
        default: return nil
        }
    }
}
```

### Router（含延迟导航 / 推送通知处理）
```swift
@MainActor @Observable
final class Router {
    var path = NavigationPath()
    var pendingRoute: AppRoute?  // 冷启动时暂存

    func navigate(to route: AppRoute) { path.append(route) }
    func popToRoot() { path = NavigationPath() }

    func handle(url: URL) {
        guard let route = AppRoute(url: url) else { return }
        path = NavigationPath(); navigate(to: route)
    }

    func handle(notification: UNNotificationResponse) {
        let userInfo = notification.notification.request.content.userInfo
        guard let urlStr = userInfo["deep_link"] as? String,
              let url = URL(string: urlStr), let route = AppRoute(url: url) else { return }
        if UIApplication.shared.applicationState == .background {
            navigate(to: route)
        } else {
            pendingRoute = route  // 等视图树就绪
        }
    }

    func processPendingRoute() {
        guard let route = pendingRoute else { return }
        pendingRoute = nil; navigate(to: route)
    }
}
```

### NavigationStack 集成
```swift
struct RootView: View {
    @Environment(Router.self) var router
    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .home: HomeView()
                    case .articleDetail(let id): ArticleDetailView(id: id)
                    case .userProfile(let u): UserProfileView(username: u)
                    case .settings(let s): SettingsView(section: s)
                    case .search(let q): SearchView(initialQuery: q)
                    }
                }
        }
        .onOpenURL { url in router.handle(url: url) }
        .task { router.processPendingRoute() }
    }
}

@main struct MyApp: App {
    @State private var router = Router()
    var body: some Scene {
        WindowGroup { RootView().environment(router) }
    }
}
```

## 统一错误处理

### AppError 类型（typed throws）
```swift
enum AppError: LocalizedError {
    case network(NetworkError)
    case database(Error)
    case authentication(AuthError)
    case validation(String)
    case unknown(Error)

    init(_ error: Error) {
        switch error {
        case let e as NetworkError: self = .network(e)
        case let e as AuthError: self = .authentication(e)
        default: self = .unknown(error)
        }
    }

    var errorDescription: String? {
        switch self {
        case .network(let e): e.localizedDescription
        case .database: "数据存储错误，请重试"
        case .authentication(let e): e.localizedDescription
        case .validation(let msg): msg
        case .unknown: "发生未知错误"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .network, .database: true
        case .authentication, .validation, .unknown: false
        }
    }
}

enum NetworkError: LocalizedError {
    case noConnection, timeout, serverError(statusCode: Int), invalidResponse
    var errorDescription: String? {
        switch self {
        case .noConnection: "无网络连接"
        case .timeout: "请求超时"
        case .serverError(let code): "服务器错误（\(code)）"
        case .invalidResponse: "无效数据"
        }
    }
}

// async throws(AppError)（Swift 6 typed throws）
func fetchArticle(id: String) async throws(AppError) -> Article {
    do { return try await repository.fetchArticle(id: id) }
    catch let error as AppError { throw error }
    catch { throw AppError(error) }
}
```

### 全局错误展示 Modifier
```swift
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: AppError?
    func body(content: Content) -> some View {
        content.alert(error?.errorDescription ?? "错误", isPresented: .constant(error != nil), presenting: error) { err in
            if err.isRetryable { Button("重试") { /* 触发重试 */ } }
            Button("关闭", role: .cancel) { error = nil }
        }
    }
}
extension View {
    func errorAlert(error: Binding<AppError?>) -> some View { modifier(ErrorAlertModifier(error: error)) }
}

// 使用
List { ... }.errorAlert(error: $vm.error)
```

## 分页 / 无限滚动

### 分页状态机
```swift
enum PaginationState: Equatable {
    case idle, loading, loaded(hasMore: Bool), error(String)
    var canLoadMore: Bool { if case .loaded(let h) = self { return h }; return false }
}

@MainActor @Observable
final class PaginatedViewModel<T: Identifiable & Sendable> {
    private(set) var items: [T] = []
    private(set) var state: PaginationState = .idle
    private var currentPage = 0
    private let pageSize = 20
    private let loader: (Int, Int) async throws -> [T]

    init(loader: @escaping (Int, Int) async throws -> [T]) { self.loader = loader }

    func loadFirst() async {
        guard state == .idle else { return }
        state = .loading; currentPage = 0; items = []
        await loadPage()
    }

    func loadMore() async {
        guard state.canLoadMore else { return }
        state = .loading; await loadPage()
    }

    private func loadPage() async {
        do {
            let new = try await loader(currentPage, pageSize)
            items.append(contentsOf: new)
            currentPage += 1
            state = .loaded(hasMore: new.count >= pageSize)
        } catch { state = .error(error.localizedDescription) }
    }
}
```

### 无限滚动 View
```swift
struct InfiniteScrollView<T: Identifiable & Sendable, Row: View>: View {
    @Bindable var vm: PaginatedViewModel<T>
    let row: (T) -> Row

    var body: some View {
        List {
            ForEach(vm.items) { item in
                row(item)
                    .onAppear {
                        if item.id == vm.items.last?.id { Task { await vm.loadMore() } }
                    }
            }
            switch vm.state {
            case .loading: ProgressView().frame(maxWidth: .infinity).listRowSeparator(.hidden)
            case .error(let msg): Button("重试") { Task { await vm.loadMore() } }.foregroundStyle(.red)
            case .loaded(hasMore: false): Text("已加载全部").foregroundStyle(.secondary).frame(maxWidth: .infinity)
            default: EmptyView()
            }
        }
        .refreshable { await vm.loadFirst() }
        .task { if vm.state == .idle { await vm.loadFirst() } }
    }
}

// 使用
@State private var vm = PaginatedViewModel<Article> { page, size in
    try await ArticleAPI.fetch(page: page, size: size)
}
InfiniteScrollView(vm: vm) { article in ArticleRow(article: article) }

// 提前 5 个触发预加载
ForEach(Array(vm.items.enumerated()), id: \.element.id) { index, item in
    row(item).onAppear {
        if index >= vm.items.count - 5 { Task { await vm.loadMore() } }
    }
}
```

## 图片缓存策略

### URLCache 配置
```swift
extension URLCache {
    static let imageCache = URLCache(
        memoryCapacity: 50 * 1024 * 1024,   // 50MB 内存
        diskCapacity: 200 * 1024 * 1024,     // 200MB 磁盘
        directory: URL.cachesDirectory.appending(path: "ImageCache"))
}
extension URLSession {
    static let imageSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = .imageCache
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()
}
```

### 轻量图片缓存（NSCache + 磁盘）
```swift
@Observable
final class ImageCache {
    static let shared = ImageCache()
    private let memory = NSCache<NSString, UIImage>()
    private let cacheDir = URL.cachesDirectory.appending(path: "Images")

    private init() {
        memory.countLimit = 100; memory.totalCostLimit = 50 * 1024 * 1024
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    func image(for url: URL) -> UIImage? {
        let key = url.absoluteString as NSString
        if let img = memory.object(forKey: key) { return img }
        let path = cacheDir.appending(path: "\(url.absoluteString.hash).jpg")
        if let data = try? Data(contentsOf: path), let img = UIImage(data: data) {
            memory.setObject(img, forKey: key); return img
        }
        return nil
    }

    func store(_ image: UIImage, for url: URL) {
        memory.setObject(image, forKey: url.absoluteString as NSString)
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            let path = self.cacheDir.appending(path: "\(url.absoluteString.hash).jpg")
            try? image.jpegData(compressionQuality: 0.8)?.write(to: path)
        }
    }

    func clearMemory() { memory.removeAllObjects() }
}
```

### CachedAsyncImage 组件
```swift
struct CachedAsyncImage: View {
    let url: URL?
    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().aspectRatio(contentMode: .fill) }
            else if isLoading { ProgressView() }
            else { Image(systemName: "photo").resizable().foregroundStyle(.secondary) }
        }
        .task(id: url) {
            guard let url else { return }
            if let cached = ImageCache.shared.image(for: url) { image = cached; return }
            isLoading = true; defer { isLoading = false }
            if let (data, _) = try? await URLSession.imageSession.data(from: url),
               let img = UIImage(data: data) {
                ImageCache.shared.store(img, for: url); image = img
            }
        }
    }
}

// 内存压力响应
func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
    ImageCache.shared.clearMemory()
    URLCache.imageCache.removeAllCachedResponses()
}
```

## App 架构模式（MVVM + Repository + UseCase）

### Repository 协议 + 实现
```swift
// Domain 层：纯协议
protocol ArticleRepository {
    func fetchArticles(page: Int) async throws -> [Article]
    func fetchArticle(id: String) async throws -> Article
    func saveArticle(_ article: Article) async throws
}

// Data 层：缓存 → 网络 → 本地持久化
final class ArticleRepositoryImpl: ArticleRepository {
    private let remote: ArticleRemoteDataSource
    private let local: ArticleLocalDataSource
    private let cache: ArticleCache

    init(remote: ArticleRemoteDataSource, local: ArticleLocalDataSource, cache: ArticleCache) {
        self.remote = remote; self.local = local; self.cache = cache
    }

    func fetchArticles(page: Int) async throws -> [Article] {
        if let cached = cache.articles(page: page) { return cached }
        let articles = try await remote.fetchArticles(page: page)
        try await local.saveArticles(articles)
        cache.store(articles, page: page)
        return articles
    }
}
```

### ViewModel（Swift 6.2 严格并发）
```swift
@MainActor @Observable
final class HomeViewModel {
    private(set) var articles: [Article] = []
    private(set) var isLoading = false
    private(set) var error: AppError?

    private let fetchArticles: FetchArticlesUseCase

    init(fetchArticles: FetchArticlesUseCase) {
        self.fetchArticles = fetchArticles
    }

    func onAppear() async { await load() }
    func refresh() async { await load() }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true; error = nil
        defer { isLoading = false }
        do { articles = try await fetchArticles() }
        catch { self.error = AppError(error) }
    }
}
```

### UseCase（单一职责 + callAsFunction）
```swift
struct FetchArticlesUseCase {
    private let repository: any ArticleRepository
    init(repository: any ArticleRepository) { self.repository = repository }

    func callAsFunction(page: Int = 1) async throws -> [Article] {
        try await repository.fetchArticles(page: page)
            .filter { !$0.isHidden }
            .sorted { $0.publishedAt > $1.publishedAt }
    }
}
```

## 依赖注入（DI）

**方案对比**：
| 方案 | 适用场景 | 优点 | 缺点 |
|---|---|---|---|
| 构造器注入 | ViewModel/UseCase/Repository | 明确依赖、易测试 | 层层传递繁琐 |
| `@Environment` | View 层全局依赖 | SwiftUI 原生 | 仅限 View 层 |
| `@Dependency` | 全局（含非 View 层）| 功能强、支持测试覆盖 | 需三方库 |
| 单例 | 无状态工具（日志/分析）| 简单 | 难测试、全局状态 |

### 轻量 DI 容器（无三方库）
```swift
final class DIContainer {
    static let shared = DIContainer()
    private var factories: [ObjectIdentifier: Any] = [:]
    private var singletons: [ObjectIdentifier: Any] = [:]

    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        factories[ObjectIdentifier(type)] = factory
    }
    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        singletons[ObjectIdentifier(type)] = factory()
    }
    func resolve<T>(_ type: T.Type) -> T {
        let key = ObjectIdentifier(type)
        if let s = singletons[key] as? T { return s }
        guard let f = factories[key] as? () -> T else { fatalError("No registration for \(type)") }
        return f()
    }
}

// App 启动时注册
extension DIContainer {
    static func setup() {
        let c = DIContainer.shared
        c.registerSingleton(ArticleCache.self) { .init() }
        c.register(ArticleRemoteDataSource.self) { ArticleRemoteDataSourceImpl(session: .shared) }
        c.registerSingleton((any ArticleRepository).self) {
            ArticleRepositoryImpl(
                remote: c.resolve(ArticleRemoteDataSource.self),
                local: ArticleLocalDataSourceImpl(),
                cache: c.resolve(ArticleCache.self))
        }
        c.register(FetchArticlesUseCase.self) {
            FetchArticlesUseCase(repository: c.resolve((any ArticleRepository).self))
        }
    }
}
```

### Environment Key 注入（View 层）
```swift
private struct ArticleRepoKey: EnvironmentKey {
    static let defaultValue: any ArticleRepository = ArticleRepositoryImpl.preview
}
extension EnvironmentValues {
    var articleRepository: any ArticleRepository {
        get { self[ArticleRepoKey.self] }
        set { self[ArticleRepoKey.self] = newValue }
    }
}

// 使用
@Environment(\.articleRepository) var repo

// Preview 中替换
#Preview { ArticleListView().environment(\.articleRepository, MockArticleRepository()) }
```

### 测试中替换依赖
```swift
@Test func loadSuccess() async throws {
    let mockRepo = MockArticleRepository()
    mockRepo.stubbedArticles = Article.mocks
    let useCase = FetchArticlesUseCase(repository: mockRepo)
    let vm = await HomeViewModel(fetchArticles: useCase)
    await vm.onAppear()
    #expect(await vm.articles.count == Article.mocks.count)
}
```

## 常见坑点（2026 完整版）
1. **Liquid Glass**：多个 `.glassEffect()` 必须包在 `GlassEffectContainer` 中，否则性能严重下降
2. **Foundation Models**：必须 `prewarm()` + 用 `contextSize/tokenCount` 动态管理上下文
3. **SwiftData**：Schema 生产只能新增字段；`@Attribute(.unique)` 防重复；Preview 用 `inMemory: true`；CoreData 共存时开启 `NSPersistentHistoryTrackingKey`
4. **App Intents**：`AppShortcuts` 短语必须包含 `\(.applicationName)`；AssistantSchemas 需精确匹配 schema
5. **HealthKit**：每次启动重新检查权限；后台交付需配置 Background Modes；临床记录仅可读
6. **CloudKit**：加密字段不支持 CKAsset 和谓词查询；Schema 部署后不可删改字段
7. **CoreBluetooth**：RSSI >= -50 过滤弱信号；大数据分块传输并加 "EOM" 终止标记
8. **RealityKit**：SceneKit 已软废弃；ECS 管理复杂场景；visionOS 移动世界而非相机
9. **CoreMotion**：使用完毕立即 `stop*()`；visionOS 需在 immersive space 内才能获取数据
10. **AVFoundation**：`CaptureSession` 操作用 `actor` 隔离到后台线程；`CIContext` 全局复用
11. **Vision/CoreML**：Vision 坐标系原点在左下角，需用 `VNImageRectForNormalizedRect` 转换；模型编译后缓存到 Application Support
12. **ARKit**：协同会话前让用户设备靠拢扫描同一空间；`environmentTexturing` 消耗较多 GPU
13. **BackgroundTasks**：`BGContinuedProcessingTask` 需在 Xcode Capabilities 勾选；调试用 lldb `_simulateLaunch`
14. **StoreKit 2**：监听 `Transaction.updates` 处理服务端推送；`AppStore.sync()` 恢复购买
15. **EventKit**：iOS 17+ 优先用 `requestWriteOnlyAccessToEvents()` 降低权限打扰；监听 `EKEventStoreChanged`
16. **性能**：先用 Xcode 26 Performance Instrument profile，再优化；标准 Stack 优先，100+ 再用 LazyStack
17. **并发**：UI 更新必须在 `@MainActor`；共享可变状态用 `actor` 隔离；避免 `Task.detached` 逃逸主 actor
18. **Keychain**：`SecItemAdd` 前先 `SecItemDelete` 防重复；设置 `kSecAttrAccessibleWhenUnlocked` 保护数据
19. **Passkeys**：先检查 `authorizationStateForPlatformCredentials` 再发起请求；服务端需实现 WebAuthn 标准
20. **Accessibility**：用 `.accessibilityElement(children: .combine)` 合并卡片；避免图片缺少 `accessibilityLabel`
21. **Localization**：`^[count item](inflect: true)` 自动处理复数；日期/货币用 `.formatted()` 而非手动格式化
22. **DocumentGroup**：`FileDocument` 的 `readableContentTypes` 必须注册 UTType；`fileWrapper` 中用 `.atomic` 写入
23. **SpriteKit**：`SKScene.scaleMode = .resizeFill` 适配不同屏幕；物理引擎在后台会继续运行，切后台时 `isPaused = true`
24. **CIFilter**：`CIContext` 创建昂贵，全局仅创建一次；滤镜链自动合并优化
25. **Custom Layout**：`sizeThatFits` 和 `placeSubviews` 可能被多次调用，避免副作用；用 `makeCache` 缓存昂贵计算
26. **Swift Testing**：`@Test` 默认并行执行，共享资源时用 `@Suite(.serialized)`；`#require` 失败立即终止比 `#expect` 更适合前置条件
27. **Swift Macros**：宏实现必须在独立 macro target（不能和主 App 混编）；宏只能操作语法树不能读取类型信息
28. **崩溃诊断**：App Store 崩溃报告需确保 dSYM 已上传；`0x8badf00d` 是 watchdog 超时（主线程阻塞 >20 秒）
29. **xcconfig**：`$(inherited)` 必须显式写，否则覆盖而非追加；条件设置 `[sdk=*][arch=*]` 可组合使用
30. **Combine**：`AnyCancellable` 必须持有引用，否则订阅立即取消；`receive(on: RunLoop.main)` 确保 UI 更新在主线程
31. **NWConnection**：连接必须调用 `start(queue:)` 才会开始；TLS 自签名证书需自定义 `verify_block`
32. **CoreLocation CLMonitor**：iOS 17+ 替代旧 `CLLocationManager` 区域监控；`CLBackgroundActivitySession` 需在前台先获取授权
33. **iBeacon**：`startMonitoring` 检测进出区域，`startRangingBeacons` 测距；信号强度受环境影响大
34. **MapKit Overlays**：`rendererFor overlay` 代理方法按类型分发渲染器；GeoJSON 用 `MKGeoJSONDecoder` 解析
35. **通信通知**：需在 Notification Service Extension 中 `donate()` INInteraction；`mutable-content: 1` 才能触发 NSE
36. **CoreData History**：`transactionAuthor` 保存后立即重置为 nil；历史 token 需持久化到磁盘
37. **SwiftData History**：`preserveValueOnDeletion` 标记的属性可在 tombstone 中读取；`fetchHistory` 需在独立 `ModelContext` 中调用
38. **VNDetectTrajectoriesRequest**：需连续帧输入，单张图片无效；`objectMinimumNormalizedRadius` 单位是归一化值
39. **ARKit LiDAR**：仅 Pro 机型支持 `.sceneDepth`；`smoothedSceneDepth` 比 `sceneDepth` 更稳定
40. **ARWorldMap**：保存前检查 `worldMappingStatus == .mapped`；加载时用 `.resetTracking` 选项
41. **RealityKit 粒子**：`ParticleEmitterComponent.Presets` 提供预设模板；自定义粒子图像需 `.raw` semantic
42. **CustomMaterial**：Metal shader 中 USDZ 纹理需翻转 Y 坐标 `uv.y = 1.0 - uv.y`
43. **FocusFilter**：`SetFocusFilterIntent` 的 `appContext` 控制通知过滤谓词；实体需实现 `suggestedEntities()`
44. **后台下载**：`URLSessionConfiguration.background` 的任务在 App 终止后仍继续；必须在 AppDelegate 保存 `completionHandler`
45. **Security Key**：仅支持 `.ES256` 算法；注册和断言使用不同的 Provider 方法
46. **AVPlayer Observation**：`isObservationEnabled` 必须在创建任何播放器之前设置且不可更改；适合通用状态但不适合时间观察（用 `addPeriodicTimeObserver`）
47. **Camera Control**：`canAddControl` 可能因达到 `maxControlCount` 返回 false；控件的 `value` 需要与 App 其他 UI 同步更新
48. **Smart Framing**：仅前置 Ultra Wide 摄像头支持；先设 `aspectRatio` 再设 `zoomFactor` 确保平滑过渡
49. **MV-HEVC**：必须设置 `rndr` track association 否则播放器忽略 display mask；左右眼 layer ID 必须一致（0=左，1=右）
50. **LiDAR 深度流**：`AVCaptureDataOutputSynchronizer` 第一个 output 是主输出；`smoothedSceneDepth` 比 `sceneDepth` 噪声更低
51. **Live Photo**：必须先启用 `isLivePhotoCaptureEnabled` 再拍摄；保存用 `PHAssetCreationRequest` 配对 `.photo` + `.pairedVideo`
52. **ProRAW**：启用 `isAppleProRAWEnabled` 应在启动 session 之前；`fileDataRepresentation()` 返回 DNG 格式
53. **HLS 离线下载**：只能下载 VOD 流，不能下载直播流；`AVAssetDownloadConfiguration` 需配置 `primaryContentConfiguration`
54. **SharePlay 协调播放**：必须先 `join()` session 再 `coordinateWithSession`；自定义暂停结束后协调器自动恢复原始速率
55. **视频色彩**：未标记的视频默认按 SD 色彩空间处理；`AVVideoColorPropertiesKey` 写入时源和目标色彩不同会自动转换
56. **Address Sanitizer**：不检测内存泄漏和未初始化内存；内存 2-3x 增加，`-O1` 可改善
57. **Thread Sanitizer**：仅 Simulator + 64 位 macOS，不支持真机；内存 5-10x，避免在性能测试中使用
58. **Main Thread Checker**：默认开启，影响极小；修复方式是 `DispatchQueue.main.async { }`
59. **Memory Graph**：调试时暂停 App 才能捕获；retain cycle 需找到双向强引用并改一方为 `weak`
60. **启动时间**：Cold/Warm/Resume 是连续谱系，测试需覆盖多种场景；减少第三方 Framework 数量是最有效手段
61. **Hang Detection**：Organizer 报告 > 1s 的 hang；iOS 设备端可开启实时检测（Settings → Developer）
62. **性能测试**：Test Plan 应设 Release + 关闭 Debug executable + 关闭 Coverage/Sanitizer；`Set Baseline` 后自动检测回归
63. **Code Coverage**：收集影响性能但不影响相对对比；skipped test 不计入覆盖率
64. **StoreKit 测试**：本地配置文件的收据不能用于生产环境；Synced 配置不可编辑，需转换为 Local 才能修改
65. **Foundation Models Token**：`includeSchemaInPrompt: false` 可省数百 token，但首次请求建议保留以提升质量
66. **Foundation Models Prompt**：条件逻辑用 Swift `switch` 而非 prompt 中的 IF-ELSE；`prewarm(promptPrefix:)` 比空 `prewarm()` 更快
67. **Foundation Models 多语言**：`supportsLocale()` 检查支持后再调用；不支持的语言 guardrails 可能失效
68. **SwiftData CloudKit**：Relationship 必须 optional + 显式设 inverse；Schema 推生产后只能新增不能删改
69. **SwiftData CloudKit 初始化**：`initializeCloudKitSchema()` 仅在 DEBUG 模式运行；初始化后必须卸载 store 再创建 ModelContainer
70. **SwiftData Autosave**：编辑表单用 @State 暂存值，Save 时才写入 Model，防止 autosave 提前保存未完成编辑
71. **Liquid Glass 背景延伸**：`backgroundExtensionEffect` 仅延伸模糊图片，不影响内容交互区域；需配合 safe area 使用
72. **UIKit UIGlassEffect**：通过 `UIVisualEffectView(effect: UIGlassEffect())` 添加；系统组件（UITabBar/UINavigationBar 等）重编译后自动适配
73. **Liquid Glass 可访问性**：必须检测 `accessibilityReduceTransparency`，开启时用 `.regularMaterial` 替代 glass；测试 Reduce Motion 和 Increase Contrast
74. **CloudKit 同步调试**：启动参数 `-com.apple.CoreData.CloudKitDebug 1` 查看详细日志；监听 `eventChangedNotification` 检测 setup/import/export 状态
75. **CloudKit Schema 生产**：推到生产后只能新增 Optional 属性；模拟器同步不可靠，必须真机测试；变更后需在 Dashboard 重置开发环境
76. **watchOS Extended Runtime**：CPU 持续高负载会导致系统取消 session；Smart Alarm 必须在会话期间播放 haptic，否则系统警告并可能禁用未来会话
77. **tvOS Focus Engine**：所有交互基于焦点系统；自定义控件必须实现 focus API 才能被 Siri Remote 操作
78. **visionOS 隐私**：眼睛/手部追踪用于交互由系统处理，App 不需获取原始数据；仅在需要手部位置绑定内容时才请求 `handTracking` 授权
79. **visionOS Immersive Space**：同一时间只能显示一个；`.mixed` 样式不要填满屏幕（阻挡真实环境有安全风险）；`.full` 隐藏其他 App
80. **App Store Connect JWT**：最长 20 分钟有效期（部分安全 GET 可 6 个月）；私钥只能下载一次，Apple 不保存副本
81. **dSYM 管理**：Build Settings 必须设为 DWARF with dSYM File；dSYM 和 binary 通过 build UUID 配对，版本不同则不匹配
82. **APNs HTTP/2**：HPACK 压缩必须正确使用（:path 用 literal without indexing）；JSON payload 最大 4KB（VoIP 5KB）
83. **本地通知**：`UNCalendarNotificationTrigger` 用 DateComponents 不是 Date；取消通知用 `removePendingNotificationRequests(withIdentifiers:)`
84. **MVVM 架构**：ViewModel 必须 `@MainActor @Observable`；用 `private(set)` 防止 View 直接修改状态；UseCase 用 `callAsFunction` 简化调用
85. **DI 容器**：`registerSingleton` 立即创建实例，`register` 每次解析时创建新实例；`resolve` 找不到注册时会 `fatalError`
86. **分页状态机**：`loadMore` 前检查 `canLoadMore`；用 `onAppear` 最后一个元素触发或提前 5 个预加载；`refreshable` 重置到第一页
87. **图片缓存**：`NSCache` 自动响应内存压力释放（无需手动清理内存部分）；磁盘写入用 `Task.detached(priority: .background)` 避免阻塞主线程
88. **CachedAsyncImage**：`.task(id: url)` 确保 URL 变化时重新加载；`applicationDidReceiveMemoryWarning` 中清空内存和 URLCache
89. **深度链接路由**：冷启动时用 `pendingRoute` 暂存，在根 View 的 `.task` 中处理；`onOpenURL` 仅在 App 已运行时触发
90. **统一错误处理**：`isRetryable` 区分可重试错误；typed throws `throws(AppError)` 需 Swift 6+；`errorAlert` modifier 全局使用避免每个 View 重复处理

## 崩溃报告分析与符号化
```swift
// 崩溃类型速查
// EXC_BAD_ACCESS (SIGSEGV)   → 访问无效内存（野指针、use-after-free）
// EXC_BAD_ACCESS (SIGBUS)    → 对齐错误或物理内存不可访问
// EXC_BREAKPOINT (SIGTRAP)   → Swift 运行时错误（force unwrap nil、数组越界、preconditionFailure）
// EXC_BAD_INSTRUCTION (SIGILL) → 非法指令（Intel 上的 Swift 运行时错误）
// EXC_CRASH (SIGABRT)        → 主动 abort（NSException、fatalError）
// EXC_CRASH (SIGKILL)        → 系统终止（watchdog 超时、内存压力）
// EXC_RESOURCE               → 资源限制超标（CPU、内存、磁盘 I/O）

// Watchdog 超时（0x8badf00d）：App 启动/恢复/暂停超过 ~20 秒
// 解决：避免在 main thread 执行长耗时操作
```

### 符号化流程（atos）
```bash
# 1. 找到崩溃报告中的 Binary Images 段，获取加载地址和 UUID
grep --after-context=1000 "Binary Images:" crash.ips | grep MyApp

# 2. 查找本地 dSYM
mdfind "com_apple_xcode_dsym_uuids == <UUID>"

# 3. 验证 UUID 匹配
dwarfdump --uuid MyApp.app.dSYM/Contents/Resources/DWARF/MyApp

# 4. 符号化地址
atos -arch arm64 -o MyApp.app.dSYM/Contents/Resources/DWARF/MyApp \
     -l 0x100000000 0x100012345
# 输出: -[ViewController viewDidLoad] (ViewController.m:42)

# Xcode Organizer 自动符号化：Window → Organizer → Crashes
# 确保 Archive 时 dSYM 已上传到 App Store Connect
```

### 常见崩溃诊断
```swift
// 1. Force unwrap nil → EXC_BREAKPOINT
// 修复：使用 guard let / if let / ?? 替代 !

// 2. 数组越界 → EXC_BREAKPOINT
// 修复：检查 index < array.count

// 3. 主线程阻塞 → SIGKILL (0x8badf00d)
// 修复：耗时操作移到 Task { } 或后台队列

// 4. 内存压力终止 → Jetsam (EXC_RESOURCE)
// 修复：使用 Instruments Allocations 排查泄漏；减少图片缓存

// 5. Unbalanced call to begin/end → NSInternalInconsistencyException
// 修复：确保 UI 更新在 @MainActor

// MetricKit 自动收集崩溃诊断（iOS 14+）
import MetricKit
class MetricSubscriber: NSObject, MXMetricManagerSubscriber {
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            if let crashDiagnostics = payload.crashDiagnostics {
                for crash in crashDiagnostics {
                    print(crash.callStackTree)  // 完整堆栈
                }
            }
        }
    }
}
// AppDelegate 中注册：MXMetricManager.shared.add(subscriber)
```

## Xcode 构建配置（xcconfig）
```
// .xcconfig 文件语法
ONLY_ACTIVE_ARCH = YES
SWIFT_VERSION = 6.0
IPHONEOS_DEPLOYMENT_TARGET = 26.0
MACOSX_DEPLOYMENT_TARGET = 26.0

// 引用其他设置值
CONFIGURATION_BUILD_DIR = $(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)
DSTROOT = /tmp/$(PROJECT_NAME).dst

// 继承父级设置（关键！）
OTHER_SWIFT_FLAGS = $(inherited) -strict-concurrency=complete
OTHER_LDFLAGS = $(inherited) -lsqlite3

// 条件设置（按 SDK / 架构）
OTHER_LDFLAGS[sdk=macos*] = -lncurses
OTHER_LDFLAGS[arch=arm64] = -framework Metal
OTHER_SWIFT_FLAGS[config=Debug] = $(inherited) -DDEBUG

// 引入其他配置文件
#include "Shared.xcconfig"
#include? "Local.xcconfig"  // ? 表示文件不存在时不报错
```

### 构建性能优化
```swift
// 1. 并行构建：Xcode → Build Settings → SWIFT_COMPILATION_MODE
//    Debug: Incremental（增量编译）
//    Release: WholeModule（全模块优化）

// 2. 显式模块（Xcode 26）：加速模块导入
//    Build Settings → SWIFT_ENABLE_EXPLICIT_MODULES = YES

// 3. 构建时间分析
//    Other Swift Flags: -Xfrontend -warn-long-function-bodies=200
//    （函数体类型检查超过 200ms 则警告）

// 4. 条件编译
#if DEBUG
let baseURL = URL(string: "https://dev.api.example.com")!
#else
let baseURL = URL(string: "https://api.example.com")!
#endif

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(visionOS)
import RealityKit
#endif

#if canImport(FoundationModels)
import FoundationModels  // 仅支持 Apple Intelligence 的设备
#endif

// 5. 自定义编译标志
// Build Settings → Active Compilation Conditions: PREMIUM_FEATURE
#if PREMIUM_FEATURE
func unlockPremium() { /* ... */ }
#endif
```

### Xcode Instruments 速查
```
// 常用 Instrument 模板
Time Profiler     → CPU 热点分析（查看哪个函数耗时最多）
Allocations       → 内存分配跟踪（查找泄漏和过度分配）
Leaks             → 引用循环检测（配合 Allocations 使用）
Network           → 网络请求分析（延迟、带宽、并发连接数）
Core Animation    → 帧率 & 离屏渲染检测
Energy Log        → 电量消耗分析（CPU/GPU/网络/定位）
SwiftUI           → View body 重新计算次数（Xcode 26 新增）
File Activity     → 文件 I/O 追踪
System Trace      → 线程调度 & 系统调用

// 命令行启动 Instruments
xctrace record --device <UDID> --template "Time Profiler" \
    --launch -- /path/to/MyApp.app

// Xcode 构建测试（命令行）
xcodebuild test -scheme MyApp -destination "platform=iOS Simulator,name=iPhone 16"
xcodebuild test -scheme MyApp -testPlan "UnitTests" -only-testing MyAppTests
xcodebuild test -scheme MyApp -run-tests-until-failure -test-iterations 100
```

## 持续更新资源
- SwiftUI：https://developer.apple.com/documentation/swiftui
- Foundation Models：https://developer.apple.com/documentation/foundationmodels
- HIG + Liquid Glass：https://developer.apple.com/design/human-interface-guidelines
- App Intents：https://developer.apple.com/documentation/appintents
- SwiftData：https://developer.apple.com/documentation/swiftdata
- WidgetKit：https://developer.apple.com/documentation/widgetkit
- RealityKit：https://developer.apple.com/documentation/realitykit
- ARKit：https://developer.apple.com/documentation/arkit
- Vision：https://developer.apple.com/documentation/vision
- CoreML：https://developer.apple.com/documentation/coreml
- CreateML：https://developer.apple.com/documentation/createml
- AVFoundation：https://developer.apple.com/documentation/avfoundation
- HealthKit：https://developer.apple.com/documentation/healthkit
- CloudKit：https://developer.apple.com/documentation/cloudkit
- StoreKit 2：https://developer.apple.com/documentation/storekit
- BackgroundTasks：https://developer.apple.com/documentation/backgroundtasks
- Swift Testing：https://developer.apple.com/documentation/testing
- Xcode Cloud：https://developer.apple.com/documentation/xcode/xcode-cloud
- SpriteKit：https://developer.apple.com/documentation/spritekit
- EventKit：https://developer.apple.com/documentation/eventkit
- Contacts：https://developer.apple.com/documentation/contacts
- CoreImage：https://developer.apple.com/documentation/coreimage
- CoreMotion：https://developer.apple.com/documentation/coremotion
- CoreBluetooth：https://developer.apple.com/documentation/corebluetooth
- NaturalLanguage：https://developer.apple.com/documentation/naturallanguage
- Network：https://developer.apple.com/documentation/network
- SafariServices：https://developer.apple.com/documentation/safariservices
- PassKit：https://developer.apple.com/documentation/passkit
- Combine：https://developer.apple.com/documentation/combine
- Network：https://developer.apple.com/documentation/network
- MapKit：https://developer.apple.com/documentation/mapkit
- CoreLocation：https://developer.apple.com/documentation/corelocation
- AuthenticationServices：https://developer.apple.com/documentation/authenticationservices
- Intents：https://developer.apple.com/documentation/intents

**编辑规则**：仅修改此 SKILL.md → 运行 build 脚本生成各 AI 工具配置。
