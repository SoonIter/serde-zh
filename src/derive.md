# 使用 derive

Serde 提供了一个宏 `derive` 来为您 crate 中定义的数据结构生成 `Serialize` 和 `Deserialize` traits 的实现，让它们方便地在所有 Serde 的数据格式中表示。

**您只需在代码中使用 `#[derive(Serialize, Deserialize)]` 时设置这个功能。**

这个功能基于 Rust 的 `#[derive]` 机制，就像您用来自动派生内置的 `Clone`、`Copy`、`Debug` 或其他特性的实现一样。它能为大多数带有复杂泛型类型或特性边界的结构体和枚举生成实现。在极少数情况下，对于特别复杂的类型，您可能需要[手动实现这些特性](custom-serialization.md)。

这些派生需要 Rust 编译器版本 1.31 及以上。

!CHECKLIST
- 在 Cargo.toml 中添加依赖 `serde = { version = "1.0", features = ["derive"] }`。
- 确保所有其他基于 Serde 的依赖项（例如 serde_json）的版本与 serde 1.0 是兼容的。
- 对于您想序列化的结构体和枚举，在相同模块中导入派生宏为 `use serde::Serialize;` 并在结构体或枚举上写上 `#[derive(Serialize)]`。
- 类似地导入`use serde::Deserialize;` 并在您想反序列化的结构体和枚举上写 `#[derive(Deserialize)]`。

这是 `Cargo.toml`：

<!-- !FILENAME Cargo.toml -->
```toml
[package]
name = "my-crate"
version = "0.1.0"
authors = ["Me <user@rust-lang.org>"]

[dependencies]
serde = { version = "1.0", features = ["derive"] }

# serde_json 只是为例子而已，一般不需要
serde_json = "1.0"
```

现在这是在 `src/main.rs` 中使用 Serde 的自定义派生：

<!-- !FILENAME src/main.rs -->
<!-- !PLAYGROUND 1dbc76000e9875fac72c2865748842d7 -->
```rust
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize, Debug)]
struct Point {
    x: i32,
    y: i32,
}

fn main() {
    let point = Point { x: 1, y: 2 };

    let serialized = serde_json::to_string(&point).unwrap();
    println!("serialized = {}", serialized);

    let deserialized: Point = serde_json::from_str(&serialized).unwrap();
    println!("deserialized = {:?}", deserialized);
}
```

这是输出：

```bash
$ cargo run
serialized = {"x":1,"y":2}
deserialized = Point { x: 1, y: 2 }
```

### 故障排除

有时您可能会看到编译时错误，告诉您：

```bash
the trait `serde::ser::Serialize` is not implemented for `...`
```

即使结构体或枚举明确上有 `#[derive(Serialize)]`。

这几乎总是意味着您正在使用依赖于不兼容版本 Serde 的库。您可能在 Cargo.toml 中依赖于 serde 1.0，但是使用另一个依赖于 serde 0.9 的库。因此，从 Rust 编译器的角度来看，serde 1.0 中的 `Serialize` 特性可能已经实现，但该库期望 serde 0.9 中的 `Serialize` 特性的实现。这些对于 Rust 编译器而言是完全不同的特性。

修复的方法是根据需要升级或降级库，直到 Serde 版本匹配。`cargo tree -d` 命令有助于找出所有重复依赖项被引入的地方。