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
	on make_factory() --> Factory
	on make_supported_app() --> abstract product
	on make_safari_window() --> concrete product
	on make_webkit_window() --> concrete product
	on make_chrome_window() --> concrete product
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
			set app_factory to make_factory()
			tell app_factory
				-- Register apps that support resizing by window content area dimensions.
				register_product(make_safari_window())
				register_product(make_chrome_window())
				register_product(make_webkit_window())
			end tell
			
			set app_window to app_factory's make_window(my Util's get_front_app_name()) --> Model
			set ui_view to make_ui(app_window) --> View
			
			ui_view's create_view() -- primary dialog
			if app_window's get_new_size() is false then return -- no (more) adjustments
			app_window's validate_window_size()
			ui_view's which_dimensions() -- secondary dialogs
			app_window's calculate_size()
			app_window's resize_window()
			if app_window's has_alert() then ui_view's display_alert()
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
		
		property _new_size : missing value -- string (or bool false)
		property _new_width : missing value -- int
		property _new_height : missing value -- int
		property _is_width_only : missing value -- boolean
		property _should_subtract_mac_menu : missing value -- boolean
		property _is_mobile : missing value -- boolean
		
		property _alert_title : missing value -- string
		property _alert_msg : missing value -- string
		
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
		
		on validate_window_size() --> void
			local msg, txt
			set msg to "Window size should be formatted as WIDTHxHEIGHT (separated by a lowercase \"x\")."
			
			try
				set _new_size to my Util's split_text(_new_size, tab)'s first item
				set {_new_width, _new_height} to my Util's split_text(_new_size, "x")
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
		
		on has_alert() --> boolean
			if _alert_title is not missing value and _alert_title is not missing value then
				return true
			end if
			return false
		end has_alert
		
		(* == Setters == *)
		
		on set_new_size(new_size) --> void
			set _new_size to new_size
		end set_new_size
		
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
		
		on set_alert_title(val) --> void
			set _alert_title to val
		end set_alert_title
		
		on set_alert_msg(val) --> void
			set _alert_msg to val
		end set_alert_msg
		
		(* == Getters == *)
		
		on get_new_size() --> string (or bool false)
			return _new_size
		end get_new_size
		
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
		
		on get_alert_title() --> string
			return _alert_title
		end get_alert_title
		
		on get_alert_msg() --> string
			return _alert_msg
		end get_alert_msg
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
		
		(* == View Methods == *)
		
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
			_app_window's set_new_size(_size_choice)
		end create_view
		
		on display_alert() --> void
			set t to _dialog_title & ": " & _app_window's get_alert_title()
			tell application (_app_window's get_name())
				display alert t message _app_window's get_alert_msg() as warning
			end tell
		end display_alert
		
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

on make_factory() --> Factory
	script
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
end make_factory

on make_supported_app() --> abstract product
	script
		property class : "SupportedApp"
		property parent : make_app_window() -- extends AppWindow (Model)
		
		property _js : "window.innerHeight ||
				document.documentElement.clientHeight ||
				document.body.clientHeight ||
				document.body.offsetHeight;" -- string (JavaScript program)
		
		on to_string() --> string
			return my short_name
		end to_string
		
		on reset_gui(app_process)
			using terms from application "System Events"
				tell app_process
					-- XXX: Release any keys that may have been used to invoke
					-- the script.
					--
					-- This one caused problems with Safari (in Yosemite, at
					-- least) when invoking the script with a keyboard shortcut
					-- using FastScripts. The control key causes a "Display a
					-- menu" pop-up label thingie to appear in the Safari
					-- window which apparently prevents UI scripting from
					-- accessing the targeted UI elements. When the script is
					-- run from Script Editor or by selecting the script from
					-- the FastScript menu instead of with a keyboard shortcut,
					-- the UI scripting works fine because no keys are down
					-- to interfere with UI scripting.
					key up control
					-- Might as well preemptively release these (untested) keys
					-- as well while I'm at it, just in case.
					key up command
					key up option
					key up shift
				end tell
			end using terms from
		end reset_gui
		
		on set_default_alert()
			set t to "Couldn't target window content area for resizing"
			set m to "The height of the content area of the window could not be resized to the selected mobile dimensions, so the overall window frame height was resized instead." & return & return & "Try enabling JavaScript if it's not already enabled and rerun the script."
			set_alert(t, m)
		end set_default_alert
		
		on set_alert(this_title, this_msg)
			my set_alert_title(this_title)
			my set_alert_msg(this_msg)
		end set_alert
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
				set doc_height to 0
				
				-- First try GUI scripting since it doesn't require JavaScript to be enabled
				my Util's gui_scripting_status()
				repeat 10 times -- until hopefully GUI scripting succeeds
					try
						tell application "System Events" to tell application process (my _app_name)
							set frontmost to true
							my reset_gui(it)
							--tell window 1's scroll area 1 -- DEBUG: cause error for testing
							tell window 1's tab group 1's group 1's group 1's scroll area 1
								set doc_height to (attribute "AXSize"'s value as list)'s last item
							end tell
						end tell
						exit repeat
					on error
						delay 0.1 -- give the UI time to catch up
					end try
				end repeat
				
				-- If GUI Scripting fails (possibly because of changes between
				-- app versions), try JavaScript
				if doc_height = 0 then
					try
						using terms from application "Safari"
							tell application (my _app_name)
								set doc_height to (do JavaScript my _js in document 1) as integer
							end tell
						end using terms from
					end try
				end if
				
				if doc_height > 0 then
					my adjust_bottom((my _height) - doc_height)
				else
					my set_default_alert()
				end if
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
				set doc_height to 0
				-- Google Chrome doesn't provide access to the dimensions of
				-- the window scroll area via UI Scripting, so try JavaScript
				-- instead.
				try
					using terms from application "Google Chrome"
						tell application (my _app_name)
							set doc_height to (execute front window's active tab javascript my _js) as integer
						end tell
					end using terms from
				end try
				if doc_height > 0 then
					my adjust_bottom((my _height) - doc_height)
				else
					my set_default_alert()
				end if
			end if
		end calculate_size
	end script
end make_chrome_window

-- Firefox doesn't provide access to AppleScript for inner window dimensions
-- via either GUI Scripting or JavaScript, so don't even bother. Hardcoding
-- values is too fragile. Just a use a browser that supports AppleScript.
(*on make_firefox_window() --> concrete product
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
end make_firefox_window*)

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
