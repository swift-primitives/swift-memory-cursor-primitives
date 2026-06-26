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

public import Byte_Primitives
import Cardinal_Primitives
public import Cursor_Primitive
import Ordinal_Primitives
public import Span_Protocol_Primitives
public import Tagged_Primitives

// Cursor operations — applicable to every `Cursor<DomainTag>` whose
// `DomainTag.Borrowed` conforms to `Span.\`Protocol\`` with `Element == Byte`.
// peek / peek(at:) / advance / advance(by:) / consume / position / count /
// isAtEnd / seek(to:). Generalized over a single protocol constraint so the
// same surface fires for Cursor<Byte>, Cursor<Text>, Cursor<Binary>, and any
// future DomainTag whose Borrowed type conforms to the protocol.
//
// Per `binary-byte-namespace-domain-foundations.md` v3.0.0 and
// `cursor-shape-a-vs-three-worlds.md` v1.5.0 — Binary as third Case-B
// conformer.
//
// ## Byte Substrate (W3 `.Borrowed` prune landed)
//
// The constraint is `Element == Byte` per the byte-domain typing discipline.
// After the W3 prune, `Byte`/`Text`/`Binary` all resolve `Borrowed` to bare
// `Swift.Span<Byte>` (the `Byte.Borrowed`/`Binary.Borrowed` nominals are
// deleted), which conforms to the unified `Span.`Protocol`` by identity.
// These operations read only `storage.span`, so they fire unchanged for
// every such cursor. peek/consume return `Byte` directly without per-element
// wrapping.

extension Cursor
where
    DomainTag.Borrowed: Span.`Protocol`,
    DomainTag.Borrowed.Element == Byte,
    DomainTag: ~Copyable
{
    // swiftlint:disable no_tag_suffix_phantom
    // reason: `DomainTag` is the public generic-parameter name of `Cursor`
    // (`swift-cursor-primitives`), referenced here in the typed position and
    // count signatures. Renaming it to the bare-concept form is a cross-package
    // breaking change, out of scope for mechanical release-prep; deferred to a
    // coordinated rename.

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
    // swiftlint:enable no_tag_suffix_phantom
}
