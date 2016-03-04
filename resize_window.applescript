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

(********** Code Overview
	$ egrep "^(on|script|\(\* ====)" resize_window.applescript
	on run -- main
	(* ==== MVC Classes ==== *)
	on make_controller() --> Controller
	on make_app_window() --> Model
	on make_ui(app_window) --> View
	(* ==== Factory Pattern ==== *)
	script AppFactory -- Factory
	on make_supported_app() --> abstract product
	on make_safari_window() --> concrete product
	on make_webkit_window() --> concrete product
	on make_chrome_window() --> concrete product
	on make_firefox_window() --> concrete product
	(* ==== Miscellaneous Classes ==== *)
	script Util -- Utility Functions
********************)

on run -- main
	run make_controller() --> Controller
end run

(* ==== MVC Classes ==== *)

on make_controller() --> Controller
	script
		on run
			tell my AppFactory
				-- Register apps that support resizing by window content area dimensions.
				register_product(make_safari_window())
				register_product(make_chrome_window())
				register_product(make_firefox_window())
				register_product(make_webkit_window())
			end tell
			
			set app_window to my AppFactory's make_window(my Util's get_front_app_name()) --> Model
			
			set ui_view to make_ui(app_window) --> View
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

on make_app_window() --> Model
	script
		property class : "AppWindow" -- superclass
		property _app_name : missing value -- string
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
		property _is_mobile : missing value -- boolean
		
		on init(app_name) --> void
			set _app_name to app_name
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
				set size_choice to my Util's split_text(size_choice, tab)'s first item
				set {_new_width, _new_height} to my Util's split_text(size_choice, "x")
			on error
				set txt to "Invalid window size"
				my Util's error_with_alert(txt, msg)
			end try
			
			if _new_width is "" or _new_height is "" then
				set txt to "Invalid width and/or height"
				my Util's error_with_alert(txt, msg)
			end if
			
			try
				_new_width as integer
				_new_height as integer
			on error
				set txt to "Invalid width and/or height"
				set msg to "Width and height must be integers."
				my Util's error_with_alert(txt, msg)
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
		
		on set_mobile(true_or_false) --> void
			set _is_mobile to true_or_false
		end set_mobile
		
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
		
		on is_mobile() --> boolean
			return _is_mobile
		end is_mobile
		
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

on make_ui(app_window) --> View
	script
		property _app_window : app_window -- Model
		property _size_choice : missing value -- string
		
		(* == View Components == *)
		
		property _dialog_title : __SCRIPT_NAME__
		property _custom_choice : "Custom sizeÉ"
		property _u_dash : Çdata utxt2500È as Unicode text -- BOX DRAWINGS LIGHT HORIZONTAL
		property _menu_rule : my Util's multiply_text(_u_dash, 21)
		
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
			
			-- Only supported apps can target the window body for mobile sizes.
			-- Those supported apps will have a different class name than the
			-- generic fallback "AppWindow".
			if _app_window's class is not "AppWindow" and _size_choice is in _mobile_sizes then
				_app_window's set_mobile(true)
			else
				_app_window's set_mobile(false)
			end if
			
			_handle_user_action()
		end create_view
		
		on get_size_choice() --> string
			return _size_choice
		end get_size_choice
		
		on which_dimensions() --> void
			local dimension_choice, mac_menu_choice, m, b
			tell _app_window
				set m to "Resize both the window's width and height (" & get_new_width() & "x" & get_new_height() & ") or just the width (" & get_new_width() & ")?"
			end tell
			set b to {"Cancel", "Width & Height", "Width-only"}
			display dialog m with title _dialog_title buttons b default button 3
			set dimension_choice to button returned of result
			if dimension_choice is b's item 3 then
				_app_window's set_width_only(true)
			else
				_app_window's set_width_only(false)
			end if
			
			_app_window's set_subtract_mac_menu(false)
			if not _app_window's is_width_only() and not _app_window's is_mobile() then
				set m to "Subtract Mac Menu Bar height (" & _app_window's get_mac_menu_bar() & "px)?"
				set b to {"Cancel", "Subtract Mac Menu Bar", "Don't Subtract"}
				display dialog m with title _dialog_title buttons b default button 3
				set mac_menu_choice to button returned of result
				if mac_menu_choice is b's item 2 then
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
				set {width_or_height, _sign, _amount} to my Util's split_text(characters 1 thru -3 of _size_choice as string, space)
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
end make_ui

(* ==== Factory Pattern ==== *)

script AppFactory -- Factory
	property class : "AppFactory"
	property _registered_products : {} -- array (concrete products)
	
	on register_product(this_product) --> void
		set end of _registered_products to this_product
	end register_product
	
	on make_window(app_name) --> AppWindow
		repeat with this_product in _registered_products
			if app_name is this_product's to_string() then
				this_product's init(app_name)
				return this_product
			end if
		end repeat
		-- fallback to generic app window w/o inner dimension support
		set this_app to make_app_window() --> AppWindow superclass (Model)
		this_app's init(app_name)
		return this_app
	end make_window
end script

on make_supported_app() --> abstract product
	script
		property class : "SupportedApp"
		property parent : make_app_window() -- extends AppWindow (Model)
		on to_string() --> string
			return my short_name
		end to_string
	end script
end make_supported_app

on make_safari_window() --> concrete product
	script
		property class : "SafariWindow"
		property parent : make_supported_app() -- extends SupportedApp
		property short_name : "Safari"
		
		on calculate_size()
			continue calculate_size() -- call superclass's method first
			-- Resize mobile sizes by the window content area instead of the window bounds
			if my _is_mobile then
				my Util's gui_scripting_status() -- requires GUI scripting
				tell application "System Events" to tell application process (my _app_name)
					tell window 1's tab group 1's group 1's group 1's scroll area 1
						set h_adj to (attribute "AXSize"'s value as list)'s last item
					end tell
				end tell
				my adjust_bottom((my _height) - h_adj)
			end if
		end calculate_size
	end script
end make_safari_window

on make_webkit_window() --> concrete product
	script
		property class : "WebKitWindow"
		property parent : make_safari_window() -- extends SafariWindow
		property short_name : "WebKit"
	end script
end make_webkit_window

on make_chrome_window() --> concrete product
	script
		property class : "ChromeWindow"
		property parent : make_supported_app() -- extends SupportedApp
		property short_name : "Chrome"
		
		on calculate_size()
			continue calculate_size() -- call superclass's method first
			-- Resize mobile sizes by the window content area instead of the window bounds
			if my _is_mobile then
				my Util's gui_scripting_status() -- requires GUI scripting
				set h_adj to 0
				tell application "System Events" to tell application process (my _app_name)
					tell window 1
						try
							set h_adj to h_adj + ((toolbar 1's attribute "AXSize"'s value as list)'s last item)
						end try
						try
							set h_adj to h_adj + ((tab group 1's attribute "AXSize"'s value as list)'s last item)
						end try
					end tell
				end tell
				my adjust_bottom(h_adj)
			end if
		end calculate_size
	end script
end make_chrome_window

on make_firefox_window() --> concrete product
	script
		property class : "FirefoxWindow"
		property parent : make_supported_app() -- extends SupportedApp
		property short_name : "Firefox"
		
		on calculate_size()
			continue calculate_size() -- call superclass's method first
			-- Resize mobile sizes by the window content area instead of the window bounds.
			if my _is_mobile then
				-- XXX: Firefox doesn't provide access to the window content
				-- area dimensions so just use a best-guess hardcoded value
				-- (which could become outdated with app updates or if other
				-- toolbars are installed or hidden).
				my adjust_bottom(102) -- tab bar + bookmarks toolbar
			end if
		end calculate_size
	end script
end make_firefox_window

-- Just an example. It works, but it's not necessary, so don't register it with the factory in the final script.
(*on make_textedit_window() --> concrete product
	script
		property class : "TextEditWindow"
		property parent : make_supported_app() -- extends SupportedApp
		property short_name : "TextEdit"
		
		on calculate_size()
			continue calculate_size() -- call superclass's method first
			if my _is_mobile then
				my Util's gui_scripting_status() -- requires GUI scripting
				tell application "System Events" to tell application process (my _app_name)
					tell window 1's scroll area 1's text area 1
						set h_adj to (attribute "AXSize"'s value as list)'s last item
					end tell
				end tell
				my adjust_bottom((my _height) - h_adj)
			end if
		end calculate_size
	end script
end make_textedit_window*)


(* ==== Miscellaneous Classes ==== *)

script Util -- Utility Functions
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
	
	on gui_scripting_status()
		local os_ver, is_before_mavericks, ui_enabled, apple_accessibility_article
		local err_msg, err_num, msg, t, b
		
		set os_ver to system version of (system info)
		
		considering numeric strings -- version strings
			set is_before_mavericks to os_ver < "10.9"
		end considering
		
		if is_before_mavericks then -- things changed in Mavericks (10.9)
			-- check to see if assistive devices is enabled
			tell application "System Events"
				set ui_enabled to UI elements enabled
			end tell
			if ui_enabled is false then
				tell application "System Preferences"
					activate
					set current pane to pane id "com.apple.preference.universalaccess"
					display dialog "This script utilizes the built-in Graphic User Interface Scripting architecture of Mac OS X which is currently disabled." & return & return & "You can activate GUI Scripting by selecting the checkbox \"Enable access for assistive devices\" in the Accessibility preference pane." with icon 1 buttons {"Cancel"} default button 1
				end tell
			end if
		else
			-- In Mavericks (10.9) and later, the system should prompt the user with
			-- instructions on granting accessibility access, so try to trigger that.
			try
				tell application "System Events"
					tell (first process whose frontmost is true)
						set frontmost to true
						tell window 1
							UI elements
						end tell
					end tell
				end tell
			on error err_msg number err_num
				-- In some cases, the system prompt doesn't appear, so always give some info.
				set msg to "Error: " & err_msg & " (" & err_num & ")"
				if err_num is -1719 then
					set apple_accessibility_article to "http://support.apple.com/en-us/HT202802"
					set t to "GUI Scripting needs to be activated"
					set msg to msg & return & return & "This script utilizes the built-in Graphic User Interface Scripting architecture of Mac OS X which is currently disabled." & return & return & "If the system doesn't prompt you with instructions for how to enable GUI scripting access, then see Apple's article at: " & return & apple_accessibility_article
					set b to {"Go to Apple's Webpage", "Cancel"}
					display alert t message msg buttons b default button 2
					if button returned of result is b's item 1 then
						tell me to open location apple_accessibility_article
					end if
					error number -128 --> User canceled
				end if
			end try
		end if
	end gui_scripting_status
end script
