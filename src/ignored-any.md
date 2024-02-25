# 丢弃数据

[`IgnoredAny`] 类型提供了一种有效的方法来从反序列化器中丢弃数据。

[`IgnoredAny`]: https://docs.rs/serde/1/serde/de/struct.IgnoredAny.html

可以将其视为 `serde_json::Value`，因为它可以从任何类型反序列化，但它不会存储关于反序列化的数据的任何信息。

```rust
use std::fmt;
use std::marker::PhantomData;

use serde::de::{
    self, Deserialize, DeserializeSeed, Deserializer, Visitor, SeqAccess,
    IgnoredAny,
};
use serde_json::json;

// 可用于仅反序列化序列中的第 `n` 个元素，并且可以高效地丢弃索引 `n` 之前或之后的任意类型元素的种子。
//
// 例如，仅反序列化索引为 3 的元素：
//
//    NthElement::new(3).deserialize(deserializer)
pub struct NthElement<T> {
    n: usize,
    marker: PhantomData<fn() -> T>,
}

impl<T> NthElement<T> {
    pub fn new(n: usize) -> Self {
        NthElement {
            n: n,
            marker: PhantomData,
        }
    }
}

impl<'de, T> Visitor<'de> for NthElement<T>
where
    T: Deserialize<'de>,
{
    type Value = T;

    fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
        write!(formatter, "我们关心索引 {} 处的序列", self.n)
    }

    fn visit_seq<V>(self, mut seq: V) -> Result<Self::Value, V::Error>
    where
        V: SeqAccess<'de>,
    {
        // 跳过前 `n` 个元素。
        for i in 0..self.n {
            // 如果在到达元素 `n` 之前序列结束，则出错。
            if seq.next_element::<IgnoredAny>()?.is_none() {
                return Err(de::Error::invalid_length(i, &self));
            }
        }

        // 反序列化我们关心的那个元素。
        let nth = seq.next_element()?
                     .ok_or_else(|| de::Error::invalid_length(self.n, &self))?;

        // 跳过 `n` 之后序列中的任何剩余元素。
        while let Some(IgnoredAny) = seq.next_element()? {
            // ignore
        }

        Ok(nth)
    }
}

impl<'de, T> DeserializeSeed<'de> for NthElement<T>
where
    T: Deserialize<'de>,
{
    type Value = T;

    fn deserialize<D>(self, deserializer: D) -> Result<Self::Value, D::Error>
    where
        D: Deserializer<'de>,
    {
        deserializer.deserialize_seq(self)
    }
}

fn main() {
    let array = json!(["a", "b", "c", "d", "e"]);

    let nth: String = NthElement::new(3).deserialize(&array).unwrap();

    println!("{}", nth);
    assert_eq!(nth, array[3]);
}
```
