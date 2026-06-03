# wxauto-mcp-macos

macOS 版微信自动化 MCP Server，基于 AppleScript + Accessibility API 操控微信桌面版。

> 灵感来自 [wxauto-mcp](https://github.com/barantt/wxauto-mcp)（仅支持 Windows），本项目是 macOS 平台的替代方案。

## ⚠️ 前置条件

- macOS 系统
- 微信桌面版已安装并登录
- **系统设置 → 隐私与安全性 → 辅助功能** → 需授权终端（或你使用的 MCP 客户端，如 Claude Desktop、Cherry Studio 等）访问

## 功能

| Tool | 说明 | 参数 |
|------|------|------|
| `send_message` | 给联系人/群发送消息 | `msg` 消息内容, `receiver` 联系人名 |
| `send_message_current` | 在当前聊天窗口中发送消息（不搜索联系人） | `msg` 消息内容 |
| `get_recent_messages` | 获取最近聊天记录 | `who` 联系人名, `count` 条数(默认10) |
| `get_all_messages` | 同上（兼容 wxauto-mcp 命名） | `who` 联系人名, `count` 条数(默认20) |
| `check_unread` | 检查未读消息列表 | 无 |

## 安装

### 方式一：本地安装（推荐）

```bash
git clone <repo-url>
cd wxauto-mcp-macos
uv pip install .
```

安装后会注册 `wxauto-mcp-macos` 命令行工具。

### 方式二：开发模式

```bash
git clone <repo-url>
cd wxauto-mcp-macos
uv sync
```

## 配置

### Claude Desktop

在 `~/Library/Application Support/Claude/claude_desktop_config.json` 中添加：

**已安装（推荐）：**

```json
"mcpServers": {
  "wxauto-mcp-macos": {
    "command": "wxauto-mcp-macos"
  }
}
```

**开发模式：**

```json
"mcpServers": {
  "wxauto-mcp-macos": {
    "command": "uv",
    "args": [
      "--directory",
      "/path/to/wxauto-mcp-macos",
      "run",
      "wxauto_mcp.py"
    ]
  }
}
```

### Cursor

在 `~/.cursor/mcp.json` 中添加同样的配置。

### Cherry Studio / OpenClaw / 其他 MCP 客户端

在 MCP Server 配置中添加：

```json
{
  "mcpServers": {
    "wxauto-mcp-macos": {
      "command": "wxauto-mcp-macos"
    }
  }
}
```

如果使用 uvx 运行（无需安装）：

```json
{
  "mcpServers": {
    "wxauto-mcp-macos": {
      "command": "uvx",
      "args": [
        "--from",
        "/path/to/wxauto-mcp-macos",
        "wxauto-mcp-macos"
      ]
    }
  }
}
```

## 工作原理

```
MCP Client (Claude Desktop / Cursor / Cherry Studio / ...)
    ↓  MCP 协议 (stdio)
Python MCP Server (wxauto_mcp/server.py, FastMCP)
    ↓  subprocess → osascript
AppleScript (System Events / Accessibility API)
    ↓
WeChat.app UI 元素
```

### 调用流程

每次工具调用时，Server 会先执行 `_ensure_wechat_ready()`：

1. `tell application "WeChat" to activate` — 激活微信
2. `set frontmost to true` — **强制将微信窗口置顶**，防止后续键盘操作发送到其他应用（如 Cherry Studio）
3. 检查微信是否有窗口存在

之后根据具体工具执行对应操作。

### 操作方式

- **文字输入**：通过剪贴板粘贴（`pbcopy` + `⌘V`），而非逐字键入，确保中文输入法正常工作
- **UI 导航**：通过 `System Events` 发送快捷键（`⌘F` 搜索、`Enter` 确认、`Esc` 关闭浮层）
- **元素定位**：通过 Accessibility API 的 `role description` 属性定位聊天输入框（"编辑"/"edit"）
- **消息读取**：通过 `.scpt` 脚本读取窗口中的 `static text` 元素

### AppleScript 脚本文件

| 文件 | 用途 |
|------|------|
| `wechat_read_last.scpt` | 读取当前聊天窗口最近 N 条消息 |
| `wechat_check_unread.scpt` | 检测侧边栏未读消息标记 |
| `wechat_core.scpt` | 独立脚本：搜索联系人并发送消息 |
| `wechat_enter_chat.scpt` | 独立脚本：搜索并进入联系人聊天 |
| `wechat_send_now.scpt` | 独立脚本：在当前聊天窗口发送消息 |
| `wechat_debug_ui.scpt` | 调试工具：导出微信完整 Accessibility 树 |

> `wechat_core.scpt`、`wechat_enter_chat.scpt`、`wechat_send_now.scpt` 为独立可用脚本，Server 中的发送功能直接通过内联 AppleScript 实现。

## 项目结构

```
wxauto-mcp-macos/
├── pyproject.toml              # 项目配置，版本 v0.1.0
├── wxauto_mcp.py               # 开发模式入口
├── src/
│   └── wxauto_mcp/
│       ├── __init__.py
│       ├── server.py           # MCP Server 主文件（5 个工具定义）
│       └── scripts/
│           ├── __init__.py
│           ├── wechat_read_last.scpt
│           ├── wechat_check_unread.scpt
│           ├── wechat_core.scpt
│           ├── wechat_enter_chat.scpt
│           └── wechat_send_now.scpt
└── scripts/
    └── wechat_debug_ui.scpt    # 调试用（不打包）
```

## 已知限制

- 操作间隔依赖 `time.sleep()` 等待，微信动画较慢时可能失败
- 搜索联系人时默认选择第一个匹配结果，同名联系人可能选错
- 需要微信窗口可见（最小化到 Dock 的窗口可能无法操作）
- 消息读取仅限当前可见区域，无法获取历史滚动消息

## 依赖

- Python >= 3.10
- `mcp[cli]` >= 1.6.0
- macOS 自带的 `osascript`（AppleScript 运行时）
