# 将 enum 序列化为 number

[serde\_repr] crate 提供了替代派生宏，派生相同的 Serialize 和 Deserialize traits，但是委托给类似 C 的 enum 的底层表示。例如，在 JSON 中，这允许类似 C 的 enum 以整数而不是字符串的形式格式化。

[serde\_repr]: https://github.com/dtolnay/serde-repr

```toml
[dependencies]
serde = "1.0"
serde_json = "1.0"
serde_repr = "0.1"
```

```rust
use serde_repr::*;

#[derive(Serialize_repr, Deserialize_repr, PartialEq, Debug)]
#[repr(u8)]
enum SmallPrime {
    Two = 2,
    Three = 3,
    Five = 5,
    Seven = 7,
}

fn main() {
    use SmallPrime::*;
    let nums = vec![Two, Three, Five, Seven];

    // Prints [2,3,5,7]
    println!("{}", serde_json::to_string(&nums).unwrap());

    assert_eq!(Two, serde_json::from_str("2").unwrap());
}
```
