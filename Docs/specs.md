# Technical Architecture

## 1. Project Overview & Scale

**SnifLeaf** is a production-grade network traffic inspection and analytics platform built for macOS/iOS. The application solves a complex real-time data processing challenge: intercepting, categorizing, and analyzing HTTP/HTTPS traffic at scale while maintaining performance and data integrity.

**Problem Complexity:**
- Real-time interception of network traffic through mitmproxy integration
- Processing and categorizing thousands of log entries per minute
- Maintaining a responsive UI while handling continuous data ingestion
- Providing analytics (benchmarks, anomaly detection) over large datasets
- Cross-platform architecture supporting both macOS and iOS with shared business logic

**Scale Indicators:**
- Handles high-frequency network events with batched processing (100-entry buffers)
- Implements pagination for large datasets (50 items per page with infinite scroll)
- Database migrations for schema evolution
- ML-powered anomaly detection using CoreML models

---

## 2. Technical Design & Architecture

### Core Architectural Pattern: **Modular Clean Architecture with Interactor Pattern**

The codebase follows a **layered modular architecture** that separates concerns across three primary frameworks:

**Framework Structure:**
- **SnifLeafCore**: Core business logic, data models, and services (framework target)
- **Shared**: Network interception and cross-platform utilities (framework target)
- **Platform Targets**: macOS/iOS-specific UI and platform adapters

**Separation of Concerns:**

1. **Presentation Layer** (SwiftUI Views)
   - Pure declarative UI components
   - No business logic; delegates to Interactors
   - Examples: `LogListView`, `BenchmarkView`, `AnomalyView`

2. **Business Logic Layer** (Interactors)
   - Feature-specific business logic encapsulated in `ObservableObject` classes
   - Manages state, data transformation, and coordination
   - Examples: `LogListInteractor`, `BenchmarkInteractor`, `AnomaliesInteractor`
   - Pattern: Each scene has its own Interactor, promoting single responsibility

3. **Data Layer** (Services & Managers)
   - Database abstraction via `GRDBManager` (SQLite wrapper)
   - Service layer for complex queries (`BenchmarkService`)
   - Data models conform to `FetchableRecord` and `MutablePersistableRecord` (GRDB protocols)

4. **Infrastructure Layer**
   - Process management (`MitmProcessManager`) for external tool integration
   - Log processing pipeline (`LogProcessor`) for data transformation
   - Network abstraction (`NetworkingFactory`, `IHTTPManager` protocol)

**Modularization Strategy:**
- **Local Swift Frameworks**: `SnifLeafCore` and `Shared` are separate framework targets, enabling:
  - Independent testing and compilation
  - Clear dependency boundaries
  - Reusability across platforms
- **Feature-based Organization**: Scenes organized by feature (LogList, Benchmark, Anomalies) with Interactor/UI subdirectories
- **Dependency Injection**: Centralized via `AppState` class, which initializes and coordinates all managers and interactors

### Concurrency Model: **Hybrid Async/Await + Combine**

The architecture uses a **dual concurrency strategy**:

1. **Swift Concurrency (Async/Await)**
   - Primary mechanism for database operations (`async throws` functions)
   - Process management (`Task`, `Task.detached`)
   - Example: `fetchLogEntries(limit:offset:)` returns `async -> [LogEntry]`

2. **Combine Framework**
   - Reactive state management for UI updates
   - Debounced search with `$searchText.debounce(for: .milliseconds(500))`
   - Notification-based updates (`NotificationCenter.default.publisher`)
   - Cross-component communication via `@Published` properties

**Why This Approach:**
- Async/Await for I/O-bound operations (database, network) provides structured concurrency
- Combine for reactive UI updates ensures real-time responsiveness
- `@MainActor` annotations ensure thread-safe UI updates

---

## 3. Strategic Tech Stack

### Native Development Strategy

**Primary Languages:**
- **Swift 5.x** (100% native codebase)
- **Python 3.10+** (separate ML training service, containerized)

**No Hybrid Frameworks:**
- Pure native implementation ensures:
  - Optimal performance for real-time data processing
  - Full access to platform APIs (CoreML, SwiftUI, GRDB)
  - Native UI responsiveness

**Platform-Specific Implementations:**
- **macOS**: Full-featured application with multi-window support
- **iOS**: Separate target with platform-optimized UI (currently minimal implementation)
- **Shared Business Logic**: Core and Shared frameworks compile for both platforms

**Native Bridges:**
- **CoreML Integration**: Direct integration of ML models (`EndpointAnomalyDetector.mlpackage`)
- **Process Management**: Native `Process` API for mitmproxy subprocess management
- **Database**: GRDB (native Swift SQLite wrapper) with type-safe query builder

**External Tool Integration:**
- Bundled mitmproxy.app for network interception
- Python script bridge (`snifleaf_inspector.py`) for custom mitmproxy addon logic

---

## 4. Banking-Grade Engineering

### Security Considerations

**Data Handling:**
- **Database Encryption**: SQLite database stored in user's Documents directory (platform-managed security)
- **Sensitive Data Storage**: Request/response bodies stored as `Data` (blob) in database, not plain text
- **Content Filtering**: Large payloads (>100KB) are truncated to prevent memory issues
- **Base64 Encoding**: Binary content automatically encoded for safe storage

**Network Security:**
- **HTTPS Interception**: Requires user-installed SSL certificate (mitmproxy CA)
- **Process Isolation**: mitmproxy runs as separate subprocess, isolated from main app

**Note**: As a network inspection tool, the app prioritizes transparency over encryption. For banking applications, additional layers (Keychain for credentials, certificate pinning, data obfuscation) would be implemented.

### Data & Persistence Strategy

**Database: GRDB (SQLite Wrapper)**

**Why GRDB:**
- Type-safe query builder (prevents SQL injection)
- Native Swift integration (no Objective-C bridging)
- Excellent performance for high-frequency writes
- Built-in migration system

**Data Integrity Measures:**

1. **Schema Migrations**
   ```swift
   migrator.registerMigration("createLogEntriesTable") { db in
       // Schema definition with constraints
   }
   migrator.registerMigration("addIndexesToLogEntries") { db in
       // Performance indexes
   }
   ```

2. **Database Constraints**
   - Primary key with auto-increment
   - NOT NULL constraints on critical fields
   - Indexes on frequently queried columns (timestamp, url, host, statusCode, latency)

3. **Transaction Safety**
   - All writes wrapped in `dbPool.write { db in ... }`
   - Reads use `dbPool.read { db in ... }` for thread-safe access

4. **Data Model Validation**
   - Models conform to `Codable` for serialization safety
   - Custom `init(from decoder:)` handles edge cases (base64 decoding, date parsing)

**Persistence Architecture:**
- **Write Path**: `MitmProcessManager` → batches logs → `LogProcessor` → `GRDBManager.insertLogEntry()`
- **Read Path**: Interactors → `GRDBManager.fetchLogs()` → paginated results
- **Real-time Updates**: NotificationCenter posts on insert, Interactors observe and update UI

### Networking Architecture

**API Abstraction Layer:**

1. **Protocol-Based Design**
   - `IHTTPManager` protocol defines networking contract
   - `INetworkingFactory` protocol for factory pattern
   - Enables swapping implementations (Alamofire, AFNetworking) without changing callers

2. **Manager Implementations**
   - `AlamofireManager`: Alamofire-based implementation
   - `AFNetworkingManager`: Alternative implementation (prepared for future needs)
   - Factory pattern (`NetworkingFactory`) provides dependency injection

3. **Network Interception Logic**
   - **Custom Middleware**: Python script (`snifleaf_inspector.py`) acts as mitmproxy addon
   - **Filtering**: Excludes static assets (images, fonts, CSS) to reduce noise
   - **Transformation**: Converts HTTPFlow to JSON, streams to Swift process via stdout
   - **Buffering**: Swift-side batching (100 entries or 1-second intervals) reduces database write frequency

**Data Flow:**
```
mitmproxy → Python addon → JSON stdout → Swift Process pipe → 
MitmProcessManager (buffer) → LogProcessor (categorize) → 
GRDBManager (persist) → NotificationCenter → Interactors → UI
```

---

## 5. Architectural Responsibilities

Based on the codebase structure and patterns, here are **5 high-level responsibilities** a Lead Architect would have owned:

### 1. **Architected Modular Framework Strategy with Clear Dependency Boundaries**
   - Designed the three-framework architecture (SnifLeafCore, Shared, Platform targets)
   - Established dependency rules: Platform → Shared → SnifLeafCore (unidirectional)
   - Enabled independent testing and compilation of core business logic
   - **Impact**: Reduced coupling, improved testability, enabled code reuse across platforms

### 2. **Defined the Interactor Pattern for Business Logic Separation**
   - Introduced feature-specific Interactors (`LogListInteractor`, `BenchmarkInteractor`, `AnomaliesInteractor`)
   - Established pattern: Interactors own business logic, Views are pure SwiftUI
   - Implemented reactive state management using Combine publishers and async/await
   - **Impact**: Maintainable, testable code with clear separation between UI and business rules

### 3. **Designed High-Performance Data Pipeline for Real-Time Processing**
   - Architected batched ingestion system (100-entry buffers, 1-second flush intervals)
   - Implemented async database operations with GRDB connection pooling
   - Designed pagination strategy (50 items/page) for handling large datasets
   - Created notification-based update mechanism for real-time UI synchronization
   - **Impact**: Handles high-frequency events without UI blocking or memory issues

### 4. **Established Database Abstraction Layer with Migration Strategy**
   - Selected GRDB over CoreData for type safety and performance
   - Designed migration system for schema evolution (`migrator.registerMigration`)
   - Created index strategy for query performance (timestamp, url, host, statusCode)
   - Implemented type-safe query builder pattern to prevent SQL injection
   - **Impact**: Scalable data layer with zero-downtime schema updates

### 5. **Integrated ML Capabilities with Native CoreML Pipeline**
   - Architected ML model integration (`EndpointAnomalyDetector.mlpackage`)
   - Designed Python-based training service (containerized) for model generation
   - Implemented feature extraction from `LogEntry` to ML model inputs
   - Created anomaly detection workflow in `AnomaliesInteractor`
   - **Impact**: Enabled AI-powered insights without external service dependencies

---

## Additional Technical Highlights

- **XcodeGen Configuration**: Project structure defined in `project.yml` for reproducible builds
- **Swift Package Manager**: External dependencies (Alamofire, GRDB, SwiftNIO) managed via SPM
- **Docker Integration**: ML training service containerized for consistent environments
- **Testing Strategy**: Unit tests for database layer (`GRDBManagerTests`) with async test support
- **Performance Optimizations**: Database indexes, batched writes, debounced search, pagination
