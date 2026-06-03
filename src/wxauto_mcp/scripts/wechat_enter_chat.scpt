#!/usr/bin/env osascript
(*
 * wechat_enter_chat.scpt (v6)
 *
 * 搜索并进入指定联系人/群的聊天（不发消息）
 * v6: 修复 keystroke 时序问题，合并 tell 块；联系人名走剪贴板
 *
 * Usage:
 *   osascript wechat_enter_chat.scpt "联系人名"
 *)

on run argv
	if (count of argv) < 1 then
		return "ERROR: 用法: osascript wechat_enter_chat.scpt \"联系人\""
	end if

	set contactName to item 1 of argv

	try
		tell application "WeChat" to activate
		delay 0.8

		tell application "System Events" to tell process "WeChat"
			if (count of windows) = 0 then
				return "ERROR: 微信未打开或无窗口"
			end if
		end tell

		-- 打开搜索 + 粘贴联系人名
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

		-- 等搜索结果
		delay 3.5

		-- Enter 选中搜索结果进入聊天
		tell application "System Events" to tell process "WeChat"
			keystroke (key code 36) -- ↵
		end tell
		delay 1.5

		-- Esc 清除残留浮层
		tell application "System Events" to tell process "WeChat"
			key code 53 -- Esc
		end tell
		delay 0.5

		return "OK: 已进入与 " & contactName & " 的聊天"

	on error errMsg
		return "ERROR: " & errMsg
	end try
end run
