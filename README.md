# CodeMage - Intelligent Image Processing App

A Flutter application that automatically detects content type (faces or documents) and applies appropriate processing pipelines. Built as a case study for **Codeway**.

## Features

### Core Features
- **Smart Content Detection** — Automatically classifies images as face or document using ML Kit
- **Face Processing** — Detects faces, crops regions, applies B&W grayscale filter, and composites back
- **Document Scanning** — Edge detection, perspective correction, contrast enhancement, and PDF export
- **Processing History** — Grid view of all processed results with thumbnails, type badges, and timestamps
- **Before/After Comparison** — Interactive slider to compare original and processed face images
- **OCR Text Extraction** — Extracted text from scanned documents with copy-to-clipboard

### Bonus Features
- **Real-time Camera Overlay** — Live bounding boxes on faces (green) and edge guides on documents (blue) during camera preview
- **Batch Processing** — Queue-based multi-image processing with progress tracking, background mode, and local notifications on completion

### Additional Features
- **Bottom Navigation Bar** — Shell-based navigation with Home, Capture, and Settings tabs
- **Settings Page** — Privacy Policy, Terms of Use, and About section
- **Paywall Screen** — Demo paywall with pricing tiers (weekly/monthly/yearly), shown once on first launch
- **Splash Screen** — Animated app intro with pulse effect and loading indicator

## Architecture

Clean Architecture with four layers:

```
lib/
├── core/              # Constants, theme, utils, errors, extensions
│   ├── constants/     # AppColors, AppStrings, StoragePaths
│   ├── theme/         # Dark theme with NavigationBar theming
│   ├── utils/         # Logger, FileUtils, ImageUtils
│   ├── errors/        # Custom exceptions
│   └── extensions/    # Dart extensions
│
├── data/              # Data layer — models, repositories, services
│   ├── models/        # ProcessingHistoryModel (Hive TypeAdapter)
│   ├── repositories/  # Repository implementations
│   └── datasources/
│       ├── local/     # HiveDatabase
│       └── services/  # FaceDetection, TextRecognition, EdgeDetection,
│                      # ImageManipulation, PdfGeneration, FileStorage,
│                      # NotificationService
│
├── domain/            # Business logic — entities, interfaces, use cases
│   ├── entities/      # ProcessingHistory, ProcessingType, ProcessingResult, BatchItem
│   ├── repositories/  # Abstract repository interfaces
│   └── usecases/      # DetectContentType, ProcessFaceImage, ProcessDocumentImage,
│                      # GetProcessingHistory, SaveProcessingEntry, DeleteProcessingEntry
│
└── presentation/      # UI layer
    ├── bindings/      # GetX dependency injection (InitialBinding + per-screen)
    ├── controllers/   # GetX controllers (Home, Capture, Processing, Result,
    │                  # HistoryDetail, BatchProcessing, MainShell)
    ├── pages/         # Screen widgets
    │   ├── splash/
    │   ├── main/          # MainShellPage (bottom nav host)
    │   ├── home/
    │   ├── capture/       # Camera preview + overlay painter
    │   ├── processing/
    │   ├── result/
    │   ├── history_detail/
    │   ├── batch_processing/
    │   ├── paywall/
    │   └── settings/
    └── routes/        # AppRoutes + AppPages (GetX named routing)
```

## Tech Stack

| Category | Technology | Version |
|----------|-----------|---------|
| Framework | Flutter | 3.27+ |
| Language | Dart | 3.6+ |
| State Management | GetX | ^4.7.2 |
| Face Detection | Google ML Kit Face Detection | ^0.12.0 |
| Text Recognition | Google ML Kit Text Recognition | ^0.14.0 |
| Image Processing | `image` (pure Dart, isolate-safe) | ^4.3.0 |
| PDF Generation | `pdf` | ^3.11.1 |
| Local Storage | Hive + Hive Flutter | ^2.2.3 |
| Camera | `camera` | ^0.11.0+2 |
| Image Picker | `image_picker` | ^1.1.2 |
| File System | `path_provider` | ^2.1.5 |
| Permissions | `permission_handler` | ^11.3.1 |
| Sharing | `share_plus` | ^10.1.3 |
| Notifications | `flutter_local_notifications` | ^18.0.1 |
| UI Shimmer | `shimmer` | ^3.0.0 |

## Key Design Decisions

1. **GetX** — Reactive `Rx` types, named routing with bindings, and dependency injection in a single package
2. **Hive over SQLite** — Pure Dart, no native dependencies, faster for simple key-value/model storage
3. **Pure Dart image processing** — `image` package avoids 30-50MB OpenCV binary bloat, runs safely in isolates
4. **Isolate-based processing** — All heavy pixel operations run in `Isolate.run()` to keep UI at 60fps
5. **Strategy pattern** — `DetectContentType` use case classifies the image, then delegates to `ProcessFaceImage` or `ProcessDocumentImage`
6. **Permanent BatchProcessingController** — Registered with `Get.put(permanent: true)` in `InitialBinding` so batch state survives navigation
7. **Shell-based navigation** — `MainShellPage` with `IndexedStack` hosts Home and Settings; Capture tab opens camera as a pushed route

## Processing Pipelines

### Face Flow
1. ML Kit Face Detection (platform channel)
2. Extract face bounding rectangles
3. **In Isolate:** Crop face with 10% padding → Grayscale filter → Composite back onto original
4. Save original, processed, and thumbnail images
5. Add entry to Hive history with metadata

### Document Flow
1. ML Kit Text Recognition (platform channel)
2. Infer document corners from text block positions
3. Edge detection via Sobel operator + density thresholding
4. **In Isolate:** Perspective transform (homography) → Contrast enhancement (1.4x) → Grayscale
5. Generate A4 PDF via `pdf` package
6. Save original, processed, PDF, and thumbnail
7. Store extracted OCR text in history entry

## Setup Instructions

### Prerequisites
- Flutter **3.27.0** or later (`flutter --version` to check)
- Dart **3.6.0** or later
- Xcode **15+** with iOS 15.5+ deployment target (for iOS)
- Android Studio with minSdk **21** (for Android)
- A physical device is recommended for camera and ML Kit features

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/agbabaumut/CodeMage.git
cd codeway_image_processor

# 2. Install dependencies
flutter pub get

# 3. Generate Hive type adapters
dart run build_runner build --delete-conflicting-outputs

# 4. Run on a connected device
flutter run
```

### iOS-Specific Setup
- Minimum deployment target: **iOS 15.5**
- Camera and Photo Library usage descriptions are pre-configured in `ios/Runner/Info.plist`
- If running on a physical device, ensure a valid signing team is set in Xcode

### Android-Specific Setup
- Minimum SDK: **21** (configured in `android/app/build.gradle`)
- Camera and storage permissions are pre-configured in `AndroidManifest.xml`

## Screens

| Screen | Description |
|--------|-------------|
| **Splash** | Animated logo with pulse effect, initializes services, shows paywall on first launch |
| **Home** | 2-column grid of processing history with type badges, timestamps, batch progress banner, FAB for new capture |
| **Capture** | Full-screen camera preview with real-time detection overlay, flash/flip controls, batch select, gallery picker |
| **Processing** | Step-by-step progress indicator with type badge and percentage, background processing option |
| **Result** | Before/after slider (faces) or PDF preview with OCR text tab (documents), metadata card, share button |
| **History Detail** | Full-screen viewer with pinch-to-zoom (0.5x–4x), metadata display, share, delete, Open PDF |
| **Batch Processing** | Sequential queue with per-item progress, status indicators, continue in background, summary |
| **Batch Results** | Summary of completed/failed items with thumbnails and status |
| **Settings** | CodeMage Pro upgrade, About dialog, Privacy Policy, Terms of Use |
| **Paywall** | Demo paywall with 3 pricing tiers, feature list, CTA button |

## Error Handling

- **Permission denied** → Settings redirect dialog with fallback to gallery
- **No faces/text detected** → User-friendly message with suggestion to retry
- **Image too large** (>4000px) → Auto-downscale before processing
- **Camera unavailable** → Fallback to gallery picker
- **Storage full** → Clear error message
- **Processing failure** → Error state with retry option in batch queue
- **Global error handler** via `runZonedGuarded` in `main.dart`
