(***********************************************************************

Resize Window - Resize frontmost Safari browser window

@version @@VERSION@@
@date @@RELEASE_DATE@@
@author Steve Wheeler

This program is free software available under the terms of a BSD-style
(3-clause) open source license detailed below.

************************************************************************
Copyright (c) 2014 Steve Wheeler  
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
***********************************************************************)

(* == Initializations == *)

set u_dash to Çdata utxt2500È as Unicode text -- BOX DRAWINGS LIGHT HORIZONTAL
set menu_rule to my multiply_text(u_dash, 21)

set size_adjustment_list to {"Width + 1px", "Width - 1px"}

set size_list to paragraphs of "320x480	iPhone Portrait (640x960)
480x320	iPhone Landscape (960x640)
320x568	iPhone 5 Portrait (640x1136)
568x320	iPhone 5 Landscape (1136x640)
640x480	VGA (4:3)
800x600	SVGA (4:3)
768x1024	iPad Portrait
1024x768	XGA (4:3), iPad Landscape
1280x800	WXGA (16:10)
1366x768	WXGA (16:9)" & Â
	menu_rule & Â
	size_adjustment_list & Â
	menu_rule & Â
	"Show front browser window size"

set mac_menu_bar to 22


(* == Main == *)

set t to "Safari Ñ Resize Window"
set m to "Choose a browser window size:"
repeat -- until a horizontal rule is not selected
	set size_choice to choose from list size_list default items {size_list's item 8} with title t with prompt m with multiple selections allowed
	if size_choice as string is not menu_rule then
		exit repeat
	else
		display alert "Invalid selection" message "Try again." as warning
	end if
end repeat
if size_choice is false then error number -128 -- User canceled
set size_choice to size_choice as string

tell application "Safari"
	set {win_left, win_top, win_right, win_bottom} to bounds of window 1
	set cur_width to win_right - win_left
	set cur_height to win_bottom - win_top
end tell

if size_choice is size_list's last item then
	set m to cur_width & "x" & cur_height as text
	display alert "Safari front window size" message m buttons {"OK"} default button 1
	return
else if size_choice is in size_adjustment_list then
	-- Currently we're only adjusting the width, so no need for specific variables
	if size_choice is size_adjustment_list's first item then
		set size_adjustment to 1
	else
		set size_adjustment to -1
	end if
	set win_right to win_right + size_adjustment
	tell application "Safari" to set bounds of window 1 to {win_left, win_top, win_right, win_bottom}
	return
end if


-- Parse size choice
set size_choice to split_text(size_choice, tab)'s first item
set {new_width, new_height} to split_text(size_choice, "x")
--return {new_width, new_height} -- :DEBUG:


-- Check for size adjustments

set m to "Resize both the browser window's width and height or just the width?"
set b to {"Cancel", "Width & Height", "Width-only"}
set dimension_choice to button returned of (display dialog m with title t buttons b default button 3)
if dimension_choice is b's item 3 then
	set is_width_only to true
else
	set is_width_only to false
end if

if not is_width_only then
	set m to "Subtract Mac Menu Bar height (" & mac_menu_bar & "px)?"
	set b to {"Cancel", "Subtract Mac Menu Bar", "Don't Subtract"}
	set mac_menu_choice to button returned of (display dialog m with title t buttons b default button 3)
	if mac_menu_choice is b's item 2 then
		set should_subtract_mac_menu to true
	else
		set should_subtract_mac_menu to false
	end if
end if


-- Calculate new window size
set win_right to win_left + new_width

if not is_width_only then
	set win_bottom to win_top + new_height
	if should_subtract_mac_menu then
		set win_bottom to win_bottom - mac_menu_bar
	end if
end if


-- Resize window
tell application "Safari"
	set bounds of window 1 to {win_left, win_top, win_right, win_bottom}
end tell


(* == Subroutines == *)

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
