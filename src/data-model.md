# Serde 数据模型(data model)

Serde 数据模型是数据结构(data structure)和数据格式(data format)交互的 API。您可以将其视为 Serde 的类型系统。

在代码中，Serde 数据模型的序列化部分由 [`Serializer`] trait 定义，反序列化部分由[`Deserializer`] trait 定义。这是一种将每个Rust数据结构映射到 29 种可能类型之一的方式。`Serializer` trait 的每个方法对应数据模型的一种类型。

当将数据结构序列化为某种格式时，数据结构的 [`Serialize`] 实现负责通过调用 `Serializer` 的某一方法将数据结构映射为 Serde 数据模型，而数据格式的 `Serializer` 实现负责将Serde数据模型映射为预期的输出表示。

当从某种格式反序列化数据结构时，数据结构的 [`Deserialize`] 实现负责通过向 `Deserializer` 传递可接收数据模型各种类型的 [`Visitor`] 来将数据结构映射为 Serde 数据模型，而数据格式的 `Deserializer` 实现负责通过调用 `Visitor` 方法之一将输入数据映射为 Serde 数据模型。

[`Serializer`]: https://docs.rs/serde/1/serde/trait.Serializer.html
[`Deserializer`]: https://docs.rs/serde/1/serde/trait.Deserializer.html
[`Serialize`]: https://docs.rs/serde/1/serde/trait.Serialize.html
[`Deserialize`]: https://docs.rs/serde/1/serde/trait.Deserialize.html
[`Visitor`]: https://docs.rs/serde/1/serde/de/trait.Visitor.html

## 类型

Serde 数据模型是 Rust 类型系统的简化形式。它包括以下29种类型：

- **14 种基本类型**
  - bool
  - i8, i16, i32, i64, i128
  - u8, u16, u32, u64, u128
  - f32, f64
  - char
- **string**
  - 带有长度且没有空终止符的 UTF-8 bytes。可能包含 0-bytes。
  - 在序列化时，所有字符串都是平等处理的。在反序列化时，有三种字符串的类型：瞬态（transient）、所有权（owned）和借用（borrowed）。这种区别在[理解反序列化生命周期]中有解释，是 Serde 实现高效零拷贝反序列化的关键方式。
- **byte array** - [u8]
  - 类似于字符串，在反序列化时字节数组可以是瞬态、所有权或借用。
- **option**
  - 可能为 none 或 some。
- **unit**
  - Rust 中的 `()` 类型。它表示一个不包含任何数据的匿名值。
- **unit_struct**
  - 例如 `struct Unit` 或 `PhantomData<T>`。它表示包含不包含任何数据的命名值。
- **unit_variant**
  - 例如 `enum E { A, B }` 中的`E::A`和`E::B`。
- **newtype_struct**
  - 例如 `struct Millimeters(u8)`。
- **newtype_variant**
  - 例如 `enum E { N(u8) }` 中的 `E::N`。
- **seq**
  - 一个大小可变的**异构**值序列，例如 `Vec<T>` 或 `HashSet<T>`。在序列化时，在迭代所有数据之前可能无法确定长度。在反序列化时，长度通过查看序列化数据确定。请注意，类似于 `vec![Value::Bool(true), Value::Char('c')]` 的同构 Rust 集合可能序列化为异构 Serde 序列，这种情况包含一个 Serde bool 后跟一个 Serde char。
- **tuple**
  - 静态大小的异构值序列，在不查看序列化数据的情况下反序列化时将知道长度，例如 `(u8,)` 或 `(String, u64, Vec<T>)`或 `[u64; 10]`。
- **tuple_struct**
  - 一个命名元组，例如 `struct Rgb(u8, u8, u8)`。
- **tuple_variant**
  - 例如 `enum E { T(u8, u8) }` 中的 `E::T`。
- **map**
  - 可变大小的异构键值对，例如 `BTreeMap<K, V>`。在序列化时，在迭代所有 entries 之前可能无法确定长度。在反序列化时，长度通过查看序列化数据确定。
- **struct**
  - 静态大小的异构键值对，其中键是编译时的常量字符串，在不查看序列化数据的情况下反序列化时将知道，例如 `struct S { r: u8, g: u8, b: u8 }`。
- **struct_variant**
  - 例如 `enum E { S { r: u8, g: u8, b: u8 } }` 中的`E::S`。

[理解反序列化生命周期]: lifetimes.md

## 映射到数据模型

对于大多数 Rust 类型，它们映射到 Serde 数据模型是直接的。例如，Rust 的 `bool` 类型对应于 Serde 的 bool 类型。Rust 的元组结构体 `Rgb(u8, u8, u8)` 对应于Serde的元组结构体类型。

但这些映射无需是直接的。[`Serialize`] 和[`Deserialize`] traits 可以执行适用情况下的 *任何* Rust类型和Serde数据模型之间的映射。

举个例子，考虑Rust的 [`std::ffi::OsString`] 类型。此类型表示平台本地字符串。在Unix系统上，它们是任意非零字节，在 Windows 系统上，它们是任意非零16位值。将 `OsString` 映射到 Serde 数据模型时，似乎自然的方式可能是选用以下一种类型：

- 作为Serde的 **string**。不幸的是，序列化会很脆弱，因为 `OsString` 不能保证可表示为UTF-8，反序列化会很脆弱，因为 Serde 字符串允许包含 0 字节。
- 作为Serde的 **byte array**。这样可以解决使用字符串时的所有问题，但现在如果在 Unix 上序列化 `OsString`，然后在 Windows 上反序列化，最终得到的是[错误的字符串]。

相反，`OsString`的`Serialize`和`Deserialize`实现将`OsString`映射为Serde数据模型， treating `OsString` as a Serde **enum**。实际上，它的工作方式就像`OsString`被定义为以下类型，即使这与任何单个平台上的定义不匹配。

```rust
# #![allow(dead_code)]
#
enum OsString {
    Unix(Vec<u8>),
    Windows(Vec<u16>),
    // 和其他平台
}
#
# fn main() {}
```

在 Serde 数据模型中映射的灵活性是深远而强大的。在实现`Serialize` 和 `Deserialize` 时，请注意可能使最直观的映射不是最佳选择的更广泛的类型上下文。

[`std::ffi::OsString`]: https://doc.rust-lang.org/std/ffi/struct.OsString.html
[错误的字符串]: https://www.joelonsoftware.com/2003/10/08/the-absolute-minimum-every-software-developer-absolutely-positively-must-know-about-unicode-and-character-sets-no-excuses/