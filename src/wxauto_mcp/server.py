import subprocess
import time
from pathlib import Path

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("wxauto_mcp_macos")

SCRIPTS_DIR = Path(__file__).parent / "scripts"
OSASCRIPT_TIMEOUT = 10  # seconds per small step


def _run_osascript(*lines: str) -> str:
    """Run AppleScript code (one or more -e lines) and return stdout."""
    cmd = ["osascript"]
    for line in lines:
        cmd += ["-e", line]
    result = subprocess.run(
        cmd, capture_output=True, text=True, timeout=OSASCRIPT_TIMEOUT
    )
    output = result.stdout.strip()
    if result.returncode != 0:
        raise RuntimeError(output or result.stderr.strip())
    return output


def _run_script(script_name: str, *args: str) -> str:
    """Run a .scpt file and return its stdout."""
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


def _keystroke(key_code: int):
    """Send a single key press via osascript."""
    _run_osascript(
        'tell application "System Events"',
        f"    key code {key_code}",
        "end tell",
    )


def _keystroke_with_mod(key: str, *modifiers: str):
    """Send a key with modifiers (e.g. 'f' with command down)."""
    mod_str = ", ".join(modifiers)
    _run_osascript(
        'tell application "System Events"',
        f'    keystroke "{key}" using {{{mod_str}}}',
        "end tell",
    )


def _ensure_wechat_ready():
    """Activate WeChat and verify it has a window."""
    _run_osascript(
        'tell application "WeChat" to activate',
    )
    time.sleep(0.3)
    # 强制将微信窗口置顶，防止后续按键发送到其他应用
    _run_osascript(
        'tell application "System Events" to tell process "WeChat"',
        "    set frontmost to true",
        "end tell",
    )
    time.sleep(0.3)
    out = _run_osascript(
        'tell application "System Events" to tell process "WeChat"',
        "    return count of windows",
        "end tell",
    )
    if out.strip() == "0":
        raise RuntimeError("微信未打开或无窗口")


def _click_chat_input():
    """Use accessibility to find and click the chat input text area."""
    _run_osascript(
        'tell application "System Events" to tell process "WeChat"',
        "    set inputFound to false",
        "    try",
        "        set chatInputs to every text area of window 1",
        "        repeat with ci in chatInputs",
        "            try",
        "                set myRoleDesc to role description of ci",
        '                if myRoleDesc contains "编辑" or myRoleDesc contains "edit" then',
        "                    set focused of ci to true",
        "                    click ci",
        "                    set inputFound to true",
        "                    exit repeat",
        "                end if",
        "            end try",
        "        end repeat",
        "    end try",
        "    return inputFound",
        "end tell",
    )


@mcp.tool(name="send_message", description="给微信联系人或群组发送消息")
def send_message(msg: str, receiver: str):
    """搜索联系人并发送消息。receiver: 联系人/群名, msg: 消息内容。"""
    # 1. 激活微信
    _ensure_wechat_ready()

    # 2. 搜索联系人（用剪贴板粘贴）
    subprocess.run(["pbcopy"], input=receiver.encode(), check=True)
    time.sleep(0.1)

    _keystroke_with_mod("f", "command down")
    time.sleep(1.0)
    _keystroke_with_mod("v", "command down")
    time.sleep(0.5)

    # 3. 等搜索结果 + Enter 选中
    time.sleep(3.5)
    _keystroke(36)  # Enter
    time.sleep(2.0)

    # 4. Esc 清除残留浮层
    _keystroke(53)  # Esc
    time.sleep(0.5)

    # 5. 点击聊天输入框
    _click_chat_input()
    time.sleep(0.5)

    # 6. 粘贴消息并发送
    subprocess.run(["pbcopy"], input=msg.encode(), check=True)
    time.sleep(0.2)

    _keystroke_with_mod("v", "command down")
    time.sleep(0.8)
    _keystroke(36)  # Enter

    return f"OK: 已向 {receiver} 发送消息"


@mcp.tool(
    name="send_message_current",
    description="在当前已打开的聊天窗口中发送消息（不搜索联系人）",
)
def send_message_current(msg: str):
    """前提：必须已经在某个聊天窗口中。"""
    _ensure_wechat_ready()

    # Esc 清除残留浮层
    _keystroke(53)
    time.sleep(0.5)
    _keystroke(53)
    time.sleep(0.3)

    # 点击聊天输入框
    _click_chat_input()
    time.sleep(0.5)

    # 粘贴消息并发送
    subprocess.run(["pbcopy"], input=msg.encode(), check=True)
    time.sleep(0.2)

    _keystroke_with_mod("v", "command down")
    time.sleep(0.8)
    _keystroke(36)  # Enter

    return "OK: 消息已发送"


@mcp.tool(name="get_recent_messages", description="获取与某人的最近聊天记录")
def get_recent_messages(who: str, count: int = 10):
    """先搜索进入聊天，再读取最近 count 条消息。"""
    # 1. 搜索并进入聊天
    _ensure_wechat_ready()

    subprocess.run(["pbcopy"], input=who.encode(), check=True)
    time.sleep(0.1)

    _keystroke_with_mod("f", "command down")
    time.sleep(1.0)
    _keystroke_with_mod("v", "command down")
    time.sleep(0.5)

    time.sleep(3.5)
    _keystroke(36)  # Enter
    time.sleep(2.0)
    _keystroke(53)  # Esc
    time.sleep(0.5)

    # 2. 读取消息
    raw = _run_script("wechat_read_last.scpt", str(count))
    messages = [line for line in raw.split("\n") if line.strip()]
    return [{"sender": who, "content": m} for m in messages]


@mcp.tool(
    name="get_all_messages",
    description="获取与某人的聊天记录（兼容 wxauto-mcp 命名）",
)
def get_all_messages(who: str, count: int = 20):
    """与 get_recent_messages 功能相同，命名兼容 wxauto-mcp。"""
    return get_recent_messages(who, count)


@mcp.tool(name="check_unread", description="检查微信是否有未读消息")
def check_unread():
    """返回有未读标记的对话列表。无未读返回空列表。"""
    raw = _run_script("wechat_check_unread.scpt")
    if not raw:
        return []
    raw = raw.removeprefix("UNREAD: ")
    return [name.strip() for name in raw.split("\n") if name.strip()]


def main():
    mcp.run()


if __name__ == "__main__":
    main()
