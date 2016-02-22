(*
Resize Window - Resize the front window of any application

@version @@VERSION@@
@date @@RELEASE_DATE@@
@author Steve Wheeler

This program is free software available under the terms of a BSD-style
(3-clause) open source license detailed below.
*)

(*
Copyright (c) 2014-2016 Steve Wheeler
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the copyright holder nor the names of
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)

property __SCRIPT_NAME__ : "Resize Window"
property __SCRIPT_VERSION__ : "@@VERSION@@"
property __SCRIPT_AUTHOR__ : "Steve Wheeler"
property __SCRIPT_COPYRIGHT__ : "Copyright © 2014Ð2016 " & __SCRIPT_AUTHOR__
property __SCRIPT_WEBSITE__ : "http://jazzheaddesign.com/work/code/resize-window/"
property __SCRIPT_LICENSE_SUMMARY__ : "This program is free software available under the terms of a BSD-style (3-clause) open source license. Click the \"License\" button or see the README file included with the distribution for details."
property __SCRIPT_LICENSE__ : __SCRIPT_COPYRIGHT__ & return & "All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  ¥ Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

  ¥ Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

  ¥ Neither the name of the copyright holder nor the names of contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."

(* ==== Initializations ==== *)

global dialog_title, size_adjustment_list, custom_choice, size_list, mac_menu_bar

set dialog_title to __SCRIPT_NAME__
set size_adjustment_list to {"Width + 1px", "Width - 1px", "Width + 10px", "Width - 10px"}
set custom_choice to "Custom sizeÉ"
set mac_menu_bar to 23 -- 22px menu plus 1px bottom border

set u_dash to Çdata utxt2500È as Unicode text -- BOX DRAWINGS LIGHT HORIZONTAL
set menu_rule to my multiply_text(u_dash, 21)

set mobile_sizes to paragraphs of "320x480		iPhone 4 Ñ Portrait (2x)
480x320		iPhone 4 Ñ Landscape (2x)
320x568		iPhone 5 Ñ Portrait (2x)
568x320		iPhone 5 Ñ Landscape (2x)
375x667		iPhone 6 Ñ Portrait (2x)
667x375		iPhone 6 Ñ Landscape (2x)
414x736		iPhone 6 Plus Ñ Portrait (3x)
736x414		iPhone 6 Plus Ñ Landscape (3x)
768x1024	iPad Ñ Portrait (2x)
1024x768	iPad Ñ Landscape (2x)"

set desktop_sizes to paragraphs of "640x480		VGA (4:3)
800x600		SVGA (4:3)
1024x768	XGA (4:3)
1280x800	WXGA (16:10)
1366x768	WXGA (16:9)"

set size_list to mobile_sizes & Â
	menu_rule & Â
	desktop_sizes & Â
	menu_rule & Â
	size_adjustment_list & Â
	custom_choice & Â
	menu_rule & Â
	"Show front window size" & Â
	("About " & __SCRIPT_NAME__)


(* ==== Main ==== *)

set current_app to get_front_app_name()

-- Prompt for desired window size
set m to "Choose a size for " & current_app & "'s front window:"
repeat -- until a horizontal rule is not selected
	set size_choice to choose from list size_list default items {size_list's item 14} with title dialog_title with prompt m
	if size_choice as string is not menu_rule then
		exit repeat
	else
		display alert "Invalid selection" message "Try again." as warning
	end if
end repeat
if size_choice is false then error number -128 -- User canceled
set size_choice to size_choice as string

-- Get current window size
tell application current_app
	set {win_left, win_top, win_right, win_bottom} to bounds of window 1
	set cur_width to win_right - win_left
	set cur_height to win_bottom - win_top
end tell

-- Handle user choice
set size_choice to handle_user_action(size_choice, cur_width, cur_height, current_app, {win_left, win_top, win_right, win_bottom})
if size_choice is false then return

-- Parse and validate size choice
set {new_width, new_height} to validate_window_size(size_choice)

-- Check for size adjustments
set {is_width_only, should_subtract_mac_menu} to which_dimensions()


-- Calculate new window size
set win_right to win_left + new_width

if not is_width_only then
	set win_bottom to win_top + new_height
	if should_subtract_mac_menu then
		set win_bottom to win_bottom - mac_menu_bar
	end if
end if


-- Resize window
tell application current_app
	set bounds of window 1 to {win_left, win_top, win_right, win_bottom}
end tell


(* ==== Subroutines ==== *)

on error_with_alert(txt, msg)
	display alert txt message msg as critical buttons {"Cancel"} default button 1
	error number -128 -- User canceled
end error_with_alert

on get_front_app_name()
	tell application "System Events"
		
		-- Ignore (Apple)Script Editor and Terminal when getting the front app
		-- name since most of the time they will just be used during
		-- development and testing to run the script.
		repeat 10 times -- limit repetitions just in case
			set frontmost_process to first process where it is frontmost
			if short name of frontmost_process is in {"Script Editor", "AppleScript Editor", "Terminal"} then
				set original_process to frontmost_process
				set visible of original_process to false
				repeat while (original_process is frontmost)
					delay 0.2
				end repeat
			else
				exit repeat
			end if
		end repeat
		set current_app to short name of frontmost_process
		try -- if we hid a process
			set frontmost of original_process to true -- return orginal app to front
		end try
	end tell
	return current_app
end get_front_app_name

on handle_user_action(size_choice, cur_width, cur_height, current_app, win_bounds)
	set {win_left, win_top, win_right, win_bottom} to win_bounds
	if size_choice is size_list's last item then
		set t to __SCRIPT_NAME__
		set b to {"License", "Website", "OK"}
		set m to Â
			"Resize the front window of any application." & return & return Â
			& "Version " & __SCRIPT_VERSION__ & return & return & return & return Â
			& __SCRIPT_COPYRIGHT__ & return & return Â
			& __SCRIPT_LICENSE_SUMMARY__ & return
		display alert t message m buttons b default button 3
		set btn_choice to button returned of result
		if btn_choice is b's item 1 then
			display alert t message __SCRIPT_LICENSE__
		else if btn_choice is b's item 2 then
			open location __SCRIPT_WEBSITE__
		end if
		return false
	else if size_choice is size_list's item -2 then
		set m to cur_width & "x" & cur_height as text
		display alert current_app & " front window size" message m buttons {"OK"} default button 1
		return false
	else if size_choice is custom_choice then
		set m to "Type in a custom width and height separated by an \"x\":"
		display dialog m with title dialog_title default answer "1024x768"
		set size_choice to text returned of result
	else if size_choice is in size_adjustment_list then
		-- Currently we're only adjusting the width, so no need for specific variables
		if size_choice is size_adjustment_list's item 1 then
			set size_adjustment to 1
		else if size_choice is size_adjustment_list's item 2 then
			set size_adjustment to -1
		else if size_choice is size_adjustment_list's item 3 then
			set size_adjustment to 10
		else
			set size_adjustment to -10
		end if
		set win_right to win_right + size_adjustment
		tell application current_app to set bounds of window 1 to {win_left, win_top, win_right, win_bottom}
		return false
	end if
	return size_choice
end handle_user_action

on validate_window_size(size_choice)
	set msg to "Window size should be formatted as WIDTHxHEIGHT (separated by a lowercase \"x\")."
	
	try
		set size_choice to split_text(size_choice, tab)'s first item
		set {new_width, new_height} to split_text(size_choice, "x")
	on error
		set txt to "Invalid window size"
		error_with_alert(txt, msg)
	end try
	
	if new_width is "" or new_height is "" then
		set txt to "Invalid width and/or height"
		error_with_alert(txt, msg)
	end if
	
	try
		new_width as integer
		new_height as integer
	on error
		set txt to "Invalid width and/or height"
		set msg to "Width and height must be integers."
		error_with_alert(txt, msg)
	end try
	
	return {new_width, new_height}
end validate_window_size

on which_dimensions()
	local dimension_choice, m, b
	set m to "Resize both the window's width and height or just the width?"
	set b to {"Cancel", "Width & Height", "Width-only"}
	display dialog m with title dialog_title buttons b default button 3
	set dimension_choice to button returned of result
	if dimension_choice is b's item 3 then
		set is_width_only to true
	else
		set is_width_only to false
	end if
	
	set should_subtract_mac_menu to false
	if not is_width_only then
		set m to "Subtract Mac Menu Bar height (" & mac_menu_bar & "px)?"
		set b to {"Cancel", "Subtract Mac Menu Bar", "Don't Subtract"}
		display dialog m with title dialog_title buttons b default button 3
		set mac_menu_choice to button returned of result
		if mac_menu_choice is b's item 2 then
			set should_subtract_mac_menu to true
		end if
	end if
	
	return {is_width_only, should_subtract_mac_menu}
end which_dimensions

on multiply_text(str, n)
	if n < 1 or str = "" then return ""
	set lst to {}
	repeat n times
		set end of lst to str
	end repeat
	return lst as string
end multiply_text

on split_text(txt, delim)
	try
		set AppleScript's text item delimiters to (delim as string)
		set lst to every text item of (txt as string)
		set AppleScript's text item delimiters to ""
		return lst
	on error errMsg number errNum
		set AppleScript's text item delimiters to ""
		error "Can't splitText: " & errMsg number errNum
	end try
end split_text
