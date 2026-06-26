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

import Index_Primitives
import Iterator_Protocol
import Memory_Allocator_Primitive
import Memory_Cursor_Primitives_Test_Support
import Memory_Heap_Primitives
import Ordinal_Primitives
import Storage_Contiguous_Primitives
import Testing

// MARK: - Test Suite Structure

@Suite("Memory.Cursor")
struct MemoryCursorTest {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

// The post-dissolution owned-typed contiguous region: `Storage.Contiguous` over a
// heap passthrough allocation. It is the `~Copyable` `Span.\`Protocol\`` conformer
// the cursor consumes.
private typealias OwnedRegion<Element: ~Copyable> =
    Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Element>

// Helper: build an owned `Storage.Contiguous<Int>` from a Swift array, run a body
// over a `Memory.Cursor` instantiated on it. The storage owns a heap allocation and
// frees it on deinit; the cursor consumes it.
private func withMemoryCursor<R>(
    over values: [Int],
    _ body: (consuming Memory.Cursor<OwnedRegion<Int>>) -> R
) -> R {
    var region = OwnedRegion<Int>.create(
        minimumCapacity: Index<Int>.Count(UInt(values.count))
    )
    for (i, v) in values.enumerated() {
        region.initialize(at: Index<Int>(Ordinal(UInt(i))), to: v)
    }
    return body(Memory.Cursor(region))
}

// MARK: - Unit

extension MemoryCursorTest.Unit {
    @Test
    func `next yields first element then advances`() {
        let first = withMemoryCursor(over: [10, 20, 30]) { cursor -> Int? in
            var iterator = cursor
            return iterator.next()
        }
        #expect(first == 10)
    }

    @Test
    func `next returns nil on empty region`() {
        let value = withMemoryCursor(over: []) { cursor -> Int? in
            var iterator = cursor
            return iterator.next()
        }
        #expect(value == nil)
    }
}

// MARK: - Edge Case

extension MemoryCursorTest.`Edge Case` {
    @Test
    func `single element drains to nil`() {
        let collected = withMemoryCursor(over: [42]) { cursor -> [Int] in
            var iterator = cursor
            var out: [Int] = []
            while let x = iterator.next() { out.append(x) }
            return out
        }
        #expect(collected == [42])
    }
}

// MARK: - Integration

extension MemoryCursorTest.Integration {
    // OQ-2 in-context verdict: a generic `Memory.Cursor<Base>` instantiated on
    // the real `~Copyable` `Storage.Contiguous<Int>` conformer, conforming
    // `Iterator.`Protocol``, drains every element through the `next()` loop
    // that re-derives `base.span` on each call.
    @Test
    func `drains every element via next loop over Storage.Contiguous`() {
        let source = Array(0..<32)
        let collected = withMemoryCursor(over: source) { cursor -> [Int] in
            var iterator = cursor
            var out: [Int] = []
            while let x = iterator.next() { out.append(x) }
            return out
        }
        #expect(collected == source)
    }
}
