#!/usr/bin/env osascript
(*
 * wechat_debug_ui.scpt — 探测微信窗口所有 UI 元素
 *
 * 先手动打开微信，然后执行:
 *   osascript wechat_debug_ui.scpt
 *)

property gOutput : ""

on clearOutput()
	set gOutput to ""
end clearOutput

on appendOutput(txt)
	set gOutput to gOutput & txt & linefeed
end appendOutput

on dumpElement(elem, depth)
	set indent to ""
	repeat depth times
		set indent to indent & "  "
	end repeat

	try
		set elemRole to ""
		set elemRoleDesc to ""
		set elemDesc to ""
		set elemVal to ""
		set elemTitle to ""

		try
			set elemRole to role of elem as text
		on error
			set elemRole to "?"
		end try
		try
			set elemRoleDesc to role description of elem as text
		on error
			set elemRoleDesc to "?"
		end try
		try
			set elemDesc to description of elem as text
		on error
			set elemDesc to "?"
		end try
		try
			set elemVal to value of elem as text
			if (count of elemVal) > 60 then
				set elemVal to text 1 thru 60 of elemVal & "..."
			end if
		on error
			set elemVal to "?"
		end try
		try
			set elemTitle to title of elem as text
		on error
			set elemTitle to "?"
		end try

		my appendOutput(indent & "[role=" & elemRole & "] [roleDesc=" & elemRoleDesc & "] [desc=" & elemDesc & "] [value=" & elemVal & "] [title=" & elemTitle & "]")

		-- 递归子元素
		try
			set kids to UI elements of elem
			repeat with k in kids
				my dumpElement(k, depth + 1)
			end repeat
		end try
	end try
end dumpElement

-- 主流程
on run
	my clearOutput()

	tell application "WeChat" to activate
	delay 1

	-- 阶段 1: 当前状态
	my appendOutput("===== 阶段 1: 当前窗口（未按 Cmd+F）=====")

	tell application "System Events" to tell process "WeChat"
		set wc to count of windows
		my appendOutput("窗口数量: " & wc)

		repeat with wi from 1 to wc
			set w to window wi
			my appendOutput("")
			my appendOutput("--- 窗口 " & wi & ": " & (name of w) & " ---")
			my dumpElement(w, 0)
		end repeat
	end tell

	-- 阶段 2: 按 Cmd+F 之后
	my appendOutput("")
	my appendOutput("===== 阶段 2: 按 Cmd+N 之后 =====")

	tell application "System Events" to tell process "WeChat"
		keystroke "f" using {command down}
	end tell
	delay 2

	tell application "System Events" to tell process "WeChat"
		set wc to count of windows
		my appendOutput("窗口数量: " & wc)

		repeat with wi from 1 to wc
			set w to window wi
			my appendOutput("")
			my appendOutput("--- 窗口 " & wi & ": " & (name of w) & " ---")
			my dumpElement(w, 0)
		end repeat
	end tell

	-- 关闭搜索
	tell application "System Events" to tell process "WeChat"
		key code 53
	end tell

	return gOutput
end run
