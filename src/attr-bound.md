# 手写泛型边界(generic trait bound)

当为具有泛型类型参数的结构体派生 `Serialize` 和 `Deserialize` 实现时，大多数情况下 Serde 能够推断出正确的 trait 边界，无需程序员的帮助。它使用几种启发式方法来猜测正确的边界，但最重要的是，它会在每个序列化字段中包含的类型参数 `T`上放置一个边界 `T: Serialize`，并在每个反序列化字段中包含的类型参数 `T` 上放置一个边界 `T: Deserialize`。就像大多数启发式方法一样，这并不总是正确的，Serde 提供了一个 escape

<!-- !PLAYGROUND d2a50878ab69a5786f5a3a11a9de71ea -->

```rust
use serde::{de, Deserialize, Deserializer};

use std::fmt::Display;
use std::str::FromStr;

#[derive(Deserialize, Debug)]
struct Outer<'a, S, T: 'a + ?Sized> {
    // 当生成 Deserialize 实现时，Serde 希望在此字段的类型上生成一个边界`S: Deserialize`。但是，我们将使用类型的 `FromStr` 实现而不是其`Deserialize` 实现，通过 `deserialize_from_str` 来实现结果，因此我们通过为 `deserialize_from_str` 所需的边界覆盖自动生成的边界。
    #[serde(deserialize_with = "deserialize_from_str")]
    #[serde(bound(deserialize = "S: FromStr, S::Err: Display"))]
    s: S,

    // 这里 Serde 希望生成一个边界 `T: Deserialize`。这是一个比必要条件更严格的条件。事实上，下面的 `main` 函数使用 T=str，它并不实现Deserialize。我们通过一个更宽松的边界覆盖自动生成的边界。
    #[serde(bound(deserialize = "Ptr<'a, T>: Deserialize<'de>"))]
    ptr: Ptr<'a, T>,
}

/// 通过反序列化字符串，然后使用 `S` 的 `FromStr` 实现来创建结果，对类型 `S` 进行反序列化。泛型类型 `S` 不需要实现 `Deserialize`。
fn deserialize_from_str<'de, S, D>(deserializer: D) -> Result<S, D::Error>
where
    S: FromStr,
    S::Err: Display,
    D: Deserializer<'de>,
{
    let s: String = Deserialize::deserialize(deserializer)?;
    S::from_str(&s).map_err(de::Error::custom)
}

/// 指向 `T` 的指针，可能或可能不拥有数据。在反序列化时，我们总是希望生成拥有数据。
#[derive(Debug)]
enum Ptr<'a, T: 'a + ?Sized> {
    # #[allow(dead_code)]
    Ref(&'a T),
    Owned(Box<T>),
}

impl<'de, 'a, T: 'a + ?Sized> Deserialize<'de> for Ptr<'a, T>
where
    Box<T>: Deserialize<'de>,
{
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        Deserialize::deserialize(deserializer).map(Ptr::Owned)
    }
}

fn main() {
    let j = r#"
        {
            "s": "1234567890",
            "ptr": "owned"
        }
    "#;

    let result: Outer<u64, str> = serde_json::from_str(j).unwrap();

    // result = Outer { s: 1234567890, ptr: Owned("owned") }
    println!("result = {:?}", result);
}
```
