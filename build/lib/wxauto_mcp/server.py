import subprocess
from pathlib import Path

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("wxauto_mcp_macos")

SCRIPTS_DIR = Path(__file__).parent / "scripts"
OSASCRIPT_TIMEOUT = 60  # seconds


def _run_applescript(script_name: str, *args: str) -> str:
    """Run an AppleScript file and return its stdout."""
    script_path = str(SCRIPTS_DIR / script_name)
    result = subprocess.run(
        ["osascript", script_path, *args],
        capture_output=True,
        text=True,
        timeout=OSASCRIPT_TIMEOUT,
    )
    output = result.stdout.strip()
    if result.returncode != 0 or output.startswith("ERROR"):
        raise RuntimeError(output or result.stderr.strip())
    return output


@mcp.tool(name="send_message", description="给微信联系人或群组发送消息")
def send_message(msg: str, to: str):
    """搜索联系人并发送消息。to: 联系人/群名, msg: 消息内容。"""
    return _run_applescript("wechat_core.scpt", to, msg)


@mcp.tool(name="send_message_current", description="在当前已打开的聊天窗口中发送消息（不搜索联系人）")
def send_message_current(msg: str):
    """前提：必须已经在某个聊天窗口中。"""
    return _run_applescript("wechat_send_now.scpt", msg)


@mcp.tool(name="get_recent_messages", description="获取与某人的最近聊天记录")
def get_recent_messages(who: str, count: int = 10):
    """先搜索进入聊天，再读取最近 count 条消息。"""
    _run_applescript("wechat_enter_chat.scpt", who)
    raw = _run_applescript("wechat_read_last.scpt", str(count))
    # 脚本返回按换行分隔的文本
    messages = [line for line in raw.split("\n") if line.strip()]
    return [{"sender": who, "content": m} for m in messages]


@mcp.tool(name="get_all_messages", description="获取与某人的聊天记录（兼容 wxauto-mcp 命名）")
def get_all_messages(who: str, count: int = 20):
    """与 get_recent_messages 功能相同，命名兼容 wxauto-mcp。"""
    return get_recent_messages(who, count)


@mcp.tool(name="check_unread", description="检查微信是否有未读消息")
def check_unread():
    """返回有未读标记的对话列表。无未读返回空列表。"""
    raw = _run_applescript("wechat_check_unread.scpt")
    if not raw:
        return []
    # 脚本返回 "UNREAD: 张三\n李四" 或空字符串
    raw = raw.removeprefix("UNREAD: ")
    return [name.strip() for name in raw.split("\n") if name.strip()]


def main():
    mcp.run()


if __name__ == "__main__":
    main()
