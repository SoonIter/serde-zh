# 在不同 crate 中为类型派生 De/Serialize

Rust 的[孤儿规则]要求实现 trait 的 crate 或实现 trait 的类型必须和 impl 在同一个 crate 中定义，因此不可能直接为不同 crate 中的类型实现 `Serialize` 和 `Deserialize`。

[孤儿规则]: https://doc.rust-lang.org/book/traits.html#rules-for-implementing-traits

```diff
- use serde::Serialize;
- use other_crate::Duration;
-
- // 孤儿规则不允许
- impl Serialize for Duration {
-     /* ... */
- }
```

为了解决这个问题，Serde 提供了一种方法，可以为其他 crate 中类型派生 `Serialize` 和 `Deserialize` 实现。唯一需要注意的是，你必须提供类型的定义让 Serde 的派生可以处理。在编译时，serde 将检查你提供的定义中的所有字段是否和远程类型中的字段匹配。

<!-- !PLAYGROUND 0a344c9dfc4cf965e66125ebdfbc48b8 -->
```rust
// 假装这是别人的 crate，而不是一个模块
mod other_crate {
    // Serde 和其他 crate 都没有为这个结构体提供 Serialize 和 Deserialize 的实现
    pub struct Duration {
        pub secs: i64,
        pub nanos: i32,
    }
}

////////////////////////////////////////////////////////////////////////////////

use other_crate::Duration;
use serde::{Serialize, Deserialize};

// Serde 将其称为远程类型的定义。这只是远程数据结构的一个副本。`remote`属性指定了我们要派生代码的实际类型路径。
#[derive(Serialize, Deserialize)]
#[serde(remote = "Duration")]
struct DurationDef {
    secs: i64,
    nanos: i32,
}

// 现在远程类型可以像本来就有自己的 Serialize 和 Deserialize 实现一样使用。`with`属性指定了远程类型的定义路径。请注意字段的实际类型是远程类型，而不是定义类型。
#[derive(Serialize, Deserialize)]
struct Process {
    command_line: String,

    #[serde(with = "DurationDef")]
    wall_time: Duration,
}
#
# fn main() {}
```

如果远程类型是一个具有所有公共字段或枚举的结构体，那就是全部内容了。如果远程类型是一个具有一个或多个私有字段的结构体，那么必须为私有字段提供 getter，并提供一个转换来构造远程类型。

<!-- !PLAYGROUND 02b8513dfb060b6580f998bac5a04a1a -->
```rust
// 假装这是别人的 crate，而不是一个模块
mod other_crate {
    // Serde 和其他 crate 都没有为这个结构体提供 Serialize 和 Deserialize 的实现。哦，而且字段是私有的
    pub struct Duration {
        secs: i64,
        nanos: i32,
    }

    impl Duration {
        pub fn new(secs: i64, nanos: i32) -> Self {
            Duration { secs: secs, nanos: nanos }
        }

        pub fn seconds(&self) -> i64 {
            self.secs
        }

        pub fn subsec_nanos(&self) -> i32 {
            self.nanos
        }
    }
}

////////////////////////////////////////////////////////////////////////////////

use other_crate::Duration;
use serde::{Serialize, Deserialize};

// 为远程结构体的每个私有字段提供 getter。getter 必须返回 `T` 或 `&T`，其中 `T` 是字段的类型。
#[derive(Serialize, Deserialize)]
#[serde(remote = "Duration")]
struct DurationDef {
    #[serde(getter = "Duration::seconds")]
    secs: i64,
    #[serde(getter = "Duration::subsec_nanos")]
    nanos: i32,
}

// 提供一个转换来构造远程类型。
impl From<DurationDef> for Duration {
    fn from(def: DurationDef) -> Duration {
        Duration::new(def.secs, def.nanos)
    }
}

#[derive(Serialize, Deserialize)]
struct Process {
    command_line: String,

    #[serde(with = "DurationDef")]
    wall_time: Duration,
}
#
# fn main() {}
```

## 直接调用远程实现

如上所示，远程实现旨在通过某些其他结构体字段上的 `#[serde(with = "...")]`属性来调用。

直接调用远程实现，例如如果这是正在序列化或反序列化的顶层类型，则由于孤儿规则的存在，可能会稍微复杂。这些远程派生最终生成的代码不是 `Serialize`和`Deserialize` 实现，而是具有相同签名的关联函数。

```rust
# #![allow(dead_code)]
#
# use serde::Deserialize;
#
# struct Duration {
#     secs: i64,
#     nanos: i32,
# }
#
// 严格来说，这个派生并未为 Duration 生成 Deserialize 实现，也没有为 DurationDef 生成 Deserialize 实现。
//
// 相反，它生成了一个叫做 DurationDef::deserialize 的反序列化方法，其返回类型是 Duration。这个方法具有与为 Duration 派生 Deserialize 实现相同的签名，但并不是一个 Deserialize 实现。
#[derive(Deserialize)]
#[serde(remote = "Duration")]
struct DurationDef {
    secs: i64,
    nanos: i32,
}
#
# fn main() {}
```

知道这些，生成的方法可以通过传递一个 `Deserializer` 实现来直接调用。

<!-- !PLAYGROUND 29cadbd640a231d5703564a666b0bc85 -->
```rust
# #![allow(dead_code)]
#
# use serde::Deserialize;
#
# struct Duration;
#
# #[derive(Deserialize)]
# #[serde(remote = "Duration")]
# struct DurationDef;
#
# fn try_main(j: &str) -> Result<Duration, serde_json::Error> {
let mut de = serde_json::Deserializer::from_str(j);
let dur = DurationDef::deserialize(&mut de)?;

// `dur` 的类型是 Duration
#     Ok(dur)
# }
#
# fn main() {}
```

另外我们可以编写一个顶层的 newtype 包装器作为私有助手来反序列化远程类型。

<!-- !PLAYGROUND 159da6ebf3a3573b8bd7f3bc2246026c -->
```rust
# #![allow(dead_code)]
#
# use serde::Deserialize;
#
# struct Duration;
#
# #[derive(Deserialize)]
# #[serde(remote = "Duration")]
# struct DurationDef;
#
# fn try_main(j: &str) -> Result<Duration, serde_json::Error> {
#[derive(Deserialize)]
struct Helper(#[serde(with = "DurationDef")] Duration);

let dur = serde_json::from_str(j).map(|Helper(dur)| dur)?;

// `dur` 的类型是 Duration
#     Ok(dur)
# }
#
# fn main() {}
```
