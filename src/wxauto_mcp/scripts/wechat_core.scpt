#!/usr/bin/env osascript
(*
 * wechat_core.scpt — 微信发消息核心脚本 (v7)
 *
 * Usage:
 *   osascript wechat_core.scpt "联系人名" "消息内容"
 *
 * v7: 拆分 accessibility 和 keystroke 为独立步骤，避免冲突
 *)

on run argv
	if (count of argv) < 2 then
		return "ERROR: 用法: osascript wechat_core.scpt \"联系人\" \"消息\""
	end if

	set contactName to item 1 of argv
	set messageText to item 2 of argv

	try
		-- ── 1. 激活微信 ──
		tell application "WeChat" to activate
		my waitFor("WeChat", 3)
		delay 0.5

		tell application "System Events" to tell process "WeChat"
			if (count of windows) = 0 then
				return "ERROR: 微信未打开或无窗口"
			end if
		end tell

		-- ── 2. 打开搜索 + 粘贴联系人名 ──
		set the clipboard to contactName
		delay 0.1

		tell application "System Events" to tell process "WeChat"
			keystroke "f" using {command down}
		end tell
		delay 1.0

		tell application "System Events" to tell process "WeChat"
			keystroke "v" using {command down}
		end tell
		delay 0.5

		-- 等搜索结果加载
		delay 3.5

		-- ── 3. Enter 选中搜索结果进入聊天 ──
		tell application "System Events" to tell process "WeChat"
			keystroke (key code 36) -- ↵
		end tell
		delay 2.0

		-- Esc 清除残留浮层
		tell application "System Events" to tell process "WeChat"
			key code 53 -- Esc
		end tell
		delay 0.5

		-- ── 4. 用 accessibility 找到聊天输入框并点击（单独步骤）──
		set inputFound to false
		tell application "System Events" to tell process "WeChat"
			try
				set chatInputs to every text area of window 1
				repeat with ci in chatInputs
					try
						set myRoleDesc to role description of ci
						if myRoleDesc contains "编辑" or myRoleDesc contains "edit" then
							set focused of ci to true
							click ci
							set inputFound to true
							exit repeat
						end if
					end try
				end repeat
			end try
		end tell

		if not inputFound then
			-- fallback: 用 Tab 切到输入框
			tell application "System Events" to tell process "WeChat"
				keystroke (key code 48) -- Tab
			end tell
			delay 0.3
		end if
		delay 0.5

		-- ── 5. 粘贴消息 + 发送（纯 keystroke，独立步骤）──
		set the clipboard to messageText
		delay 0.2

		tell application "System Events" to tell process "WeChat"
			keystroke "a" using {command down}
		end tell
		delay 0.2

		tell application "System Events" to tell process "WeChat"
			key code 51 -- delete
		end tell
		delay 0.3

		tell application "System Events" to tell process "WeChat"
			keystroke "v" using {command down}
		end tell
		delay 0.8

		tell application "System Events" to tell process "WeChat"
			keystroke (key code 36) -- ↵
		end tell
		delay 0.3

		return "OK: 已向 " & contactName & " 发送消息"

	on error errMsg
		return "ERROR: " & errMsg
	end try
end run


(* 等待进程就绪 *)
on waitFor(procName, maxSec)
	repeat (maxSec * 10) times
		delay 0.1
		tell application "System Events"
			if (count of (every process whose name is procName)) > 0 then return true
		end tell
	end repeat
	return false
end waitFor
