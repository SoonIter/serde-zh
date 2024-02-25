<!-- <span style="float:right">
  [![GitHub]][repo]
  [![rustdoc]][docs]
  [![Latest Version]][crates.io]
</span> -->

[GitHub]: /img/github.svg
[repo]: https://github.com/serde-rs/serde
[rustdoc]: /img/rustdoc.svg
[docs]: https://docs.rs/serde
[Latest Version]: https://img.shields.io/crates/v/serde.svg?style=social
[crates.io]: https://crates.io/crates/serde 

# Serde

Serde 是一个高效且通用的序列化(***ser***ializing) 和 反序列化 (***de***serializing) Rust 数据结构的框架

Serde 生态由可序列化、反序列化的**数据结构(data structure)** 和 **数据格式(data format)** 组成. 
Serde 提供了使它们两个相互交互的抽象层, 允许使用任何数据格式对任何数据结构进行序列化和反序列化。

<iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/BI_bHCGRgMY" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

### 设计 Design 

与许多其他语言依赖运行时反射来序列化相反，
Serde 是建立在 Rust 强大的特征系统之上. 
一个可序列化和反序列化的数据结构是通过实现 Serde 的
`Serialize` 和 `Deserialize` traits（或者使用 Serde 的 derive attribute 来
在编译时自动生成实现. 
这避免了任何反射或运行时类型信息的开销. 事实上，在很多情况下，数据结构和数据格式之间的转化可以被 Rust 编译器完全优化，使 Serde 序列化在特定数据结构和数据格式时与手写 serializer 速度旗鼓相当。

### 数据格式 Data formats

以下是 Serde 社区中已实现的部分数据格式。

- [JSON], 被许多 HTTP API 使用的无处不在的 JavaScript 对象表示 (JavaScript Object Notation).
- [Postcard], 一个非标准且嵌入式系统友好的紧凑二进制格式.
- [CBOR], 简洁的二进制对象表示，专为 size 小的消息而设计，无需版本协商.
- [YAML], 一种自称为人类友好的配置语言，但不是标记语言.
- [MessagePack], 一种类似于紧凑 JSON 的高效二进制格式.
- [TOML], 使用的最小配置格式
- [Pickle], Python 世界中常见的格式.
- [RON], Rust 对象表示 (Rusty Object Notation).
- [BSON], MongoDB 使用的数据存储和网络传输格式.
- [Avro], Apache Hadoop 中使用的二进制格式，支持 schema definition.
- [JSON5], JSON 的超集，包括 ES5 的一些改进.
- [URL] query-string，采用 x-www-form-urlencoded 格式.
- [Starlark], Bazel 和 Buck 构建系统中用于描述构建目标的格式. *(仅支持 serialization)*
- [Envy], 一种将环境变量反序列化为 Rust struct 的方式。 *(仅支持 deserialization)*
- [Envy Store], 一种将 [AWS Parameter Store] 参数反序列化为 Rust struct 的方法. *(仅支持 deserialization)*
- [S-expressions], Lisp 语言家族使用的代码和数据的文本表示.
- [D-Bus] 的二进制有线格式 wire format.
- [FlexBuffers], Google FlatBuffers 零拷贝序列化格式的 schemaless 表亲.
- [Bencode], BitTorrent 协议中使用的简单二进制格式.
- [Token streams], 用于处理 Rust 过程宏 input。 *(仅支持 deserialization)*
- [DynamoDB Items], [rusoto_dynamodb] 用于和 DynamoDB 收发信息的数据格式
- [Hjson], 围绕人类阅读和编辑而设计的 JSON 语法扩展. *(仅支持 deserialization)*
- [CSV], 用逗号分隔表示表格的文件格式.

[JSON]: https://github.com/serde-rs/json
[Postcard]: https://github.com/jamesmunns/postcard
[CBOR]: https://github.com/enarx/ciborium
[YAML]: https://github.com/dtolnay/serde-yaml
[MessagePack]: https://github.com/3Hren/msgpack-rust
[TOML]: https://docs.rs/toml
[Pickle]: https://github.com/birkenfeld/serde-pickle
[RON]: https://github.com/ron-rs/ron
[BSON]: https://github.com/mongodb/bson-rust
[Avro]: https://docs.rs/apache-avro
[JSON5]: https://github.com/callum-oakley/json5-rs
[URL]: https://docs.rs/serde_qs
[Starlark]: https://github.com/dtolnay/serde-starlark
[Envy]: https://github.com/softprops/envy
[Envy Store]: https://github.com/softprops/envy-store
[Cargo]: http://doc.crates.io/manifest.html
[AWS Parameter Store]: https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html
[S-expressions]: https://github.com/rotty/lexpr-rs
[D-Bus]: https://docs.rs/zvariant
[FlexBuffers]: https://github.com/google/flatbuffers/tree/master/rust/flexbuffers
[Bencode]: https://github.com/P3KI/bendy
[Token streams]: https://github.com/oxidecomputer/serde_tokenstream
[DynamoDB Items]: https://docs.rs/serde_dynamo
[rusoto_dynamodb]: https://docs.rs/rusoto_dynamodb
[Hjson]: https://github.com/Canop/deser-hjson
[CSV]: https://docs.rs/csv

### 数据格式 Data structures

开箱即用下，Serde 能够以上述任何格式序列化和反序列化常见 Rust 数据类型。 例如： `String`, `&str`, `usize`, `Vec<T>`, `HashMap<K,V>` 都被支持。 另外， Serde 提供了一个派生宏(derive macro)来为您自己的程序中的 struct 生成序列化实现.

使用派生宏就像这样:

!PLAYGROUND 72755f28f99afc95e01d63174b28c1f5
```rust
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize, Debug)]
struct Point {
    x: i32,
    y: i32,
}

fn main() {
    let point = Point { x: 1, y: 2 };

    // Convert the Point to a JSON string.
    let serialized = serde_json::to_string(&point).unwrap();

    // Prints serialized = {"x":1,"y":2}
    println!("serialized = {}", serialized);

    // Convert the JSON string back to a Point.
    let deserialized: Point = serde_json::from_str(&serialized).unwrap();

    // Prints deserialized = Point { x: 1, y: 2 }
    println!("deserialized = {:?}", deserialized);
}
```
