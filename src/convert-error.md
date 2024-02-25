# 转换错误类型

在某些情况下，某种格式的值必须包含在另一种格式的数据中。例如，Terraform 中的[IAM策略]被表示为包含在HCL配置中的JSON字符串。

[IAM策略]: https://www.terraform.io/docs/providers/aws/r/iam_policy.html

将内部值视为简单的字符串可能很简单，但是如果我们要操作内部和外部值，则通常将它们一次性序列化和反序列化会更方便。

在这种情况下，偶尔会遇到的绊脚石是正确处理错误。这两种格式（很可能）具有不同的错误类型，因此需要进行一些转换。

此示例显示包含简化IAM策略的简化 HCL 资源。在序列化时，策略文档被表示为 JSON 字符串。

```rust
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize)]
struct Resource {
    name: String,

    #[serde(with = "as_json_string")]
    policy: Policy,
}

#[derive(Serialize, Deserialize)]
struct Policy {
    effect: String,
    action: String,
    resource: String,
}

// 用于处理表示为 JSON 字符串的嵌套值的序列化和反序列化逻辑。
mod as_json_string {
    use serde_json;
    use serde::ser::{Serialize, Serializer};
    use serde::de::{Deserialize, DeserializeOwned, Deserializer};

    // 序列化为 JSON 字符串，然后将字符串序列化为输出格式。
    pub fn serialize<T, S>(value: &T, serializer: S) -> Result<S::Ok, S::Error>
    where
        T: Serialize,
        S: Serializer,
    {
        use serde::ser::Error;
        let j = serde_json::to_string(value).map_err(Error::custom)?;
        j.serialize(serializer)
    }

    // 从输入格式中反序列化字符串，然后将该字符串的内容反序列化为 JSON。
    pub fn deserialize<'de, T, D>(deserializer: D) -> Result<T, D::Error>
    where
        T: DeserializeOwned,
        D: Deserializer<'de>,
    {
        use serde::de::Error;
        let j = String::deserialize(deserializer)?;
        serde_json::from_str(&j).map_err(Error::custom)
    }
}

fn main() {
    let resource = Resource {
        name: "test_policy".to_owned(),
        policy: Policy {
            effect: "Allow".to_owned(),
            action: "s3:ListBucket".to_owned(),
            resource: "arn:aws:s3:::example_bucket".to_owned(),
        },
    };

    let y = serde_yaml::to_string(&resource).unwrap();
    println!("{}", y);
}
```
