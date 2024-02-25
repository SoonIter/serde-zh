# 错误处理

在序列化期间，[`Serialize`] trait 将 Rust 数据结构映射到 Serde 的[data model]，而 [`Serializer`] trait 将 data model 映射到输出格式。在反序列化期间，[`Deserializer`] 将输入数据映射到 Serde 的 data model，并且 [`Deserialize`] 和 [`Visitor`] traits 将 data model 映射到最终的数据结构。在这些步骤中的任何一个都有可能失败。

- `Serialize` 可能会失败，例如当序列化 `Mutex<T>` 时，mutex 恰好被 poisoned 了。
- `Serializer` 可能会失败，例如 Serde 数据模型允许具有非字符串键的映射，但 JSON 不允许。
- `Deserializer` 可能会失败，特别是如果输入数据在语法上无效。
- `Deserialize` 可能会失败，通常是因为输入与正在反序列化的值的类型不匹配。

在 Serde 中，`Serializer` 和 `Deserializer` 中的错误处理方式与任何其他 Rust 库中的方式一样。该 crate 定义了一个错误类型，公共函数返回带有该错误类型的 Result，并且有各种可能的失败模式的变体。

对于由库处理的 `Serialize` 和 `Deserialize` 中的错误，数据结构构建在 [`ser::Error`] 和 [`de::Error`] traits 周围。这些 traits 允许数据格式为其错误类型暴露构造函数，以便数据结构在各种情况下使用它们。

[`Deserialize`]: https://docs.rs/serde/1/serde/trait.Deserialize.html
[`Deserializer`]: https://docs.rs/serde/1/serde/trait.Deserializer.html
[`Serialize`]: https://docs.rs/serde/1/serde/trait.Serialize.html
[`Serializer`]: https://docs.rs/serde/1/serde/ser/trait.Serializer.html
[`Visitor`]: https://docs.rs/serde/1/serde/de/trait.Visitor.html
[`de::Error`]: https://docs.rs/serde/1/serde/de/trait.Error.html
[`ser::Error`]: https://docs.rs/serde/1/serde/ser/trait.Error.html
[data model]: data-model.md

<!-- !FILENAME src/error.rs -->
```rust
# macro_rules! ignore {
#     ($($tt:tt)*) => {}
# }
#
# ignore! {
use std;
# }
use std::fmt::{self, Display};

use serde::{de, ser};

pub type Result<T> = std::result::Result<T, Error>;

// This is a bare-bones implementation. A real library would provide additional
// information in its error type, for example the line and column at which the
// error occurred, the byte offset into the input, or the current key being
// processed.
#[derive(Debug)]
pub enum Error {
    // 通过 `ser::Error` 和 `de::Error` traits 可以由数据结构创建的一个或多个变体。例如，对于 Mutex<T> 的 Serialize 实现可能会返回一个错误，因为 mutex 被 poisoned，或者对于结构体的 Deserialize 实现可能会因为一个必需的字段丢失而返回错误。
    Message(String),

    // 通过 Serializer 和 Deserializer 直接创建的一个或多个变体，无需经过`ser::Error` 和 `de::Error`。这些特定于格式，在这种情况下是 JSON。
    Eof,
    Syntax,
    ExpectedBoolean,
    ExpectedInteger,
    ExpectedString,
    ExpectedNull,
    ExpectedArray,
    ExpectedArrayComma,
    ExpectedArrayEnd,
    ExpectedMap,
    ExpectedMapColon,
    ExpectedMapComma,
    ExpectedMapEnd,
    ExpectedEnum,
    TrailingCharacters,
}

impl ser::Error for Error {
    fn custom<T: Display>(msg: T) -> Self {
        Error::Message(msg.to_string())
    }
}

impl de::Error for Error {
    fn custom<T: Display>(msg: T) -> Self {
        Error::Message(msg.to_string())
    }
}

impl Display for Error {
    fn fmt(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Error::Message(msg) => formatter.write_str(msg),
            Error::Eof => formatter.write_str("unexpected end of input"),
            /* and so forth */
#             _ => unimplemented!(),
        }
    }
}

impl std::error::Error for Error {}
#
# fn main() {}
```
