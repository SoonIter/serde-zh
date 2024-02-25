# 在不缓冲到 Vec 中的情况下处理值数组

假设我们有一个整数数组，我们想要找出最大值，而不需要一次将整个数组全部保存在内存中。这种方法可以被调整用于处理各种需要在反序列化时处理数据而不是之后的情况。

<!-- !PLAYGROUND 270186a56b8321704dc45001fdfa3c92 -->
```rust
use serde::{Deserialize, Deserializer};
use serde::de::{self, Visitor, SeqAccess};

use std::{cmp, fmt};
use std::marker::PhantomData;

#[derive(Deserialize)]
struct Outer {
    # #[allow(dead_code)]
    id: String,

    // 通过计算序列（JSON 数组）中值的最大值来反序列化此字段。
    #[serde(deserialize_with = "deserialize_max")]
    // 尽管结构体字段被命名为 `max_value`，但实际将来自名为 `values` 的 JSON 字段。
    #[serde(rename(deserialize = "values"))]
    max_value: u64,
}

/// 反序列化值序列的最大值。整个序列不会像如果我们反序列化为 Vec<T> 然后稍后计算最大值那样缓冲到内存中。
///
/// 这个函数是泛型的，T 可以是任何实现 Ord 的类型。上面，它被用于 T=u64。
fn deserialize_max<'de, T, D>(deserializer: D) -> Result<T, D::Error>
where
    T: Deserialize<'de> + Ord,
    D: Deserializer<'de>,
{
    struct MaxVisitor<T>(PhantomData<fn() -> T>);

    impl<'de, T> Visitor<'de> for MaxVisitor<T>
    where
        T: Deserialize<'de> + Ord,
    {
        /// 该访问者的返回类型。该访问者计算类型 T 的值序列的最大值，因此最大值的类型为 T。
        type Value = T;

        fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
            formatter.write_str("一组非空数字序列")
        }

        fn visit_seq<S>(self, mut seq: S) -> Result<T, S::Error>
        where
            S: SeqAccess<'de>,
        {
            // 从序列中的第一个值开始设置最大值。
            let mut max = seq.next_element()?.ok_or_else(||
                // 在查找最大值时，无法取空序列的最大值。
                de::Error::custom("在查找最大值时序列中没有值")
            )?;

            // 在还有其他值时更新最大值。
            while let Some(value) = seq.next_element()? {
                max = cmp::max(max, value);
            }

            Ok(max)
        }
    }

    // 创建访问者并要求反序列化器驱动它。如果输入数据中存在序列，反序列化器将调用 visitor.visit_seq()。
    let visitor = MaxVisitor(PhantomData);
    deserializer.deserialize_seq(visitor)
}

fn main() {
    let j = r#"
        {
          "id": "demo-deserialize-max",
          "values": [
            256,
            100,
            384,
            314,
            271
          ]
        }
    "#;

    let out: Outer = serde_json::from_str(j).unwrap();

    // 打印 "最大值：384"
    println!("最大值：{}", out.max_value);
}
```
