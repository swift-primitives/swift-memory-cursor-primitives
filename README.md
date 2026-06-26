# Memory Cursor Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-primitives/swift-memory-cursor-primitives/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-primitives/swift-memory-cursor-primitives/actions/workflows/ci.yml)

Cursor operations for reading contiguous memory. This package supplies the byte-level read surface for a borrowed cursor — `peek`, `peek(at:)`, `advance`, `advance(by:)`, `consume`, and `seek`, plus `position`, `count`, and `isAtEnd` — over any `Cursor<DomainTag>` whose borrowed view is a `Span` of `Byte`. The operations read and walk the region in place, without copying it.

It also supplies two owned single-pass iterators for when the data must outlive the place it was created: `Memory.Cursor<Base>`, which consumes a contiguous region by value and re-derives its span on every step, and `Memory.Snapshot.Cursor<Element>`, which iterates a captured array of elements.

The bare `Cursor<DomainTag>` type itself lives in [`swift-cursor-primitives`](https://github.com/swift-primitives/swift-cursor-primitives); this package is the sibling that adds the memory-contiguous read operations to it. Splitting the operations out keeps the cursor type's own dependency surface minimal — consumers that only need the type don't pull in the byte-span operation set.

---

## Key Features

- **In-place byte reads** — `peek` / `peek(at:)` look without consuming; `advance` / `consume` / `seek` walk or jump the cursor — all over a borrowed `Span<Byte>`, no copy.
- **Typed positions** — `position`, `count`, and offsets are phantom-typed to the cursor's domain (`Tagged<DomainTag, Ordinal>` / `Tagged<DomainTag, Cardinal>`), so an index for one region can't be used against another.
- **Owned iteration when you need it** — `Memory.Cursor` owns its region so a lazy pipeline can outlive the scope that built it; it never holds the non-escapable span across steps (re-derived in O(1) each call).
- **Copyability follows the region** — an owned `~Copyable` region yields a `~Copyable` cursor; a copyable region yields a copyable one.

---

## Quick Start

```swift
import Memory_Cursor_Primitives

// `cursor` is a Cursor<DomainTag> over a contiguous Span<Byte>
// (constructed via swift-cursor-primitives).

while let byte = cursor.peek() {   // look at the current byte without consuming
    process(byte)
    cursor.advance()               // step forward one byte
}

let header = cursor.consume()      // read the byte and advance past it
cursor.seek(to: start)             // jump back to an absolute position
```

For owned, single-pass iteration that keeps its region alive:

```swift
var cursor = Memory.Cursor(region) // consumes `region` (a ~Copyable contiguous Base)
while let element = cursor.next() {
    process(element)
}
```

---

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-memory-cursor-primitives.git", branch: "main")
]
```

Add the product to your target:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Memory Cursor Primitives", package: "swift-memory-cursor-primitives")
    ]
)
```

The package is pre-1.0 — depend on `branch: "main"` until `0.1.0` is tagged. Requires Swift 6.3 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the corresponding Linux / Windows toolchain).

---

## Architecture

| Product | Contents | When to import |
|---------|----------|----------------|
| `Memory Cursor Primitives` | The byte read operations on `Cursor`, the owned `Memory.Cursor` iterator, and the `Memory.Snapshot.Cursor` element iterator | The only product — import this |

---

## Platform Support

| Platform         | CI  | Status       |
|------------------|-----|--------------|
| macOS 26         | Yes | Full support |
| Linux            | Yes | Full support |
| Windows          | Yes | Full support |
| iOS/tvOS/watchOS | —   | Supported    |

---

## Related Packages

- [`swift-cursor-primitives`](https://github.com/swift-primitives/swift-cursor-primitives) — `Cursor<DomainTag>`, the borrowed cursor type these operations extend.
- [`swift-storage-primitives`](https://github.com/swift-primitives/swift-storage-primitives) — `Storage.Contiguous`, an owned contiguous region a `Memory.Cursor` can iterate.
- [`swift-span-primitives`](https://github.com/swift-primitives/swift-span-primitives) — the `Span` protocol the byte operations read through.

---

## Community

<!-- BEGIN: discussion -->
<!-- Discussion thread created at publication. -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
