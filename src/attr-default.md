# 字段的默认值

<!-- !PLAYGROUND b238170d32f604295a1110ad912ef3ee -->
```rust
use serde::Deserialize;

#[derive(Deserialize, Debug)]
struct Request {
    // 如果输入中没有包含 "resource"，则将一个函数的结果用作默认值。
    #[serde(default = "default_resource")]
    resource: String,

    // 如果输入中没有包含 "timeout"，则使用类型实现的std::default::Default 作为默认值。
    #[serde(default)]
    timeout: Timeout,

    // 如果输入中没有包含 "priority"，则使用类型的方法作为默认值。这也可以是一个特质方法。
    #[serde(default = "Priority::lowest")]
    priority: Priority,
}

fn default_resource() -> String {
    "/".to_string()
}

/// 超时时间（秒）。
#[derive(Deserialize, Debug)]
struct Timeout(u32);
impl Default for Timeout {
    fn default() -> Self {
        Timeout(30)
    }
}

#[derive(Deserialize, Debug)]
enum Priority { ExtraHigh, High, Normal, Low, ExtraLow }
impl Priority {
    fn lowest() -> Self { Priority::ExtraLow }
}

fn main() {
    let json = r#"
        [
          {
            "resource": "/users"
          },
          {
            "timeout": 5,
            "priority": "High"
          }
        ]
    "#;

    let requests: Vec<Request> = serde_json::from_str(json).unwrap();

    // 第一个请求的 resource 为 "/users"，timeout 为 30，priority为ExtraLow
    println!("{:?}", requests[0]);

    // 第二个请求的 resource 为 "/"，timeout 为 5，priority 为 sHigh
    println!("{:?}", requests[1]);
}
```
