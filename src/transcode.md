# 将一种格式转码为另一种格式

[`serde-transcode`](https://github.com/sfackler/serde-transcode) crate提供了一种功能，可以从任意Serde `Deserializer` 转码到任意Serde `Serializer`，而无需将整个输入收集到内存中作为中间形式。这提供了一种完全通用的方式，以内存高效的流式方式将任何自描述的 Serde 数据格式转换为任何其他 Serde 数据格式。

例如，您可以将一个 JSON 数据流转码为一个 CBOR 数据流，或者将未格式化的 JSON 转码为其漂亮打印的形式。

这个示例实现了Go的 `json.Compact` 函数的等效功能，该函数以流式方式从JSON字符串中移除无关的空格。

```rust
use std::io;

fn main() {
    // 具有大量空格的 JSON 输入。
    let input = r#"
      {
        "a boolean": true,
        "an array": [3, 2, 1]
      }
    "#;

    // JSON 反序列化器。您可以在这里使用任何 Serde Deserializer。
    let mut deserializer = serde_json::Deserializer::from_str(input);

    // 一个紧凑的 JSON 序列化器。您可以在这里使用任何 Serde Serializer。
    let mut serializer = serde_json::Serializer::new(io::stdout());

    // 将 `{"a boolean":true,"an array":[3,2,1]}` 打印到标准输出。
    // 该行适用于任何自描述的 Deserializer 和任何 Serializer。
    serde_transcode::transcode(&mut deserializer, &mut serializer).unwrap();
}
```
