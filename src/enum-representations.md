# 枚举表示

考虑以下枚举类型:

```rust
# use serde::{Serialize, Deserialize};
#
# type Params = ();
# type Value = ();
#
#[derive(Serialize, Deserialize)]
enum Message {
    Request { id: String, method: String, params: Params },
    Response { id: String, result: Value },
}
#
# fn main() {}
```

## 外部标记(Externally tagged)

在 Serde 中，此枚举的默认表示称为外部标记的枚举表示。用 JSON 语法书写，看起来像:

```json
{"Request": {"id": "...", "method": "...", "params": {...}}}
```

外部标记表示的特点是能够在开始解析变体内容之前知道我们正在处理哪种变体。这个属性使得它能够适用于广泛的文本和二进制格式。`Serializer::serialize_*_variant` 和 `Deserializer::deserialize_enum` 方法使用外部标记表示。

此表示可以处理任何类型的变体: 类似上面的结构变体、元组变体、新类型变体和单元变体。

在 JSON 和其他自描述格式中，外部标记的表示通常不太适合可读性。Serde提供了属性来选择其他三种可能的表示。

## 内部标记(Internally tagged)

```rust
# use serde::{Serialize, Deserialize};
#
# type Params = ();
# type Value = ();
#
#[derive(Serialize, Deserialize)]
#[serde(tag = "type")]
enum Message {
    Request { id: String, method: String, params: Params },
    Response { id: String, result: Value },
}
#
# fn main() {}
```

用 JSON 语法书写，内部标记表示如下:

```json
{"type": "Request", "id": "...", "method": "...", "params": {...}}
```

用于标识我们正在处理哪种变体的标记现在在内容内部，与变体的任何其他字段相邻。这种表示在 Java 库中很常见。

这种表示适用于结构变体、包含结构或映射的新类型变体和单元变体，但并不适用于包含元组变体的枚举。在包含元组变体的枚举上使用 `#[serde(tag = "...")]` 属性是在编译时错误。

## 相邻标记(Adjacently tagged)

```rust
# use serde::{Serialize, Deserialize};
#
# type Inline = ();
#
#[derive(Serialize, Deserialize)]
#[serde(tag = "t", content = "c")]
enum Block {
    Para(Vec<Inline>),
    Str(String),
}
#
# fn main() {}
```

这种表示在 Haskell 世界中很常见。用 JSON 语法书写:

```json
{"t": "Para", "c": [{...}, {...}]}
{"t": "Str", "c": "the string"}
```

标记和内容是作为同一对象中的两个字段相邻的。

## 无标记(Untagged)

```rust
# use serde::{Serialize, Deserialize};
#
# type Params = ();
# type Value = ();
#
#[derive(Serialize, Deserialize)]
#[serde(untagged)]
enum Message {
    Request { id: String, method: String, params: Params },
    Response { id: String, result: Value },
}
#
# fn main() {}
```

用 JSON 语法书写，无标记表示如下:

```json
{"id": "...", "method": "...", "params": {...}}
```

没有显式的标记表明数据包含哪种变体。Serde 会尝试按顺序将数据与每个变体进行匹配，第一个成功反序列化的变体将被返回。

作为另一个无标记枚举的例子，此枚举可以从整数或两个字符串的数组反序列化:

```rust
# use serde::{Serialize, Deserialize};
#
#[derive(Serialize, Deserialize)]
#[serde(untagged)]
enum Data {
    Integer(u64),
    Pair(String, String),
}
#
# fn main() {}
```
