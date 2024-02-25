# 自定义序列化

Serde 的 [派生宏](derive.md) 通过 `#[derive(Serialize, Deserialize)]` 为 struct 和 enum 提供了合理的默认序列化行为，并且可以使用 [属性](attributes.md) 进行一定程度的定制。对于特殊需求，Serde 允许通过手动为您的类型实现 [`Serialize`] 和 [`Deserialize`] traits 来完全定制序列化行为。

[`Serialize`]: https://docs.rs/serde/1/serde/ser/trait.Serialize.html
[`Deserialize`]: https://docs.rs/serde/1/serde/de/trait.Deserialize.html

这两个 traits 每个都有一个方法：

```rust
# use serde::{Serializer, Deserializer};
#
pub trait Serialize {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer;
}

pub trait Deserialize<'de>: Sized {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>;
}
#
# fn main() {}
```

这些方法是针对序列化格式进行泛型化的，由 [`Serializer`] 和 [`Deserializer`] traits 表示。例如，JSON 有一个 Serializer 类型，而 Postcard 则有另一种。

[`Serializer`]: https://docs.rs/serde/1/serde/ser/trait.Serializer.html
[`Deserializer`]: https://docs.rs/serde/1/serde/de/trait.Deserializer.html

- [实现 `Serialize`](impl-serialize.md)
- [实现 `Deserialize`](impl-deserialize.md)