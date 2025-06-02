# Live2DSDK

## Example

To run the example project, clone the repo, `cd Example` and run `sh clean.sh` from the Example directory first.

## Requirements

## Installation

Live2DSDK is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Live2DSDK'
```

## Author

NY, nycode.jn@gmail.com


## 🌟 EvaAI Core Module

### English | 🇺🇸

This repository contains core components of the **EvaAI** project, focusing on:

* 🎨 **Live2D Model Rendering**
* 🔌 **OpenRouter API Integration**
* 🧪 **Basic Feature Demonstrations**

---

### 📦 Live2D SDK Integration

This project includes a simplified integration framework for [Live2D Cubism Native Framework](https://github.com/Live2D/CubismNativeFramework), making it easier to use within iOS projects.

* You can customize the build for different architectures by modifying the `Live2DSDK.podspec` file.
* ⚠️ **Important Warning**:
  The Live2D SDK includes a large amount of C++ source code. Submitting an app to the Apple App Store with this SDK might lead to it being flagged as a *"replicated/masked app (马甲包)"*.
  Please use it **with caution**.

---

### 🌐 OpenRouter Integration

EvaAI connects to [OpenRouter](https://openrouter.ai) to provide AI interaction and dialogue capabilities. API integration examples are included in the repository.

---

### 🚀 Features

* Live2D avatar rendering in real-time
* Basic animation and interaction logic
* Text-to-speech (TTS) and chat interface ready
* Simple examples for extending EvaAI into full applications

---

### 📁 Structure Overview


```bash
EvaAI/
├── Live2DSDK/
│   └── (Live2D rendering logic)
├── API/
│   └── NetworkClient.swift
├── Assets/
│   └── (Model and UI assets)
├── ViewController.swift
└── README.md
```

---

### ⚖️ License & Third-Party Attribution

EvaAI integrates the [Live2D Cubism Native Framework](https://github.com/Live2D/CubismNativeFramework) under the terms of its official license:
📄 [Live2D Cubism Framework License Agreement](https://github.com/Live2D/CubismNativeFramework/blob/develop/LICENSE.md)

> **You must comply with Live2D’s license when using or distributing this project.**
> The Live2D SDK is © Live2D Inc. All rights reserved. Commercial use requires a separate license agreement with Live2D Inc.

---

### 📌 Disclaimer

This is **not** a full product, but a core module. EvaAI is under active development and will continue to evolve.

---

## 🇨🇳 中文说明

该仓库包含 **EvaAI** 项目的核心代码模块，主要包括：

* 🎨 **Live2D 模型渲染集成**
* 🔌 **OpenRouter 接口调用**
* 🧪 **基础功能演示**

---

### 📦 Live2D SDK 集成说明

本项目封装了 [Live2D Cubism Native Framework](https://github.com/Live2D/CubismNativeFramework)，提供更适合 iOS 项目的集成方式。

* 你可以通过修改 `Live2DSDK.podspec` 文件实现不同架构的打包构建。
* ⚠️ **重要警告**：
  Live2D SDK 包含大量 C++ 源码。在提交 App Store 时可能会被苹果误判为 **马甲包**，请谨慎使用。

---

### 🌐 OpenRouter 接口集成

本项目接入了 [OpenRouter](https://openrouter.ai) 以实现 AI 助手功能，支持对话请求和响应。示例代码已包含在仓库中。

---

### 🚀 功能展示

* 实时 Live2D 虚拟角色渲染
* 简单动画与互动逻辑
* 初步集成语音合成和聊天接口
* 为完整应用提供结构范例和演示

---

### 📁 项目结构概览

```bash
EvaAI/
├── Live2DSDK/
│   └── (Live2D rendering logic)
├── API/
│   └── NetworkClient.swift
├── Assets/
│   └── (Model and UI assets)
├── ViewController.swift
└── README.md
```

---

### ⚖️ 授权信息与第三方声明

EvaAI 集成了 [Live2D Cubism Native Framework](https://github.com/Live2D/CubismNativeFramework)，并遵循其官方授权协议：
📄 [Live2D Cubism Framework 使用许可协议](https://github.com/Live2D/CubismNativeFramework/blob/develop/LICENSE.md)

> **使用或分发本项目时，必须遵守 Live2D 的授权协议。**
> Live2D SDK 版权归 Live2D Inc. 所有。如用于商业用途，请单独向 Live2D Inc. 申请授权。

---

### 📌 注意事项

此项目为 EvaAI 的部分核心模块，并非完整产品。EvaAI 正在持续开发中，欢迎关注与贡献。
