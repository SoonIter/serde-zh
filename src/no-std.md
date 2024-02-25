# No-std 支持

`serde` crate 有一个 Cargo feature，名为 `"std"`，默认情况下是启用的。
为了在 no\_std 环境中使用 Serde，需要禁用这个 feature。
在 Cargo.toml 中修改 Serde 依赖项，以选择不启用默认 feature。

```toml
[dependencies]
serde = { version = "1.0", default-features = false }
```

请注意，Cargo feature 在整个依赖图中是联合在一起的。这意味着，如果你依赖的任何其他 crate 没有选择关闭 Serde 的默认 feature，无论你对 Serde 的直接依赖是否设置了 `default-features = false`，你都会构建带有 std feature 的 Serde。

需要特别地说一句，对 `serde_json` 的依赖始终需要使用带有 std 的 Serde。如果需要不带标准库的 JSON 支持，请使用 [`serde-json-core`] 而非 `serde_json`。

[`serde-json-core`]: https://crates.io/crates/serde-json-core

### 派生

在无标准库 crate 中，`#[derive(Serialize, Deserialize)]` 派生宏的工作方式与标准库 crate 中相同。

```toml
[dependencies]
serde = { version = "1.0", default-features = false, features = ["derive"] }
```

一些需要堆分配临时缓冲区的反序列化功能在 no-std 模式下可能无法使用，除非有内存分配器。特别是 [untagged enums] 无法反序列化。

[derive macros]: derive.md
[untagged enums]: enum-representations.md

### 内存分配

禁用 Serde 的 `"std"` feature 删除了涉及堆内存分配的任何标准库数据结构的支持，包括 `String` 和 `Vec<T>`。它还移除了一些 `derive(Deserialize)` 的特性，包括 un tagged enums。

你可以通过启用 `"alloc"` Cargo feature 来重新启用这些 impls。这种配置提供了对堆分配集合的集成，而不依赖于 Rust 标准库的其他部分。

```toml
[dependencies]
serde = { version = "1.0", default-features = false, features = ["alloc"] }
```
