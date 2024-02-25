# 约定(Conventions)

按照惯例，一个 Serde 数据格式的 crate 在根模块中应该提供以下内容或从根模块重新导出：

- 一个错误类型，用于序列化和反序列化。
- 一个结果类型定义，等同于 std::result::Result&lt;T, Error&gt;。
- 一个实现了 serde::Serializer 的 Serializer 类型。
- 一个实现了 serde::Deserializer 的 Deserializer 类型。
- 一个或多个 to_abc 函数，取决于该格式支持序列化成什么类型。例如，to_string 返回一个字符串，to_bytes 返回一个 Vec&lt;u8&gt;，或者 to_writer 写入一个 [`io::Write`]。
- 一个或多个 from_xyz 函数，取决于该格式支持从什么类型反序列化。例如，from_str 接受一个 &str，from_bytes 接受一个 &[u8]，或者 from_reader 接受一个 [`io::Read`]。

另外，如果提供了超出 Serializer 和 Deserializer 之外的序列化或反序列化特定 API，数据格式应该将这些内容公开在顶层的 `ser` 和 `de` 模块下。例如，serde_json 提供了一个可插拔的 pretty-printer trait，例如[`serde_json::ser::Formatter`]。

[`io::Write`]: https://doc.rust-lang.org/std/io/trait.Write.html
[`io::Read`]: https://doc.rust-lang.org/std/io/trait.Read.html
[`serde_json::ser::Formatter`]: https://docs.rs/serde_json/1/serde_json/ser/trait.Formatter.html

一个基本的数据格式开始如下。这三个模块将在接下来的页面中更详细地讨论。

!FILENAME src/lib.rs
```rust
# macro_rules! modules {
#     (mod de) => {
#         mod de {
#             pub fn from_str() {}
#             pub type Deserializer = ();
#         }
#     };
#     (mod error) => {
#         mod error {
#             pub type Error = ();
#             pub type Result = ();
#         }
#     };
#     (mod ser) => {
#         mod ser {
#             pub fn to_string() {}
#             pub type Serializer = ();
#         }
#     };
#     ($(mod $n:ident;)+) => {
#         $(
#             modules!(mod $n);
#         )+
#     };
# }
#
# modules! {
mod de;
mod error;
mod ser;
# }

pub use de::{from_str, Deserializer};
pub use error::{Error, Result};
pub use ser::{to_string, Serializer};
#
# fn main() {}
```
