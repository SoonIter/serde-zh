# 变体属性(Variant attributes)

- ##### `#[serde(rename = "name")]` {#rename}

  用给定名称而不是其在 Rust 中的名称对此变体进行序列化和反序列化。

  允许为序列化和反序列化分别指定独立的名称：

  - `#[serde(rename(serialize = "ser_name"))]`
  - `#[serde(rename(deserialize = "de_name"))]`
  - `#[serde(rename(serialize = "ser_name", deserialize = "de_name"))]`

- ##### `#[serde(alias = "name")]` {#alias}

  从给定名称或其 Rust 名称反序列化此变体。可以重复使用以指定同一变体的多个可能名称。

- ##### `#[serde(rename_all = "...")]` {#rename_all}

  根据给定的大小写约定对此结构变体的所有字段进行重命名。可能的值包括 `"lowercase"`,`"UPPERCASE"`,`"PascalCase"`,`"camelCase"`,`"snake_case"`,`"SCREAMING_SNAKE_CASE"`,`"kebab-case"`,`"SCREAMING-KEBAB-CASE"`。

  允许为序列化和反序列化分别指定独立的大小写约定：

  - `#[serde(rename_all(serialize = "..."))]`
  - `#[serde(rename_all(deserialize = "..."))]`
  - `#[serde(rename_all(serialize = "...", deserialize = "..."))]`

- ##### `#[serde(skip)]` {#skip}

  不要序列化或反序列化此变体。

- ##### `#[serde(skip_serializing)]` {#skip_serializing}

  永远不序列化此变体。尝试序列化此变体将被视为错误。

- ##### `#[serde(skip_deserializing)]` {#skip_deserializing}

  永远不反序列化此变体。

- ##### `#[serde(serialize_with = "path")]` {#serialize_with}

  使用与 `Serialize` 的实现中不同的函数对此变体进行序列化。给定的函数必须可调用为 `fn<S>(&FIELD0, &FIELD1, ..., S) -> Result<S::Ok, S::Error> where S: Serializer`，尽管它也可以在 `FIELD{n}` 类型上为泛型。与 `serialize_with` 一起使用的变体不需要能够推导 `Serialize`。

  对于每个字段，都存在 `FIELD{n}`。因此，单位变体仅具有 `S` 参数，而 tuple/struct 变体为每个字段都有一个参数。

- ##### `#[serde(deserialize_with = "path")]` {#deserialize_with}

  使用与其 `Deserialize` 实现不同的函数对此变体进行反序列化。给定的函数必须可调用为 `fn<'de, D>(D) -> Result<FIELDS, D::Error> where D: Deserializer<'de>`，尽管它也可以在 `FIELDS` 的元素上为泛型。与`deserialize_with` 一起使用的变体不需要能够推导 `Deserialize`。

  `FIELDS` 是变体的所有字段的元组。单位变体将以 `()` 作为其 `FIELDS` 类型。

- ##### `#[serde(with = "module")]` {#with}

  `serialize_with` 和 `deserialize_with` 的组合。Serde 将使用`$module::serialize` 作为 `serialize_with` 函数，`$module::deserialize` 作为 `deserialize_with` 函数。

- ##### `#[serde(bound = "T: MyTrait")]` {#bound}

  用于 `Serialize` 和/或 `Deserialize` impls 的 where 子句。这将替换 Serde 为当前变体推断的任何 trait 限制。

  允许为序列化和反序列化分别指定独立的边界：

  - `#[serde(bound(serialize = "T: MySerTrait"))]`
  - `#[serde(bound(deserialize = "T: MyDeTrait"))]`
  - `#[serde(bound(serialize = "T: MySerTrait", deserialize = "T: MyDeTrait"))]`

- ##### `#[serde(borrow)]` 和 `#[serde(borrow = "'a + 'b + ...")]` {#borrow}

  通过使用零拷贝反序列化从反序列器中借用此字段的数据。请参阅 [此示例](lifetimes.md#borrowing-data-in-a-derived-impl)。仅在新类型变体（只有一个字段的元组变体）上允许使用。

- ##### `#[serde(other)]` {#other}

  如果枚举标记不是此枚举中其他变体的标记，则反序列化此变体。仅允许在内部标记或相邻标记的枚举中的单位变体上使用。

  例如，如果我们有一个带有`serde(tag = "variant")`的内部标记枚举，其中包含`A`、`B`和`Unknown`标记为`serde(other)`的变体，那么`Unknown`变体将在输入的`"variant"`字段既不是`"A"`也不是`"B"`时进行反序列化。

- ##### `#[serde(untagged)]` {#untagged}

  不考虑[枚举表示](enum-representations.md)，将此变体序列化和反序列化为未标记的，即仅作为变体数据而没有变体名称的记录。

  未标记的变体必须在枚举定义中最后排序。