# 跳过序列化字段

**注意:** 使用 `skip_serializing` 不会跳过 **反**序列化字段。如果只添加 `skip_serializing` 属性，然后尝试反序列化数据，会失败，因为仍会尝试反序列化已跳过的字段。请使用 `skip` 属性来同时跳过序列化和反序列化（参见[字段属性: `skip`][attr-skip]）。同样，使用 `skip_deserializing` 来仅跳过反序列化。

[attr-skip]: field-attrs.md#skip

!PLAYGROUND b65f4a90bb11285574a1917b0f5e10aa
```rust
use serde::Serialize;

use std::collections::BTreeMap as Map;

#[derive(Serialize)]
struct Resource {
    // 总是被序列化。
    name: String,

    // 从不被序列化。
    #[serde(skip_serializing)]
    # #[allow(dead_code)]
    hash: String,

    // 使用方法来决定是否跳过该字段。
    #[serde(skip_serializing_if = "Map::is_empty")]
    metadata: Map<String, String>,
}

fn main() {
    let resources = vec![
        Resource {
            name: "Stack Overflow".to_string(),
            hash: "b6469c3f31653d281bbbfa6f94d60fea130abe38".to_string(),
            metadata: Map::new(),
        },
        Resource {
            name: "GitHub".to_string(),
            hash: "5cb7a0c47e53854cd00e1a968de5abce1c124601".to_string(),
            metadata: {
                let mut metadata = Map::new();
                metadata.insert("headquarters".to_string(),
                                "San Francisco".to_string());
                metadata
            },
        },
    ];

    let json = serde_json::to_string_pretty(&resources).unwrap();

    // 打印:
    //
    //    [
    //      {
    //        "name": "Stack Overflow"
    //      },
    //      {
    //        "name": "GitHub",
    //        "metadata": {
    //          "headquarters": "San Francisco"
    //        }
    //      }
    //    ]
    println!("{}", json);
}
```
