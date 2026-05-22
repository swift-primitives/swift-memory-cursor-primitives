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

public import Cursor_Primitive
public import Byte_Primitives
public import Memory_Contiguous_Primitives
public import Cardinal_Primitives
public import Ordinal_Primitives
public import Tagged_Primitives

// Cursor operations — applicable to every `Cursor<DomainTag>` whose
// `DomainTag.Borrowed` conforms to `Memory.Contiguous<Byte>.Borrowed.\`Protocol\``.
// peek / peek(at:) / advance / advance(by:) / consume / position / count /
// isAtEnd / seek(to:). Generalized over a single protocol constraint so the
// same surface fires for Cursor<Byte>, Cursor<Text>, Cursor<Binary>, and any
// future DomainTag whose Borrowed type conforms to the protocol.
//
// Per `binary-byte-namespace-domain-foundations.md` v3.0.0 and
// `cursor-shape-a-vs-three-worlds.md` v1.5.0 — Binary as third Case-B
// conformer.
//
// ## Byte Substrate (W2 cascade landed)
//
// The constraint is `Element == Byte` per the W2 byte-domain typing
// discipline — `Byte.Borrowed` and `Binary.Borrowed` both expose
// `Swift.Span<Byte>`. peek/consume return `Byte` directly without
// per-element wrapping.

extension Cursor
where DomainTag.Borrowed: Memory.Contiguous<Byte>.Borrowed.`Protocol`,
      DomainTag.Borrowed.Element == Byte,
      DomainTag: ~Copyable {
    /// The cursor's current position within the borrowed source.
    @inlinable
    public var position: Tagged<DomainTag, Ordinal> { _position }

    /// Number of bytes remaining from the current position to the end.
    @inlinable
    public var count: Tagged<DomainTag, Cardinal> {
        Tagged<DomainTag, Cardinal>(
            _unchecked: Cardinal(UInt(bitPattern: storage.span.count - Int(bitPattern: _position)))
        )
    }

    /// `true` if no bytes remain to read.
    @inlinable
    public var isAtEnd: Bool {
        Int(bitPattern: _position) >= storage.span.count
    }

    /// The byte at the current position, or `nil` if the cursor is at end of input.
    @inlinable
    public func peek() -> Byte? {
        let p = Int(bitPattern: _position)
        guard p < storage.span.count else { return nil }
        return storage.span[p]
    }

    /// The byte `offset` bytes past the current position, or `nil` if that
    /// position is at or past the end.
    @inlinable
    public func peek(at offset: Tagged<DomainTag, Cardinal>) -> Byte? {
        let p = Int(bitPattern: _position) &+ Int(bitPattern: offset)
        guard p >= 0 && p < storage.span.count else { return nil }
        return storage.span[p]
    }

    /// Advances the cursor by one byte.
    ///
    /// - Precondition: `!isAtEnd`.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func advance() {
        precondition(Int(bitPattern: _position) < storage.span.count, "advance() past end of input")
        _position += .one
    }

    /// Advances the cursor by `count` bytes.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func advance(by count: Tagged<DomainTag, Cardinal>) {
        _position += count
    }

    /// Reads the byte at the current cursor and advances by one.
    ///
    /// Fused peek-then-advance — callers that have already verified
    /// `!isAtEnd` (e.g., via a preceding ``peek()`` check) avoid the
    /// redundant Optional unwrap that a separate `peek()` + `advance()`
    /// pair pays.
    ///
    /// - Precondition: `!isAtEnd`.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func consume() -> Byte {
        let p = Int(bitPattern: _position)
        precondition(p < storage.span.count, "consume() past end of input")
        let b = storage.span[p]
        _position += .one
        return b
    }

    /// Seeks the cursor to an absolute position within the source.
    ///
    /// Used for parser-machine backtracking — when a branch fails, restore
    /// the cursor to a previously-captured position. Position-only seeks are
    /// well-defined on a borrowed Span-cursor because no data is consumed
    /// destructively; the source is borrowed read-only and any position in
    /// `0...storage.span.count` remains valid.
    ///
    /// - Precondition: `0 ≤ position ≤ storage.span.count`.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func seek(to position: Tagged<DomainTag, Ordinal>) {
        let p = Int(bitPattern: position)
        precondition(p >= 0 && p <= storage.span.count, "seek to position out of bounds")
        _position = position
    }
}
