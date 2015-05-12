# Load helpx.
package require helpx 0.2

# Find what directory this file is in.
set MyDirectory [file dirname [info script]]

# Make a connection to our helpx database.
sqlite3 sample-helpxdb $MyDirectory/sample-helpx.db

# Register that connection.
HelpxNS::RegisterDatabase sample-helpxdb

proc SampleCommand {Arg1 Arg2} {
     puts "$Arg1 $Arg2"
}
