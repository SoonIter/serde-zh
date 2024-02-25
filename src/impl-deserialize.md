# 实现 Deserialize

[`Deserialize`] trait 如下所示：

[`Deserialize`]: https://docs.rs/serde/1/serde/de/trait.Deserialize.html

```rust
# use serde::Deserializer;
#
pub trait Deserialize<'de>: Sized {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>;
}
#
# fn main() {}
```

这个方法的作用是通过为 [`Deserializer`] 提供一个 [`Visitor`]，将类型映射到 [Serde 数据模型]，然后由 `Deserializer` 驱动 `Visitor` 来构建类型的实例。

[Serde 数据模型]: data-model.md
[`Deserializer`]: https://docs.rs/serde/1/serde/trait.Deserializer.html
[`Visitor`]: https://docs.rs/serde/1/serde/de/trait.Visitor.html

在大多数情况下，Serde 的 [derive] 能够为您的 crate 中定义的 struct 和 enum 生成适当的 `Deserialize` 实现。如果您需要对某种类型的反序列化行为进行自定义，而派生不支持该行为，可以自己实现 `Deserialize`。实现 `Deserialize` 对于类型而言比实现`Serialize` 更加复杂。

[derive]: derive.md

`Deserializer` trait 支持两种入口样式，从而实现不同种类的反序列化。

1. `deserialize_any` 方法。像 JSON 这样的自描述数据格式能够查看序列化数据并判断其代表的内容。例如，JSON 反序列化器可能看到一个左花括号 (`{`) 并知道它看到的是一个 map。如果数据格式支持 `Deserializer::deserialize_any`，它将根据 input 中判断的类型来驱动 Visitor。JSON 在反序列化 `serde_json::Value` 时使用了这种方法，它是能够表示任何 JSON 文档的 enum。不需要知道 JSON 文档中的内容是什么，我们也可以通过 `Deserializer::deserialize_any` 将其反序列化为 `serde_json::Value`。

2. 其他各种 `deserialize_*` 方法。非自描述格式例如 Postcard 需要告诉输入中包含的是什么内容才能对其进行反序列化。`deserialize_*` 方法是为反序列器提供关于如何解释下一个输入片段的提示。非自描述格式无法对类似`serde_json::Value` 这样依赖 `Deserializer::deserialize_any` 的内容进行反序列化。

在实现 `Deserialize` 时，应避免依赖`Deserializer::deserialize_any`，除非需要反序列化器告诉您输入中的类型。要知道，依赖`Deserializer::deserialize_any` 意味着您的数据类型只能从自描述格式中反序列化，排除了 Postcard 等许多其他格式。

## The Visitor trait

[`Visitor`] 是由 `Deserialize` 实例化并传递给 `Deserializer` 的。然后，`Deserializer` 会调用 `Visitor` 上的方法来构造所需类型。

这是一个 `Visitor` 示例，能够从各种类型中反序列化基本的 `i32`。

```rust
use std::fmt;

use serde::de::{self, Visitor};

# #[allow(dead_code)]
struct I32Visitor;

impl<'de> Visitor<'de> for I32Visitor {
    type Value = i32;

    fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
        formatter.write_str("an integer between -2^31 and 2^31")
    }

    fn visit_i8<E>(self, value: i8) -> Result<Self::Value, E>
    where
        E: de::Error,
    {
        Ok(i32::from(value))
    }

    fn visit_i32<E>(self, value: i32) -> Result<Self::Value, E>
    where
        E: de::Error,
    {
        Ok(value)
    }

    fn visit_i64<E>(self, value: i64) -> Result<Self::Value, E>
    where
        E: de::Error,
    {
        use std::i32;
        if value >= i64::from(i32::MIN) && value <= i64::from(i32::MAX) {
            Ok(value as i32)
        } else {
            Err(E::custom(format!("i32 out of range: {}", value)))
        }
    }

    // 其他方法类似：
    //   - visit_i16
    //   - visit_u8
    //   - visit_u16
    //   - visit_u32
    //   - visit_u64
}
#
# fn main() {}
```

`Visitor` trait 还有许多没有为`I32Visitor`实现的方法。如果调用这些方法，将返回[类型错误]。例如，`I32Visitor`没有实现`Visitor::visit_map`，因此尝试在输入包含映射时反序列化一个i32 是一个类型错误。

[类型错误]: https://docs.rs/serde/1/serde/de/trait.Error.html#method.invalid_type

## 驱动 Visitor

通过向给定的 `Deserializer` 传递一个 `Visitor` 来反序列化值。`Deserializer` 将根据输入数据之间调用 `Visitor` 的某个方法，这称为 “驱动” `Visitor`。

```rust
# use std::fmt;
#
# use serde::de::{Deserialize, Deserializer, Visitor};
#
# #[allow(non_camel_case_types)]
# struct i32;
# struct I32Visitor;
#
# impl<'de> Visitor<'de> for I32Visitor {
#     type Value = i32;
#
#     fn expecting(&self, _: &mut fmt::Formatter) -> fmt::Result {
#         unimplemented!()
#     }
# }
#
impl<'de> Deserialize<'de> for i32 {
    fn deserialize<D>(deserializer: D) -> Result<i32, D::Error>
    where
        D: Deserializer<'de>,
    {
        deserializer.deserialize_i32(I32Visitor)
    }
}
#
# fn main() {}
```

请注意，`Deserializer` 不一定会遵循类型提示，因此调用 `deserialize_i32`并不一定意味着 `Deserializer` 将调用 `I32Visitor::visit_i32`。例如，JSON 将所有有符号整数类型视为相同。JSON `Deserializer` 将对任何有符号整数调用 `visit_i64`，对任何无符号整数调用 `visit_u64`，即使提示不同的类型也是如此。

## 其他示例

- [反序列化一个 map](deserialize-map.md)
- [反序列化一个 struct](deserialize-struct.md)