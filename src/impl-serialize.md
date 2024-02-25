# 实现 Serialize

[`Serialize`] trait 如下所示：

[`Serialize`]: https://docs.rs/serde/1/serde/ser/trait.Serialize.html

```rust
# use serde::Serializer;
#
pub trait Serialize {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer;
}
#
# fn main() {}
```

这个方法的作用是取出你的类型 (`&self`)，通过在给定的 [`Serializer`] 上调用恰当的一个方法来映射它到 [Serde 数据模型]。

[Serde 数据模型]: data-model.md
[`Serializer`]: https://docs.rs/serde/1/serde/ser/trait.Serializer.html

在大多数情况下，Serde的[派生]能够为你的 crate 中定义的结构体和枚举生成适当的 `Serialize`实现。如果你需要自定义某种类型的序列化行为，而派生不支持，你可以自己实现 `Serialize`。

[派生]: derive.md

## 序列化基本类型

作为最简单的示例，这里是内置的 `i32` 的 `Serialize` 实现。

```rust
# use std::os::raw::c_int as ActualI32;
#
# use serde::{Serialize, Serializer};
#
# #[allow(dead_code, non_camel_case_types)]
# struct i32;
#
# trait Serialize2 {
#     fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
#     where
#         S: Serializer;
# }
#
impl Serialize for i32 {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
#         impl Serialize2 for ActualI32 {
#             fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
#             where
#                 S: Serializer,
#             {
        serializer.serialize_i32(*self)
#             }
#         }
#
#         _ = serializer;
#         unimplemented!()
    }
}
#
# fn main() {}
```

Serde 为所有 Rust 的 [基本类型] 提供了这样的实现，因此你无需自己实现它们，但是 `serialize_i32` 和类似方法可能在你的类型需要以原始形式表示时很有用。例如，你可以 [将类似 C 的 enum 序列化为基本类型的数字]。

[基本类型]: https://doc.rust-lang.org/book/primitive-types.html
[将类似 C 的 enum 序列化为基本类型的数字]: https://serde.rs/enum-number.html

## 序列化 sequence 或 map

复合类型遵循初始化(init)，元素(elements)，结束(end)的三步过程。

```rust
# use std::marker::PhantomData;
#
# struct Vec<T>(PhantomData<T>);
#
# impl<T> Vec<T> {
#     fn len(&self) -> usize {
#         unimplemented!()
#     }
# }
#
# impl<'a, T> IntoIterator for &'a Vec<T> {
#     type Item = &'a T;
#     type IntoIter = Box<dyn Iterator<Item = &'a T>>;
#
#     fn into_iter(self) -> Self::IntoIter {
#         unimplemented!()
#     }
# }
#
# struct MyMap<K, V>(PhantomData<K>, PhantomData<V>);
#
# impl<K, V> MyMap<K, V> {
#     fn len(&self) -> usize {
#         unimplemented!()
#     }
# }
#
# impl<'a, K, V> IntoIterator for &'a MyMap<K, V> {
#     type Item = (&'a K, &'a V);
#     type IntoIter = Box<dyn Iterator<Item = (&'a K, &'a V)>>;
#
#     fn into_iter(self) -> Self::IntoIter {
#         unimplemented!()
#     }
# }
#
use serde::ser::{Serialize, Serializer, SerializeSeq, SerializeMap};

impl<T> Serialize for Vec<T>
where
    T: Serialize,
{
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut seq = serializer.serialize_seq(Some(self.len()))?;
        for e in self {
            seq.serialize_element(e)?;
        }
        seq.end()
    }
}

impl<K, V> Serialize for MyMap<K, V>
where
    K: Serialize,
    V: Serialize,
{
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut map = serializer.serialize_map(Some(self.len()))?;
        for (k, v) in self {
            map.serialize_entry(k, v)?;
        }
        map.end()
    }
}
#
# fn main() {}
```

## 序列化 tuple

`serialize_tuple` 方法与 `serialize_seq` 非常相似。Serde 所做的区别是 `serialize_tuple` 适用于序列，其长度不需要序列化，因为在反序列化时会知道长度。通常的示例是 Rust 的 [tuples] 和 [arrays]。在非自描述格式中，`Vec<T>` 需要以其长度序列化，以便能够将 `Vec<T>` 再次反序列化。但是 `[T; 16]` 可以使用 `serialize_tuple` 进行序列化，因为长度将在反序列化时知道，而无需查看序列化的 bytes。

[tuples]: https://doc.rust-lang.org/std/primitive.tuple.html
[arrays]: https://doc.rust-lang.org/std/primitive.array.html

## 序列化 struct

Serde 区分四种类型的结构体。[普通结构体] 和 [元组结构体] 遵循初始化，元素，结束的三步过程，就像 sequence 或 map 一样。 [新类型结构体] 和 [单元结构体] 更像基本类型。

[普通结构体]: https://doc.rust-lang.org/book/structs.html
[元组结构体]: https://doc.rust-lang.org/book/structs.html#tuple-structs
[新类型结构体]: https://doc.rust-lang.org/book/structs.html#tuple-structs
[单元结构体]: https://doc.rust-lang.org/book/structs.html#unit-like-structs

```rust
# #![allow(dead_code)]
#
// 一个普通结构体。使用三步过程：
//   1. serialize_struct
//   2. serialize_field
//   3. end
struct Color {
    r: u8,
    g: u8,
    b: u8,
}

// 一个元组结构体。使用三步过程：
//   1. serialize_tuple_struct
//   2. serialize_field
//   3. end
struct Point2D(f64, f64);

// 一个新类型结构体。使用 serialize_newtype_struct。
struct Inches(u64);

// 一个单元结构体。使用 serialize_unit_struct。
struct Instance;
#
# fn main() {}
```

在某些格式中，包括 JSON，struct 和 map 可能看起来相似。Serde 的区别在于 struct 具有在编译时为常量的字符串键，并且这些键在不查看序列化数据的情况下是已知的。这个条件使得某些数据格式能够比 map 更高效和紧凑地处理 struct。

数据格式鼓励将新类型结构体视为内部值的不重要的外壳，只序列化内部值。例如，参见[JSON 对新类型结构体的处理]。

[JSON 对新类型结构体的处理]: json.md

```rust
# #![allow(dead_code)]
#
use serde::ser::{Serialize, Serializer, SerializeStruct};

struct Color {
    r: u8,
    g: u8,
    b: u8,
}

impl Serialize for Color {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        // 3 是结构体中字段的数量。
        let mut state = serializer.serialize_struct("Color", 3)?;
        state.serialize_field("r", &self.r)?;
        state.serialize_field("g", &self.g)?;
        state.serialize_field("b", &self.b)?;
        state.end()
    }
}
#
# fn main() {}
```

## 序列化 enum

序列化 enum variants 与序列化 structs 非常相似。

```rust
# #[allow(dead_code)]
enum E {
    // 使用三步过程：
    //   1. serialize_struct_variant
    //   2. serialize_field
    //   3. end
    Color { r: u8, g: u8, b: u8 },

    // 使用三步过程：
    //   1. serialize_tuple_variant
    //   2. serialize_field
    //   3. end
    Point2D(f64, f64),

    // 使用 serialize_newtype_variant。
    Inches(u64),

    // 使用 serialize_unit_variant。
    Instance,
}
#
# fn main() {}
```

## 其他特殊情况

有两个更特殊的情况，属于 Serializer trait 的一部分。

有一个方法 `serialize_bytes`，用于序列化 `&[u8]`。有些格式将 bytes 视为 seq，但有些格式能够更紧凑地序列化 bytes。目前，Serde 在 `Serialize` 实现中不使用 `serialize_bytes` 用于 `&[u8]` 或 `Vec<u8>`，但一旦[specialization] 在稳定的 Rust 中出现，我们将开始使用它。目前可以使用 [`serde_bytes`] crate 来使得能够通过 `serialize_bytes` 高效处理 `&[u8]` 和 `Vec<u8>`。

[specialization]: https://github.com/rust-lang/rust/issues/31844
[`serde_bytes`]: https://docs.rs/serde_bytes

最后，`serialize_some` 和 `serialize_none` 对应于 `Option::Some` 和 `Option::None`。用户对 `Option` 枚举的期望通常与其他枚举不同。Serde JSON 将 `Option::None` 序列化为 `null`，将 `Option::Some` 仅序列化为包含的值。
