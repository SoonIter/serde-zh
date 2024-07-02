# 示例

**[JSON 中的结构体和枚举](json.md)**: 由[`serde_json`](https://github.com/serde-rs/json)选择的结构体和枚举表示形式。鼓励其他易读的数据格式在可能的情况下采用类似的方法。

**[枚举表示方式](enum-representations.md)**: 在自描述格式中表示枚举的外部标记、内部标记、相邻标记和无标记方式。

**[字段的默认值](attr-default.md)**: `#[serde(default)]`属性的一些示例。

**[手写通用类型边界](attr-bound.md)**: Serde 的衍生推断出错通用类型边界的一些不寻常情形。可以使用`#[serde(bound)]`属性手动替换 impl 边界。

**[自定义映射类型的反序列化](deserialize-map.md)**: 解释反序列化映射涉及的每个步骤。

**[无需缓冲区 (Buffering) 的流式数组](stream-array.md)**: 在不一次性保留整个数组在内存中的情况下反序列化整数数组的最大值。这种方法可以适应各种需要在反序列化时处理数据而不是之后处理数据的情况。

**[将枚举作为数字序列化](enum-number.md)**: 为类似 C 的枚举实现`Serialize`和`Deserialize`的宏，以在所有数据格式中表示它为`u64`。

**[将字段重命名为 camelCase](attr-rename.md)**: `#[serde(rename)]`属性的一个常见应用。

**[跳过序列化字段](attr-skip-serializing.md)**: `#[serde(skip_serializing)]`和`#[serde(skip_serializing_if)]`属性的一些示例。

**[为远程库派生](remote-derive.md)**: 为别人的库中的类型派生 `Serialize` 和 `Deserialize` 实现。

**[手动反序列化结构体](deserialize-struct.md)**: 一个简单结构体由 derive 生成的 `Deserialize` 实现的长表格形式。

**[丢弃数据](ignored-any.md)**: 使用 `IgnoredAny` 高效地丢弃 Deserializer 中的数据。

**[将一种格式转码为另一种](transcode.md)**: 使用[serde-transcode](https://github.com/sfackler/serde-transcode)库将输入流从一种格式转换为另一种格式。

**[反序列化字符串或结构体](string-or-struct.md)**: [`docker-compose.yml`](https://docs.docker.com/compose/compose-file/#/build)配置文件有一个"build"键，可以是字符串或结构体。

**[转换错误类型](convert-error.md)**: 使用`Error::custom`将来自某种格式的 Serde 错误映射成为其他格式的 Serde 错误。

**[自定义格式的日期](custom-date-format.md)**: 处理用自定义字符串表示的[`chrono`](https://github.com/chronotope/chrono) `DateTime`。
