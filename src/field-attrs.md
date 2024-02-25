# 字段属性(Field attributes)

- ##### `#[serde(rename = "name")]` {#rename}

  使用给定的名称而不是其在 Rust 中的名称对该字段进行序列化和反序列化。这对于[将字段序列化为驼峰命名](attr-rename.md) 或使用保留的 Rust 关键字命名字段很有用。

  允许指定序列化和反序列化的独立名称：

  - `#[serde(rename(serialize = "ser_name"))]`
  - `#[serde(rename(deserialize = "de_name"))]`
  - `#[serde(rename(serialize = "ser_name", deserialize = "de_name"))]`

- ##### `#[serde(alias = "name")]` {#alias}

  从给定名称 *或* 其 Rust 名称中反序列化此字段。可以重复使用来指定相同字段的多个可能名称。

- ##### `#[serde(default)]` {#default}

  如果在反序列化时值不存在，则使用 `Default::default()`。

- ##### `#[serde(default = "path")]` {#default--path}

  如果在反序列化时值不存在，则调用一个函数来获取默认值。给定的函数必须可以调用为 `fn() -> T`。例如，`default = "empty_value"` 将调用 `empty_value()`，`default = "SomeTrait::some_default"` 将调用 `SomeTrait::some_default()`。

- ##### `#[serde(flatten)]` {#flatten}

  将此字段的内容扁平化到其所定义的容器中。

  这会在序列化表示和 Rust 数据结构表示之间消除一层结构。它可用于将常用的 keys 化为一个共享结构，或将剩余字段捕获到一个可带有任意字符串 keys 的 map 中。[结构扁平化](attr-flatten.md) 页面提供了一些示例。

  *注意:* 此属性不支持在 struct 与 [`deny_unknown_fields`] 中一起使用。外部扁平化的结构和内部扁平化的结构都不应该使用该属性。

  [`deny_unknown_fields`]: container-attrs.md#deny_unknown_fields

- ##### `#[serde(skip)]` {#skip}

  跳过此字段：不对其进行序列化或反序列化。

- ##### `#[serde(skip_serializing)]` {#skip_serializing}

  在序列化时跳过此字段，但在反序列化时不跳过。

  在反序列化时，Serde 将使用 `Default::default()` 或由 `default = "..."` 给出的函数来获取该字段的默认值。

- ##### `#[serde(skip_deserializing)]` {#skip_deserializing}

  在反序列化时跳过此字段，但在序列化时不跳过。

  在反序列化时，Serde 将使用 `Default::default()` 或由 `default = "..."` 给出的函数来获取该字段的默认值。

- ##### `#[serde(skip_serializing_if = "path")]` {#skip_serializing_if}

  调用一个函数来确定是否跳过序列化该字段。给定的函数必须可调用为 `fn(&T) -> bool`，尽管它可能是关于 `T` 的通用函数。例如，`skip_serializing_if = "Option::is_none"` 将跳过为 None 的 Option。

- ##### `#[serde(serialize_with = "path")]` {#serialize_with}

  使用一个与其 `Serialize` 实现中不同的函数来序列化此字段。给定的函数必须可调用为 `fn<S>(&T, S) -> Result<S::Ok, S::Error> where S: Serializer`，尽管它也可能是关于 `T` 的通用函数。使用 `serialize_with` 的字段不需要实现 `Serialize`。

- ##### `#[serde(deserialize_with = "path")]` {#deserialize_with}

  使用一个与其 `Deserialize` 实现中不同的函数来反序列化此字段。给定的函数必须可调用为 `fn<'de, D>(D) -> Result<T, D::Error> where D: Deserializer<'de>`，尽管它也可能是关于 `T` 的通用函数。使用 `deserialize_with` 的字段不需要实现 `Deserialize`。

- ##### `#[serde(with = "module")]` {#with}

  `serialize_with` 和 `deserialize_with` 的组合。Serde 将使用 `$module::serialize` 作为 `serialize_with` 函数，将 `$module::deserialize` 作为 `deserialize_with` 函数。

- ##### `#[serde(borrow)]` 和 `#[serde(borrow = "'a + 'b + ...")]` {#borrow}

  通过零拷贝反序列化从反序列化器中为此字段借用数据。请参阅[此示例](lifetimes.md#borrowing-data-in-a-derived-impl)。

- ##### `#[serde(bound = "T: MyTrait")]` {#bound}

  `Serialize` 和 `Deserialize` 实现的条件。这取代了 Serde 为当前字段推断的任何特质边界。

  允许为序列化和反序列化指定独立的边界：

  - `#[serde(bound(serialize = "T: MySerTrait"))]`
  - `#[serde(bound(deserialize = "T: MyDeTrait"))]`
  - `#[serde(bound(serialize = "T: MySerTrait", deserialize = "T: MyDeTrait"))]`

- ##### `#[serde(getter = "...")]` {#getter}

  用于派生[远程类型](remote-derive.md) 的 `Serialize` 时，该类型具有一个或多个私有字段时使用。