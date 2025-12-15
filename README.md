# DesignAlgorithmsKit

[![Tests](https://github.com/rickhohler/DesignAlgorithmsKit/workflows/Tests/badge.svg)](https://github.com/rickhohler/DesignAlgorithmsKit/actions)
[![codecov](https://codecov.io/gh/rickhohler/DesignAlgorithmsKit/branch/main/graph/badge.svg)](https://codecov.io/gh/rickhohler/DesignAlgorithmsKit)
[![Documentation](https://img.shields.io/badge/docs-DocC-blue)](https://rickhohler.github.io/DesignAlgorithmsKit/documentation/designalgorithmskit/)

A Swift package providing common design patterns and algorithms with protocols and base types for extensibility.

## Overview

DesignAlgorithmsKit provides implementations of:
- **Design Patterns**: Classic patterns (Gang of Four) and modern patterns commonly used in Swift development
- **Algorithms**: Common algorithms and data structures (Merkle Tree, hashing, etc.)

All patterns and algorithms follow consistent implementation guidelines for maintainability, testability, and extensibility.

## Features

### Creational Patterns
- **Singleton Pattern** - Thread-safe singleton implementations
- **Factory Pattern** - Object creation without specifying concrete classes
- **Builder Pattern** - Step-by-step object construction with fluent API
- **Prototype Pattern** - Object cloning and copying
- **Dependency Injection** - Protocol-based dependency injection

### Structural Patterns
- **Adapter Pattern** - Adapting interfaces to client expectations
- **Facade Pattern** - Simplified interface to complex subsystems
- **Decorator Pattern** - Adding behavior to objects dynamically
- **Composite Pattern** - Composing objects into tree structures
- **Proxy Pattern** - Controlling access to objects

### Behavioral Patterns
- **Strategy Pattern** - Interchangeable algorithms
- **Observer Pattern** - Event notification and subscription
- **Queue Processing Pattern** - Concurrent queue management with status tracking, progress monitoring, and retry support
- **Merging/Upsert Pattern** - Configurable merge strategies for conflict resolution
- **Command Pattern** - Encapsulating requests as objects
- **State Pattern** - Object behavior based on state
- **Template Method Pattern** - Defining algorithm skeleton
- **Chain of Responsibility** - Passing requests along a chain
- **Job Manager Pattern** - Orchestration of asynchronous tasks with status tracking
- **Pipeline Pattern** - Type-erased async processing pipeline
- **Iterator Pattern** - Traversing collections

### Modern Patterns
- **Registry Pattern** - Centralized type registration and discovery
- **Provider Pattern** - Chain of responsibility for extensible behavior
- **Repository Pattern** - Data access abstraction

### Algorithms & Data Structures
- **Merkle Tree** - Hash tree for efficient data verification
- **Bloom Filter** - Probabilistic data structure for membership testing
- **Counting Bloom Filter** - Bloom Filter variant that supports element removal
- **Hash Computation** - Unified cryptographic hash functions (SHA-256, SHA-1, MD5, CRC32)

## Requirements

- Swift 6.2+
- macOS 10.15+ / iOS 13.0+ / tvOS 13.0+ / watchOS 6.0+

## Installation

### Swift Package Manager

Add DesignAlgorithmsKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/rickhohler/DesignAlgorithmsKit.git", from: "1.0.0")
]
```

Or add it via Xcode:
1. File → Add Packages...
2. Enter the repository URL
3. Select version requirements

## Usage

### Registry Pattern

```swift
import DesignAlgorithmsKit

// Register a type
TypeRegistry.shared.register(MyType.self)

// Find registered type
if let type = TypeRegistry.shared.find(for: "myKey") {
    // Use type
}
```

### Factory Pattern

```swift
import DesignAlgorithmsKit

// Create object via factory
let object = try ObjectFactory.shared.create(type: "myType", configuration: [:])
```

### Builder Pattern

```swift
import DesignAlgorithmsKit

// Build complex object
let object = try MyObjectBuilder()
    .setProperty1("value1")
    .setProperty2(42)
    .build()
```

### Strategy Pattern

```swift
import DesignAlgorithmsKit

// Use strategy
let strategy: AlgorithmStrategy = ConcreteStrategy()
let result = strategy.execute(input)
```

### Observer Pattern

```swift
import DesignAlgorithmsKit

// Subscribe to events
let observer = MyObserver()
subject.addObserver(observer)

// Notify observers
subject.notifyObservers(event: .somethingHappened)
```

### Queue Processing Pattern

```swift
import DesignAlgorithmsKit

// Define your item type
struct MyItem: QueueItem {
    let id: UUID
    var status: QueueItemStatus = .pending
    var progress: Double = 0.0
    let data: Data
}

// Define your processor
struct MyProcessor: QueueProcessor {
    typealias Item = MyItem
    
    func process(_ item: MyItem) async throws {
        // Process the item
        // Update progress if needed
    }
}

// Create and use the queue
let queue = ProcessingQueue<MyItem, MyProcessor>(
    processor: MyProcessor(),
    maxConcurrent: 3
)

// Add items
let items = [MyItem(id: UUID(), data: data1), MyItem(id: UUID(), data: data2)]
await queue.add(items)

// Monitor progress
let pending = await queue.pendingItems
let processing = await queue.processingItems
let completed = await queue.completedItems
let failed = await queue.failedItems

// Retry failed items
if let failedItem = await queue.failedItems.first {
    await queue.retry(id: failedItem.id)
}

// Pause/resume
await queue.pause()
await queue.resume()
```

### Merging/Upsert Pattern

```swift
import DesignAlgorithmsKit

// Define your item type
struct MyItem: Mergeable {
    let id: UUID
    var name: String
    var metadata: [String: String]
}

// Create a merger
class MyMerger: DefaultMerger<MyItem> {
    var storage: [UUID: MyItem] = [:]
    
    override func findExisting(by id: UUID) async -> MyItem? {
        return storage[id]
    }
    
    override func upsert(_ item: MyItem, strategy: MergeStrategy) async throws -> MyItem {
        if let existing = await findExisting(by: item.id) {
            let merged = merge(existing: existing, with: item, strategy: strategy)
            storage[item.id] = merged
            return merged
        } else {
            storage[item.id] = item
            return item
        }
    }
}

// Use the merger
let merger = MyMerger()

// Upsert with prefer existing strategy
let item1 = MyItem(id: UUID(), name: "Item", metadata: ["key": "value"])
let upserted1 = try await merger.upsert(item1, strategy: .preferExisting)

// Upsert with prefer new strategy
let item2 = MyItem(id: item1.id, name: "Updated", metadata: ["key": "new"])
let upserted2 = try await merger.upsert(item2, strategy: .preferNew)

// Upsert with custom merge strategy
let customStrategy: MergeStrategy = .custom { existing, new in
    let existingItem = existing as! MyItem
    let newItem = new as! MyItem
    var mergedMetadata = existingItem.metadata
    mergedMetadata.merge(newItem.metadata) { _, new in new }
    return MyItem(
        id: existingItem.id,
        name: newItem.name,
        metadata: mergedMetadata
    )
}
let upserted3 = try await merger.upsert(item2, strategy: customStrategy)
```


### Job Manager Pattern

```swift
import DesignAlgorithmsKit

// Initialize JobManager
let jobManager = JobManager(maxConcurrentJobs: 4)

// Submit a job
let jobID = jobManager.submit(description: "Heavy Processing") {
    // Perform async work
    try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
    return "Success"
}

// Check status (snapshot)
if let snapshot = await jobManager.getJob(id: jobID) {
    print("Status: \(snapshot.status)")
}
```

### Pipeline Pattern (Dynamic Async)

```swift
import DesignAlgorithmsKit

// Create a dynamic pipeline
let pipeline = DynamicAsyncPipeline()

// Add generic stages
pipeline.append(AnyAsyncPipelineStage(process: { input in
    guard let text = input as? String else { throw PipelineError.invalidInputType(expected: "String", actual: "Unknown") }
    return text.uppercased()
}))

// Execute
let result = try await pipeline.execute(input: "hello world")
// Result: "HELLO WORLD"
```

### Merkle Tree

```swift
import DesignAlgorithmsKit

// Build Merkle tree from data
let data = ["block1", "block2", "block3", "block4"].map { $0.data(using: .utf8)! }
let tree = MerkleTree.build(from: data)

// Get root hash
let rootHash = tree.rootHash

// Generate proof for a specific leaf
if let proof = tree.generateProof(for: data[0]) {
    // Verify proof
    let isValid = MerkleTree.verify(proof: proof, rootHash: rootHash)
}
```

### Bloom Filter

```swift
import DesignAlgorithmsKit

// Create Bloom Filter with expected capacity and false positive rate
let filter = BloomFilter(capacity: 1000, falsePositiveRate: 0.01)

// Add elements
filter.insert("element1")
filter.insert("element2")
filter.insert("element3")

// Check membership
if filter.contains("element1") {
    // Element might be in set (could be false positive)
}

if !filter.contains("element4") {
    // Element is definitely NOT in set
}

// Use Counting Bloom Filter for removable elements
let countingFilter = CountingBloomFilter(capacity: 1000, falsePositiveRate: 0.01)
countingFilter.insert("item1")
countingFilter.remove("item1")
```

### Hash Computation

```swift
import DesignAlgorithmsKit

// Compute SHA256 hash
let data = "Hello, World!".data(using: .utf8)!
let hash = try HashComputation.computeHash(data: data, algorithm: .sha256)

// Get hash as hex string
let hexHash = try HashComputation.computeHashHex(data: data, algorithm: .sha256)
// Result: "dffd6021bb2bd5b0af676290809ec3a53191dd81c7f70a4b28688a362182986f"

// Use string algorithm names
let sha1Hash = try HashComputation.computeHashHex(data: data, algorithm: "sha1")

// Convenience Data extensions
let quickHash = data.sha256Hex

// Supported algorithms: SHA-256, SHA-1, MD5, CRC32
let md5 = try HashComputation.computeHashHex(data: data, algorithm: .md5)
let crc = HashComputation.computeCRC32(data: data)
```

## Architecture

DesignAlgorithmsKit is organized into modules:

- **Core** - Base protocols and types
- **Creational** - Creational design patterns
- **Structural** - Structural design patterns
- **Behavioral** - Behavioral design patterns
- **Algorithms** - Algorithms and data structures
  - **DataStructures** - Merkle Tree and other data structures
  - **Cryptography** - Hash computation (SHA-256, SHA-1, MD5, CRC32)
- **Modern** - Modern patterns and extensions

## Thread Safety

All patterns are designed with thread safety in mind:
- **NSLock** - For traditional concurrency
- **Actor** - For Swift concurrency (Swift 5.5+)
- **Sendable** - Marked where appropriate

## Documentation

- **[Full API Documentation (DocC)](https://rickhohler.github.io/DesignAlgorithmsKit/documentation/designalgorithmskit/)** - Complete API reference with interactive documentation
- [Design Patterns Guide](docs/DESIGN_PATTERNS.md)
- [Usage Examples](docs/EXAMPLES.md)

You can also generate documentation locally:

```bash
swift package generate-documentation --target DesignAlgorithmsKit
```

## License

MIT License - see LICENSE file for details

## Contributing

> **Note**: This project is currently internal-only. External contributions are not accepted at this time.

For internal contributors, please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Before contributing, please review:
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security Policy](SECURITY.md)
- [Contributing Guidelines](CONTRIBUTING.md)

## References

- [Design Patterns: Elements of Reusable Object-Oriented Software (Gang of Four)](https://en.wikipedia.org/wiki/Design_Patterns)
- [Swift Design Patterns](https://softwarepatternslexicon.com/swift/introduction-to-design-patterns-in-swift/)
- [Apple Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [Merkle Tree (Wikipedia)](https://en.wikipedia.org/wiki/Merkle_tree)
