# 容器属性(Container attributes)

- ##### `#[serde(rename = "name")]` {#rename}

  使用指定的名称而不是 Rust 中的名称对此结构体或枚举进行序列化和反序列化。

  允许在序列化和反序列化中指定独立的名称：

  - `#[serde(rename(serialize = "ser_name"))]`
  - `#[serde(rename(deserialize = "de_name"))]`
  - `#[serde(rename(serialize = "ser_name", deserialize = "de_name"))]`

- ##### `#[serde(rename_all = "...")]` {#rename_all}

  根据给定的大小写规范来重命名所有字段（如果是 Struct）或变体（如果是 Enum）。可能的取值为`"lowercase"`、`"UPPERCASE"`、`"PascalCase"`、`"camelCase"`、`"snake_case"`、`"SCREAMING_SNAKE_CASE"`、`"kebab-case"`、`"SCREAMING-KEBAB-CASE"`。

  允许在序列化和反序列化中指定独立的大小写规范：

  - `#[serde(rename_all(serialize = "..."))]`
  - `#[serde(rename_all(deserialize = "..."))]`
  - `#[serde(rename_all(serialize = "...", deserialize = "..."))]`

- ##### `#[serde(rename_all_fields = "...")]` {#rename_all_fields}

  根据给定的大小写规范，在 enum 的每个 struct variant 上应用 `rename_all`。可能的取值为 `"lowercase"`、`"UPPERCASE"`、`"PascalCase"`、`"camelCase"`、`"snake_case"`、`"SCREAMING_SNAKE_CASE"`、`"kebab-case"`、`"SCREAMING-KEBAB-CASE"`。

  允许在序列化和反序列化中指定独立的大小写规范：

  - `#[serde(rename_all_fields(serialize = "..."))]`
  - `#[serde(rename_all_fields(deserialize = "..."))]`
  - `#[serde(rename_all_fields(serialize = "...", deserialize = "..."))]`

- ##### `#[serde(deny_unknown_fields)]` {#deny_unknown_fields}

  在反序列化时，遇到未知字段时始终报错。如果没有这个属性，默认情况下，对于像 JSON 这样的自描述格式，未知字段会被忽略。

  *注意:* 此属性不支持与[`flatten`]一起使用，无论是在外部结构体上还是在已展开的字段上。

  [`flatten`]: field-attrs.md#flatten

- ##### `#[serde(tag = "type")]` {#tag}

  对于 enum ：使用内部标记的枚举表示，使用给定的标记。有关此表示的详细信息，请参见[枚举表示](enum-representations.md)。

  对于具有命名字段的 struct：将结构体的名称（或`serde(rename)`的值）序列化为具有给定键的字段，并排在结构体的所有实际字段之前。

- ##### `#[serde(tag = "t", content = "c")]` {#tag--content}

  对于此枚举，使用邻接标记的枚举表示，并使用给定的标记和内容字段名称。有关此表示的详细信息，请参见[枚举表示](enum-representations.md)。

- ##### `#[serde(untagged)]` {#untagged}

  对于此枚举，使用非标记的枚举表示。有关此表示的详细信息，请参见[枚举表示](enum-representations.md)。

- ##### `#[serde(bound = "T: MyTrait")]` {#bound}

  用于 `Serialize` 和 `Deserialize` 实现的 `where` 子句。这将替换 Serde 推断的任何 trait 约束。

  允许在序列化和反序列化中指定独立的约束：

  - `#[serde(bound(serialize = "T: MySerTrait"))]`
  - `#[serde(bound(deserialize = "T: MyDeTrait"))]`
  - `#[serde(bound(serialize = "T: MySerTrait", deserialize = "T: MyDeTrait"))]`

- ##### `#[serde(default)]` {#default}

  在反序列化时，任何丢失的字段都应该从该结构体对 `Default` 的实现中填充。仅允许在结构体上使用。

- ##### `#[serde(default = "path")]` {#default--path}

  在反序列化时，任何丢失的字段都应该从给定函数或方法返回的对象中填充。该函数必须可调用为`fn() -> T`。例如，`default = "my_default"` 将调用 `my_default()`，`default = "SomeTrait::some_default"` 将调用 `SomeTrait::some_default()`。仅允许在结构体上使用。

- ##### `#[serde(remote = "...")]` {#remote}

  用于派生 [远程类型](remote-derive.md) 的 `Serialize` 和 `Deserialize`。

- ##### `#[serde(transparent)]` {#transparent}

  序列化和反序列化新类型结构体或带有一个字段的括号结构体，就好像它的一个字段被单独序列化和反序列化一样。类似于 `#[repr(transparent)]`。

- ##### `#[serde(from = "FromType")]` {#from}

  通过将类型先反序列化为 `FromType`，然后转换，来反序列化。该类型必须实现 `From<FromType>`，并且 `FromType` 必须实现 `Deserialize`。

- ##### `#[serde(try_from = "FromType")]` {#try_from}

  通过将其反序列化为 `FromType`，然后进行可失败转换，来反序列化此类型。该类型必须使用实现具有实现 `Display` 的错误类型的 `TryFrom<FromType>`，并且 `FromType` 必须实现`Deserialize`。

- ##### `#[serde(into = "IntoType")]` {#into}

  通过先将该类型转换为指定的 `IntoType` 再将其序列化，来序列化该类型。该类型必须实现 `Clone` 和 `Into<IntoType>`，并且 `IntoType` 必须实现 `Serialize`。

- ##### `#[serde(crate = "...")]` {#crate}

  指定生成代码时引用 Serde API 用的 `serde` 包的路径。通常情况下，仅当从不同 crate 中的公共宏调用重新导出的 Serde 派生时才适用。

- ##### `#[serde(expecting = "...")]` {#expecting}

  为反序列化错误消息指定自定义类型期望文本。这将用于容器 `Visitor` 生成的 `expecting` 方法，并用作 untagged enums 的默认错误消息。