Resize Window
=============

[Resize Window][website] is an AppleScript program for Mac OS X that quickly
resizes the frontmost window of any application to some common sizes as well as
custom sizes and increments. Although the script works with any Mac
application, it is most useful for resizing web browser windows while designing
responsive websites that adapt to different sizes.


Features
--------

* Select from a list of common browser window sizes.
* Increment the width plus or minus 1 pixel or 10 pixels.
* Type in a custom width and height.
* Choose to adjust only the width or both the width and the height.
* When adjusting the height, choose whether or not to subtract the OS X menu
  bar height.
* Display the current window size.

_Note: The sizes refer to the overall size of the window and not the interior
document size minus the window chrome. So the smaller sizes are mostly useful
for just testing the width for mobile devices. A few FPO images are included
along with the script though for loading into a browser window and quickly
eyeballing the fit and manually adjusting the window height._


Screen Shots
------------

  ![Initial dialog](doc/img/dialog-1-s.png "Screenshot of initial dialog")

  ![Resize dialog](doc/img/dialog-2-s.png "Screenshot of resize choice dialog")

  ![Menu bar dialog](doc/img/dialog-3-s.png "Screenshot of menu bar dialog")

  ![Custom size dialog](doc/img/dialog-4-s.png "Screenshot of custom size dialog")


Installation
------------

### Compile and Install the Script

To compile and install the script, `cd` into the directory containing the
source code and run:

~~~ bash
$ make
$ make install
~~~

That uses `osacompile` to create a compiled AppleScript named "Resize
Window.scpt" from the source file and installs it in a
`~/Library/Scripts/General` directory.

### Enable the Script Menu

If you're not already using a third-party script runner, enable Apple's Script
menu. The procedure for enabling the menu is different depending on which
version of Mac OS X you're running. For Snow Leopard (10.6) and later, it is a
preference setting in the AppleScript Editor app called "Show Script menu in
menu bar":

  ![Script menu setting](doc/img/scriptmenu-s.png "Screenshot of Script menu setting")


Bugs
----

Please report any bugs using the GitHub [issue tracker].


Credits
-------

Resize Window was written by [Steve Wheeler](http://swheeler.com/).


License
-------

Copyright &copy; 2014--2015 Steve Wheeler.

This program is free software available under the terms of a BSD-style
(3-clause) open source license. See the [LICENSE] file for details.


  [website]: http://jazzheaddesign.com/work/code/resize-window/
  [issue tracker]: https://github.com/jazzhead/resize-window/issues
  [LICENSE]: LICENSE
