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

on run
	run make_controller() --> Controller
end run

(* ==== MVC Classes ==== *)

on make_controller() --> Controller
	script
		on run
			set app_window to make_app_window(get_front_app_name()) --> Model
			app_window's init()
			
			set ui_view to make_ui_view(app_window) --> View
			tell ui_view
				create_view()
				if get_size_choice() is false then return -- no (more) adjustments
			end tell
			
			app_window's validate_window_size(ui_view's get_size_choice())
			ui_view's which_dimensions()
			tell app_window
				calculate_size()
				resize_window()
			end tell
		end run
	end script
end make_controller

on make_app_window(app_name) --> Model
	script
		property class : "AppWindow"
		property _app_name : app_name -- string
		property _mac_menu_bar : 23 -- int (22px menu plus 1px bottom border)
		
		property _width : missing value -- int
		property _height : missing value -- int
		property _left : missing value -- int
		property _right : missing value -- int
		property _top : missing value -- int
		property _bottom : missing value -- int
		
		property _new_width : missing value -- int
		property _new_height : missing value -- int
		property _is_width_only : missing value -- boolean
		property _should_subtract_mac_menu : missing value -- boolean
		
		on init() --> void
			tell application _app_name
				set {_left, _top, _right, _bottom} to bounds of window 1
				set _width to _right - _left
				set _height to _bottom - _top
			end tell
		end init
		
		on resize_window() --> void
			tell application _app_name
				set bounds of window 1 to {_left, _top, _right, _bottom}
			end tell
			return {_left, _top, _right, _bottom}
		end resize_window
		
		on validate_window_size(size_choice) --> void
			local msg, txt
			set msg to "Window size should be formatted as WIDTHxHEIGHT (separated by a lowercase \"x\")."
			
			try
				set size_choice to split_text(size_choice, tab)'s first item
				set {_new_width, _new_height} to split_text(size_choice, "x")
			on error
				set txt to "Invalid window size"
				error_with_alert(txt, msg)
			end try
			
			if _new_width is "" or _new_height is "" then
				set txt to "Invalid width and/or height"
				error_with_alert(txt, msg)
			end if
			
			try
				_new_width as integer
				_new_height as integer
			on error
				set txt to "Invalid width and/or height"
				set msg to "Width and height must be integers."
				error_with_alert(txt, msg)
			end try
		end validate_window_size
		
		on calculate_size() --> void
			set_right(_left + _new_width)
			if not _is_width_only then
				set_bottom(_top + _new_height)
				if _should_subtract_mac_menu then
					adjust_bottom(-_mac_menu_bar)
				end if
			end if
		end calculate_size
		
		(* == Setters == *)
		
		on set_right(val) --> void
			set _right to val
		end set_right
		
		on set_bottom(val) --> void
			set _bottom to val
		end set_bottom
		
		on adjust_right(val) --> void
			set_right(_right + val)
		end adjust_right
		
		on adjust_bottom(val) --> void
			set_bottom(_bottom + val)
		end adjust_bottom
		
		on set_width_only(val) --> void
			set _is_width_only to val
		end set_width_only
		
		on set_subtract_mac_menu(val) --> void
			set _should_subtract_mac_menu to val
		end set_subtract_mac_menu
		
		(* == Getters == *)
		
		on is_width_only() --> boolean
			return _is_width_only
		end is_width_only
		
		on get_name() --> string
			return _app_name
		end get_name
		
		on get_mac_menu_bar() --> int
			return _mac_menu_bar
		end get_mac_menu_bar
		
		on get_width() --> int
			return _width
		end get_width
		
		on get_height() --> int
			return _height
		end get_height
		
		on get_new_width() --> int
			return _new_width
		end get_new_width
		
		on get_new_height() --> int
			return _new_height
		end get_new_height
	end script
end make_app_window

on make_ui_view(app_window) --> View
	script
		property _app_window : app_window -- Model
		property _size_choice : missing value -- string
		
		(* == View Components == *)
		
		property _dialog_title : __SCRIPT_NAME__
		property _custom_choice : "Custom sizeÉ"
		property _u_dash : Çdata utxt2500È as Unicode text -- BOX DRAWINGS LIGHT HORIZONTAL
		property _menu_rule : my multiply_text(_u_dash, 21)
		
		property _width_increments : {"Width + 1px", "Width - 1px", "Width + 10px", "Width - 10px"}
		property _height_increments : {"Height + 1px", "Height - 1px", "Height + 10px", "Height - 10px"}
		
		property _mobile_sizes : paragraphs of "320x480		iPhone 4 Ñ Portrait (2x)
480x320		iPhone 4 Ñ Landscape (2x)
320x568		iPhone 5 Ñ Portrait (2x)
568x320		iPhone 5 Ñ Landscape (2x)
375x667		iPhone 6 Ñ Portrait (2x)
667x375		iPhone 6 Ñ Landscape (2x)
414x736		iPhone 6 Plus Ñ Portrait (3x)
736x414		iPhone 6 Plus Ñ Landscape (3x)
768x1024	iPad Ñ Portrait (2x)
1024x768	iPad Ñ Landscape (2x)"
		
		property _desktop_sizes : paragraphs of "640x480		VGA (4:3)
800x600		SVGA (4:3)
1024x768	XGA (4:3)
1280x800	WXGA (16:10)
1366x768	WXGA (16:9)"
		
		property _size_list : _mobile_sizes & Â
			_menu_rule & Â
			_desktop_sizes & Â
			_menu_rule & Â
			_width_increments & Â
			_menu_rule & Â
			_height_increments & Â
			_menu_rule & Â
			_custom_choice & Â
			_menu_rule & Â
			("About " & __SCRIPT_NAME__)
		
		(* == Methods == *)
		
		on create_view() --> void
			local m
			tell _app_window
				set m to "Choose a size for " & get_name() & "'s front window" & return & "(currently " & get_width() & "x" & get_height() & "):"
			end tell
			repeat -- until a horizontal rule is not selected
				set _size_choice to choose from list _size_list default items {_size_list's item 14} with title _dialog_title with prompt m
				if _size_choice as string is not _menu_rule then
					exit repeat
				else
					display alert "Invalid selection" message "Try again." as warning
				end if
			end repeat
			if _size_choice is false then error number -128 -- User canceled
			set _size_choice to _size_choice as string
			
			_handle_user_action()
		end create_view
		
		on get_size_choice() --> string
			return _size_choice
		end get_size_choice
		
		on which_dimensions() --> void
			local this_choice, m, b
			tell _app_window
				set m to "Resize both the window's width and height (" & get_new_width() & "x" & get_new_height() & ") or just the width (" & get_new_width() & ")?"
			end tell
			set b to {"Cancel", "Width & Height", "Width-only"}
			display dialog m with title _dialog_title buttons b default button 3
			set this_choice to button returned of result
			if this_choice is b's item 3 then
				_app_window's set_width_only(true)
			else
				_app_window's set_width_only(false)
			end if
			
			_app_window's set_subtract_mac_menu(false)
			if not _app_window's is_width_only() then
				set m to "Subtract Mac Menu Bar height (" & _app_window's get_mac_menu_bar() & "px)?"
				set b to {"Cancel", "Subtract Mac Menu Bar", "Don't Subtract"}
				display dialog m with title _dialog_title buttons b default button 3
				set this_choice to button returned of result
				if this_choice is b's item 2 then
					_app_window's set_subtract_mac_menu(true)
				end if
			end if
		end which_dimensions
		
		on _handle_user_action() --> void -- PRIVATE
			local t, b, m, btn_choice
			local width_or_height, _sign, _amount, size_adjustment
			if _size_choice is _size_list's last item then
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
				set _size_choice to false
			else if _size_choice is _custom_choice then
				set m to "Type in a custom width and height separated by an \"x\":"
				display dialog m with title _dialog_title default answer "1024x768"
				set _size_choice to text returned of result
			else if _size_choice is in _width_increments & _height_increments then
				set {width_or_height, _sign, _amount} to split_text(characters 1 thru -3 of _size_choice as string, space)
				set size_adjustment to _sign & _amount as integer
				if width_or_height is "Width" then
					_app_window's adjust_right(size_adjustment)
				else
					_app_window's adjust_bottom(size_adjustment)
				end if
				_app_window's resize_window()
				set _size_choice to false
			end if
		end _handle_user_action
	end script
end make_ui_view


(* ==== Utility Functions (Global) ==== *)

on get_front_app_name() --> string
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

on error_with_alert(txt, msg) --> void
	display alert txt message msg as critical buttons {"Cancel"} default button 1
	error number -128 -- User canceled
end error_with_alert

on multiply_text(str, n) --> string
	if n < 1 or str = "" then return ""
	set lst to {}
	repeat n times
		set end of lst to str
	end repeat
	return lst as string
end multiply_text

on split_text(txt, delim) --> array
	try
		set AppleScript's text item delimiters to (delim as string)
		set lst to every text item of (txt as string)
		set AppleScript's text item delimiters to ""
		return lst
	on error err_msg number err_num
		set AppleScript's text item delimiters to ""
		error "Can't split_text: " & err_msg number err_num
	end try
end split_text
