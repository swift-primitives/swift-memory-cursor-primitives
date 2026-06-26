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

import Cursor_Primitive
import Memory_Cursor_Primitives_Test_Support
import Testing

private enum TestDomain {}

extension TestDomain: Ownership.Borrow.`Protocol` {
    // W3 PRUNE: Byte.Borrowed nominal deleted; the borrowed projection is
    // bare Swift.Span<Byte>.
    typealias Borrowed = Swift.Span<Byte>
}

// MARK: - Test Suite Structure

@Suite("Cursor")
struct CursorTest {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit

extension CursorTest.Unit {
    @Test
    func `init at zero with empty source`() {
        let bytes: [Byte] = []
        unsafe bytes.withUnsafeBufferPointer { buf in
            let span = unsafe Swift.Span(_unsafeElements: buf)
            let cursor = Cursor<TestDomain>(span)
            let atEnd = cursor.isAtEnd
            let peeked = cursor.peek()
            #expect(atEnd)
            #expect(peeked == nil)
        }
    }

    @Test
    func `init at zero with non-empty source`() {
        let bytes: [Byte] = [0x01, 0x02, 0x03, 0x04]
        unsafe bytes.withUnsafeBufferPointer { buf in
            let span = unsafe Swift.Span(_unsafeElements: buf)
            let cursor = Cursor<TestDomain>(span)
            let atEnd = cursor.isAtEnd
            let peeked = cursor.peek()
            #expect(!atEnd)
            #expect(peeked == 0x01)
        }
    }

    @Test
    func `peek does not advance`() {
        let bytes: [Byte] = [0x42, 0x43]
        unsafe bytes.withUnsafeBufferPointer { buf in
            let span = unsafe Swift.Span(_unsafeElements: buf)
            let cursor = Cursor<TestDomain>(span)
            let first = cursor.peek()
            let second = cursor.peek()
            #expect(first == 0x42)
            #expect(second == 0x42)
        }
    }

    @Test
    func `peek at offset reads ahead`() {
        let bytes: [Byte] = [0xAA, 0xBB, 0xCC, 0xDD]
        unsafe bytes.withUnsafeBufferPointer { buf in
            let span = unsafe Swift.Span(_unsafeElements: buf)
            let cursor = Cursor<TestDomain>(span)
            let at0 = cursor.peek(at: Tagged<TestDomain, Cardinal>(_unchecked: Cardinal(UInt(0))))
            let at2 = cursor.peek(at: Tagged<TestDomain, Cardinal>(_unchecked: Cardinal(UInt(2))))
            let past = cursor.peek(at: Tagged<TestDomain, Cardinal>(_unchecked: Cardinal(UInt(4))))
            #expect(at0 == 0xAA)
            #expect(at2 == 0xCC)
            #expect(past == nil)
        }
    }

    @Test
    func `advance moves cursor forward`() {
        let bytes: [Byte] = [0x01, 0x02, 0x03]
        unsafe bytes.withUnsafeBufferPointer { buf in
            let span = unsafe Swift.Span(_unsafeElements: buf)
            var cursor = Cursor<TestDomain>(span)
            cursor.advance()
            let after1 = cursor.peek()
            cursor.advance()
            let after2 = cursor.peek()
            #expect(after1 == 0x02)
            #expect(after2 == 0x03)
        }
    }

    @Test
    func `consume reads and advances`() {
        let bytes: [Byte] = [0x10, 0x20, 0x30]
        unsafe bytes.withUnsafeBufferPointer { buf in
            let span = unsafe Swift.Span(_unsafeElements: buf)
            var cursor = Cursor<TestDomain>(span)
            let a = cursor.consume()
            let b = cursor.consume()
            let c = cursor.consume()
            let atEnd = cursor.isAtEnd
            #expect(a == 0x10)
            #expect(b == 0x20)
            #expect(c == 0x30)
            #expect(atEnd)
        }
    }

    @Test
    func `seek to position restores cursor`() {
        let bytes: [Byte] = [0x10, 0x20, 0x30, 0x40]
        unsafe bytes.withUnsafeBufferPointer { buf in
            let span = unsafe Swift.Span(_unsafeElements: buf)
            var cursor = Cursor<TestDomain>(span)
            let saved = cursor.position
            cursor.advance()
            cursor.advance()
            let after2 = cursor.peek()
            cursor.seek(to: saved)
            let backToStart = cursor.peek()
            #expect(after2 == 0x30)
            #expect(backToStart == 0x10)
        }
    }

    @Test
    func `count reflects remaining bytes`() {
        let bytes: [Byte] = [1, 2, 3, 4, 5]
        unsafe bytes.withUnsafeBufferPointer { buf in
            let span = unsafe Swift.Span(_unsafeElements: buf)
            var cursor = Cursor<TestDomain>(span)
            let initialCount = Int(bitPattern: cursor.count)
            #expect(initialCount == 5)
            cursor.advance()
            let afterOne = Int(bitPattern: cursor.count)
            #expect(afterOne == 4)
            cursor.advance(by: Tagged<TestDomain, Cardinal>(_unchecked: Cardinal(UInt(3))))
            let afterFour = Int(bitPattern: cursor.count)
            #expect(afterFour == 1)
        }
    }
}

// MARK: - Edge Case

extension CursorTest.`Edge Case` {
    @Test
    func `isAtEnd true after consuming all bytes`() {
        let bytes: [Byte] = [0xFF]
        unsafe bytes.withUnsafeBufferPointer { buf in
            let span = unsafe Swift.Span(_unsafeElements: buf)
            var cursor = Cursor<TestDomain>(span)
            _ = cursor.consume()
            let atEnd = cursor.isAtEnd
            let peeked = cursor.peek()
            #expect(atEnd)
            #expect(peeked == nil)
        }
    }

    @Test
    func `count is zero on empty source`() {
        let bytes: [Byte] = []
        unsafe bytes.withUnsafeBufferPointer { buf in
            let span = unsafe Swift.Span(_unsafeElements: buf)
            let cursor = Cursor<TestDomain>(span)
            let initialCount = Int(bitPattern: cursor.count)
            #expect(initialCount == 0)
        }
    }
}

// MARK: - Integration

extension CursorTest.Integration {
    @Test
    func `drains every byte via consume loop`() {
        let bytes: [Byte] = (0..<32).map { Byte(UInt8($0)) }
        let collected: [Byte] = unsafe bytes.withUnsafeBufferPointer { buf -> [Byte] in
            let span = unsafe Swift.Span(_unsafeElements: buf)
            var cursor = Cursor<TestDomain>(span)
            var out: [Byte] = []
            while !cursor.isAtEnd {
                out.append(cursor.consume())
            }
            return out
        }
        #expect(collected == bytes)
    }

    @Test
    func `peek + advance loop matches consume loop`() {
        let bytes: [Byte] = (0..<32).map { Byte(UInt8($0)) }
        let collected: [Byte] = unsafe bytes.withUnsafeBufferPointer { buf -> [Byte] in
            let span = unsafe Swift.Span(_unsafeElements: buf)
            var cursor = Cursor<TestDomain>(span)
            var out: [Byte] = []
            while let b = cursor.peek() {
                out.append(b)
                cursor.advance()
            }
            return out
        }
        #expect(collected == bytes)
    }
}

// MARK: - Performance
//
// Substantive performance tests live in the BENCH-011 experiments.
// This suite stays empty at the package level; existence satisfies
// [TEST-005]'s four-category structure.
