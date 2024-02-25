# 编写一个数据格式

在编写数据格式之前最重要的一点是要明白**Serde 不是一个解析库**。Serde 中没有任何功能能够帮助您解析任何格式。Serde 的作用非常明确：

- **序列化** — 接受用户提供的任意数据结构并以最高效的方式将其呈现为指定格式。
- **反序列化** — 将解析的数据解释为用户选择的数据结构，并以最高效的方式处理。

解析不是上述两者之一，您要么需要从头开始编写解析代码，要么使用解析库来实现您的 Deserializer。

第二个最重要的事情是理解 [**Serde 数据模型**]。

[**Serde 数据模型**]: data-model.md

以下页面将引导您通过使用 Serde 实现的一个基本但功能齐全的 JSON 序列化器和反序列化器。

- [根目录导出约定](conventions.md)
- [Serde 错误 trait 和错误处理](error-handling.md)
- [实现一个 Serializer](impl-serializer.md)
- [实现一个 Deserializer](impl-deserializer.md)

您可以在 [这个 GitHub 仓库] 中找到这四个源代码文件，它们组合在一起可以构建一个完整的 crate。

[这个 GitHub 仓库]: https://github.com/serde-rs/example-format