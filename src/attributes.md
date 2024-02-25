# 属性(Attributes)

[属性(Attributes)] 用于自定义 Serde 派生生成的 `Serialize` 和 `Deserialize` 实现。它们需要 Rust 编译器版本 1.15 及以上。

[属性(Attributes)]: https://doc.rust-lang.org/book/attributes.html

有三类属性：

- [**容器属性(Container attributes)**] — 应用于 struct 或 enum声明。
- [**变体属性(Variant attributes)**] — 应用于 enum 的一个变体。
- [**字段属性(Field attributes)**] — 应用于 struct 中的一个字段或 enum 变体中的一个字段。

[**容器属性(Container attributes)**]: container-attrs.md
[**变体属性(Variant attributes)**]: variant-attrs.md
[**字段属性(Field attributes)**]: field-attrs.md

```rust
# use serde::{Serialize, Deserialize};
#
#[derive(Serialize, Deserialize)]
#[serde(deny_unknown_fields)]  // <-- 这是一个容器属性
struct S {
    #[serde(default)]  // <-- 这是一个字段属性
    f: i32,
}

#[derive(Serialize, Deserialize)]
#[serde(rename = "e")]  // <-- 这也是一个容器属性
enum E {
    #[serde(rename = "a")]  // <-- 这是一个变体属性
    A(String),
}
#
# fn main() {}
```

请注意，一个单独的 struct、enum、variant 或 field 可能有多个属性。