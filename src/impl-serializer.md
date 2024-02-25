# 实现 Serializer

此页面提供了使用 Serde 实现 JSON 序列化器基本功能的实现。

[`Serializer`] trait 有很多方法，但此实现中的方法都不复杂。每个方法对应于 [Serde 数据模型] 的一种类型。序列化器负责将数据模型映射到输出表示，本例中为 JSON。

请参阅 `Serializer` trait 的 rustdoc，了解每个方法的用法示例。

[`Serializer`]: https://docs.rs/serde/1/serde/trait.Serializer.html
[Serde 数据模型]: data-model.md

<!-- !FILENAME src/ser.rs -->

```rust
# mod error {
#     pub use serde::de::value::Error;
#     pub type Result<T> = ::std::result::Result<T, Error>;
# }
#
use serde::{ser, Serialize};

use error::{Error, Result};

pub struct Serializer {
    // 此字符串开始为空，将随着序列化值的附加而被填充为 JSON。
    output: String,
}

// 按照约定，Serde 序列化器的公共 API 是一个或多个 `to_abc` 函数，例如 `to_string`、`to_bytes` 或 `to_writer`，取决于序列化器能够生成哪种 Rust 类型的输出。
//
// 此基本序列化器仅支持 `to_string`。
pub fn to_string<T>(value: &T) -> Result<String>
where
    T: Serialize,
{
    let mut serializer = Serializer {
        output: String::new(),
    };
    value.serialize(&mut serializer)?;
    Ok(serializer.output)
}

impl<'a> ser::Serializer for &'a mut Serializer {
    // 在成功序列化期间由此`Serializer`生成的输出类型。大多数生成文本或二进制输出的序列化器应设置 `Ok = ()` 并将其序列化到 `io::Write` 中或者在 `Serializer` 实例内部的缓冲区中，就像这里发生的那样。构建内存数据结构的序列化器可以通过使用 `Ok` 在数据结构周围传播数据结构来简化。
    type Ok = ();

    // 在序列化期间发生错误时的错误类型。
    type Error = Error;

    // 与序列化复合数据结构（如序列和映射）一起跟踪附加状态的相关类型。在这种情况下，除了已经存储在 Serializer 结构中的内容外，不需要其他状态。
    type SerializeSeq = Self;
    type SerializeTuple = Self;
    type SerializeTupleStruct = Self;
    type SerializeTupleVariant = Self;
    type SerializeMap = Self;
    type SerializeStruct = Self;
    type SerializeStructVariant = Self;

    // 接下来是简单的方法。以下 12 个方法中的每一个接收数据模型的原始类型之一，并通过将其附加到输出字符串中将其映射为 JSON。
    fn serialize_bool(self, v: bool) -> Result<()> {
        self.output += if v { "true" } else { "false" };
        Ok(())
    }

    // JSON 不区分不同大小的整数，因此所有有符号整数将被序列化为相同的值，所有无符号整数将被序列化为相同的值。其他格式，特别是紧凑的二进制格式，可能需要对不同大小进行独立处理。
    // JSON 不区分不同大小的整数，因此所有有符号整数将被序列化为相同的值，所有无符号整数将被序列化为相同的值。其他格式，特别是紧凑的二进制格式，可能需要对不同大小进行独立处理。
    fn serialize_i8(self, v: i8) -> Result<()> {
        self.serialize_i64(i64::from(v))
    }

    fn serialize_i16(self, v: i16) -> Result<()> {
        self.serialize_i64(i64::from(v))
    }

    fn serialize_i32(self, v: i32) -> Result<()> {
        self.serialize_i64(i64::from(v))
    }

    // 尽管效率并不是最高，但这只是示例代码。一个更高效的方法是使用 `itoa` crate。
    fn serialize_i64(self, v: i64) -> Result<()> {
        self.output += &v.to_string();
        Ok(())
    }

    fn serialize_u8(self, v: u8) -> Result<()> {
        self.serialize_u64(u64::from(v))
    }

    fn serialize_u16(self, v: u16) -> Result<()> {
        self.serialize_u64(u64::from(v))
    }

    fn serialize_u32(self, v: u32) -> Result<()> {
        self.serialize_u64(u64::from(v))
    }

    fn serialize_u64(self, v: u64) -> Result<()> {
        self.output += &v.to_string();
        Ok(())
    }

    fn serialize_f32(self, v: f32) -> Result<()> {
        self.serialize_f64(f64::from(v))
    }

    fn serialize_f64(self, v: f64) -> Result<()> {
        self.output += &v.to_string();
        Ok(())
    }

    // 将 char 序列化为单个字符的字符串。其他格式可能以不同方式表示此内容。
    fn serialize_char(self, v: char) -> Result<()> {
        self.serialize_str(&v.to_string())
    }

    // 仅适用于不需要转义序列的字符串，但你能理解这个方法。例如，如果输入字符串包含`"`字符，则它会生成无效的 JSON。
    fn serialize_str(self, v: &str) -> Result<()> {
        self.output += "\"";
        self.output += v;
        self.output += "\"";
        Ok(())
    }

    // 将字节数组序列化为字节数组。这里也可以使用 base64 字符串。二进制格式通常会更紧凑地表示字节数组。
    fn serialize_bytes(self, v: &[u8]) -> Result<()> {
        use serde::ser::SerializeSeq;
        let mut seq = self.serialize_seq(Some(v.len()))?;
        for byte in v {
            seq.serialize_element(byte)?;
        }
        seq.end()
    }

    // 缺少的可选项将被表示为 JSON 中的 `null`。
    fn serialize_none(self) -> Result<()> {
        self.serialize_unit()
    }

    // 存在的可选项将只表示为包含的值。请注意，这是一个丢失的表示。例如值 `Some(())` 和 `None` 都序列化为 `null`。不幸的是，这通常是人们在使用 JSON 时的预期行为。鼓励其他格式在可能的情况下更智能地处理。
    fn serialize_some<T>(self, value: &T) -> Result<()>
    where
        T: ?Sized + Serialize,
    {
        value.serialize(self)
    }

    // 在 Serde 中，单元表示一个不包含数据的匿名值。将其映射为 JSON 为 `null`。
    fn serialize_unit(self) -> Result<()> {
        self.output += "null";
        Ok(())
    }

    // 单元结构表示一个不包含数据的命名值。同样，由于没有数据，将其映射为 JSON 为 `null`。在大多数格式中不需要序列化名称。
    fn serialize_unit_struct(self, _name: &'static str) -> Result<()> {
        self.serialize_unit()
    }

    // 在序列化单元变体（或任何其他类型的变体）时，格式可以选择是按索引还是按名称跟踪。二进制格式通常使用变体的索引，人类可读格式通常使用名称。
    fn serialize_unit_variant(
        self,
        _name: &'static str,
        _variant_index: u32,
        variant: &'static str,
    ) -> Result<()> {
        self.serialize_str(variant)
    }

    // 与此处所做的相同，序列化器鼓励将新型结构视为包含的数据的不重要包装。
    fn serialize_newtype_struct<T>(
        self,
        _name: &'static str,
        value: &T,
    ) -> Result<()>
    where
        T: ?Sized + Serialize,
    {
        value.serialize(self)
    }

    // 请注意，新型变体（以及所有其他变体序列化方法）仅适用于“外部标记”枚举表示。
    //
    // 将其作为 JSON 中的外部标记形式序列化，例如 `{ NAME: VALUE }`。
    fn serialize_newtype_variant<T>(
        self,
        _name: &'static str,
        _variant_index: u32,
        variant: &'static str,
        value: &T,
    ) -> Result<>()
    where
        T: ?Sized + Serialize,
    {
        self.output += "{";
        variant.serialize(&mut *self)?;
        self.output += ":";
        value.serialize(&mut *self)?;
        self.output += "}";
        Ok(())
    }

    // 现在我们开始序列化复合类型。
    //
    // 序列开始，每个值以及结束是三个单独的方法调用。此方法仅负责序列化开始，在 JSON 中为 `[`。
    //
    // 序列的长度可能提前知道，也可能不知道。在 JSON 中这并没有区别，因为序列化形式中不明确表示长度。某些序列化器可能仅能支持预先知晓长度的序列。
    fn serialize_seq(self, _len: Option<usize>) -> Result<Self::SerializeSeq> {
        self.output += "[";
        Ok(self)
    }

    // 元组在 JSON 中看起来就像序列。某些格式可能能够更有效地表示元组，省略长度，因为元组意味着对应的 `Deserialize` 实现将无需查看序列化数据即可知道长度。
    fn serialize_tuple(self, len: usize) -> Result<Self::SerializeTuple> {
        self.serialize_seq(Some(len))
    }

    // 元组结构在 JSON 中看起来就像序列。
    fn serialize_tuple_struct(
        self,
        _name: &'static str,
        len: usize,
    ) -> Result<Self::SerializeTupleStruct> {
        self.serialize_seq(Some(len))
    }

    // 元组变体在 JSON 中表示为 `{ NAME: [DATA...] }`。同样，此方法仅负责外部标记表示。
    fn serialize_tuple_variant(
        self,
        _name: &'static str,
        _variant_index: u32,
        variant: &'static str,
        _len: usize,
    ) -> Result<Self::SerializeTupleVariant> {
        self.output += "{";
        variant.serialize(&mut *self)?;
        self.output += ":[";
        Ok(self)
    }

    // 映射在 JSON 中表示为 `{ K: V, K: V, ... }`。
    fn serialize_map(self, _len: Option<usize>) -> Result<Self::SerializeMap> {
        self.output += "{";
        Ok(self)
    }

    // 结构在 JSON 中看起来就像映射。特别是，JSON 要求我们序列化结构的字段名称。其他格式可能能够在序列化结构时省略字段名称，因为要求的 Deserialize 实现必须知道键是什么而不必查看序列化数据。
    fn serialize_struct(
        self,
        _name: &'static str,
        len: usize,
    ) -> Result<Self::SerializeStruct> {
        self.serialize_map(Some(len))
    }

    // 结构变体在 JSON 中表示为 `{ NAME: { K: V, ... } }`。这是外部标记的表示方式。
    fn serialize_struct_variant(
        self,
        _name: &'static str,
        _variant_index: u32,
        variant: &'static str,
        _len: usize,
    ) -> Result<Self::SerializeStructVariant> {
        self.output += "{";
        variant.serialize(&mut *self)?;
        self.output += ":{";
        Ok(self)
    }
}

// 接下来的 7 个 impl 处理复合类型（如序列和映射）的序列化。序列化此类类型是由 Serializer 方法开始的，并跟随零个或多个序列化单个元素和一个结束复合类型的调用。
//
// 此 impl 是 SerializeSeq，因此这些方法是在 Serializer 上调用`serialize_seq`之后调用的。
impl<'a> ser::SerializeSeq for &'a mut Serializer {
    // 必须匹配序列化器的 `Ok` 类型。
    type Ok = ();
    // 必须匹配序列化器的 `Error` 类型。
    type Error = Error;

    // 序列化序列的单个元素。
    fn serialize_element<T>(&mut self, value: &T) -> Result<()>
    where
        T: ?Sized + Serialize,
    {
        if !self.output.ends_with('[') {
            self.output += ",";
        }
        value.serialize(&mut **self)
    }

    // 关闭序列。
    fn end(self) -> Result<()> {
        self.output += "]";
        Ok(())
    }
}

// 元组同样如此。
impl<'a> ser::SerializeTuple for &'a mut Serializer {
    type Ok = ();
    type Error = Error;

    fn serialize_element<T>(&mut self, value: &T) -> Result<()>
    where
        T: ?Sized + Serialize,
    {
        if !self.output.ends_with('[') {
            self.output += ",";
        }
        value.serialize(&mut **self)
    }

    fn end(self) -> Result<()> {
        self.output += "]";
        Ok(())
    }
}

// 元组结构也是一样。
impl<'a> ser::SerializeTupleStruct for &'a mut Serializer {
    type Ok = ();
    type Error = Error;

    fn serialize_field<T>(&mut self, value: &T) -> Result<()>
    where
        T: ?Sized + Serialize,
    {
        if !self.output.ends_with('[') {
            self.output += ",";
        }
        value.serialize(&mut **self)
    }

    fn end(self) -> Result<()> {
        self.output += "]";
        Ok(())
    }
}

// 元组变体有些不同。请参考前面的`serialize_tuple_variant`方法：
//
//    self.output += "{";
//    variant.serialize(&mut *self)?;
//    self.output += ":[";
//
// 因此，此 impl 中的 `end` 方法负责同时关闭 `]` 和 `}`。
impl<'a> ser::SerializeTupleVariant for &'a mut Serializer {
    type Ok = ();
    type Error = Error;

    fn serialize_field<T>(&mut self, value: &T) -> Result<()>
    where
        T: ?Sized + Serialize,
    {
        if !self.output.ends_with('[') {
            self.output += ",";
        }
        value.serialize(&mut **self)
    }

    fn end(self) -> Result<()> {
        self.output += "]}";
        Ok(())
    }
}

// 一些 `Serialize` 类型无法同时在内存中保存键和值，因此 `SerializeMap` 实现需要支持单独支持`serialize_key`和`serialize_value`。
//
// `SerializeMap` trait 还有第三个可选方法。`serialize_entry` 方法允许序列化器针对同时可用的键和值进行优化。在 JSON 中不会有区别，因此 `serialize_entry` 的默认行为是合理的。
impl<'a> ser::SerializeMap for &'a mut Serializer {
    type Ok = ();
    type Error = Error;

    // Serde 数据模型允许映射键是任何可序列化类型。但 JSON 仅允许字符串键，因此以下实现将在键序列化为非字符串时生成无效的 JSON。
    //
    // 真正的 JSON 序列化器需要验证映射键是字符串。这可以通过使用一个不同的 Serializer 来序列化键（而不是 `&mut **self`）进行，让另一个 Serializer 只实现 `serialize_str` 并且在其他数据类型上返回错误来实现。
    fn serialize_key<T>(&mut self, key: &T) -> Result<()>
    where
        T: ?Sized + Serialize,
    {
        if !self.output.ends_with('{') {
            self.output += ",";
        }
        key.serialize(&mut **self)
    }

    // 在`serialize_key`方法的末尾打印冒号或在`serialize_value`的开头打印冒号都是没有区别的。在这种情况下，将冒号放在此处代码更简单一些。
    fn serialize_value<T>(&mut self, value: &T) -> Result<()>
    where
        T: ?Sized + Serialize,
    {
        self.output += ":";
        value.serialize(&mut **self)
    }

    fn end(self) -> Result<()> {
        self.output += "}";
        Ok(())
    }
}

// 结构类似于映射，其中键受限于是编译时常量字符串。
impl<'a> ser::SerializeStruct for &'a mut Serializer {
    type Ok = ();
    type Error = Error;

    fn serialize_field<T>(&mut self, key: &'static str, value: &T) -> Result<()>
    where
        T: ?Sized + Serialize,
    {
        if !self.output.ends_with('{') {
            self.output += ",";
        }
        key.serialize(&mut **self)?;
        self.output += ":";
        value.serialize(&mut **self)
    }

    fn end(self) -> Result<()> {
        self.output += "}";
        Ok(())
    }
}

// Similar to `SerializeTupleVariant`, here the `end` method is responsible for
// closing both of the curly braces opened by `serialize_struct_variant`.
impl<'a> ser::SerializeStructVariant for &'a mut Serializer {
    type Ok = ();
    type Error = Error;

    fn serialize_field<T>(&mut self, key: &'static str, value: &T) -> Result<()>
    where
        T: ?Sized + Serialize,
    {
        if !self.output.ends_with('{') {
            self.output += ",";
        }
        key.serialize(&mut **self)?;
        self.output += ":";
        value.serialize(&mut **self)
    }

    fn end(self) -> Result<()> {
        self.output += "}}";
        Ok(())
    }
}

////////////////////////////////////////////////////////////////////////////////

# macro_rules! not_actually_test {
#     ($(#[test] $test:item)+) => {
#         $($test)+
#     }
# }
#
# not_actually_test! {
#[test]
fn test_struct() {
    #[derive(Serialize)]
    struct Test {
        int: u32,
        seq: Vec<&'static str>,
    }

    let test = Test {
        int: 1,
        seq: vec!["a", "b"],
    };
    let expected = r#"{"int":1,"seq":["a","b"]}"#;
    assert_eq!(to_string(&test).unwrap(), expected);
}

#[test]
fn test_enum() {
    #[derive(Serialize)]
    enum E {
        Unit,
        Newtype(u32),
        Tuple(u32, u32),
        Struct { a: u32 },
    }

    let u = E::Unit;
    let expected = r#""Unit""#;
    assert_eq!(to_string(&u).unwrap(), expected);

    let n = E::Newtype(1);
    let expected = r#"{"Newtype":1}"#;
    assert_eq!(to_string(&n).unwrap(), expected);

    let t = E::Tuple(1, 2);
    let expected = r#"{"Tuple":[1,2]}"#;
    assert_eq!(to_string(&t).unwrap(), expected);

    let s = E::Struct { a: 1 };
    let expected = r#"{"Struct":{"a":1}}"#;
    assert_eq!(to_string(&s).unwrap(), expected);
}
# }
#
# fn main() {
#     test_struct();
#     test_enum();
# }
```
