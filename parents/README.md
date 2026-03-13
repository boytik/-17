## 🌐 WebView Flow

### Структура файлов

```
Stride/
├── Services/
│   ├── DocumentValidationService.swift
│   └── DocumentFlowState.swift
├── DocumentFlow/
│   ├── DocumentSplashScreenView.swift
│   ├── DocumentViewPanel.swift
│   ├── DocumentViewContainer.swift
│   ├── WebViewHostingViewController.swift
│   ├── NativeAppViewController.swift
│   ├── DocumentRootView.swift
│   └── DocumentFlowAppDelegate.swift
└── StrideApp.swift  // точка входа, DocumentRootView как root
```

### Overview

This application implements a flow that determines whether to show a WebView with an external website or the native application based on date validation, device checks, network connectivity, and server responses.

**Key Rule**: 
- If `firstLaunchChoice = "webView"` → Always show WebView on subsequent launches (never Native App interface)
- If `firstLaunchChoice = "nativeApp"` → Always show Native App on subsequent launches (never WebView interface)

**Orientation Rules**:
- **WebView**: Supports ALL orientations (portrait, landscape left, landscape right)
- **Native App**: STRICT portrait only (never rotates to landscape)

**Safe Area Rules**:
- **WebView**: Respects safe area (no `.ignoresSafeArea()`). Content does not extend under notch, status bar, home indicator.
- **Native App**: Ignores safe area (`.ignoresSafeArea()` on `StrideNativeContentView`). Content fills entire screen edge-to-edge.

**WebView UX**:
- **Swipe navigation**: `allowsBackForwardNavigationGestures = true` — user can swipe back/forward through WebView history.

### Key Components

1. **DocumentValidationService** (`Services/DocumentValidationService.swift`): Handles validation logic and URL management
2. **DocumentFlowState** (`Services/DocumentFlowState.swift`): Main flow controller managing state transitions
3. **DocumentViewContainer** (`DocumentFlow/DocumentViewContainer.swift`): WebView container with app rating alert
4. **DocumentViewPanel** (`DocumentFlow/DocumentViewPanel.swift`): WebView wrapper (UIViewControllerRepresentable) with error handling
5. **DocumentSplashScreenView** (`DocumentFlow/DocumentSplashScreenView.swift`): Loading screen shown during initialization
6. **WebViewHostingViewController** (`DocumentFlow/WebViewHostingViewController.swift`): Hosts WebView with all-orientation support
7. **NativeAppViewControllerWrapper** (`DocumentFlow/NativeAppViewController.swift`): Wrapper for native content (portrait-only)
8. **DocumentRootView** (`DocumentFlow/DocumentRootView.swift`): Root view orchestrating the entire flow
9. **DocumentFlowAppDelegate** (`DocumentFlow/DocumentFlowAppDelegate.swift`): Orientation control

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    App Launch                                │
└───────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
            ┌────────────────────────┐
            │   Loading Screen       │
            │   (DocumentSplashScreenView)│
            │   ⏳ Show until all    │
            │      checks complete   │
            └───────────┬────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │   STEP 1: Check First Launch  │
        │   Choice                      │
        │   - firstLaunchChoice?         │
        └───────┬───────────────────────┘
                │
        ┌───────┴────────┐
        │                 │
    CHOICE SET        FIRST LAUNCH
        │                 │
        ▼                 ▼
┌──────────────┐   ┌──────────────────────┐
│ firstChoice  │   │  STEP 2: Validations  │
│ = "webView"  │   │  - Date Check        │
│              │   │  - Device (iPad?)     │
│ Show WebView │   │  - Internet           │
│ (saved URL → │   │  - Server Request     │
│  fallback →  │   └───────┬──────────────┘
│  empty)      │           │
│              │   ┌───────┴────────┐
│ firstChoice  │   │                 │
│ = "nativeApp"│   ❌ FAIL            ✅ SUCCESS
│              │   │                 │
│ Show Native  │   ▼                 ▼
│ App (ALWAYS) │   ┌──────────────┐  ┌──────────────┐
│              │   │ firstChoice   │  │ firstChoice   │
└──────────────┘   │ = "nativeApp"│  │ = "webView"  │
                   │              │  │              │
                   │ Save URL &   │  │ Save URL &   │
                   │ pathId       │  │ pathId       │
                   │              │  │              │
                   │ Show Native  │  │ Show WebView │
                   │ App (first)  │  │              │
                   │              │  │              │
                   │ Next launch: │  │ Next launch: │
                   │ Always Native│  │ Always WebView│
                   └──────────────┘  └──────────────┘
```

### Detailed Flow Description

#### Phase 1: Initial Launch Sequence

**1.1 Loading Screen**
- App shows `DocumentSplashScreenView` immediately on launch
- Animated scene with gradient background and progress indicator
- Shows app title and "Preparing..." text
- **Loading screen stays visible until ALL checks complete:**
  - All validations passed

**1.2 First Launch Choice Check**
```swift
// Check first launch choice FIRST
if let firstChoice = service.getFirstLaunchChoice() {
    if firstChoice == "webView" {
        // Always show WebView (saved URL → fallback → empty)
        if let savedURL = service.getSavedURL() {
            → Show WebView with savedURL
        } else {
            → Try fallback with pathId
        }
        return
    } else if firstChoice == "nativeApp" {
        // Always show Native App (never WebView)
        → Show Native App
        return
    }
}

// No choice set → First launch → Proceed with validations
```

**Key Points:**
- First launch choice check happens FIRST
- If `firstLaunchChoice = "webView"` → Always show WebView (never Native App)
- If `firstLaunchChoice = "nativeApp"` → Always show Native App (never WebView)
- Only proceed to validations if no choice is set (first launch)

---

#### Phase 2: Validations (First Launch Only)

**2.1 Date Validation**
```swift
// Check if current date > researchLaunchDate
if !service.documentCheckDatePublic() {
    // Date check FAILED
    service.setFirstLaunchChoice("nativeApp")
    → Show Native App (first launch only)
    → Next launch: Always show Native App
    return
}
```

**2.2 Device Check**
```swift
if UIDevice.current.userInterfaceIdiom == .pad {
    // iPad detected
    service.setFirstLaunchChoice("nativeApp")
    → Show Native App (first launch only)
    → Next launch: Always show Native App
    return
}
```

**2.3 Internet Connection Check**
```swift
let monitor = NWPathMonitor()
monitor.pathUpdateHandler = { path in
    if path.status == .satisfied {
        // Internet available → continue
    } else {
        // No internet
        service.setFirstLaunchChoice("nativeApp")
        → Show Native App (first launch only)
        → Next launch: Always show Native App
        return
    }
}
// Timeout: 2 seconds
```

**2.4 Server Request**
```swift
// Build URL: primaryServerURL (no tracking parameters)
let url = primaryServerURL

// Make HTTP request
// Headers: Browser-like headers (User-Agent, Accept, etc.)
// Timeout: 5 seconds (initial request), 4 seconds (fallback request)
```

**2.5 Response Handling**
```swift
if statusCode >= 200 && statusCode <= 403 {
    // Success
    let finalURL = httpResponse.url ?? baseURL
    
    // Extract pathId from URL or HTML
    if let pathId = extractPathId(from: finalURL, htmlData: data) {
        UserDefaults.set(pathId, forKey: "CrabsSavedPathId")
    }
    
    // Save final URL
    UserDefaults.set(finalURL.absoluteString, forKey: "ProteinsSavedTargetURL")
    UserDefaults.set(true, forKey: "ProteinsHasShownAlternative")
    
    // Set first launch choice to WebView
    service.setFirstLaunchChoice("webView")
    
    → Show WebView with finalURL
    → Show app rating alert (once, on first WebView appearance)
} else {
    // Error (404, 500, etc.)
    service.setFirstLaunchChoice("nativeApp")
    → Show Native App (first launch only)
    → Next launch: Always show Native App
}
```

---

#### Phase 3: Non-First Launch Flow

**3.1 First Launch Choice Check**
```swift
if let firstChoice = service.getFirstLaunchChoice() {
    if firstChoice == "webView" {
        // Always show WebView (never Native App)
        if let savedURL = service.getSavedURL() {
            → Show WebView with savedURL
            → Show app rating alert (once, if not yet shown)
        } else {
            → Try fallback with pathId
            → If fallback fails → Show empty WebView
        }
        return
    } else if firstChoice == "nativeApp" {
        // Always show Native App (never WebView)
        → Show Native App
        return
    }
}
```

---

#### Phase 4: WebView Error Handling & Fallback

**4.1 Fallback Logic**
```swift
func documentTryFallbackURL(completion: @escaping (Bool, URL?) -> Void) {
    // 1. Clear broken URL
    UserDefaults.removeObject(forKey: "ProteinsSavedTargetURL")
    
    // 2. Get saved pathId
    guard let pathId = UserDefaults.string(forKey: "CrabsSavedPathId") else {
        → Show empty WebView
        return
    }
    
    // 3. Build fallback URL: primaryServerURL + pathId
    var urlComponents = URLComponents(string: primaryServerURL)
    urlComponents?.queryItems = [URLQueryItem(name: "pathid", value: pathId)]
    
    let fallbackURL = urlComponents?.url?.absoluteString ?? primaryServerURL
    
    // 4. Request fallback URL (timeout: 4 seconds)
    documentRequestServerURL(startURL: fallbackURL, timeout: 4) { success, finalURL in
        if success {
            → Save new finalURL
            → Update WebView with new URL (force refresh)
            → Show WebView with new URL
        } else {
            → Show empty WebView (never Native App)
        }
    }
}
```

---

### Storage Keys & Flags

```swift
enum StorageKeys {
    // URL Management
    static let savedTargetURL = "ProteinsSavedTargetURL"      // Final URL after redirects
    static let tempCurrentURL = "ProteinsTempCurrentURL"     // Temporary URL (priority)
    static let savedPathId = "CrabsSavedPathId"              // PathId for fallback
    
    // Flow Control
    static let hasShownAlternative = "ProteinsHasShownAlternative"  // WebView was shown (for compatibility)
    static let firstLaunchChoice = "firstLaunchChoice"               // "webView" or "nativeApp"
    static let validationPassed = "CrabsValidationPassed"           // Validation state
    static let hasShownWebViewRating = "StrideHasShownWebViewRating" // App rating shown once
}
```

---

### URL Structure

**Primary URL (First Request):**
```
{primaryServerURL}
```

**Fallback URL (Error Recovery):**
```
{primaryServerURL}?pathid={savedPathId}
```

---

### Complete Flow Summary

**First Launch:**
1. ✅ **Loading Screen** → Show immediately (`DocumentSplashScreenView`)
2. ✅ **First Launch Choice Check** → If choice set → Show appropriate view (skip all checks)
3. ✅ **Date Check** → If fail → Native App (`firstLaunchChoice = "nativeApp"`)
4. ✅ **Device Check** → If iPad → Native App (`firstLaunchChoice = "nativeApp"`)
5. ✅ **Internet Check** → If no internet → Native App (`firstLaunchChoice = "nativeApp"`)
6. ✅ **Server Request** → If success → WebView (`firstLaunchChoice = "webView"`)
7. ✅ **Server Request** → If fail → Native App (`firstLaunchChoice = "nativeApp"`)
8. ✅ **Loading Screen** → Hide after all checks complete
9. ✅ **App Rating Alert** → Show **once** on first WebView appearance (persisted via `StrideHasShownWebViewRating` in AppStorage)

**Subsequent Launches:**
- If `firstLaunchChoice = "webView"` → Always show WebView
  - Try saved URL → if fails → fallback → if fails → empty WebView
- If `firstLaunchChoice = "nativeApp"` → Always show Native App
  - Never show WebView
- **Critical Rule**: Never switch between WebView and Native App after first launch

---

### Implementation Notes (избежать типичных ошибок)

#### 1. DocumentFlowState и ObservableObject

При `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` автогенерация `@Published` может конфликтовать. Используйте явную реализацию:

```swift
final class DocumentFlowState: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    var currentPhase: DocumentFlowPhase = .loading {
        willSet { objectWillChange.send() }
    }
    // ...
}
```

**Не используйте синглтон:** создавайте `DocumentFlowState()` в App с `@StateObject` и передавайте через `.environmentObject(flowState)`.

#### 2. NativeAppViewControllerWrapper — параметр content

Ошибка: `Function produces expected type 'Content'; did you mean to call it with '()'?`

Инициализатор принимает closure `() -> Content`. Варианты:

```swift
// Вариант A: хранить результат, вызывать content()
init(@ViewBuilder content: () -> Content) {
    self.content = content()
}

// Вариант B: использовать AnyView для type-erasure
struct NativeAppViewControllerWrapper: UIViewControllerRepresentable {
    let content: AnyView
    init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }
}
```

#### 3. WebViewHostingViewController — обновление при fallback

После успешного fallback WebView должен показать новый URL. Обязательно:

- **Добавить `.id(url.absoluteString)`** к `WebViewHostingViewControllerWrapper` в DocumentRootView — при смене URL SwiftUI пересоздаст view
- **Реализовать `updateUIViewController`** — обновлять `hostingController.rootView` при смене URL
- **`hostingController` не должен быть `private`** — иначе `makeUIViewController` не сможет его установить

```swift
// WebViewHostingViewController
var hostingController: UIHostingController<DocumentViewContainer>?  // не private!

func updateContent(url: URL, onError: @escaping () -> Void, on404Detected: @escaping () -> Void) {
    let content = DocumentViewContainer(url: url, onError: onError, on404Detected: on404Detected)
    hostingController?.rootView = content
}

// В DocumentRootView:
WebViewHostingViewControllerWrapper(...)
    .id(url.absoluteString)
```

#### 4. App Entry

```swift
@main
struct App: App {
    @UIApplicationDelegateAdaptor(DocumentFlowAppDelegate.self) var appDelegate
    @StateObject private var flowState = DocumentFlowState()

    var body: some Scene {
        WindowGroup {
            DocumentRootView()
                .environmentObject(flowState)
                .environmentObject(vault)
                .environmentObject(router)
        }
    }
}
```

#### 5. Frameworks

- `WebKit` — для WKWebView
- `Network` — для NWPathMonitor
- `StoreKit` — для SKStoreReviewController

#### 6. Отладка (логи в консоль)

Рекомендуется логировать: сохранённую ссылку, path id, ответ сервера, fallback-логику. Префикс `[DocumentFlow]` для фильтрации.

#### 7. App Rating Alert

Показывать **один раз** при первом появлении WebView. Использовать `@AppStorage("StrideHasShownWebViewRating")` — флаг сохраняется между запусками.

#### 8. Fallback и таймауты

- **WebView load timeout**: 8 секунд. Если страница не загрузилась — вызывать `onError` и запускать fallback.
- **HTTP request**: 5 секунд (первый запрос), 4 секунды (fallback).
- В `DocumentViewPanel`: таймер при `didStartProvisionalNavigation`, отмена при `didFinish`/`didFail`.

#### 9. Safe Area

- **WebView**: без `.ignoresSafeArea()` — контент не заходит под notch/home indicator.
- **Native App**: `.ignoresSafeArea()` на `StrideNativeContentView`.

#### 10. Swipe navigation

`webView.allowsBackForwardNavigationGestures = true` в `DocumentViewPanel`.

---

**Version**: 2.1.0  
**Platform**: iOS 15+  
**Language**: Swift 5.0  
**Framework**: SwiftUI  
**Architecture**: MVVM + Clean Architecture
