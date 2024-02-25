# JSON 中的 Structs 和 Enums

一个 Serde `Serializer` 负责选择 Rust struct 和 enums 在该格式中的表示约定。以下是 [`serde_json`](https://github.com/serde-rs/json) 数据格式选择的约定。为了保持一致性，在可能的情况下鼓励其他人类可读格式制定类似的约定。

```rust
# #![allow(dead_code, unused_variables)]
#
# fn main() {
#
struct W {
    a: i32,
    b: i32,
}
let w = W { a: 0, b: 0 }; // 表示为 `{"a":0,"b":0}`

struct X(i32, i32);
let x = X(0, 0); // 表示为 `[0,0]`

struct Y(i32);
let y = Y(0); // 仅表示内部值 `0`

struct Z;
let z = Z; // 表示为 `null`

enum E {
    W { a: i32, b: i32 },
    X(i32, i32),
    Y(i32),
    Z,
}
let w = E::W { a: 0, b: 0 }; // 表示为 `{"W":{"a":0,"b":0}}`
let x = E::X(0, 0);          // 表示为 `{"X":[0,0]}`
let y = E::Y(0);             // 表示为 `{"Y":0}`
let z = E::Z;                // 表示为 `"Z"`
#
# }
```
