# 理解 deserializer 的生命周期

[`Deserialize`] 和 [`Deserializer`] 两个 trait 都有一个名为 `'de` 的生命周期，一些其他与反序列化相关的 trait 也有类似的生命周期。

[`Deserialize`]: https://docs.rs/serde/1/serde/trait.Deserialize.html
[`Deserializer`]: https://docs.rs/serde/1/serde/trait.Deserializer.html

```rust
# use serde::Deserializer;
#
trait Deserialize<'de>: Sized {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>;
}
#
# fn main() {}
```

这个生命周期使得 Serde 能够在各种数据格式之间安全地执行高效的零拷贝反序列化，这在 Rust 以外的语言中是不可能或者非常不安全的。

```rust
# #![allow(dead_code)]
#
# use serde::Deserialize;
#
#[derive(Deserialize)]
struct User<'a> {
    id: u32,
    name: &'a str,
    screen_name: &'a str,
    location: &'a str,
}
#
# fn main() {}
```

零拷贝反序列化意味着将数据反序列化到一个数据结构中，例如上面的 `User` 结构体，该结构体从包含输入的字符串或字节数组中借用数据。这避免了为每个字段分配存储字符串的内存，然后将字符串数据从输入复制到新分配的字段中。Rust 保证输入数据在输出数据结构的作用域内仍然有效，这意味着当输出数据结构仍然引用输入数据时，不可能出现悬空指针错误。

## Trait bounds

有两种编写 `Deserialize` trait bounds 的主要方式，无论是在 impl 块中还是在函数或其他地方。

- **`<'de, T> where T: Deserialize<'de>`**

    这表示“T 可以从**某个**生命周期进行反序列化”。调用方决定该生命周期是什么。通常，当调用方还提供正在从中反序列化的数据时，例如在类似 [`serde_json::from_str`] 的函数中，此时输入数据也必须具有生命周期 `'de`，例如可以是 `&'de str`。

- **`<T> where T: DeserializeOwned`**

    这表示“T 可以从**任意**生命周期进行反序列化”。被调用方决定该生命周期。通常，这是因为正在从中反序列化的数据在函数返回之前将被丢弃，因此不能允许 T 借用该数据。例如，一个函数接受输入为 base64 编码数据，解码 base64，反序列化类型为 T 的值，然后丢弃 base64 解码的结果。另一个常见的使用情况是从 IO 流中进行反序列化的函数，比如 [`serde_json::from_reader`]。

    更准确地说，[`DeserializeOwned`] trait 等效于[更高阶的 trait bound] `for<'de> Deserialize<'de>`。唯一的区别是 `DeserializeOwned` 更直观。它表示 T 拥有所有会被反序列化的数据。

请注意，`<T> where T: Deserialize<'static>` 绝不是你想要的。同样 `Deserialize<'de> + 'static` 也不是你想要的。通常，将 `'static` 写在与 `Deserialize` 附近表明你走错了方向。请改用上述其中一种约束。

[`serde_json::from_str`]: https://docs.rs/serde_json/1/serde_json/fn.from_str.html
[`serde_json::from_reader`]: https://docs.rs/serde_json/1/serde_json/fn.from_reader.html
[更高阶的 trait bound]: https://doc.rust-lang.org/nomicon/hrtb.html

## Transient、borrowed 和 owned 数据

Serde 数据模型在反序列化过程中有三种 strings 和 byte arrays 的不同类型。它们对应于 [`Visitor`] trait 上的不同方法。

[`Visitor`]: https://docs.rs/serde/1/serde/de/trait.Visitor.html

- **Transient** — [`visit_str`] 接受一个 `&str`。
- **Borrowed** — [`visit_borrowed_str`] 接受一个 `&'de str`。
- **Owned** — [`visit_string`] 接受一个 `String`。

[`visit_str`]: https://docs.rs/serde/1/serde/de/trait.Visitor.html#method.visit_str
[`visit_borrowed_str`]: https://docs.rs/serde/1/serde/de/trait.Visitor.html#method.visit_borrowed_str
[`visit_string`]: https://docs.rs/serde/1/serde/de/trait.Visitor.html#method.visit_string

Transient 数据不能保证在传递给它的方法调用之后仍然有效。通常这就足够了，例如当使用 [`FromStr`] trait 从 Serde 字符串反序列化类似 IP 地址的内容时。当这不够时，数据可以通过调用 [`to_owned()`] 进行复制。反序列化器通常在从 IO 流中缓冲内存中的输入数据后传递给 `Visitor`，或者在处理转义序列时，生成的字符串没有以明文形式出现在输入中。

[`FromStr`]: https://doc.rust-lang.org/std/str/trait.FromStr.html
[`to_owned()`]: https://doc.rust-lang.org/std/borrow/trait.ToOwned.html

Borrowed 数据保证至少与 `Deserializer` 的 `'de` 生命周期参数具有相同的生命周期。并非所有反序列化器都支持提供借用数据。例如，从 IO 流中反序列化时不能借用任何数据。

Owned 数据保证在 [`Visitor`] 想要它存在的时间内保持有效。一些访问者受益于接收拥有所有已反序列化的 Serde 字符串数据的所有权。


## Deserialize&lt;'de&gt; 生命周期

这个生命周期记录了对该类型借用数据必须保持有效的限制。

该类型借用的每个数据的生命周期必须是其 `Deserialize` impl 的 `'de` 生命周期的约束。如果该类型从具有生命周期 `'a` 的数据中借用数据，则 `'de` 必须被限制为超过 `'a`。

```rust
# #![allow(dead_code)]
#
# trait Deserialize<'de> {}
#
struct S<'a, 'b, T> {
    a: &'a str,
    b: &'b str,
    bb: &'b str,
    t: T,
}

impl<'de: 'a + 'b, 'a, 'b, T> Deserialize<'de> for S<'a, 'b, T>
where
    T: Deserialize<'de>,
{
    /* ... */
}
#
# fn main() {}
```

如果该类型不从 `Deserializer` 借用任何数据，则 `'de` 生命周期上根本没有约束。这样的类型自动实现 [`DeserializeOwned`] trait。

[`DeserializeOwned`]: https://docs.rs/serde/1/serde/de/trait.DeserializeOwned.html

```rust
# #![allow(dead_code)]
#
# pub trait Deserialize<'de> {}
#
struct S {
    owned: String,
}

impl<'de> Deserialize<'de> for S {
    /* ... */
}
#
# fn main() {}
```

`'de` 生命周期 **不应该** 出现在应用 `Deserialize` impl 的类型中。

```diff
- // 不要这样做。迟早你会感到沮丧。
- impl<'de> Deserialize<'de> for Q<'de> {

+ // 而是这样。
+ impl<'de: 'a, 'a> Deserialize<'de> for Q<'a> {
```

## Deserializer&lt;'de&gt; 生命周期

这是可以从 `Deserializer` 借用数据的数据的生命周期。

```rust
# #![allow(dead_code)]
#
# pub trait Deserializer<'de> {}
#
struct MyDeserializer<'de> {
    input_data: &'de [u8],
    pos: usize,
}

impl<'de> Deserializer<'de> for MyDeserializer<'de> {
    /* ... */
}
#
# fn main() {}
```

如果 `Deserializer` 从未调用 [`visit_borrowed_str`] 或 [`visit_borrowed_bytes`]，`'de` 生命周期将成为一个没有约束的生命周期参数。

[`visit_borrowed_str`]: https://docs.rs/serde/1/serde/de/trait.Visitor.html#method.visit_borrowed_str
[`visit_borrowed_bytes`]: https://docs.rs/serde/1/serde/de/trait.Visitor.html#method.visit_borrowed_bytes

```rust
# #![allow(dead_code)]
#
# use std::io;
#
# pub trait Deserializer<'de> {}
#
struct MyDeserializer<R> {
    read: R,
}

impl<'de, R> Deserializer<'de> for MyDeserializer<R>
where
    R: io::Read,
{
    /* ... */
}
#
# fn main() {}
```

## 在派生的 impl 中借用数据

`&str` 和 `&[u8]` 类型的字段会被 Serde 隐式地从输入数据中借用。其他类型的字段可以通过使用 `#[serde(borrow)]` 属性选择性地进行借用。

```rust
# #![allow(dead_code)]
#
use serde::Deserialize;

use std::borrow::Cow;

#[derive(Deserialize)]
struct Inner<'a, 'b> {
    // &str 和 &[u8] 类型会被隐式借用。
    username: &'a str,

    // 其他类型必须显式借用。
    #[serde(borrow)]
    comment: Cow<'b, str>,
}

#[derive(Deserialize)]
struct Outer<'a, 'b, 'c> {
    owned: String,

    #[serde(borrow)]
    inner: Inner<'a, 'b>,

    // 此字段永不被借用。
    not_borrowed: Cow<'c, str>,
}
#
# fn main() {}
```

此属性通过在生成的 `Deserialize` impl 的 `'de` 生命周期上放置约束来工作。例如，上面定义的 `Outer` 结构的 impl 如下所示：

```rust
# #![allow(dead_code)]
#
# use std::borrow::Cow;
#
# trait Deserialize<'de> {}
#
# struct Inner<'a, 'b> {
#     username: &'a str,
#     comment: Cow<'b, str>,
# }
#
# struct Outer<'a, 'b, 'c> {
#     owned: String,
#     inner: Inner<'a, 'b>,
#     not_borrowed: Cow<'c, str>,
# }
#
// Lifetimes 'a 和 'b 被借用，'c 没有。
impl<'de: 'a + 'b, 'a, 'b, 'c> Deserialize<'de> for Outer<'a, 'b, 'c> {
    /* ... */
}
#
# fn main() {}
```

该属性可明确指定借用哪些生命周期。

```rust
# #![allow(dead_code)]
#
# use serde::Deserialize;
#
use std::marker::PhantomData;

// 这个结构体借用前两个生命周期但不借用第三个。
#[derive(Deserialize)]
struct Three<'a, 'b, 'c> {
    a: &'a str,
    b: &'b str,
    c: PhantomData<&'c str>,
}

#[derive(Deserialize)]
struct Example<'a, 'b, 'c> {
    // 仅借用 'a 和 'b，不借用 'c。
    #[serde(borrow = "'a + 'b")]
    three: Three<'a, 'b, 'c>,
}
#
# fn main() {}
```
