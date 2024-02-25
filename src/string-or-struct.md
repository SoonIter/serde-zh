# 反序列化字符串或结构体

[`docker-compose.yml`](https://docs.docker.com/compose/compose-file/#/build) 配置文件有一个 "build" 键，该键可以是一个字符串或结构体。

```yaml
build: ./dir

# --- 或 ---

build:
  context: ./dir
  dockerfile: Dockerfile-alternate
  args:
    buildno: 1
```

配置文件在其他地方也使用相同的模式，通常是先前存在的字符串字段已被扩展以处理更复杂的数据。

我们可以使用 Rust 的 [`FromStr`](https://doc.rust-lang.org/std/str/trait.FromStr.html) trait 和 Serde 的 `deserialize_with` 属性来以一种通用的方式处理这种模式。

```rust
use std::collections::BTreeMap as Map;
use std::fmt;
use std::marker::PhantomData;
use std::str::FromStr;

use serde::{Deserialize, Deserializer};
use serde::de::{self, Visitor, MapAccess};
use void::Void;

fn main() {
    let build_string = "
        build: ./dir
    ";
    let service: Service = serde_yaml::from_str(build_string).unwrap();

    // context="./dir"
    // dockerfile=None
    // args={}
    println!("{:?}", service);

    let build_struct = "
        build:
          context: ./dir
          dockerfile: Dockerfile-alternate
          args:
            buildno: '1'
    ";
    let service: Service = serde_yaml::from_str(build_struct).unwrap();

    // context="./dir"
    // dockerfile=Some("Dockerfile-alternate")
    // args={"buildno": "1"}
    println!("{:?}", service);
}

#[derive(Debug, Deserialize)]
struct Service {
    // The `string_or_struct` function delegates deserialization to a type's
    // `FromStr` impl if given a string, and to the type's `Deserialize` impl if
    // given a struct. The function is generic over the field type T (here T is
    // `Build`) so it can be reused for any field that implements both `FromStr`
    // and `Deserialize`.
    #[serde(deserialize_with = "string_or_struct")]
    build: Build,
}

#[derive(Debug, Deserialize)]
struct Build {
    // This is the only required field.
    context: String,

    dockerfile: Option<String>,

    // When `args` is not present in the input, this attribute tells Serde to
    // use `Default::default()` which in this case is an empty map. See the
    // "default value for a field" example for more about `#[serde(default)]`.
    #[serde(default)]
    args: Map<String, String>,
}

// The `string_or_struct` function uses this impl to instantiate a `Build` if
// the input file contains a string and not a struct. According to the
// docker-compose.yml documentation, a string by itself represents a `Build`
// with just the `context` field set.
//
// > `build` can be specified either as a string containing a path to the build
// > context, or an object with the path specified under context and optionally
// > dockerfile and args.
impl FromStr for Build {
    // This implementation of `from_str` can never fail, so use the impossible
    // `Void` type as the error type.
    type Err = Void;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Ok(Build {
            context: s.to_string(),
            dockerfile: None,
            args: Map::new(),
        })
    }
}

fn string_or_struct<'de, T, D>(deserializer: D) -> Result<T, D::Error>
where
    T: Deserialize<'de> + FromStr<Err = Void>,
    D: Deserializer<'de>,
{
    // This is a Visitor that forwards string types to T's `FromStr` impl and
    // forwards map types to T's `Deserialize` impl. The `PhantomData` is to
    // keep the compiler from complaining about T being an unused generic type
    // parameter. We need T in order to know the Value type for the Visitor
    // impl.
    struct StringOrStruct<T>(PhantomData<fn() -> T>);

    impl<'de, T> Visitor<'de> for StringOrStruct<T>
    where
        T: Deserialize<'de> + FromStr<Err = Void>,
    {
        type Value = T;

        fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
            formatter.write_str("string or map")
        }

        fn visit_str<E>(self, value: &str) -> Result<T, E>
        where
            E: de::Error,
        {
            Ok(FromStr::from_str(value).unwrap())
        }

        fn visit_map<M>(self, map: M) -> Result<T, M::Error>
        where
            M: MapAccess<'de>,
        {
            // `MapAccessDeserializer` is a wrapper that turns a `MapAccess`
            // into a `Deserializer`, allowing it to be used as the input to T's
            // `Deserialize` implementation. T then deserializes itself using
            // the entries from the map visitor.
            Deserialize::deserialize(de::value::MapAccessDeserializer::new(map))
        }
    }

    deserializer.deserialize_any(StringOrStruct(PhantomData))
}
```
