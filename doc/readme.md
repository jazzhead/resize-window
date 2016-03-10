Resize Window
=============

**Version:**       |  @@VERSION@@
**Released:**      |  @@RELEASE_DATE@@
**Author:**        |  Steve Wheeler
**Website:**       |  [jazzheaddesign.com][website]
**Requirements:**  |  Mac OS X

  [website]: http://jazzheaddesign.com/work/code/resize-window/

Description
-----------

Resize Window is an AppleScript program for Mac OS X that quickly resizes the
frontmost window of any application to some common sizes as well as custom
sizes and increments. Although the script works with any Mac application, it is
most useful for resizing web browser windows while designing responsive
websites that adapt to different sizes.


Features
--------

* Select from a list of common web browser window sizes, both mobile and
  desktop.

* For the preconfigured mobile sizes, windows for supported apps (Safari and
  Google Chrome) will be resized by the inner window content area. For desktop
  sizes and all other apps, the overall window frame is resized to the selected
  dimensions.

* Choose to adjust only the width or both the width and the height.

* When adjusting the height, choose whether or not to subtract the OS X menu
  bar height.

* Increment the width or height plus or minus 1 pixel or 10 pixels.

* Increment/decrement the width, height, or both by custom values.

* Specify a custom width and/or height.


Screen Shots
------------

Resize windows by preconfigured mobile sizes:

  ![Mobile sizes](../_build/img/mobile-sizes.png "Mobile sizes screen shot")

Resize windows by preconfigured desktop sizes:

  ![Desktop sizes](../_build/img/desktop-sizes.png "Desktop sizes screen shot")

Resize windows by custom sizes:

  ![Custom size](../_build/img/custom-size.png "Custom size screen shot")

Resize windows by custom widths, heights, or increments (custom width increment
shown here):

  ![Custom width](../_build/img/custom-width.png "Custom width screen shot")


Installation
------------

### Create the Installation Folder

The script needs to be installed in the Scripts folder in the Library folder of
your home directory. Since the script can be used with any application, if you
like to keep your scripts grouped, you may want to put it in a subdirectory
such as "General", i.e., `~/Library/Scripts/General`. If any of those folders
do not exist yet on your system, go ahead and create them. The Library folder
will already exist but may not be visible in the Finder in Mac OS X Lion (10.7)
or later. To get to the invisible Library folder, Option-click the Finder's Go
menu and select the Library menu item that appears.

### Install the Script

Double-click to expand the downloaded .zip archive. Move the script file to the
folder created above. You can also move this README file to the same location
to easily find it if you need it.

### Enable the Script Menu

If you're not already using a third-party script runner, enable Apple's Script
menu. The procedure for enabling the menu is different depending on which
version of Mac OS X you're running. For Snow Leopard (10.6) and later, it is a
preference setting in the Script Editor app called "Show Script menu in menu
bar":

  ![Script menu setting](img/common/scriptmenu-s.png "Screen shot of Script menu setting")


Development
-----------

This script is written using object-oriented design patterns including
Model-View-Controller (MVC) and the Factory Pattern. A Makefile is used to
compile the script and generate the documentation. The [source code][] is
available on GitHub.

  ![Source code](../_build/img/dev-source.png "Source code screen shot")

  [source code]: https://github.com/jazzhead/resize-window


Bugs
----

Please report any bugs using the GitHub [issue tracker].

  [issue tracker]: https://github.com/jazzhead/resize-window/issues


Credits
-------

Resize Window was written by [Steve Wheeler](http://www.swheeler.com/).


License
-------

This program is free software available under the terms of a BSD-style
(3-clause) open source license detailed below.

---

