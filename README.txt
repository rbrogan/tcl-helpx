
Helpx

README

CONTENTS OF THIS FILE
---------------------
01| HOW TO USE THIS DOCUMENT
02| INTRO
03| GETTING STARTED
04| DEPENDENCIES
05| BUILDING
06| INSTALLATION
07| CONFIGURATION
08| MANUAL
09| FAQ
10| PLATFORM NOTES
11| TROUBLESHOOTING
12| KNOWN ISSUES
13| BUG REPORTING
14| FEEDBACK
15| TESTING
16| CONTRIBUTING
17| UPDATING
18| RECENT CHANGES
19| LICENSE
20| LEGAL
21| CREDITS


---01| HOW TO USE THIS DOCUMENT

(Note that this README is designed to be filled out over the course of many
versions. Some sections are currently blank (e.g. Recent Changes) because it is
early in the project.)

You might prefer to use the website (http://www.robertbrogan.com/helpx) for
better and more up-to-date info instead. Otherwise, prefer to use HTML versions
as they are hyperlinked.

What is the software about?
See 01|INTRO.

Is it OK for me to use? OK for me to modify? OK to make copies?
See 19|LICENSE for info about the software license. License itself is in
LICENSE.txt.
See 20|LEGAL for any additional info.

How do I get it working?
See 03|GETTING STARTED (after you have it installed and configured) to see how
to use.
See 04|DEPENDENCIES for anything external that is required or optional.
See 05|BUILDING for how to compile from source (if even necessary).
See 06|INSTALLATION for how to install it on your system (and how to uninstall).
See 07|CONFIGURATION for how you can customize it for your own use.

I cannot make it work, what now?
See 11|TROUBLESHOOTING for dealing with problems with the software.
See 10|PLATFORM NOTES for ensuring it works with your platform/OS.
See 08|MANUAL to make sure you are using it correctly.
See 09|FAQ to see if your question has been answered.
See 12|KNOWN ISSUES to see if your problem is already known about (and any
workarounds / advice).
See 13|BUG REPORTING if you want to make a report and get follow-up.

What is in the other sections?
14|FEEDBACK - Info about things like feature requests.
15|TESTING - How you can test changes you make to the code.
16|CONTRIBUTING - How you improve the product for everyone.
17|UPDATING - How to get the latest changes.
18|RECENT CHANGES - What the latest changest are.
21|CREDITS - Who or what helped with making Helpx.

---02| INTRO

One of the nicest features about Tcl is its command documentation. Likewise, the
man pages for Linux can be very helpful and convenient. Would you like to add
such features to your Tcl programs?

Helpx will let you generate HTML pages that look like the core Tcl
documentation. Helpx also has a module that allows your users to pull up command
documentation right from the Tcl shell.

---03| GETTING STARTED

If you would like to confirm the library is installed and working then try the
following from a Tcl shell.

% package require helpx
0.2
% helpx helpx
SIGNATURE
    helpx {args}

DESCRIPTION
    Print out help info for given command.

RETURNS
    None.

ARGUMENTS
    args
         Command name or option flag (see More Info for list). Last argument will
be taken as the name of the command.

MORE INFO
    If you use no flags or -all then helpx will show all info. If you want
specific info only, then you can use one or more of the following flags.

    -arg : Arguments.

    -more : More Info section.

    -desc : Short (<= 60 words) description.

    -ex : Examples.

    -ret : Return Value.

    -sig : Signature.

    -see : See Also



SEE ALSO


EXAMPLE(S)

% helpx -sig String2File
SIGNATURE
String2File {StringValue OutFilePath}

You should be all set!

---04| DEPENDENCIES

Helpx uses the following packages, which you likely will already have got in
your Tcl distribution:

    sqlite3
    Tclx
    textutil::string
    textutil::split

If you do not have these, then check the documentation that came with your
distro for information on how to get them.

---05| BUILDING

Helpx is provided as a simple Tcl package and does not need to be built.

---06| INSTALLATION

If you are reading this you most likely have already successfully installed.

To install, extract the contents of the archive file (.zip or .tar.gz). That
will result in the following files:


README.txt
     Plenty of info on how to get going.
LICENSE.txt
     Terms of use and whatnot.
WARNING.txt
     Special notices to prevent surprises.
/src
     Source files
     pkgIndex.tcl
          Used by the TCL package mechanism.
     helpx.tcl
          Main script file.
/doc
     Any other documents (like the manual).
/test
     Test suite

You will probably want to add the following at the bottom of your init.tcl so
that Tcl can find the helpx package:

lappend auto_path YOUR_DIR_PATH

See 04|DEPENDENCIES for info about what Helpx may need.

See 07|CONFIGURATION for more info about init.tcl.

What to do after you install? You can check out the 03|GETTING STARTED section
of the README. We recommend browsing the manual (or even better, use the
helpx.chm file included in your download). Each command reference has at least
one example. You can type that directly into your terminal and try out the
command.

Prefer use to git and clone the repo? It is posted up for you at the following
locations: https://github.com/rbrogan/tcl-helpx

How to uninstall? To uninstall you can simply delete the directory. You can also
remove the lappend auto_path YOUR_DIR_PATH line from your Tcl init.

---07| CONFIGURATION

You will probably want to add the following at the bottom of your init.tcl so
that Tcl can find the helpx package:

lappend auto_path YOUR_DIR_PATH

How to find init.tcl? Here are some locations found for Windows and Linux. Most
likely if you use the number of your version then you can find your init.tcl in
a similar spot.

C:\Tcl\lib\tcl8.5\init.tcl
C:\Tcl\lib\tcl8.6\init.tcl
/usr/share/tcltk/tcl8.4/init.tcl
/usr/share/tcltk/tcl8.5/init.tcl

Alternatively, do a search for init.tcl starting from the root directory of your
installation.

Be sure to check this space when SQL-related commands are added.

---08| MANUAL

We have a few options. You can see the online manual at
http://www.robertbrogan.com/helpx/doc/manual-home.html (which will be the most
up-to-date).

Alternatively, you can use the offline version at doc/manual-home.html or
(preferrably) use the compiled HTML Help version at doc/helpx.chm.

---09| FAQ

No questions yet. We will put them here as we get them.

Please send questions you have to :

helpx.questions@robertbrogan.com or you can visit
http://www.robertbrogan.com/helpx/feedback.html and use the form there.

Also note, you may possibly find the answer to your question in 08|MANUAL,
10|PLATFORM NOTES, 11|TROUBLESHOOTING, or 12|KNOWN ISSUES.

---10| PLATFORM NOTES

If you have Tcl working for your platform, then the library should work without
problem.

None of the commands themselves include platform-specifc interactions (i.e. make
system calls) beyond occasionally calling another Tcl command that is
platform-specific (e.g. in an upcoming release the command Reg2Dict will call
the Tcl command registry, which is Windows-specific).

---11| TROUBLESHOOTING

No tips at this time.

Also note, you may possibly find help in 07|MANUAL, 09|PLATFORM NOTES, 08|FAQ,
or 11|KNOWN ISSUES.

---12| KNOWN ISSUES

None at this time.

None at this time. We will post them here as they arise.

---13| BUG REPORTING

Visit http://www.robertbrogan.com/helpx/feedback.html.

Alternatively, send an email to one of:

helpx.questions@robertbrogan.com
helpx.comments@robertbrogan.com
helpx.bugreport@robertbrogan.com
helpx.wishlist@robertbrogan.com
helpx.other@robertbrogan.com

and we will try to get back to you ASAP.

---14| FEEDBACK

You can visit our feedback page at --
http://www.robertbrogan.com/helpx/feedback.html.

Alternatively, send an email to one of:

helpx.questions@robertbrogan.com
helpx.comments@robertbrogan.com
helpx.bugreport@robertbrogan.com
helpx.wishlist@robertbrogan.com
helpx.other@robertbrogan.com

and we will try to get back to you ASAP.

---15| TESTING

You can find tests in the /test directory.

You will find a README file there as well, further details on things like how to
run the tests yourself.

---16| CONTRIBUTING

Nothing formal has been set up for governing this project, yet.

---17| UPDATING

The latest version can be found at
http://www.robertbrogan.com/helpx/download.html.

Want to receive notifications about changes to Helpx? You can subscribe to the
announcements mailing list by sending an email to
helpx-announce-subscribe@robertbrogan.com. (No need for anything in subject or
message body.) You will get an email every time we have a new release.

---18| RECENT CHANGES

Pre-release to support Gen.

---19| LICENSE

The license is the same as the license for Tcl, for all practical purposes. See
LICENSE.txt or license.html for the actual license.

---20| LEGAL

No legal notice at this time (i.e. no use of crypto). See LICENSE.txt or
license.html for the license.

---21| CREDITS

Information posted at wiki.tcl.tk has been helpful throughout work on Tcl
projects.

