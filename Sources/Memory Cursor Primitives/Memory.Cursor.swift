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
public import Memory_Primitive
public import Ordinal_Primitives
public import Span_Protocol_Primitives
public import Tagged_Primitives

extension Memory {
    // SAFETY: Safe by construction — backing storage uses only the owned
    // SAFETY: `Base` and a typed `Tagged<Base, Ordinal>` position; the type
    // SAFETY: performs no unsafe operations of its own. `@frozen` exposes the
    // SAFETY: two-field layout (base + position) to the optimizer for
    // SAFETY: cross-module specialization, mirroring the borrowed `Cursor`.
    /// An owned, single-pass cursor over a contiguous memory region.
    ///
    /// `Memory.Cursor` is the **owned** analog of the borrowed
    /// ``Cursor`` (`swift-cursor-primitives`): where `Cursor<DomainTag>`
    /// stores a borrowed `~Copyable, ~Escapable` view (`DomainTag.Borrowed`),
    /// `Memory.Cursor` **owns** its consumed contiguous `Base` by value and
    /// re-derives the span inside every ``next()``. It realizes the deferred
    /// W1 owned-cursor sibling named in
    /// `swift-institute/Research/cursor-shape-a-vs-three-worlds.md` (Phase-4
    /// scope note) and supplies the iterator the
    /// `Storage.Contiguous → Sequenceable` bridge vends
    /// (`swift-institute/Research/memory-contiguous-iteration-bridge.md` §1).
    ///
    /// ## Ownership
    ///
    /// Stores ``base`` by value (consumed at construction). The
    /// `Sequenceable.makeIterator()` requirement is `consuming`, so the
    /// iterator must outlive `self`; owning the base keeps the memory alive
    /// for the duration of a lazy pipeline that stores the consumed stage.
    ///
    /// Conditionally `~Copyable`: the cursor inherits `Base`'s copyability,
    /// so an owned `~Copyable` contiguous region (e.g.,
    /// ``Memory/Contiguous``) yields a `~Copyable` cursor, while a `Copyable`
    /// `Base` yields a `Copyable` cursor. The foundation
    /// `Iterator.`Protocol`` suppresses both `Copyable` and `Escapable`, so
    /// either profile satisfies it.
    ///
    /// ## Escapability and `@_lifetime`
    ///
    /// `Memory.Cursor` is **Escapable** (it tracks `Base`, whose contiguous
    /// regions are Escapable owned containers). Because the cursor is
    /// Escapable, ``next()`` **omits** `@_lifetime` — the annotation is
    /// invalid on an Escapable result, and the Escapable witness satisfies
    /// the `@_lifetime(&self)`-annotated `Iterator.`Protocol`.next()`
    /// requirement without it (confirmed by the bridge-shape spike, OQ-2,
    /// debug + release).
    ///
    /// ## Span lifetime
    ///
    /// ``next()`` re-derives `base.span` on every call and never stores it —
    /// the span is `~Escapable` and cannot be held across calls. Re-deriving
    /// borrows the owned `base` per call in O(1).
    @frozen
    public struct Cursor<Base: Span.`Protocol` & ~Copyable>: ~Copyable
    where Base.Element: Copyable & Escapable {
        /// The owned contiguous region being iterated.
        ///
        /// Consumed at construction; the cursor keeps it alive for the
        /// lifetime of the iteration (and of any lazy pipeline that consumes
        /// the cursor).
        public var base: Base

        /// The cursor's current position within ``base``.
        ///
        /// Phantom-typed to `Base` to mirror the borrowed ``Cursor``'s
        /// `Tagged<_, Ordinal>` position convention.
        public var position: Tagged<Base, Ordinal>

        /// Creates a cursor at position zero from an owned contiguous region.
        ///
        /// - Parameter base: The contiguous region to iterate. Consumed.
        @inlinable
        public init(_ base: consuming Base) {
            self.base = base
            self.position = Tagged<Base, Ordinal>(_unchecked: Ordinal(UInt(0)))
        }
    }
}

// `where Base: ~Copyable` propagates the type's `~Copyable` suppression to the
// conformance ([MEM-COPY-004] / `feedback_extension_implies_copyable`); without
// it the bare extension would implicitly require `Base: Copyable`, making
// `next()` unavailable for owned `~Copyable` regions like `Storage.Contiguous`.
extension Memory.Cursor: Iterator.`Protocol` where Base: ~Copyable {
    /// The element type the iterator yields, taken from the region's element.
    public typealias Element = Base.Element

    /// The error type; iteration never fails.
    public typealias Failure = Never

    /// Advances the cursor and returns the next element, or `nil` when the
    /// region is exhausted.
    ///
    /// Re-derives `base.span` on each call (never stored — the span is
    /// `~Escapable`) and copies the element out (`Element: Copyable &
    /// Escapable`). No `@_lifetime`: the Escapable result rejects it, and the
    /// Escapable witness satisfies the `@_lifetime(&self)`-annotated protocol
    /// requirement without it.
    @inlinable
    public mutating func next() -> Base.Element? {
        let span = base.span
        let index = Int(bitPattern: position)
        guard index < span.count else { return nil }
        defer { position = position.successor.saturating() }
        return span[index]
    }
}
