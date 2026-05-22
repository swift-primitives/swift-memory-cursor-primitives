# Memory Cursor Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Memory-contiguous-borrow operations for `Cursor` — `peek`, `peek(at:)`, `advance`, `advance(by:)`, `consume`, `seek`, `position`, `count`, `isAtEnd` over a `Cursor<DomainTag>` whose `DomainTag.Borrowed` conforms to `Memory.Contiguous<Byte>.Borrowed.`Protocol``.

Sibling extraction of swift-cursor-primitives. The bare `Cursor<DomainTag>` type lives in `Cursor_Primitive`; this package adds the memory-contiguous-borrow operation surface that fires across every `DomainTag` whose `Borrowed` type exposes a `Swift.Span<Byte>`. Subject-first naming per `[API-NAME-001b]` — Memory is the subject (data domain), Cursor is the role.

For the byte-substrate init convenience (`Cursor<DomainTag>(_ span: borrowing Swift.Span<Byte>)`), see [swift-byte-cursor-primitives](https://github.com/swift-primitives/swift-byte-cursor-primitives).

---
