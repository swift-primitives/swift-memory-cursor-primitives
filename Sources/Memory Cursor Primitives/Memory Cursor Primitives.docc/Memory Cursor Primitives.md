# ``Memory_Cursor_Primitives``

@Metadata {
    @DisplayName("Memory Cursor Primitives")
    @TitleHeading("Swift Primitives")
}

Cursor operations for reading contiguous memory: the in-place byte read surface (`peek` / `advance` / `consume` / `seek`) on a borrowed `Cursor`, plus the owned single-pass iterators `Memory.Cursor` and `Memory.Snapshot.Cursor` for data that must outlive the scope that built it.

## Topics

### Owned cursors

- ``Memory/Cursor``
- ``Memory/Snapshot/Cursor``
```
