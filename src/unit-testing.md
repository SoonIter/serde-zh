# 单元测试

[`serde_test`](https://docs.rs/serde_test) crate 提供了一种方便简洁的方式来为 `Serialize` 和 `Deserialize` 的实现编写单元测试。

一个值的 `Serialize` 实现可以通过序列化该值时调用的 [`Serializer`](https://docs.rs/serde/1/serde/ser/trait.Serializer.html) 方法的顺序来表征，因此 `serde_test` 提供了一个 [`Token`](https://docs.rs/serde_test/1/serde_test/enum.Token.html) 抽象，大致对应于 `Serializer` 方法的调用。它提供了一个 `assert_ser_tokens` 函数，用于测试值是否序列化为特定的方法调用序列，一个 `assert_de_tokens` 函数用于测试值是否可以从特定的方法调用序列反序列化，以及一个 `assert_tokens` 函数用于测试双向操作。它还提供了一些函数来测试预期的失败条件。

这里是来自 [`linked-hash-map`](https://github.com/contain-rs/linked-hash-map) crate 的一个示例。

```rust
# #[allow(unused_imports)]
use linked_hash_map::LinkedHashMap;
#
# mod test {
#     use std::fmt;
#     use std::marker::PhantomData;
#
#     use serde::ser::{Serialize, Serializer, SerializeMap};
#     use serde::de::{Deserialize, Deserializer, Visitor, MapAccess};
#
use serde_test::{Token, assert_tokens};
#
#     // yaml-rust 使用的 linked-hash-map 版本与 Serde 0.9 不兼容，并且 Skeptic 测试中不能有多个版本的任何依赖项。这里重新实现一个简单的 imitation。
#     #[derive(PartialEq, Debug)]
#     struct LinkedHashMap<K, V>(Vec<(K, V)>);
#
#     impl<K, V> LinkedHashMap<K, V> {
#         fn new() -> Self {
#             LinkedHashMap(Vec::new())
#         }
#
#         fn insert(&mut self, k: K, v: V) {
#             self.0.push((k, v));
#         }
#     }
#
#     impl<K, V> Serialize for LinkedHashMap<K, V>
#     where
#         K: Serialize,
#         V: Serialize,
#     {
#         fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
#         where
#             S: Serializer,
#         {
#             let mut map = serializer.serialize_map(Some(self.0.len()))?;
#             for &(ref k, ref v) in &self.0 {
#                 map.serialize_entry(k, v)?;
#             }
#             map.end()
#         }
#     }
#
#     struct LinkedHashMapVisitor<K, V>(PhantomData<fn() -> LinkedHashMap<K, V>>);
#
#     impl<'de, K, V> Visitor<'de> for LinkedHashMapVisitor<K, V>
#     where
#         K: Deserialize<'de>,
#         V: Deserialize<'de>,
#     {
#         type Value = LinkedHashMap<K, V>;
#
#         fn expecting(&self, _: &mut fmt::Formatter) -> fmt::Result {
#             unimplemented!()
#         }
#
#         fn visit_map<M>(self, mut access: M) -> Result<Self::Value, M::Error>
#         where
#             M: MapAccess<'de>,
#         {
#             let mut map = LinkedHashMap::new();
#             while let Some((key, value)) = access.next_entry()? {
#                 map.insert(key, value);
#             }
#             Ok(map)
#         }
#     }
#
#     impl<'de, K, V> Deserialize<'de> for LinkedHashMap<K, V>
#     where
#         K: Deserialize<'de>,
#         V: Deserialize<'de>,
#     {
#         fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
#         where
#             D: Deserializer<'de>,
#         {
#             deserializer.deserialize_map(LinkedHashMapVisitor(PhantomData))
#         }
#     }

#[test]
# fn skeptic_test_ser_de_empty() {}
fn test_ser_de_empty() {
    let map = LinkedHashMap::<char, u32>::new();

    assert_tokens(&map, &[
        Token::Map { len: Some(0) },
        Token::MapEnd,
    ]);
}

#[test]
# fn skeptic_test_ser_de() {}
fn test_ser_de() {
    let mut map = LinkedHashMap::new();
    map.insert('b', 20);
    map.insert('a', 10);
    map.insert('c', 30);

    assert_tokens(&map, &[
        Token::Map { len: Some(3) },
        Token::Char('b'),
        Token::I32(20),

        Token::Char('a'),
        Token::I32(10),

        Token::Char('c'),
        Token::I32(30),
        Token::MapEnd,
    ]);
}
#
#     pub fn run_tests() {
#         test_ser_de_empty();
#         test_ser_de();
#     }
# }
#
# fn main() {
#     test::run_tests();
# }
```
