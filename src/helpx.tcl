package provide helpx-cli 0.1.0
package require sqlite3
package require Tclx
package require textutil::string
package require textutil::adjust
if {[string equal $::tcl_platform(platform) "windows"]} {
     package require registry
}

array set ErrorCode {
     VARIABLE_NOT_FOUND -1
     INPUT_NON_NUMERIC -2
     VARIABLE_NAME_EMPTY -3
     INDEX_OUT_OF_RANGE -4
     INPUT_NOT_WELL_FORMED -5
     CANNOT_FACTOR_INPUT_LIST -6
     INPUT_INVALID -7
     INPUT_OUT_OF_RANGE -8
     INPUT_NON_POSITIVE -9
     SEARCH_STRING_EMPTY -10
     VARIABLE_CONTENTS_INVALID -11
     VARIABLE_CONTENTS_EMPTY -12
     DATABASE_VARIABLE_NOT_FOUND -13
     TABLE_NOT_FOUND -14
     ARGUMENTS_INCOHERENT -15
     REGISTRY_ELEMENT_NOT_FOUND -16
     PROC_NOT_FOUND -17
}

array set ErrorMessage {
     VARIABLE_NOT_FOUND {Could not find variable %s in caller.}
     INPUT_NON_NUMERIC {Got input value %s. Expected numeric value.}
     VARIABLE_NAME_EMPTY {Variable name is missing. Got empty string.}
     INDEX_OUT_OF_RANGE {List index %s is invalid.}
     INPUT_NOT_WELL_FORMED {Got input value %s. Expected input of the form %s.}
     CANNOT_FACTOR_INPUT_LIST {Input value %s does not divide list evenly.}
     INPUT_INVALID {Input value %s is invalid.}
     INPUT_OUT_OF_RANGE {Input value %s is out-of-range.}
     INPUT_NON_POSITIVE {Expected positive input value, got input value %s instead.}
     SEARCH_STRING_EMPTY {Got empty string for search value.}
     VARIABLE_CONTENTS_INVALID {Variable %s has invalid value %s.}
     VARIABLE_CONTENTS_EMPTY {Variable %s has empty value.}
     DATABASE_VARIABLE_NOT_FOUND {No variable called %s was found in the database globals table.}
     TABLE_NOT_FOUND {Table %s not found.}
     ARGUMENTS_INCOHERENT {Arguments %s and %s have incoherent values %s and %s.}
     REGISTRY_ELEMENT_NOT_FOUND {Registry key/value %s not found.}
     PROC_NOT_FOUND {Could not find proc %s.}
}


namespace eval HelpxCliNS {
     variable DatabaseConnectionList {}
}
     
proc HelpxCliNS::RegisterDatabase ConnectionName {

     variable DatabaseConnectionList
     
     if {[lsearch $DatabaseConnectionList $ConnectionName] == -1} {
          lappend DatabaseConnectionList $ConnectionName
     }
}

proc HelpxCliNS::UnregisterDatabase ConnectionName {

     variable DatabaseConnectionList

     while {[set Index [lsearch $DatabaseConnectionList $ConnectionName]] != -1} {
          set DatabaseConnectionList [lreplace $DatabaseConnectionList $Index $Index]
     }
}

proc helpx args {


     # If second argument is not used or if -all flag is used,
     # then show all the information,
     # otherwise, just show the piece corresponding to the flag.
     if {([llength $args] == 1) || ([lindex $args 0] eq "-all")} {
          set Options [list -arg -more -desc -ex -ret -sig -see]
     } else {
          set Options [lrange $args 0 end-1]
     }
     set ProcName [lindex $args end]
     
    
     # In future, figure out how to deal with multiple procs with same name.
     set Results ""
     set ::sql "SELECT id FROM procs WHERE name = '$ProcName'"
     foreach ConnectionName $HelpxCliNS::DatabaseConnectionList {
          set Results [$ConnectionName eval $::sql]
          if {$Results ne ""} {
               set TargetConnection $ConnectionName
               set ProcId [lindex $Results 0]
               break
          }
     }
     if {$Results eq ""} {
          puts "$ProcName not found."
          return
     }
     
     set InfoTypes {example more desc signature returnvalue seealso}

     # Based on the options selected, get the data from the database.
     set InfoDict [dict create]
     foreach Option $Options {
          switch $Option {
               -arg {
                    set InfoType args
                    set ::sql "SELECT argname, argdesc FROM proc_args WHERE procid = $ProcId ORDER BY position ASC"
                    dict set InfoDict arguments [$TargetConnection eval $::sql]                    
               }
               -more {
                    set InfoType more
                    set ::sql "SELECT infodata FROM procinfo WHERE infotype = 'ldesc' AND procid = $ProcId"
                    dict set InfoDict more [lindex [$ConnectionName eval $::sql] 0]

               }
               -desc {
                    set InfoType desc
                    set ::sql "SELECT infodata FROM procinfo WHERE infotype = 'sdesc' AND procid = $ProcId"
                    dict set InfoDict desc [lindex [$ConnectionName eval $::sql] 0]
               }          
               -ex {
                    set InfoType example
                    set ::sql "SELECT infodata FROM proc_examples WHERE procid = $ProcId ORDER BY position ASC"
                    dict set InfoDict example [$ConnectionName eval $::sql]
               }
               -ret {
                    set InfoType returnvalue
                    set ::sql "SELECT infodata FROM procinfo WHERE infotype = 'returnvalue' AND procid = $ProcId"
                    dict set InfoDict returnvalue [lindex [$ConnectionName eval $::sql] 0]
               }
               -sig {              
                    set InfoType signature
                    set ::sql "SELECT infodata FROM procinfo WHERE infotype = 'signature' AND procid = $ProcId"
                    dict set InfoDict signature [lindex [$ConnectionName eval $::sql] 0]
               }
               -see {
                    set InfoType seealso
                    set ::sql "SELECT infodata FROM procinfo WHERE infotype = 'seealso' AND procid = $ProcId"
                    dict lappend InfoDict seealso [$ConnectionName eval $::sql]
               }
               default {
                    error "Unknown option $Option"
               }
          }     
     }
     # Set the order in which each element will be displayed.
     set DisplayOrder {signature desc returnvalue arguments more seealso example}
     
     # Print each element, in turn.
     foreach key $DisplayOrder {
          if {![dict exists $InfoDict $key]} {
               continue
          }
          set value [dict get $InfoDict $key]
          set value [regsub -all {(<.+?>)} $value ""]
          set value [regsub -all {(</.+?>)} $value ""]
          set value [regsub -all {\\&lt;} $value <]
          set value [regsub -all {\\&gt;} $value >]
          
          switch $key {
               desc {
                    puts "DESCRIPTION"
                    puts "    [::textutil::adjust::adjust $value]"
               }
               more {
                    puts "MORE INFO"
                    set Paragraphs [split $value "\n"]
                    foreach Paragraph $Paragraphs {
                         puts "    [::textutil::adjust::adjust $Paragraph]"
                    }
               }
               signature {
                    puts "SIGNATURE"
                    puts "    [::textutil::adjust::adjust $value]"
               }
               returnvalue {
                    puts "RETURNS"
                    foreach Element [split $value "|"] {
                         puts "    [::textutil::adjust::adjust $Element]"
                    }
               }
               seealso {
                    puts "SEE ALSO"                    
                    puts "    [::textutil::adjust::adjust [join $value ", "]]"
               }
               example {
                    puts "EXAMPLE(S)"
                    puts ""
                    foreach Example $value {
                         foreach Line [split $Example "\n"] {
                              puts [::textutil::adjust::adjust $Line]
                         }
                    }
               }
               arguments {
                    puts "ARGUMENTS"
                    dict for {ArgKey ArgValue} $value {
                         puts "    $ArgKey"
                         puts "         [::textutil::adjust::adjust $ArgValue]"
                    }
               }
               default {
                    puts "Unknown: $value"
               }
          }
          puts ""
     }
}

proc HelpxCurrentVersion {} {
     puts 0.1.0
}

set HelpxDirectory [file dirname [info script]]
cd $HelpxDirectory
sqlite3 helpx-helpxdb helpx-helpx.db
HelpxCliNS::RegisterDatabase helpx-helpxdb          
