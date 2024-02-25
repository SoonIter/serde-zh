# 功能标志

`serde` crate 定义了一些 [Cargo 功能] 来启用在各种自由环境中使用 Serde。

使用 `default-features = false` 构建 Serde，您将收到一个不支持任何集合类型的标准 `no_std` Serde。

[Cargo features]: https://doc.rust-lang.org/cargo/reference/manifest.html#the-features-section

<div class="indent"></div>

#### <span style="font-weight:normal">features = [</span>"derive"<span style="font-weight:normal">]</span> {#derive}

为 Serialize 和 Deserialize 特性提供派生宏。

这是一个功能，因为派生宏实现需要额外的编译时间。

#### <span style="font-weight:normal">features = [</span>"std"<span style="font-weight:normal">]</span> {#std}

*此功能默认已启用。*

提供常见标准库类型的实现，如 Vec&lt;T&gt; 和 HashMap&lt;K, V&gt;。需要依赖于 Rust 标准库。

查看 [no-std 支持] 以了解详情。

[no-std 支持]: no-std.md

#### <span style="font-weight:normal">features = [</span>"unstable"<span style="font-weight:normal">]</span> {#unstable}

为需要不稳定功能的类型提供实现。有关不稳定功能的跟踪和讨论，请参考 [serde-rs/serde#812]。

[serde-rs/serde#812]: https://github.com/serde-rs/serde/issues/812

#### <span style="font-weight:normal">features = [</span>"alloc"<span style="font-weight:normal">]</span> {#alloc}

为 Rust 核心分配和集合库中的类型提供实现，包括 String、Box&lt;T&gt;、Vec&lt;T&gt; 和 Cow&lt;T&gt;。这是 std 的子集，可以在不依赖所有 std 的情况下启用。

需要依赖于 [核心分配库]。

查看 [no-std 支持] 以了解详情。

[核心分配库]: https://doc.rust-lang.org/alloc/

#### <span style="font-weight:normal">features = [</span>"rc"<span style="font-weight:normal">]</span> {#rc}

选择为 Rc&lt;T&gt; 和 Arc&lt;T&gt; 提供实现。序列化和反序列化这些类型不会保留身份，可能会导致同一数据的多个副本。在启用此功能之前，请确保这正是您想要的。

序列化包含引用计数指针的数据结构时，将在每次引用数据结构中的指针时序列化指针的内部值的副本。序列化不会尝试去重这些重复的数据。

反序列化包含引用计数指针的数据结构将不尝试去重对相同数据的引用。每个反序列化的指针最终将具有强计数为 1。
