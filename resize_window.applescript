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

			set app_model to app_factory's make_window(my Util's get_front_app_name()) --> Model
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
			if first character of val is in {"+", "-"} then -- increment/decrement the size
				if width_or_height is "width" then
					_model's adjust_width(val as integer)
				else
					_model's adjust_height(val as integer)
				end if
			else -- exact size
				if width_or_height is "width" then
					_model's set_width(val as integer)
				else
					_model's set_height(val as integer)
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
			repeat -- until a horizontal rule is not selected
				set action_event to choose from list _menu default items {_menu's item 14} with title _dialog_title with prompt m
				if action_event as string is not _menu_rule then
					exit repeat
				else
					display alert "Invalid selection" message "Try again." as warning
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
			display dialog m with title _dialog_title buttons b default button 3
			set dimension_choice to button returned of result
			_controller's set_width_only(dimension_choice is b's item 3) -- boolean arg

			if not _model's is_width_only() and not _model's is_mobile() and _model's should_prompt_mac_menu() then
				set m to "Subtract Mac menu bar height (" & _model's get_mac_menu_bar() & "px)?"
				set b to {"Cancel", "Subtract Mac Menu Bar", "Don't Subtract"}
				display dialog m with title _dialog_title buttons b default button 3
				set mac_menu_choice to button returned of result
				_controller's set_subtract_mac_menu(mac_menu_choice is b's item 2) -- boolean arg
			end if
		end which_dimensions

		on display_alert() --> void
			set t to _dialog_title & ": " & _model's get_alert_title()
			tell application (_model's get_name())
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
				display alert t message m buttons b default button 3
			end timeout
			set btn_choice to button returned of result
			if btn_choice is b's item 1 then
				with timeout of (10 * 60) seconds
					display alert t message __SCRIPT_LICENSE__
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
				display alert t message m buttons b default button 2
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

			display dialog m with title _dialog_title default answer a
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

		on set_default_alert() --> void
			set t to "Couldn't target window content area for resizing"
			set m to "The height of the content area of the window could not be resized to the selected mobile dimensions, so the overall window frame height was resized instead." & return & return & "Try enabling JavaScript if it's not already enabled and rerun the script."
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
				set doc_height to 0

				-- First try GUI scripting since it doesn't require JavaScript
				-- to be enabled
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
					my adjust_height((my _height) - doc_height)
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

		on calculate_size() --> void
			continue calculate_size() -- call superclass's method first
			-- Resize mobile sizes by the window content area instead of the
			-- window bounds
			if my is_mobile() and not my is_width_only() then
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
					my adjust_height((my _height) - doc_height)
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
				my Util's gui_scripting_status() -- requires GUI scripting
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

script Util -- Utility Functions
	on get_front_app_name() --> string
		tell application "System Events"

			-- Ignore (Apple)Script Editor and Terminal when getting the front
			-- app name since most of the time they will just be used during
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
end script
