//
//  JobManager.swift
//  DesignAlgorithmsKit
//
//  Job Manager Pattern - Orchestration of asynchronous long-running tasks
//

import Foundation

/// Status of a job managed by JobManager
public enum JobStatus: String, Sendable, Codable {
    /// Job is queued but not started
    case pending
    /// Job is currently executing
    case running
    /// Job completed successfully
    case completed
    /// Job failed with an error
    case failed
}

/// Generic container for job result data 
/// In a real app, you might use AnyCodable, but for this pattern we use Any & Sendable.
public typealias JobOutput = Any & Sendable

/// Information about a specific job
public struct JobSnapshot: Sendable {
    /// Unique identifier
    public let id: UUID
    /// Human-readable description
    public let description: String
    /// Current status
    public let status: JobStatus
    /// Progress (0.0 - 1.0)
    public let progress: Double
    /// Result if completed
    public let result: JobOutput?
    /// Error message if failed
    public let errorMessage: String?
    
    public init(
        id: UUID,
        description: String,
        status: JobStatus,
        progress: Double,
        result: JobOutput? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.description = description
        self.status = status
        self.progress = progress
        self.result = result
        self.errorMessage = errorMessage
    }
}

/// Delegate protocol for receiving job updates
public protocol JobManagerDelegate: Sendable {
    func jobManager(_ manager: JobManager, didUpdateJob job: JobSnapshot)
}

/// A manager that orchestrates the execution of asynchronous background jobs.
///
/// The JobManager provides a central place to submit, track, and retrieve results 
/// from long-running asynchronous tasks. It ensures thread safety via Actor isolation
/// and prevents system overload by limiting concurrent execution.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public actor JobManager {
    
    // MARK: - State
    
    private struct JobState {
        let id: UUID
        let description: String
        var status: JobStatus
        var progress: Double
        var result: JobOutput?
        var error: String?
    }
    
    private var jobs: [UUID: JobState] = [:]
    private var delegate: JobManagerDelegate?
    
    // MARK: - Configuration
    
    /// Maximum number of concurrent jobs
    public let maxConcurrentJobs: Int
    
    // Semaphores are not Sendable or actor-safe in the same way. 
    // We should use a counter or a TaskGroup pattern. 
    // For simplicity in this pattern, we will just run them as they come (unbounded) 
    // OR we should implement a queue. 
    // Given the previous Queue implementation, reusing that logic is complex here.
    // We'll trust the underlying Task scheduler for now or implement a simple active counter check.
    
    private var activeJobCount = 0
    private var pendingJobs: [(UUID, @Sendable () async throws -> JobOutput)] = []
    
    // MARK: - Init
    
    public init(maxConcurrentJobs: Int = 4, delegate: JobManagerDelegate? = nil) {
        self.maxConcurrentJobs = max(1, maxConcurrentJobs)
        self.delegate = delegate
    }
    
    // MARK: - Public API
    
    /// Set a delegate to receive updates
    public func setDelegate(_ delegate: JobManagerDelegate?) {
        self.delegate = delegate
    }
    
    /// Start a new job
    /// - Parameters:
    ///   - description: Description of the job
    ///   - operation: The async operation to perform
    /// - Returns: The UUID of the newly created job
    public func submit(
        description: String,
        operation: @escaping @Sendable () async throws -> JobOutput
    ) -> UUID {
        let id = UUID()
        let state = JobState(
            id: id,
            description: description,
            status: .pending,
            progress: 0.0,
            result: nil,
            error: nil
        )
        jobs[id] = state
        notifyDelegate(for: id)
        
        pendingJobs.append((id, operation))
        processNext()
        
        return id
    }
    
    /// Retrieve the current snapshot of a job
    public func getJob(id: UUID) -> JobSnapshot? {
        guard let state = jobs[id] else { return nil }
        return JobSnapshot(
            id: state.id,
            description: state.description,
            status: state.status,
            progress: state.progress,
            result: state.result,
            errorMessage: state.error
        )
    }
    
    /// Cancel a job (Not fully implemented in this basic pattern without Task storage)
    public func cancel(id: UUID) {
        // In a full implementation, we would store the Task handle and cancel it.
        // For this pattern demo, we simply mark as failed if pending.
        if var state = jobs[id], state.status == .pending {
            state.status = .failed
            state.error = "Cancelled"
            jobs[id] = state
            notifyDelegate(for: id)
        }
    }
    
    // MARK: - Validations
    
    /// List all job IDs
    public var allJobIDs: [UUID] {
        return Array(jobs.keys)
    }
    
    // MARK: - Internal Execution
    
    private func processNext() {
        guard activeJobCount < maxConcurrentJobs else { return }
        guard !pendingJobs.isEmpty else { return }
        
        let (id, operation) = pendingJobs.removeFirst()
        
        // Start Job
        activeJobCount += 1
        updateJob(id: id, status: .running)
        
        Task {
            await execute(id: id, operation: operation)
        }
        
        // Try to start more if capacity allows
        processNext()
    }
    
    private func execute(id: UUID, operation: @escaping @Sendable () async throws -> JobOutput) async {
        do {
            let result = try await operation()
            await complete(id: id, result: result)
        } catch {
            await fail(id: id, error: error)
        }
    }
    
    private func complete(id: UUID, result: JobOutput) {
        activeJobCount -= 1
        
        if var state = jobs[id] {
            state.status = .completed
            state.progress = 1.0
            state.result = result
            jobs[id] = state
            notifyDelegate(for: id)
        }
        
        // Process next in queue
        processNext()
    }
    
    private func fail(id: UUID, error: Error) {
        activeJobCount -= 1
        
        if var state = jobs[id] {
            state.status = .failed
            state.error = String(describing: error)
            jobs[id] = state
            notifyDelegate(for: id)
        }
        
        // Process next in queue
        processNext()
    }
    
    private func updateJob(id: UUID, status: JobStatus) {
        if var state = jobs[id] {
            state.status = status
            jobs[id] = state
            notifyDelegate(for: id)
        }
    }
    
    private func notifyDelegate(for id: UUID) {
        guard let delegate = delegate, let snapshot = getJob(id: id) else { return }
        // We are in an actor, calling a delegate which is Sendable.
        // The delegate method is synchronous but we can call it on a separated Task or assume it's fast.
        // However, if the delegate is an actor isolated instance, we generally should await. 
        // But `JobManagerDelegate` defines a synchronous func.
        // Let's assume the delegate handles thread safety internally or is just a listener.
        delegate.jobManager(self, didUpdateJob: snapshot)
    }
}
