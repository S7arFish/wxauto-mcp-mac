#!/usr/bin/env osascript
(*
 * wechat_core.scpt — 微信发消息核心脚本 (v4)
 *
 * Usage:
 *   osascript wechat_core.scpt "联系人名" "消息内容"
 *
 * v4 改进：
 *   - 增加顶层错误处理
 *   - 激活后检查微信窗口是否存在
 *   - 聊天输入框识别增加英文 "edit" fallback
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

		-- 检查微信是否有窗口
		tell application "System Events" to tell process "WeChat"
			if (count of windows) = 0 then
				return "ERROR: 微信未打开或无窗口"
			end if
		end tell

		-- ── 2. 打开搜索框 (Cmd+N) ──
		tell application "System Events" to tell process "WeChat"
			keystroke "n" using {command down}
		end tell
		delay 1.5 -- 等搜索框完全弹出

		-- 用 accessibility 找到搜索文本框并点击（确保焦点在这里）
		set searchClicked to my clickSearchField()
		if not searchClicked then
			return "ERROR: 找不到搜索框"
		end if
		delay 0.3

		-- ── 3. 清空 + 输入联系人名 ──
		tell application "System Events" to tell process "WeChat"
			keystroke "a" using {command down}
			delay 0.2
			key code 51 -- delete
			delay 0.3
		end tell
		delay 0.3

		-- keystroke 逐字输入
		tell application "System Events" to tell process "WeChat"
			keystroke contactName
		end tell

		-- ★ 等搜索结果加载（微信需要 3-4 秒）
		delay 3.5

		-- ── 4. ↓ + Enter 进入聊天（最多 3 次重试）──
		set chatEntered to false
		repeat with i from 1 to 3
			-- ↓ 选择搜索结果第一条
			tell application "System Events" to tell process "WeChat"
				keystroke (key code 125) -- ↓
			end tell
			delay 0.6

			-- Enter 进入
			tell application "System Events" to tell process "WeChat"
				keystroke (key code 36) -- ↵
			end tell
			delay 1.5 -- 等聊天窗口加载

			-- 检测是否进入成功
			set stillSearching to my isSearchBoxVisible()
			if not stillSearching then
				set chatEntered to true
				exit repeat
			end if

			-- 失败 → Esc 关闭浮层，重新搜索
			tell application "System Events" to tell process "WeChat"
				key code 53 -- Esc
			end tell
			delay 0.8

			-- 重新打开搜索
			tell application "System Events" to tell process "WeChat"
				keystroke "n" using {command down}
			end tell
			delay 1.5

			-- 用 accessibility 找到搜索框
			set searchClicked to my clickSearchField()
			if not searchClicked then
				delay 0.5
				-- fallback: 再按一次 Cmd+N
				tell application "System Events" to tell process "WeChat"
					keystroke "n" using {command down}
				end tell
				delay 1.0
				set searchClicked to my clickSearchField()
			end if
			delay 0.3

			-- 清空并重新输入
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
			delay 3.0
		end repeat

		if not chatEntered then
			return "ERROR: 无法进入与 " & contactName & " 的聊天（重试 3 次失败）"
		end if

		-- ── 5. 确保焦点在聊天输入框 ──
		-- 先按 Esc 清除可能残留的搜索浮层
		tell application "System Events" to tell process "WeChat"
			key code 53 -- Esc
		end tell
		delay 0.5

		-- 用 accessibility 找到聊天输入框并点击（支持中英文 locale）
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
		delay 0.4

		-- ── 6. 清空输入区 + 发消息 ──
		tell application "System Events" to tell process "WeChat"
			keystroke "a" using {command down}
			delay 0.2
			key code 51 -- delete
			delay 0.3
		end tell
		delay 0.2

		-- 用 clipboard 粘贴消息内容
		set the clipboard to messageText
		delay 0.2
		tell application "System Events" to tell process "WeChat"
			keystroke "v" using {command down}
		end tell
		delay 0.6 -- 等粘贴完成

		-- Enter 发送
		tell application "System Events" to tell process "WeChat"
			keystroke (key code 36) -- ↵
		end tell
		delay 0.3

		return "OK: 已向 " & contactName & " 发送消息"

	on error errMsg
		return "ERROR: " & errMsg
	end try
end run


(* ══════════════════════════════════════════════
   Helper functions
   ══════════════════════════════════════════════ *)

(* 用 accessibility 精确找到并点击搜索文本框 *)
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

(* 检查搜索框是否还可见 *)
on isSearchBoxVisible()
	try
		tell application "System Events" to tell process "WeChat"
			set searchFields to every text field of every window
			repeat with tf in searchFields
				try
					if role description of tf contains "搜索" then return true
					set myRoleDesc to role description of tf
					if myRoleDesc contains "search" then return true
				end try
			end repeat
		end tell
	end try
	return false
end isSearchBoxVisible

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
