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
	$ egrep "^(on|script|\(\* ={4})" resize_window.applescript
	on run -- main
	(* ==== MVC Classes ==== *)
	on make_app_controller() --> Controller
	on make_view_controller(app_model) --> Controller
	on make_app_window() --> Model
	on make_ui(app_model, app_controller) --> View
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
	run make_app_controller() --> Controller
	Util's handle_termination() -- XXX
end run

(* ==== MVC Classes ==== *)

on make_app_controller() --> Controller
	script
		on run
			set app_factory to make_factory()
			tell app_factory
				-- Register apps that support resizing by window content area dimensions.
				register_product(make_safari_window())
				register_product(make_chrome_window())
				register_product(make_webkit_window())
			end tell

			set apps_to_ignore to {"Script Editor", "AppleScript Editor", "Terminal"}
			set app_model to app_factory's make_window(my Util's get_front_app_name(apps_to_ignore)) --> Model
			set view_controller to make_view_controller(app_model) --> Controller
			set app_view to make_ui(app_model, view_controller) --> View

			app_view's show_view() -- primary dialog
			if app_model's get_new_size() is false then return -- no (more) adjustments
			app_view's which_dimensions() -- secondary dialogs
			app_model's resize_window(true)
			if app_model's has_alert() then app_view's display_alert()
		end run
	end script
end make_app_controller

on make_view_controller(app_model) --> Controller
	script
		property _model : app_model -- Model

		on go_to_website() --> void
			open location __SCRIPT_WEBSITE__ -- in default web browser
		end go_to_website

		-- @param string|boolean Description of chosen size (or 'false'); to be parsed
		on set_new_size(size_choice) --> void
			_model's set_new_size(size_choice)
		end set_new_size

		-- Prevent further window resizing
		on set_done() --> void
			_model's set_new_size(false)
		end set_done

		-- @param boolean Should only the window width be resized?
		on set_width_only(true_or_false) --> void
			_model's set_width_only(true_or_false)
		end set_width_only

		-- @param boolean Should the Mac menu bar height be subtracted?
		on set_subtract_mac_menu(true_or_false) --> void
			_model's set_subtract_mac_menu(true_or_false)
		end set_subtract_mac_menu

		-- @param int New window width
		on set_width(val) --> void
			_set_width_or_height("width", val)
		end set_width

		-- @param int New window height
		on set_height(val) --> void
			_set_width_or_height("height", val)
		end set_height

		-- @param string Increment/decrement menu option, e.g., "width + 10px"
		on increment_width_or_height(size_choice) --> void
			set {width_or_height, int_sign, int_val} to my Util's split_text(size_choice, space)
			if int_val ends with "px" then set int_val to text 1 thru -3 of int_val as integer
			set size_adjustment to int_sign & int_val as integer
			ignoring case
				if width_or_height is "Width" then
					_model's adjust_width(size_adjustment)
				else
					_model's adjust_height(size_adjustment)
				end if
			end ignoring
			_model's resize_window(false) -- false = don't calculate new size; already calculated
			_model's set_new_size(false) -- to prevent further resizing
		end increment_width_or_height

		(* == Private == *)

		-- @param 1 string The dimension to change -- "width" or "height"
		-- @param 2 string Exact or incremental value, i.e., unsigned or signed integer, respectively.
		on _set_width_or_height(width_or_height, val) --> void -- PRIVATE
			try
				set int_val to val as integer
			on error
				set err_title to "Invalid input"
				set msg to "Input must be an integer, optionally prefixed with +/- (to add/subtract)."
				my Util's error_with_alert(err_title, msg)
			end try
			if first character of val is in {"+", "-"} then -- increment/decrement the size
				if width_or_height is "width" then
					_model's adjust_width(int_val)
				else
					_model's adjust_height(int_val)
				end if
			else -- exact size
				if width_or_height is "width" then
					_model's set_width(int_val)
				else
					_model's set_height(int_val)
				end if
			end if
			_model's resize_window(false) -- false = don't calculate new size; already calculated
			_model's set_new_size(false) -- to prevent further resizing
		end _set_width_or_height
	end script
end make_view_controller

on make_app_window() --> Model
	script
		property class : "AppWindow" -- superclass
		property _app_name : missing value -- string
		property _mac_menu_bar : 23 -- int (22px menu plus 1px bottom border)
		property _supported_apps : missing value -- array

		property _width : missing value -- int
		property _height : missing value -- int
		property _left : missing value -- int
		property _right : missing value -- int
		property _top : missing value -- int
		property _bottom : missing value -- int

		property _new_size : missing value -- string (or bool false to end resizing)
		property _new_width : missing value -- int
		property _new_height : missing value -- int

		property _is_width_only : missing value -- boolean
		property _should_subtract_mac_menu : missing value -- boolean
		property _should_prompt_mac_menu : missing value -- boolean
		property _is_mobile : missing value -- boolean

		property _alert_title : missing value -- string
		property _alert_msg : missing value -- string

		-- Preconfigured sizes (used by the View to build the menu):
		--
		property _mobile_sizes : paragraphs of "320x480		iPhone 4 Ñ Portrait (2x)
480x320		iPhone 4 Ñ Landscape (2x)
320x568		iPhone 5 Ñ Portrait (2x)
568x320		iPhone 5 Ñ Landscape (2x)
375x667		iPhone 6 Ñ Portrait (2x)
667x375		iPhone 6 Ñ Landscape (2x)
414x736		iPhone 6 Plus Ñ Portrait (3x)
736x414		iPhone 6 Plus Ñ Landscape (3x)
768x1024	iPad Ñ Portrait (2x)
1024x768	iPad Ñ Landscape (2x)" -- array
		--
		property _desktop_sizes : paragraphs of "640x480		VGA (4:3)
800x600		SVGA (4:3)
1024x768	XGA (4:3)
1280x800	WXGA (16:10)
1366x768	WXGA (16:9)" -- array

		(* == Public Methods == *)

		-- @param[in] string The name of the target (frontmost) application
		-- @param[out] string _app_name Same as input parameter
		-- @param[out] boolean _should_subtract_mac_menu Initialized to false
		-- @param[out] boolean _should_prompt_mac_menu Initialized to true
		-- @param[out] int _left,_top,_right,_bottom Current window bounds
		-- @param[out] int _width,_height Current window dimensions
		-- @return Nothing
		on init(app_name) --> void
			set _app_name to app_name
			set _should_subtract_mac_menu to false -- default
			set _should_prompt_mac_menu to true -- default
			tell application _app_name
				set {_left, _top, _right, _bottom} to bounds of window 1
				set _width to _right - _left
				set _height to _bottom - _top
			end tell
		end init

		-- @param boolean Does the new window size need to be calculated?
		on resize_window(should_calculate) --> void
			if should_calculate then calculate_size()
			tell application _app_name
				set bounds of window 1 to {_left, _top, _right, _bottom}
			end tell
			return {_left, _top, _right, _bottom} -- for debugging; not used
		end resize_window

		-- This method is overridden by subclasses to get custom behavior
		on calculate_size() --> void
			set_width(_new_width)
			if not _is_width_only then
				set_height(_new_height)
				if _should_subtract_mac_menu then
					adjust_height(-_mac_menu_bar)
				end if
			end if
		end calculate_size

		on has_alert() --> boolean
			_alert_title is not missing value and _alert_msg is not missing value
		end has_alert

		(* == Private Methods == *)

		-- @param[in]  string Description of chosen size
		-- @param[out] string _new_size Formatted size, e.g., "1024x768"
		-- @param[out] int    _new_width
		-- @param[out] int    _new_height
		-- @return Nothing
		on _parse_window_size(new_size) --> void -- PRIVATE
			set msg to "Window size should be formatted as WIDTHxHEIGHT (integers separated by an \"x\"). The width and/or height can also be prefixed with a +/- to add/subtract the associated value."

			-- Parse size, width, and height from string
			try
				set size_arg to my Util's split_text(new_size, tab)'s first item -- get size string
				set size_arg to my Util's split_text(size_arg, space) as string -- delete spaces
				set {width_arg, height_arg} to my Util's split_text(size_arg, "x")
			on error
				set err_title to "Invalid window size"
				my Util's error_with_alert(err_title, msg)
			end try

			if width_arg is "" or height_arg is "" then
				set err_title to "Missing width and/or height"
				my Util's error_with_alert(err_title, msg)
			end if

			-- Check for increment/decrement args
			set {width_sign, height_sign} to {missing value, missing value}
			try
				if character 1 of width_arg is in {"+", "-"} then
					set {width_sign, width_arg} to {width_arg's text 1, width_arg's text 2 thru -1}
				end if
				if character 1 of height_arg is in {"+", "-"} then
					set {height_sign, height_arg} to {height_arg's text 1, height_arg's text 2 thru -1}
				end if
			on error
				set err_title to "Invalid width and/or height"
				set msg to "Width and height must be integers, optionally prefixed with +/- (to add/subtract)."
				my Util's error_with_alert(err_title, msg)
			end try

			-- Validate integer args
			try
				width_arg as integer
				height_arg as integer
			on error
				set err_title to "Invalid width and/or height"
				set msg to "Width and height must be integers, optionally prefixed with +/- (to add/subtract)."
				my Util's error_with_alert(err_title, msg)
			end try

			-- Set new values from parsed/validated args
			if width_sign is missing value then
				set _new_width to width_arg as integer
			else
				set _new_width to _width + (width_sign & width_arg as integer)
			end if
			if height_sign is missing value then
				set _new_height to height_arg as integer
			else
				set _new_height to _height + (height_sign & height_arg as integer)
				set _should_prompt_mac_menu to false
			end if
			set _new_size to _new_width & "x" & _new_height as string
		end _parse_window_size

		on _set_mobile(true_or_false) --> void -- PRIVATE
			my Util's validate_boolean_arg(true_or_false, "_set_mobile")

			-- Only supported apps can target the window body for mobile sizes.
			-- Those supported apps will have a different class name than the
			-- generic fallback "AppWindow".
			set _is_mobile to (my class is not "AppWindow" and true_or_false) --> boolean
		end _set_mobile

		(* == Setters == *)

		-- @param array
		on set_supported_apps(app_names) --> void
			set _supported_apps to app_names
		end set_supported_apps

		-- @param[in]  string|boolean Description of chosen size (or 'false'); to be parsed
		-- @param[out] boolean _is_mobile
		-- @param[out] string|boolean _new_size Formatted size, e.g., "1024x768" (or 'false')
		-- @param[out] int    _new_width
		-- @param[out] int    _new_height
		-- @return Nothing
		on set_new_size(new_size) --> void
			if new_size is false then
				set _new_size to false
				return
			end if
			_set_mobile(new_size is in _mobile_sizes) -- boolean arg
			_parse_window_size(new_size) -- sets {_new_size, _new_width, _new_height}
		end set_new_size

		-- @param boolean Should only the window width be resized?
		on set_width_only(true_or_false) --> void
			my Util's validate_boolean_arg(true_or_false, "set_width_only")
			set _is_width_only to true_or_false
		end set_width_only

		-- @param boolean Should the Mac menu bar height be subtracted?
		on set_subtract_mac_menu(true_or_false) --> void
			my Util's validate_boolean_arg(true_or_false, "set_subtract_mac_menu")
			set _should_subtract_mac_menu to true_or_false
		end set_subtract_mac_menu

		-- @param int New window width
		on set_width(val) --> void
			set _right to _left + val
		end set_width

		-- @param int New window height
		on set_height(val) --> void
			set _bottom to _top + val
		end set_height

		-- @param int Value to add or substract from window width
		on adjust_width(val) --> void
			set _right to _right + val
		end adjust_width

		-- @param int Value to add or substract from window height
		on adjust_height(val) --> void
			--log "adjust_height(" & val & ")"
			--log "adjust_height(): set bottom to " & (_bottom + val)
			set _bottom to _bottom + val
		end adjust_height

		-- @param string Alert dialog title
		on set_alert_title(val) --> void
			set _alert_title to val
		end set_alert_title

		-- @param string Alert dialog message
		on set_alert_msg(val) --> void
			set _alert_msg to val
		end set_alert_msg

		(* == Getters == *)

		on get_supported_apps() --> array
			return _supported_apps
		end get_supported_apps

		on get_supported_apps_as_string() --> string
			my Util's join_list(_supported_apps, ", ")
		end get_supported_apps_as_string

		on get_new_size() --> string (or bool false)
			return _new_size
		end get_new_size

		on is_mobile() --> boolean
			return _is_mobile
		end is_mobile

		on is_width_only() --> boolean
			return _is_width_only
		end is_width_only

		on should_prompt_mac_menu() --> boolean
			return _should_prompt_mac_menu
		end should_prompt_mac_menu

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

on make_ui(app_model, app_controller) --> View
	script
		property _model : app_model -- Model
		property _controller : app_controller -- Controller

		property _size_choice : missing value -- string
		property _app_name : app_model's get_name() -- string

		(* == View Components == *)

		property _dialog_title : __SCRIPT_NAME__
		property _u_dash : Çdata utxt2500È as Unicode text -- BOX DRAWINGS LIGHT HORIZONTAL
		property _menu_rule : my Util's multiply_text(_u_dash, 21) -- string

		property _width_increments : {"Width + 1px", "Width - 1px", "Width + 10px", "Width - 10px"}
		property _height_increments : {"Height + 1px", "Height - 1px", "Height + 10px", "Height - 10px"}
		property _custom_options : {"Custom SizeÉ", "Custom WidthÉ", "Custom HeightÉ"}

		-- main dialog menu
		property _menu : _model's _mobile_sizes & Â
			_menu_rule & Â
			_model's _desktop_sizes & Â
			_menu_rule & Â
			_width_increments & Â
			_menu_rule & Â
			_height_increments & Â
			_menu_rule & Â
			_custom_options & Â
			_menu_rule & Â
			("About" & space & __SCRIPT_NAME__) -- array

		(* == View Methods == *)

		on show_view() --> void
			local m
			tell _model
				set m to "Choose a size for " & get_name() & "'s front window" & return & "(currently " & get_width() & "x" & get_height() & "):"
			end tell
			tell application _app_name to activate
			repeat -- until a horizontal rule is not selected
				tell application _app_name
					choose from list _menu default items {_menu's item 14} with title _dialog_title with prompt m
				end tell
				set action_event to result
				if action_event as string is not _menu_rule then
					exit repeat
				else
					tell application _app_name
						display alert "Invalid selection" message "Try again." as warning
					end tell
				end if
			end repeat
			_action_performed(action_event)
		end show_view

		on which_dimensions() --> void
			local m
			tell _model
				set m to "Resize both the window's width and height (" & get_new_width() & "x" & get_new_height() & ") or just the width (" & get_new_width() & ")?"
			end tell
			set b to {"Cancel", "Width & Height", "Width-only"}
			tell application _app_name
				display dialog m with title _dialog_title buttons b default button 3
			end tell
			set dimension_choice to button returned of result
			_controller's set_width_only(dimension_choice is b's item 3) -- boolean arg

			if not _model's is_width_only() and not _model's is_mobile() and _model's should_prompt_mac_menu() then
				set m to "Subtract Mac menu bar height (" & _model's get_mac_menu_bar() & "px)?"
				set b to {"Cancel", "Subtract Mac Menu Bar", "Don't Subtract"}
				tell application _app_name
					display dialog m with title _dialog_title buttons b default button 3
				end tell
				set mac_menu_choice to button returned of result
				_controller's set_subtract_mac_menu(mac_menu_choice is b's item 2) -- boolean arg
			end if
		end which_dimensions

		on display_alert() --> void
			set t to _dialog_title & ": " & _model's get_alert_title()
			tell application _app_name
				display alert t message _model's get_alert_msg() as warning
			end tell
		end display_alert

		(* == PRIVATE == *)

		on _action_performed(action_event) --> void -- PRIVATE
			if action_event is false then error number -128 -- User canceled
			set action_event to action_event as string

			if action_event is _menu's last item then
				_display_about()
			else if action_event is in _custom_options then
				_prompt_custom(action_event)
			else if action_event is in _width_increments & _height_increments then
				_controller's increment_width_or_height(action_event)
			else
				_controller's set_new_size(action_event)
			end if
		end _action_performed

		on _display_about() --> void -- PRIVATE
			_controller's set_done() -- no window resizing
			set t to __SCRIPT_NAME__
			set b to {"License", "Help", "OK"}
			set m to Â
				"Resize the front window of any application." & return & return Â
				& "Version " & __SCRIPT_VERSION__ & return & return & return & return Â
				& __SCRIPT_COPYRIGHT__ & return & return Â
				& __SCRIPT_LICENSE_SUMMARY__ & return
			with timeout of (10 * 60) seconds
				tell application _app_name
					display alert t message m buttons b default button 3
				end tell
			end timeout
			set btn_choice to button returned of result
			if btn_choice is b's item 1 then
				with timeout of (10 * 60) seconds
					tell application _app_name
						display alert t message __SCRIPT_LICENSE__
					end tell
				end timeout
			else if btn_choice is b's item 2 then
				_display_help()
			end if
		end _display_about

		on _display_help() --> void -- PRIVATE
			set t to __SCRIPT_NAME__ & space & "Help"
			set b to {"Website", "OK"}
			set m to "Resize Window can resize the frontmost window of any application (except Script Editor and Terminal which are excluded since they are often used to run scripts during development)." & return & return Â
				& "The first group of options is for preconfigured mobile sizes. Windows for supported apps (" & _model's get_supported_apps_as_string() & ") will be resized by the window content area. For all other apps, the overall window frame will be resized to match the selected size. In all cases, you can choose to resize just the width without resizing the height." & return & return Â
				& "The second group of options is for preconfigured desktop sizes. The overall window frame is resized to match those dimensions with the option to subtract the height of the Mac menu bar (23px). Like the mobile sizes, you will also be presented with the option to only resize the width without resizing the height." & return & return Â
				& "The next two groups of options are for incrementing or decrementing either the window width or window height by 1px or 10px." & return & return Â
				& "The final group of options is for entering custom values. Select \"Custom Size\" to enter custom values for both width and height. The other two options are for entering a custom value for just the width or just the height. For all three custom options, a \"+\" or \"-\" sign can be prefixed to any integer in order to add or subtract that amount instead of setting an exact value." & return
			with timeout of (10 * 60) seconds
				tell application _app_name
					display alert t message m buttons b default button 2
				end tell
			end timeout
			set btn_choice to button returned of result
			if btn_choice is b's item 1 then
				_controller's go_to_website()
			end if
		end _display_help

		on _prompt_custom(action_event) --> void -- PRIVATE
			set bp to "Any number can be prefixed with \"+\" or \"-\" to add or subtract that amount instead of setting a specific size."

			if action_event is _custom_options's item 1 then
				set m to "Enter a custom width and height separated by an \"x\". The current window size is prefilled by default." & return & return & bp
				set a to _model's get_width() & "x" & _model's get_height() as string
			else if action_event is _custom_options's item 2 then
				set m to "Enter a custom width. The current window width is prefilled by default." & return & return & bp
				set a to _model's get_width()
			else
				set m to "Enter a custom height. The current window height is prefilled by default." & return & return & bp
				set a to _model's get_height()
			end if

			tell application _app_name
				display dialog m with title _dialog_title default answer a
			end tell
			set action_input to text returned of result

			if action_event is _custom_options's item 1 then
				_controller's set_new_size(action_input)
			else if action_event is _custom_options's item 2 then
				_controller's set_width(action_input)
			else
				_controller's set_height(action_input)
			end if
		end _prompt_custom
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
			set this_app to missing value
			repeat with this_product in _registered_products
				if app_name is this_product's to_string() then
					set this_app to this_product
					exit repeat
				end if
			end repeat
			if this_app is missing value then
				-- fallback to generic app window w/o inner dimension support
				set this_app to make_app_window() --> AppWindow superclass (Model)
			end if
			this_app's init(app_name)
			this_app's set_supported_apps(_get_app_names())
			return this_app
		end make_window

		on _get_app_names() --> array -- PRIVATE
			set app_names to {}
			repeat with this_product in _registered_products
				set end of app_names to this_product's to_string()
			end repeat
			return app_names
		end _get_app_names
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

		on reset_gui(app_process) --> void
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

		on set_default_alert(extra_msg) --> void
			set t to "Couldn't target window content area for resizing"
			set m to "The height of the content area of the window could not be resized to the selected mobile dimensions, so the overall window frame height was resized instead." & return & return & "If you would like the content area resizing feature, try enabling JavaScript in your web browser if it's not already enabled and rerun the script."
			if extra_msg is not "" then set m to m & space & extra_msg
			set_alert(t, m)
		end set_default_alert

		on set_alert(this_title, this_msg) --> void
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

		on calculate_size() --> void
			continue calculate_size() -- call superclass's method first

			-- Resize mobile sizes by the window content area instead of the
			-- window bounds
			if my is_mobile() and not my is_width_only() then
				set window_chrome_height to 0
				set doc_height to 0
				set extra_alert_msg to ""

				set os_version to system version of (system info)
				tell application (my _app_name) to set app_version to version

				-- Try JavaScript first since it's faster than GUI Scripting

				--log "calculate_size(): trying JavaScript"
				try
					using terms from application "Safari"
						tell application (my _app_name)
							set doc_height to (do JavaScript my _js in document 1) as integer
						end tell
					end using terms from
				on error err_msg number err_num
					considering numeric strings -- version strings
						set is_at_least_safari_9_1_1 to app_version is greater than or equal to "9.1.1"
					end considering
					if is_at_least_safari_9_1_1 and err_num is 8 then
						--
						-- As of Safari 9.1.1 (on Yosemite or later), the
						-- default is to disallow JavaScript from Apple Events,
						-- so the user must specifically enable that
						-- functionality. (Safari 9.1.1 also runs on Mavericks,
						-- but does not include the new restriction and thus
						-- does not return error number 8.)
						--
						set extra_alert_msg to "As of Safari 9.1.1, you will also need to:" & return & return Â
							& "    ¥ Enable the Develop menu in Safari if not already enabled in Safari's Advanced preferences." & return & return Â
							& "    ¥ Enable \"Allow JavaScript from Apple Events\" in Safari's Develop menu." & return
					end if
				end try

				if doc_height > 0 then
					--log "calculate_size(): adjusting height with JavaScript result"
					my adjust_height((my _height) - doc_height)
					return
				end if

				-- If JavaScript failed, try GUI scripting

				my UI_Scripting's gui_scripting_status()
				tell application "System Events" to tell application process (my _app_name)
					set frontmost to true
					my reset_gui(it)
					tell window 1 to set ui_element to it
				end tell

				set ui_scroll_area to _find_scroll_area(ui_element, app_version, os_version)
				--log "calculate_size(): ui_scroll_area = " & ui_scroll_area's class

				if ui_scroll_area is not missing value then
					--log "calculate_size(): UI Scripting can be used"
					considering numeric strings -- version strings
						if app_version is greater than or equal to 8 and app_version < 9 then
							--
							-- Safari 8 has a major accessibility bug requiring
							-- lots of hoop jumping. The bug is that
							-- AXScrollArea reports an incorrect value for its
							-- AXSize (it includes more than just its visible
							-- scroll area). So values from a bunch of other
							-- properties are needed instead to make the
							-- calculations.
							--
							-- Note: Instead of calling this workaround method,
							-- the usual ui_element_size() could be used by
							-- passing it AXScrollArea.AXVerticalScrollBar
							-- (pseudocode), but that's just relying on another
							-- (related) Safari 8-specific bug.
							--
							try
								set window_chrome_height to my UI_Scripting's safari_8_chrome_height(ui_scroll_area)
							on error err_msg number err_num
								set window_chrome_height to 0
								--error err_msg number err_num -- debug-only
							end try
						else
							--
							-- This should work for most other cases and is
							-- preferred since it requires less work/fewer
							-- calculations.
							--
							try
								set ui_scroll_size to my UI_Scripting's ui_element_size(ui_scroll_area)
								set doc_height to ui_scroll_size's last item
							on error err_msg number err_num
								set doc_height to 0
								--error err_msg number err_num -- debug-only
							end try
						end if
					end considering
				end if -- ui_scroll_area is not missing value

				if window_chrome_height > 0 then
					--log "calculate_size(): GUI Scripting adding window chrome (" & Â
					--window_chrome_height & ") to target height"
					my set_height((my get_new_height()) + window_chrome_height)
				else if doc_height > 0 then
					--log "calculate_size(): adjusting height with GUI Scripting result"
					--log "Adjusting height using scroll area height: " & doc_height
					my adjust_height((my _height) - doc_height)
				else
					my set_default_alert(extra_alert_msg)
				end if
			end if -- my is_mobile() and not my is_width_only()
		end calculate_size

		(* == Private == *)

		on _find_scroll_area(ui_element, app_version, os_version)
			set ui_scroll_area to missing value

			repeat with idx from 1 to 10 -- give GUI scripting up to a second
				--
				-- GUI scripting is very fragile. Software updates (both
				-- application and OS) frequently break it as evidenced by all
				-- the different methods below needed to access the browser
				-- content area across different versions of OS X and Safari.

				-- Try targeted searches for known/tested OS/app versions first
				-- since it will be quicker. If the targeted searches fail, a
				-- generic recursive search of all UI elements for a scroll
				-- area containing a web area will be tried. That will be much
				-- slower.
				--
				--log "_find_scroll_area(ui_element): try #" & idx
				try
					considering numeric strings -- for version strings
						if app_version < "9" or os_version < "10.10" then
							--log "app_version < 9 or os_version < 10.10"
							--
							-- The window group number depends on what
							-- combination of Favorites Bar and Status Bar
							-- (either, both, or none) is showing, so try until
							-- hopefully the right combination is found.
							--
							set {err_msg, err_num} to {missing value, missing value}
							repeat with i from 1 to 3
								--log "Trying AXGroup " & i & "..."
								using terms from application "System Events"
									try
										set ui_scroll_area to ui_element's group i's group 1's group 1's scroll area 1
										set {err_msg, err_num} to {missing value, missing value}
										exit repeat
										--on error err_msg number err_num
										--log "Error: AXGroup " & i & " failed"
									end try
								end using terms from
							end repeat
							if {err_msg, err_num} is not {missing value, missing value} then
								error err_msg number err_num
							end if
						else if os_version < "10.11" then
							--log "os_version < 10.11"
							--
							-- Safari 9 on OS X 10.10 changed one element (to
							-- an AXTabGroup rather than one of many AXGroup
							-- elements), eliminating the need for a loop.
							--
							using terms from application "System Events"
								set ui_scroll_area to ui_element's tab group 1's group 1's group 1's scroll area 1
							end using terms from
						else
							--log "os_version >= 10.11"
							--
							-- El Capitan added an AXSplitGroup, but kept the
							-- rest of the UI element hierarchy the same as
							-- Yosemite.
							--
							using terms from application "System Events"
								set ui_scroll_area to ui_element's splitter group 1's tab group 1's group 1's group 1's scroll area 1
							end using terms from
						end if
					end considering
					exit repeat
				on error
					delay 0.1 -- give the UI time to catch up
				end try
			end repeat

			-- Make sure the found scroll area contains a web area
			if ui_scroll_area is not missing value then
				if not (my UI_Scripting's contains_web_area(ui_scroll_area)) then
					set ui_scroll_area to missing value
				end if
			end if
			--set ui_scroll_area to missing value -- :DEBUG: test recursive search

			--
			-- If the targeted searches above for a scroll area (containing a
			-- web area) did not work, fall back to a recursive search of all
			-- UI elements as a last resort. It will be much slower though.
			--
			--
			if ui_scroll_area is missing value then
				set ui_search_roles to {"AXTabGroup", "AXGroup", "AXScrollArea", "AXWebArea", "AXSplitGroup", "AXUnknown"}
				set ui_scroll_area to my UI_Scripting's find_ui_scroll_area_in_roles(ui_element, ui_search_roles)
			end if
			--set ui_scroll_area to missing value -- :DEBUG: test UI Scripting failure

			return ui_scroll_area
		end _find_scroll_area
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

		on calculate_size() --> void
			continue calculate_size() -- call superclass's method first
			-- Resize mobile sizes by the window content area instead of the
			-- window bounds
			if my is_mobile() and not my is_width_only() then
				set doc_height to 0
				set extra_alert_msg to ""
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
					my adjust_height((my _height) - doc_height)
				else
					my set_default_alert(extra_alert_msg)
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

		on calculate_size() --> void
			continue calculate_size() -- call superclass's method first
			-- Resize mobile sizes by the window content area instead of the
			-- window bounds.
			if my is_mobile() and not my is_width_only() then
				-- XXX: Firefox doesn't provide access to the window content
				-- area dimensions so just use a best-guess hardcoded value
				-- (which could become outdated with app updates or if other
				-- toolbars are installed or hidden).
				my adjust_height(102) -- tab bar + bookmarks toolbar
			end if
		end calculate_size
	end script
end make_firefox_window*)

-- Just an example. It works, but it's not necessary, so don't register it with
-- the factory in the final script.
(*on make_textedit_window() --> concrete product
	script
		property class : "TextEditWindow"
		property parent : make_supported_app() -- extends SupportedApp
		property short_name : "TextEdit"

		on calculate_size() --> void
			continue calculate_size() -- call superclass's method first
			if my is_mobile() and not my is_width_only() then
				my UI_Scripting's gui_scripting_status() -- requires GUI scripting
				tell application "System Events" to tell application process (my _app_name)
					tell window 1's scroll area 1's text area 1
						set doc_height to (attribute "AXSize"'s value as list)'s last item
					end tell
				end tell
				my adjust_height((my _height) - doc_height)
			end if
		end calculate_size
	end script
end make_textedit_window*)


(* ==== Miscellaneous Classes ==== *)

-- XXX: This hack does not work. Apparently, a Standard Additions command can't
-- be overridden if it's triggered internally by AppleScript rather than called
-- by the script. See the handle_termination() handler for another workaround
-- and details about the reason it's needed.
(*on choose application --with prompt _msg
	display dialog "DEBUG: " --& _msg
	return missing value
end choose application*)

script Util -- Utility Functions
	on handle_termination() --> void
		-- XXX: Hack to prevent \"Choose Application\" dialog for missing apps
		--
		-- See: http://lists.apple.com/archives/applescript-users/2008/Mar/msg00225.html
		--
		-- Suggestions for a better solution welcome. One idea might be to
		-- implement support for third-party apps as a script plug-in for each
		-- app that a user can choose to install, but that would require coding
		-- up a whole plug-in infrastructure and make the installation process
		-- more complicated. Would probably also need to write an installer to
		-- make installation easier. For now, this hack is probably good enough
		-- unless any issues with it are reported.
		--
		-- NOTE: Suppress the error when running the script from Script Editor.
		--
		if current application's name is not in {"Script Editor", "AppleScript Editor"} then
			set err_msg to "Not really an error, just a hack to prevent a \"Choose Application\" dialog for missing apps."
			--set err_num to -1708 -- errAEEventNotHandled = "AppleEvent not handled by any handler"
			set err_num to -128 -- "User canceled" (so FastScripts will ignore it)
			error err_msg number err_num
		end if
	end handle_termination

	on get_front_app_name(apps_to_ignore) --> string
		tell application "System Events"

			-- Ignore given list of apps (usually (Apple)Script Editor and
			-- Terminal) when getting the front app name. Usually the ignored
			-- apps are mostly just used during development and testing to run
			-- the script.
			repeat 10 times -- limit repetitions just in case
				set frontmost_process to first process where it is frontmost
				if short name of frontmost_process is in apps_to_ignore then
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

	on error_with_alert(err_title, msg) --> void
		display alert err_title message msg as critical buttons {"Cancel"} default button 1
		error number -128 -- User canceled
	end error_with_alert

	on validate_boolean_arg(boolean_arg, func_name) --> void
		try
			boolean_arg as boolean
		on error err_msg number err_num
			error func_name & "(): Boolean argument required. " & err_msg number err_num
		end try
	end validate_boolean_arg

	on multiply_text(str, n) --> string
		if n < 1 or str = "" then return ""
		set lst to {}
		repeat n times
			set end of lst to str
		end repeat
		return lst as string
	end multiply_text

	on split_text(txt, delim) --> array
		set old_tids to AppleScript's text item delimiters
		try
			set AppleScript's text item delimiters to (delim as string)
			set lst to every text item of (txt as string)
			set AppleScript's text item delimiters to old_tids
			return lst
		on error err_msg number err_num
			set AppleScript's text item delimiters to old_tids
			error "Can't split_text(): " & err_msg number err_num
		end try
	end split_text

	on join_list(lst, delim)
		set old_tids to AppleScript's text item delimiters
		try
			set AppleScript's text item delimiters to (delim as string)
			set txt to lst as string
			set AppleScript's text item delimiters to old_tids
			return txt
		on error err_msg number err_num
			set AppleScript's text item delimiters to old_tids
			error "Can't join_list(): " & err_msg number err_num
		end try
	end join_list
end script

script UI_Scripting -- UI Scripting Helpers
	on gui_scripting_status() --> void
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
			-- In Mavericks (10.9) and later, the system should prompt the user
			-- with instructions on granting accessibility access, so try to
			-- trigger that.
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
				-- In some cases, the system prompt doesn't appear, so always
				-- give some info.
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


	-- @param UI element
	-- @return list (width, height)
	on ui_element_size(ui_element)
		--log "ui_element_size(ui_element)"
		--error "[DEBUG] throwing ui_element_size() error" -- catch in caller
		using terms from application "System Events"
			return ui_element's attribute "AXSize"'s value as list
		end using terms from
	end ui_element_size


	-- Calculate the window chrome height (top and bottom) for Safari 8.
	--
	-- For now, this is only used for working around a Safari 8 accessibility
	-- bug in which it does not report the correct content area height. It
	-- requires a lot more work than the ui_element_size() method, and because
	-- so many different elements are involved, there's no guarantee that this
	-- method will work for any other version of Safari or other apps. (Update:
	-- It works with Safari 9, but not Safari 7, so just use it to work around
	-- the Safari 8 bug.)
	--
	-- @param scroll area UI element (AXScrollArea)
	-- @return integer Window chrome height including top and bottom chrome
	--
	on safari_8_chrome_height(ui_scroll_area)
		--log "safari_8_chrome_height(ui_scroll_area)"
		--error "[DEBUG] throwing safari_8_chrome_height() error" -- catch in caller

		set {x, y, w, h} to {1, 2, 3, 4} -- AXFrame indexes
		using terms from application "System Events"
			set scroll_area_frame to ui_scroll_area's attribute "AXFrame"'s value as list
			set window_frame to ui_scroll_area's attribute "AXWindow"'s value's attribute "AXFrame"'s value as list
			set parent_frame to ui_scroll_area's attribute "AXParent"'s value's attribute "AXFrame"'s value as list
		end using terms from

		(*log "AXScrollArea.AXFrame.y = " & scroll_area_frame's item y
		log "AXWindow.AXFrame.y = " & window_frame's item y
		log "AXWindow.AXFrame.h = " & window_frame's item h
		log "AXParent.AXFrame.h = " & parent_frame's item h*)

		set top_chrome_height to (scroll_area_frame's item y) - (window_frame's item y)
		set btm_chrome_height to (window_frame's item h) - (parent_frame's item h)

		(*log "top_chrome_height = " & top_chrome_height
		log "btm_chrome_height = " & btm_chrome_height*)

		return top_chrome_height + btm_chrome_height
	end safari_8_chrome_height


	-- Check if a UI Element contains a single web area (more than one would be
	-- ambiguous)
	on contains_web_area(ui_element) --> boolean
		using terms from application "System Events"
			set web_areas to (get every UI element of ui_element whose role is "AXWebArea")
			(*repeat with this_web_area in web_areas -- :DEBUG:
				log this_web_area's role as text
			end repeat*)
		end using terms from
		return (web_areas's length = 1)
	end contains_web_area


	-- @param 1 ui_element UI element whose children should be searched
	-- @param 2 ui_search_roles Array of UI element roles (strings) to match against
	-- @return Array of UI elements matching the search roles
	--
	on ui_elements_of_roles(ui_element, ui_search_roles)
		-- Couldn't find any variation of this that worked
		(*using terms from application "System Events"
			return (UI elements of ui_element whose role is in ui_search_roles)
		end using terms from*)
		--
		-- Can't find any variation of  '... whose role is in {"AXGroup",
		-- "AXTabGroup", ...}' that works, so need to loop through each
		-- individual 'whose' comparison.  Still faster than looping through
		-- every item without a 'whose' filter, but concatenating lists
		-- is slow.
		--
		set ui_elements to {}
		script s -- list speed hack
			-- These lists don't appear to be the source of any major slow-downs though.
			property ui_elements_ref : ui_elements
			property ui_search_roles_ref : ui_search_roles
		end script
		repeat with this_role in s's ui_search_roles_ref
			using terms from application "System Events"
				set s's ui_elements_ref to s's ui_elements_ref & (get every UI element of ui_element whose role is this_role)
			end using terms from
		end repeat
		return s's ui_elements_ref's contents
	end ui_elements_of_roles


	-- @param 1 ui_element UI element whose children should be searched
	-- @param 2 ui_search_roles Array of UI element roles (strings) to match
	-- @return An AXScrollArea UI element or 'missing value' if not found
	--
	-- If there is only one web area and its parent is a scroll area, that
	-- scroll area is probably what we're looking for. Otherwise, if there is
	-- only one scroll area, that's probably a good fallback to try. If there
	-- is more than one web area or scroll area, then there's probaly no easy
	-- and reliable way to determine the correct one.
	--
	on find_ui_scroll_area_in_roles(ui_element, ui_search_roles)
		--log "find_ui_scroll_area_in_roles()"

		-- Lists populated by find_ui_element() call
		set web_areas to {} -- web area parent scroll area preferred
		set scroll_areas to {} -- fallback

		-- List of UI elements matching AXRoles in given list
		set ui_elements to my ui_elements_of_roles(ui_element, ui_search_roles)

		-- Search recursively in for UI elements matching given roles.
		-- Modifies {scroll_areas, web_areas} in place. No need to capture
		-- return value because AppleScript passes lists to handlers by
		-- reference.
		find_ui_element(ui_search_roles, ui_elements, {"AXScrollArea", "AXWebArea"}, {scroll_areas, web_areas}, 0)

		set this_scroll_area to missing value

		-- web area parent scroll area preferred
		if (count of web_areas) = 1 then
			set this_web_area to web_areas's item 1
			using terms from application "System Events"
				--log ("== " & this_web_area's role as text) & " =="
				set web_area_parent to this_web_area's attribute "AXParent"'s value

				(*log ("---- " & web_area_parent's role as text) & " ----"
				log web_area_parent's attribute "AXSize"'s value as list
				log ("---- " & this_web_area's role as text) & " ----"
				log this_web_area's attribute "AXSize"'s value as list*)

				if (web_area_parent's role as text) is "AXScrollArea" then
					return web_area_parent
				end if
			end using terms from
		end if

		-- scroll area fallback if no web area found
		if (count of scroll_areas) = 1 then
			set this_scroll_area to scroll_areas's item 1

			(*using terms from application "System Events"
				log ("== " & this_scroll_area's role as text) & " =="
				log this_scroll_area's attribute "AXSize"'s value as list
			end using terms from*)
		end if

		return this_scroll_area
	end find_ui_scroll_area_in_roles


	-- Search recursively in an array of UI elements for an element matching a
	-- given role
	--
	-- @param 1 ui_search_roles Array of UI element roles to search (needed for recursion)
	-- @param 2 ui_elements Array of UI elements to search
	-- @param 3 ui_roles Array of AX roles (as strings) to match against
	-- @param 4 element_arrays Array of empty arrays to be populated with matches corresponding to ui_roles.
	-- @param 5 ui_idx Integer for recursively debugging UI element hierarchy. Always start with 0.
	-- @return element_arrays Array from argument, but populated with UI elements matching ui_roles.
	--
	on find_ui_element(ui_search_roles, ui_elements, ui_roles, element_arrays, ui_idx)
		set ui_idx to ui_idx + 1 -- for recursion debugging

		script s -- list speed hack
			-- This list doesn't appear to be the source of any major
			-- slow-downs though.  The recursion is probably the slow bit. Or
			-- maybe it's just UI Scripting in general that's so slow.
			property ui_elements_ref : ui_elements

			-- This is probably not necessary at all for this script since the
			-- array should only be an array of a couple of arrays containing
			-- one or two items each. Testing it doesn't show any noticeable
			-- speed difference.
			--property element_arrays_ref : element_arrays
		end script

		using terms from application "System Events"
			repeat with this_element in s's ui_elements_ref
				--log "[UI level " & ui_idx & "] " & this_element's role as text

				-- Find element:
				--
				repeat with i from 1 to ui_roles's length
					set this_role to ui_roles's item i
					set this_array to element_arrays's item i
					(*script s2 -- list speed hack
						-- This doesn't seem to make any difference
						property this_array : s's element_arrays_ref's item i
					end script*)
					if (this_element's role as text) is this_role then
						--log "[UI level " & ui_idx & "] Found an " & this_element's role as text
						set end of this_array to this_element's contents -- 'contents' = dereference
						--set end of s2's this_array to this_element's contents
					end if
				end repeat

				-- Recursively search for more elements:
				--
				-- DO NOT recurse inside an AXWebArea. If multiple tabs are
				-- open, that's a multi-minute operation
				if (this_element's role as text) is not "AXWebArea" then
					set these_ui_elements to ui_elements_of_roles(this_element, ui_search_roles)
					find_ui_element(ui_search_roles, these_ui_elements, ui_roles, element_arrays, ui_idx)
				end if
			end repeat
		end using terms from
		return element_arrays
	end find_ui_element
end script
