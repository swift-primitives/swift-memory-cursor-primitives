// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-memory-cursor-primitives open source project
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp and the swift-memory-cursor-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Iterator_Protocol
public import Memory_Primitive  // the `Memory` namespace

extension Memory {
    /// An owned, single-pass iterator over an **element-snapshot** of a contiguous
    /// memory region — the demangle-safe sibling of ``Memory/Cursor``.
    ///
    /// ## Why this exists
    ///
    /// The generic owned ``Memory/Cursor`` (`Memory.Cursor<Base>`) is parameterized by
    /// the *whole* contiguous `Base` type. Used as a `Sequenceable.Iterator`
    /// associated-type **witness**, its mangled name embeds the conforming type. For the
    /// old-tower value-generic, `@_rawLayout`-backed inline conformer
    /// (`Buffer.Linear.Inline`; withdrawn in the W5 tower reshape — the surviving deep
    /// conformers spell `Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>>.Linear`)
    /// that deep generic instantiation made IRGen emit a **corrupt** associated-type-
    /// witness mangled name on Swift 6.3.2 (and 6.4-dev): in debug the runtime demangler fails
    /// (`failed to demangle witness for associated type 'Iterator' … from mangled name
    /// '}'`, Signal 6 in `Sequenceable.collect()`); in release the LLVM verifier rejects
    /// the module ("Broken module found"). See
    /// `swift-institute/Research/memory-contiguous-iteration-bridge.md` (Outcome OQ-2) and
    /// `Experiments/memory-cursor-generic-witness-demangle` for the reproduction.
    ///
    /// `Memory.Snapshot.Cursor` is generic **only over `Element`**. As a witness its mangled
    /// name is the shallow `Memory.Snapshot.Cursor<A>` — it never embeds the conforming type —
    /// which **structurally dodges** the corrupt-mangling path. The
    /// `Storage.Contiguous → Sequenceable` bridge that vends it
    /// (`swift-memory-sequence-primitives`) **eagerly snapshots** the contiguous span into an
    /// owned `[Element]` at `makeIterator()` time (the source is already contiguous in memory
    /// and `Element: Copyable`), then iterates by index.
    ///
    /// ## Trade-off vs the lazy ``Memory/Cursor``
    ///
    /// The snapshot costs one `[Element]` allocation + a bulk element copy up front, versus
    /// the lazy cursor's per-`next()` span re-derivation. For inline `@_rawLayout` conformers
    /// (the old-tower `Buffer.Linear.Inline`, withdrawn in the W5 reshape) the eager snapshot
    /// was the *only* shallow-generic shape expressible safely: a lazy element-only iterator
    /// would have to hold a raw pointer into the consumed inline storage, which would dangle.
    /// The lazy ``Memory/Cursor`` remains the preferred witness for any conformer whose deep
    /// instantiation does **not** trip the demangle bug.
    ///
    /// > NOTE: This is the experiment-validated reshape from
    /// > `Experiments/memory-cursor-generic-witness-demangle` (the literal-topology dodge,
    /// > debug + release-with-`-disable-llvm-verify`). Final adoption — name, whether to
    /// > replace or sit alongside the lazy `Memory.Cursor`, and the separate ambient
    /// > buffer-linear release ICE — is a principal decision; see the experiment writeup.
    public enum Snapshot {}
}

extension Memory.Snapshot {
    /// Element-snapshot single-pass iterator.
    ///
    /// See the ``Memory/Snapshot`` discussion for the demangle-safety rationale.
    @frozen
    public struct Cursor<Element: Copyable & Escapable> {
        @usableFromInline
        var elements: [Element]

        @usableFromInline
        var index: Int

        /// Creates an iterator that drains the given owned element snapshot in order.
        ///
        /// - Parameter elements: The element snapshot to iterate. Consumed.
        @inlinable
        public init(_ elements: consuming [Element]) {
            self.elements = elements
            self.index = 0
        }
    }
}

extension Memory.Snapshot.Cursor: Iterator.`Protocol` {
    /// The error type; iteration never fails.
    public typealias Failure = Never

    /// Advances the iterator and returns the next element, or `nil` when the
    /// snapshot is exhausted.
    @inlinable
    public mutating func next() -> Element? {
        guard index < elements.count else { return nil }
        defer { index += 1 }
        return elements[index]
    }
}
