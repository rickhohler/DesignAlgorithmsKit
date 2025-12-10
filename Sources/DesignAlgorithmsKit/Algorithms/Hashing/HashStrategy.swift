// DesignAlgorithmsKit
// Hash Strategy Protocol
//
// This file implements the Strategy Pattern for hashing algorithms:
// - HashStrategy: Protocol for hash algorithm implementations
// - HashStrategyRegistry: Registry for available hash strategies

import Foundation

/// Protocol for hash calculation strategies
/// Conforms to Strategy pattern for dynamic algorithm selection
public protocol HashStrategy: Strategy {
    /// Initialize a new strategy instance
    init()
    
    /// The algorithm this strategy implements
    static var algorithm: HashAlgorithm { get }
    
    /// Compute hash for the given data
    /// - Parameter data: Input data
    /// - Returns: Computed hash as Data
    func compute(data: Data) -> Data
}

// Default implementation for Strategy conformance
public extension HashStrategy {
    var strategyID: String {
        Self.algorithm.rawValue
    }
}

public final class HashStrategyRegistry: @unchecked Sendable {
    /// Shared singleton instance
    public static let shared = HashStrategyRegistry()
    
    /// Lock for thread-safety
    private let lock = NSLock()
    
    /// Registry storage
    private var strategies: [String: any HashStrategy.Type] = [:]
    
    private init() {}
    
    /// Register a new hash strategy
    public static func register<T: HashStrategy>(_ strategy: T.Type) {
        shared.register(strategy)
    }
    
    /// Register instance method
    public func register<T: HashStrategy>(_ strategy: T.Type) {
        lock.lock()
        defer { lock.unlock() }
        strategies[strategy.algorithm.rawValue] = strategy
    }
    
    /// Get a strategy instance for the given algorithm
    public static func strategy(for algorithm: HashAlgorithm) -> (any HashStrategy)? {
        return shared.strategy(for: algorithm)
    }
    
    /// Get strategy instance method
    public func strategy(for algorithm: HashAlgorithm) -> (any HashStrategy)? {
        lock.lock()
        defer { lock.unlock() }
        
        if let StrategyType = strategies[algorithm.rawValue] {
            return StrategyType.init()
        }
        return nil
    }
}
