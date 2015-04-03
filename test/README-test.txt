
Helpx

test/README

01| HOW TO USE THIS DOCUMENT
02| INTRO
03| RUNNING TESTS
04| BUG REPORTING
05| CONTRIBUTING
06| CATALOG
07| OTHER
08| CREDITS

---01| HOW TO USE THIS DOCUMENT

What is the point of these tests? What are they for? What do they accomplish?
See INTRO.

How can I find out what files should be in this directory and what are they for?
See CATALOG.

How do I run the tests myself?
See RUNNING TESTS.

What if I find problems with the tests?
See REPORTING ISSUES.

How can I contribute back tests?
See CONTRIBUTING.

---02| INTRO

Helpx includes a moderate suite of tests. The purpose of the tests is not to be
exhaustive and guarantee the code is perfect so much as establish a baseline of
confidence. The goal of the tests is to be able to say that if you find an error
caused by the code itself, you are doing something out-of-the-ordinary; all the
typical ways things can go wrong, we should have checked.

Note that we do not test the core Tcl commands invoked by Helpx commands. For
instance, we would not include tests to check whether the Tcl regexp command
works correctly or to check the input you pass in to ensure it is valid before
passing it along to commands.

---03| RUNNING TESTS

 To run all tests from the command line:
> tclsh86 all.tcl

To run all tests from the Tcl shell:
% source all.tct

To run tests for a given proc (for instance, helpx) from the command line:
> tclsh86 helpx.test

To run tests for a given proc (for instance, AddTo) from the tcl shell:
% source helpx.test

---04| BUG REPORTING

If you find bugs in tests or missing tests, please let us know.

Visit http://www.robertbrogan.com/helpx/feedback.html to use the form.

Alternatively, send an email to:

helpx.bugreport@robertbrogan.com

and we will try to get back to you ASAP.

---05| CONTRIBUTING

Nothing formal has been set up for governing this project, yet.

If you like, you may change the test code yourself or write a new test and
submit a patch to:

helpx.bugreport@robertbrogan.com (for bug fixes)
-or-
helpx.wishlist@robertbrogan.com (for tests you implemented)

A roadmap (scheduled changes) and wishlist (not yet scheduled) are available at:

http://www.robertbrogan.com/helpx/roadmap.html
http://www.robertbrogan.com/helpx/wishlist.html

You may want to get involved by submitting wishlist items and/or offering to do
work listed in the above two sites.

---06| CATALOG

all.tcl
     Test suite.
helpxclinsxxregisterdatabase.test
     Tests for the command HelpxCliNS::RegisterDatabase.
helpxclinsxxunregisterdatabase.test
     Tests for the command HelpxCliNS::UnregisterDatabase.
helpx.test
     Tests for the command helpx.

---07| OTHER

Nothing else to note at this time.

---08| CREDITS

Testing was done using the tcltest package.

Information posted at wiki.tcl.tk was helpful.

