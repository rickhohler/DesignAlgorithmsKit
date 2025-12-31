//
//  Graph.swift
//  DesignAlgorithmsKit
//
//  Graph Data Structures and Algorithms
//

import Foundation

/// A basic node in a graph.
public struct GraphNode<T: Hashable>: Hashable, Identifiable {
    public let id: T
    public let data: T
    
    public init(_ data: T) {
        self.data = data
        self.id = data
    }
}

/// A generic Graph implemented using an Adjacency List.
public class Graph<T: Hashable> {
    
    private var adjList: [T: [T]] = [:]
    private var nodes: [T: GraphNode<T>] = [:]
    
    public init() {}
    
    /// Adds a node to the graph.
    /// - Parameter data: The data associated with the node.
    @discardableResult
    public func addNode(_ data: T) -> GraphNode<T> {
        if let existing = nodes[data] {
            return existing
        }
        let node = GraphNode(data)
        nodes[data] = node
        adjList[data] = []
        return node
    }
    
    /// Adds a directed edge from source to destination.
    public func addEdge(from source: T, to destination: T) {
        addNode(source)
        addNode(destination)
        adjList[source]?.append(destination)
    }
    
    /// Returns the neighbors of a node.
    public func neighbors(of node: T) -> [T] {
        return adjList[node] ?? []
    }
    
    /// Returns all nodes in the graph.
    public var allNodes: [T] {
        return Array(nodes.keys)
    }
}

// MARK: - Algorithms

extension Graph {
    
    /// Performs Breadth-First Search (BFS) to find all reachable nodes from a set of roots.
    /// - Parameter roots: The starting nodes.
    /// - Returns: A Set of reachable node IDs.
    public func reachability(from roots: [T]) -> Set<T> {
        var visited = Set<T>()
        var queue = roots
        
        // Mark initial roots as visited if they exist in graph
        for root in roots {
            if nodes[root] != nil {
                visited.insert(root)
            }
        }
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            
            guard let neighbors = adjList[current] else { continue }
            
            for neighbor in neighbors {
                if !visited.contains(neighbor) {
                    visited.insert(neighbor)
                    queue.append(neighbor)
                }
            }
        }
        
        return visited
    }
    
    /// Performs "Tree Shaking" - finding all unreachable nodes.
    /// - Parameter roots: The root nodes (entry points).
    /// - Returns: A Set of unreachable node IDs (candidates for removal).
    public func findUnreachable(from roots: [T]) -> Set<T> {
        let reachable = reachability(from: roots)
        let all = Set(allNodes)
        return all.subtracting(reachable)
    }
}
