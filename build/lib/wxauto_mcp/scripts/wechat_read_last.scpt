#!/usr/bin/env osascript
(*
 * wechat_read_last.scpt (v2)
 *
 * 读取当前微信聊天窗口的最后几条可见消息
 * v2: 增加微信窗口检查
 *
 * Usage:
 *   osascript wechat_read_last.scpt [条数]
 *
 * 注意：
 *   - 必须已经在某个聊天里
 *   - 返回的是消息区域可见的文本
 *   - 微信的消息气泡不一定暴露为独立 accessibility 元素，
 *     所以这里读取整个消息区域的文本内容
 *)

on run argv
	set maxMsgs to 5
	if (count of argv) > 0 then
		try
			set maxMsgs to (item 1 of argv) as number
		end try
	end if

	tell application "WeChat" to activate
	delay 0.3

	-- 检查微信是否有窗口
	tell application "System Events" to tell process "WeChat"
		if (count of windows) = 0 then
			return "ERROR: 微信未打开或无窗口"
		end if
	end tell

	set msgText to ""

	try
		tell application "System Events" to tell process "WeChat"
			-- 微信聊天内容区域通常在 window 的 scroll area 里
			-- 消息气泡的文本在 static text 元素中
			set w to window 1
			set allText to {}

			-- 方式1: 读取所有 static text（包含消息气泡文本）
			try
				set txtList to every static text of w
				repeat with sTxt in txtList
					try
						set t to value of sTxt
						if t is not "" and (length of t) > 1 then
							set end of allText to t
						end if
					end try
				end repeat
			end try

			-- 方式2: 如果 static text 没拿到，试试 group 里的 text
			if (count of allText) = 0 then
				try
					set grpTxtList to every text of every group of w
					repeat with gTxt in grpTxtList
						try
							set t to value of gTxt
							if t is not "" then
								set end of allText to t
							end if
						end try
					end repeat
				end try
			end if

			-- 取最后 maxMsgs 条
			set n to count of allText
			if n > maxMsgs then
				set allText to items (-(maxMsgs)) thru -1 of allText
			end if
		end tell

		set {TID, text item delimiters} to {text item delimiters, linefeed}
		set msgText to allText as text
		set text item delimiters to TID

	on error errMsg
		return "ERROR: " & errMsg
	end try

	if msgText is "" then
		return "ERROR: 无法读取消息内容（可能不在聊天窗口中）"
	end if

	return msgText
end run
