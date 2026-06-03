#!/usr/bin/env osascript
(*
 * wechat_send_now.scpt (v3)
 *
 * 在当前已打开的聊天中直接发送消息（不搜索、不进入）
 * v3: 增加顶层错误处理、微信窗口检查、英文 locale 兼容
 *
 * Usage:
 *   osascript wechat_send_now.scpt "消息内容"
 *
 * 前提：必须已经在某个聊天窗口里
 *)

on run argv
	if (count of argv) < 1 then
		return "ERROR: 用法: osascript wechat_send_now.scpt \"消息\""
	end if

	set messageText to item 1 of argv

	try
		tell application "WeChat" to activate
		delay 0.4

		-- 检查微信是否有窗口
		tell application "System Events" to tell process "WeChat"
			if (count of windows) = 0 then
				return "ERROR: 微信未打开或无窗口"
			end if
		end tell

		-- Esc 清除可能残留的搜索浮层
		tell application "System Events" to tell process "WeChat"
			key code 53 -- Esc
		end tell
		delay 0.5

		-- 再按一次 Esc 确保浮层关闭
		tell application "System Events" to tell process "WeChat"
			key code 53 -- Esc
		end tell
		delay 0.3

		-- 找到聊天输入框并点击（支持中英文 locale）
		tell application "System Events" to tell process "WeChat"
			set inputFound to false
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

			if not inputFound then
				keystroke (key code 48) -- Tab
				delay 0.2
			end if
		end tell
		delay 0.3

		-- 清空输入区
		tell application "System Events" to tell process "WeChat"
			keystroke "a" using {command down}
			delay 0.2
			key code 51 -- delete
			delay 0.2
		end tell
		delay 0.2

		-- 粘贴消息
		set the clipboard to messageText
		delay 0.15

		tell application "System Events" to tell process "WeChat"
			keystroke "v" using {command down}
		end tell
		delay 0.5 -- 等粘贴完成

		-- Enter 发送
		tell application "System Events" to tell process "WeChat"
			keystroke (key code 36) -- ↵
		end tell
		delay 0.3

		return "OK: 消息已发送"

	on error errMsg
		return "ERROR: " & errMsg
	end try
end run
