#!/usr/bin/env osascript
(*
 * wechat_check_unread.scpt (v2)
 *
 * 检查微信是否有未读消息
 * v2: 增加顶层错误处理、微信窗口检查
 *
 * Usage:
 *   osascript wechat_check_unread.scpt
 *
 * 返回：
 *   有未读 → "UNREAD: N 条未读" 或具体对话名
 *   无未读 → "" (空字符串)
 *)

on run
	try
		tell application "WeChat" to activate
		delay 0.6

		-- 检查微信是否有窗口
		tell application "System Events" to tell process "WeChat"
			if (count of windows) = 0 then
				return "ERROR: 微信未打开或无窗口"
			end if
		end tell

		-- 先按 Cmd+1 切到聊天列表
		tell application "System Events" to tell process "WeChat"
			keystroke "1" using {command down}
		end tell
		delay 0.5

		-- 遍历 accessibility tree 寻找未读标记
		-- 微信未读会在对话列表 row 旁边显示一个数字 badge（通常是 static text）
		set unreadList to {}
		tell application "System Events" to tell process "WeChat"
			set allWins to every window
			repeat with w in allWins
				try
					set txtElems to every static text of w
					repeat with txtElem in txtElems
						try
							set elemVal to value of txtElem as text
							-- 未读数通常是 1~999 的纯数字
							set numTest to elemVal as number
							if numTest > 0 and numTest < 1000 then
								-- 尝试获取父元素名
								set elemName to ""
								try
									set elemName to description of txtElem as text
								end try
								if elemName is "" then
									set elemName to elemVal as text
								end if
								if elemName is not in unreadList then
									set end of unreadList to elemName
								end if
							end if
						end try
					end repeat
				end try
			end repeat
		end tell

		if (count of unreadList) > 0 then
			set {TID, text item delimiters} to {text item delimiters, linefeed}
			set resultText to unreadList as text
			set text item delimiters to TID
			return "UNREAD: " & resultText
		end if

		return ""

	on error errMsg
		return "ERROR: " & errMsg
	end try
end run
