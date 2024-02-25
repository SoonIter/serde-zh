# 以自定义格式显示日期

这使用 [`chrono`](https://github.com/chronotope/chrono) crate 来序列化和反序列化包含自定义日期格式的 JSON 数据。 `with` 属性用于提供处理自定义表示的逻辑。

!PLAYGROUND 2ef7c347c76b030fe7e8c59ce9efccd3
```rust
use chrono::{DateTime, Utc};
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct StructWithCustomDate {
    // DateTime 可以直接支持 Serde，但使用 RFC3339 格式。提供一些自定义逻辑使其使用我们想要的格式。
    #[serde(with = "my_date_format")]
    pub timestamp: DateTime<Utc>,

    // 结构体中的其他字段。
    pub bidder: String,
}

mod my_date_format {
    use chrono::{DateTime, Utc, NaiveDateTime};
    use serde::{self, Deserialize, Serializer, Deserializer};

    const FORMAT: &'static str = "%Y-%m-%d %H:%M:%S";

    // serialize_with 函数的签名必须遵循以下模式：
    //
    //    fn serialize<S>(&T, S) -> Result<S::Ok, S::Error>
    //    where
    //        S: Serializer
    //
    // 尽管也可以对输入类型 T 进行泛型化。
    pub fn serialize<S>(
        date: &DateTime<Utc>,
        serializer: S,
    ) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let s = format!("{}", date.format(FORMAT));
        serializer.serialize_str(&s)
    }

    // deserialize_with 函数的签名必须遵循以下模式：
    //
    //    fn deserialize<'de, D>(D) -> Result<T, D::Error>
    //    where
    //        D: Deserializer<'de>
    //
    // 尽管也可以对输出类型 T 进行泛型化。
    pub fn deserialize<'de, D>(
        deserializer: D,
    ) -> Result<DateTime<Utc>, D::Error>
    where
        D: Deserializer<'de>,
    {
        let s = String::deserialize(deserializer)?;
        let dt = NaiveDateTime::parse_from_str(&s, FORMAT).map_err(serde::de::Error::custom)?;
        Ok(DateTime::<Utc>::from_naive_utc_and_offset(dt, Utc))
    }
}

fn main() {
    let json_str = r#"
      {
        "timestamp": "2017-02-16 21:54:30",
        "bidder": "Skrillex"
      }
    "#;

    let data: StructWithCustomDate = serde_json::from_str(json_str).unwrap();
    println!("{:#?}", data);

    let serialized = serde_json::to_string_pretty(&data).unwrap();
    println!("{}", serialized);
}
```
