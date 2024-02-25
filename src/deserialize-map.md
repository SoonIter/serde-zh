# 为自定义 map 类型实现 Deserialize

!PLAYGROUND 72f10ca685c08f8afeb618efdabfed6a
```rust
use std::fmt;
use std::marker::PhantomData;

use serde::de::{Deserialize, Deserializer, Visitor, MapAccess};
#
# struct MyMap<K, V>(PhantomData<K>, PhantomData<V>);
#
# impl<K, V> MyMap<K, V> {
#     fn with_capacity(_: usize) -> Self {
#         unimplemented!()
#     }
#
#     fn insert(&mut self, _: K, _: V) {
#         unimplemented!()
#     }
# }

// Visitor 是一个类型，其中包含 Deserializer 可以根据输入数据的内容驱动的方法。
//
// 在 map 的情况下，我们需要泛型类型参数 K 和 V 来正确设置输出类型，但不需要任何状态。
// 这是 Rust 中的 “零大小类型” 的一个例子。PhantomData
// 防止编译器因未使用的泛型类型参数而抱怨。
struct MyMapVisitor<K, V> {
    marker: PhantomData<fn() -> MyMap<K, V>>
}

impl<K, V> MyMapVisitor<K, V> {
    fn new() -> Self {
        MyMapVisitor {
            marker: PhantomData
        }
    }
}

// 这是Deserializers将驱动的特质。每种类型的数据都有一个与之对应的方法
// 我们的类型知道如何从中反序列化。这里有许多其他未在此处实现的方法，例如从整数或字符串反序列化。
// 默认情况下，这些方法将返回错误，这是有道理的，因为我们无法从整数或字符串反序列化MyMap。
impl<'de, K, V> Visitor<'de> for MyMapVisitor<K, V>
where
    K: Deserialize<'de>,
    V: Deserialize<'de>,
{
    //我们的Visitor将生成的类型。
    type Value = MyMap<K, V>;

    //格式化一条消息，说明该 Visitor 希望接收哪些数据。
    fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
        formatter.write_str("一个非常特殊的 map")
    }

    // 从Deserializer提供的抽象“地图”中反序列化MyMap。MapAccess输入是Deserializer提供的回调，让我们可以看到地图中的每个条目。
    fn visit_map<M>(self, mut access: M) -> Result<Self::Value, M::Error>
    where
        M: MapAccess<'de>,
    {
        let mut map = MyMap::with_capacity(access.size_hint().unwrap_or(0));

        // 在输入中还有条目时，将它们添加到我们的地图中。
        while let Some((key, value)) = access.next_entry()? {
            map.insert(key, value);
        }

        Ok(map)
    }
}

// 这是告诉 Serde 如何反序列化 MyMap 的特质。
impl<'de, K, V> Deserialize<'de> for MyMap<K, V>
where
    K: Deserialize<'de>,
    V: Deserialize<'de>,
{
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        //实例化我们的 Visitor，并要求 Deserializer 在输入数据上驱动它，从而生成 MyMap 的实例。
        deserializer.deserialize_map(MyMapVisitor::new())
    }
}
#
# fn main() {}
```
