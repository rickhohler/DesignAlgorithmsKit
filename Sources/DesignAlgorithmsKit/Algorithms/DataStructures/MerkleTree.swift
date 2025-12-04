//
//  MerkleTree.swift
//  DesignAlgorithmsKit
//
//  Merkle Tree - A hash tree data structure used for efficient verification of large data structures
//

import Foundation

/// Protocol for types that can be hashed for Merkle tree construction
public protocol MerkleHashable {
    /// Generate hash for this value
    /// - Returns: Hash value as Data
    func merkleHash() -> Data
}

extension Data: MerkleHashable {
    public func merkleHash() -> Data {
        return SHA256.hash(data: self)
    }
}

// Import hash algorithm at module level
// Note: This assumes SHA256 is available from Hashing module

extension String: MerkleHashable {
    public func merkleHash() -> Data {
        return self.data(using: .utf8)?.merkleHash() ?? Data()
    }
}

/// Merkle Tree Node
///
/// Represents a node in a Merkle tree. Each node contains:
/// - A hash value (computed from children or data)
/// - Left and right child nodes (for internal nodes)
/// - Data (for leaf nodes)
public class MerkleTreeNode {
    /// Hash value of this node
    public let hash: Data
    
    /// Left child node (nil for leaf nodes)
    public let left: MerkleTreeNode?
    
    /// Right child node (nil for leaf nodes)
    public let right: MerkleTreeNode?
    
    /// Data stored in this node (only for leaf nodes)
    public let data: Data?
    
    /// Whether this is a leaf node
    public var isLeaf: Bool {
        return left == nil && right == nil
    }
    
    /// Initialize a leaf node
    /// - Parameters:
    ///   - data: Data to store in the leaf
    ///   - hash: Hash value (computed if nil)
    public init(data: Data, hash: Data? = nil) {
        self.data = data
        self.left = nil
        self.right = nil
        self.hash = hash ?? data.merkleHash()
    }
    
    /// Initialize an internal node
    /// - Parameters:
    ///   - left: Left child node
    ///   - right: Right child node (can be nil for odd number of nodes)
    ///   - hash: Hash value (computed if nil)
    public init(left: MerkleTreeNode, right: MerkleTreeNode?, hash: Data? = nil) {
        self.left = left
        self.right = right
        self.data = nil
        
        // Compute hash from children
        if let right = right {
            var combined = left.hash
            combined.append(right.hash)
            self.hash = hash ?? combined.merkleHash()
        } else {
            // Odd number of nodes - duplicate left hash
            var combined = left.hash
            combined.append(left.hash)
            self.hash = hash ?? combined.merkleHash()
        }
    }
}

/// Merkle Tree - A hash tree data structure
///
/// A Merkle tree is a tree in which every leaf node is labeled with the hash of a data block,
/// and every non-leaf node is labeled with the hash of the labels of its child nodes.
///
/// ## Usage
///
/// ```swift
/// // Create Merkle tree from data
/// let data = ["block1", "block2", "block3", "block4"].map { $0.data(using: .utf8)! }
/// let tree = MerkleTree.build(from: data)
///
/// // Get root hash
/// let rootHash = tree.rootHash
///
/// // Generate proof for a specific leaf
/// if let proof = tree.generateProof(for: data[0]) {
///     // Verify proof
///     let isValid = MerkleTree.verify(proof: proof, rootHash: rootHash)
/// }
/// ```
public struct MerkleTree {
    /// Root node of the tree
    public let root: MerkleTreeNode
    
    /// Root hash (convenience accessor)
    public var rootHash: Data {
        return root.hash
    }
    
    /// Initialize with root node
    /// - Parameter root: Root node of the tree
    private init(root: MerkleTreeNode) {
        self.root = root
    }
    
    /// Build a Merkle tree from an array of data blocks
    /// - Parameter data: Array of data blocks to build tree from
    /// - Returns: Merkle tree
    public static func build(from data: [Data]) -> MerkleTree {
        guard !data.isEmpty else {
            // Empty tree - return single node with empty hash
            let emptyNode = MerkleTreeNode(data: Data())
            return MerkleTree(root: emptyNode)
        }
        
        // Create leaf nodes
        var nodes = data.map { MerkleTreeNode(data: $0) }
        
        // Build tree bottom-up
        while nodes.count > 1 {
            var nextLevel: [MerkleTreeNode] = []
            
            // Process pairs of nodes
            var i = 0
            while i < nodes.count {
                let left = nodes[i]
                let right = (i + 1 < nodes.count) ? nodes[i + 1] : nil
                
                let parent = MerkleTreeNode(left: left, right: right)
                nextLevel.append(parent)
                
                i += 2
            }
            
            nodes = nextLevel
        }
        
        return MerkleTree(root: nodes[0])
    }
    
    /// Build a Merkle tree from hashable items
    /// - Parameter items: Array of hashable items
    /// - Returns: Merkle tree
    public static func build<T: MerkleHashable>(from items: [T]) -> MerkleTree {
        let data = items.map { item -> Data in
            if let data = item as? Data {
                return data
            } else if let string = item as? String {
                return string.data(using: .utf8) ?? Data()
            } else {
                return item.merkleHash()
            }
        }
        return build(from: data)
    }
    
    /// Generate a Merkle proof for a specific data block
    /// - Parameter data: Data block to generate proof for
    /// - Returns: Merkle proof, or nil if data not found
    public func generateProof(for data: Data) -> MerkleProof? {
        let targetHash = data.merkleHash()
        var path: [MerkleProofNode] = []
        
        func traverse(node: MerkleTreeNode?, targetHash: Data) -> Bool {
            guard let node = node else { return false }
            
            if node.isLeaf {
                return node.hash == targetHash
            }
            
            // Check left subtree
            if traverse(node: node.left, targetHash: targetHash) {
                // Add right sibling to path
                if let right = node.right {
                    path.append(MerkleProofNode(hash: right.hash, isLeft: false))
                }
                return true
            }
            
            // Check right subtree
            if traverse(node: node.right, targetHash: targetHash) {
                // Add left sibling to path
                if let left = node.left {
                    path.append(MerkleProofNode(hash: left.hash, isLeft: true))
                }
                return true
            }
            
            return false
        }
        
        guard traverse(node: root, targetHash: targetHash) else {
            return nil
        }
        
        return MerkleProof(leafHash: targetHash, path: path.reversed())
    }
    
    /// Verify a Merkle proof
    /// - Parameters:
    ///   - proof: Merkle proof to verify
    ///   - rootHash: Expected root hash
    /// - Returns: true if proof is valid
    public static func verify(proof: MerkleProof, rootHash: Data) -> Bool {
        var currentHash = proof.leafHash
        
        // The proof path is built bottom-up (leaf to root) and then reversed,
        // so it's ordered from root to leaf. We need to process it leaf to root,
        // so we reverse it again.
        for node in proof.path.reversed() {
            var combined: Data
            if node.isLeft {
                // Left sibling - the sibling is on the left, current is on the right
                // Combine: left sibling + current hash
                combined = node.hash
                combined.append(currentHash)
            } else {
                // Right sibling - current is on the left, sibling is on the right
                // Combine: current hash + right sibling
                combined = currentHash
                combined.append(node.hash)
            }
            currentHash = combined.merkleHash()
        }
        
        return currentHash == rootHash
    }
}

/// Merkle Proof - Proof that a data block exists in a Merkle tree
public struct MerkleProof {
    /// Hash of the leaf node
    public let leafHash: Data
    
    /// Path from leaf to root (sibling hashes)
    public let path: [MerkleProofNode]
    
    /// Initialize proof
    /// - Parameters:
    ///   - leafHash: Hash of the leaf node
    ///   - path: Path from leaf to root
    public init(leafHash: Data, path: [MerkleProofNode]) {
        self.leafHash = leafHash
        self.path = path
    }
}

/// Merkle Proof Node - Represents a sibling node in the proof path
public struct MerkleProofNode {
    /// Hash of the sibling node
    public let hash: Data
    
    /// Whether this is a left sibling (false means right sibling)
    public let isLeft: Bool
    
    /// Initialize proof node
    /// - Parameters:
    ///   - hash: Hash of the sibling node
    ///   - isLeft: Whether this is a left sibling
    public init(hash: Data, isLeft: Bool) {
        self.hash = hash
        self.isLeft = isLeft
    }
}
