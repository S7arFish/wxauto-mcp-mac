#!/usr/bin/env osascript
(*
 * wechat_enter_chat.scpt (v4)
 *
 * 搜索并进入指定联系人/群的聊天（不发消息）
 * v4: 增加顶层错误处理、微信窗口检查
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

		-- 检查微信是否有窗口
		tell application "System Events" to tell process "WeChat"
			if (count of windows) = 0 then
				return "ERROR: 微信未打开或无窗口"
			end if
		end tell

		-- 打开搜索
		tell application "System Events" to tell process "WeChat"
			keystroke "n" using {command down}
		end tell
		delay 1.5

		-- 用 accessibility 点击搜索框
		set searchClicked to my clickSearchField()
		if not searchClicked then
			return "ERROR: 找不到搜索框"
		end if
		delay 0.3

		-- 清空 + keystroke 输入
		tell application "System Events" to tell process "WeChat"
			keystroke "a" using {command down}
			delay 0.2
			key code 51 -- delete
			delay 0.3
		end tell
		delay 0.3

		tell application "System Events" to tell process "WeChat"
			keystroke contactName
		end tell

		-- 等搜索结果
		delay 3.5

		-- ↓ + Enter（最多 3 次重试）
		repeat 3 times
			tell application "System Events" to tell process "WeChat"
				keystroke (key code 125) -- ↓
			end tell
			delay 0.6

			tell application "System Events" to tell process "WeChat"
				keystroke (key code 36) -- ↵
			end tell
			delay 1.5

			-- 检查搜索框是否消失
			set stillSearching to my isSearchBoxVisible()

			if not stillSearching then
				return "OK: 已进入与 " & contactName & " 的聊天"
			end if

			-- 重试
			tell application "System Events" to tell process "WeChat"
				key code 53 -- Esc
			end tell
			delay 0.8

			tell application "System Events" to tell process "WeChat"
				keystroke "n" using {command down}
			end tell
			delay 1.5

			set searchClicked to my clickSearchField()
			delay 0.3

			tell application "System Events" to tell process "WeChat"
				keystroke "a" using {command down}
				delay 0.2
				key code 51
				delay 0.3
			end tell
			delay 0.3
			tell application "System Events" to tell process "WeChat"
				keystroke contactName
			end tell
			delay 3.0
		end repeat

		return "ERROR: 无法进入与 " & contactName & " 的聊天"

	on error errMsg
		return "ERROR: " & errMsg
	end try
end run


on clickSearchField()
	try
		tell application "System Events" to tell process "WeChat"
			set allWins to every window
			repeat with w in allWins
				try
					set allTF to every text field of w
					repeat with tf in allTF
						try
							set myRoleDesc to role description of tf
							if myRoleDesc contains "搜索" or myRoleDesc contains "search" then
								set focused of tf to true
								click tf
								return true
							end if
						end try
					end repeat
				end try
			end repeat
		end tell
	end try
	return false
end clickSearchField


on isSearchBoxVisible()
	try
		tell application "System Events" to tell process "WeChat"
			set allWins to every window
			repeat with w in allWins
				try
					set allTF to every text field of w
					repeat with tf in allTF
						try
							set myRoleDesc to role description of tf
							if myRoleDesc contains "搜索" then return true
							if myRoleDesc contains "search" then return true
						end try
					end repeat
				end try
			end repeat
		end tell
	end try
	return false
end isSearchBoxVisible
