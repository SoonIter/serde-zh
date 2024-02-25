# Struct 扁平化

`flatten` 属性将字段中的键内联到父结构中。
`flatten` 可以在同一个结构中使用任意次数。它仅支持具有命名字段的结构，并且应用到的字段必须是 struct 或 map 类型。

_注意:_ `flatten` 不支持与使用[`deny_unknown_fields`]的结构体结合使用。外部和内部扁平化的结构体都不应该使用该属性。

[`deny_unknown_fields`]: container-attrs.md#deny_unknown_fields

`flatten` 属性用于以下两个常见用例:

### 提取经常分组的键

考虑一个分页 API，该 API 返回一页结果以及识别请求的结果数量、我们查看的结果总数以及总共存在的结果数量的分页元数据。如果我们每次查看 100 个结果，总共有 1053 个结果，则第三页可能如下所示。

```json
{
  "limit": 100,
  "offset": 200,
  "total": 1053,
  "users": [
    {"id": "49824073-979f-4814-be10-5ea416ee1c2f", "username": "john_doe"},
    ...
  ]
}
```

这种具有 `"limit"`、`"offset"` 和 `"total"` 字段的相同方案可能在许多不同的 API 查询中共享。例如，当查询用户、问题、项目等时，我们可能希望获得分页结果。

在这种情况下，将常见的分页元数据字段提取到一个共享的结构体中，然后将其扁平化到每个 API 响应对象中可能会更方便。

```rust
# use serde::{Serialize, Deserialize};
#
#[derive(Serialize, Deserialize)]
struct Pagination {
    limit: u64,
    offset: u64,
    total: u64,
}

#[derive(Serialize, Deserialize)]
struct Users {
    users: Vec<User>,

    #[serde(flatten)]
    pagination: Pagination,
}
#
# #[derive(Serialize, Deserialize)]
# struct User;
#
# fn main() {}
```

### 捕获附加字段

可以将映射类型的字段扁平化，以保存未被结构体的其他字段捕获的额外数据。

```rust
use std::collections::HashMap;
use serde::{Serialize, Deserialize};
use serde_json::Value;

#[derive(Serialize, Deserialize)]
struct User {
    id: String,
    username: String,

    #[serde(flatten)]
    extra: HashMap<String, Value>,
}
#
# fn main() {}
```

例如，如果我们用键 `"mascot": "Ferris"` 填充扁平化的 `extra` 字段，则其将序列化为以下 JSON 表示。

```json
{
  "id": "49824073-979f-4814-be10-5ea416ee1c2f",
  "username": "john_doe",
  "mascot": "Ferris"
}
```

对这些数据的反序列化将把 `"mascot"` 填充回扁平化的 `extra` 字段中。这样，对象中的附加数据可以被收集以供稍后处理。
