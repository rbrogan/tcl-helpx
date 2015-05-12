package provide helpx 0.2
package require sqlite3
package require Tclx
package require textutil::string
package require textutil::adjust
package require struct::list
package require  gen
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
     ALREADY_EXISTS -18
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
     ALREADY_EXISTS {Value %s in variable %s already exists.}
}


namespace eval HelpxNS {
     variable DatabaseConnectionList {}
}
proc HelpxNS::ArgumentInfoFor Command {

     set CommandId [CommandIdFor $Command]
     set ::sql "SELECT argname, argdesc FROM command_args WHERE commandid = $CommandId ORDER BY position ASC"
     set Dict [dict create {*}[QQ $::sql]]
     return $Dict
}

proc HelpxNS::CommandIdFor Command {

     if {[string is integer $Command]} {
          return $Command
     } else {
          set ::sql "SELECT id FROM commands WHERE name = '$Command'"
          set CommandId [Q1 $::sql]
          if {[IsEmpty $CommandId]} {
               error "Command $Command not found."
          } else {
               return $CommandId
          }
     }
}

proc HelpxNS::CreateCommand Name {

     if {[IsEmpty $Name]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_EMPTY) Name] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_EMPTY)
     }
     set ::sql "SELECT id FROM commands WHERE name = '$Name'"
     set CommandId [Q1 $::sql]
     if {[NotEmpty $CommandId]} {
          error [format $::ErrorMessage(ALREADY_EXISTS) $Name Name] $::errorInfo $::ErrorCode(ALREADY_EXISTS)
     }

     set ::sql "INSERT INTO commands (name) VALUES ('$Name')"
     QQ $::sql
     return [LastId commands]
}

proc HelpxNS::CreateHelpxDatabase FilePath {

     if {[IsEmpty $FilePath]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_EMPTY) FilePath] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_EMPTY)
     }

     sqlite3 helpxdb $FilePath
     set TableDict  [dict create   commands {  {id integer primary key}  {name text}  }  commandinfo {  {id integer primary key}  {commandid integer}  {infotype text}  {infodata text}  }  command_args {  {id integer primary key}  {commandid integer}  {argname text}  {argdesc text} {position integer} }  command_examples {  {id integer primary key}  {commandid integer}  {data text} {position integer}  }  command_seealso {{id integer primary key} {commandid integer} {data text} {position integer}}]
     dict for {TableName TableDef} $TableDict {
          set sql "SELECT count(*) FROM sqlite_master WHERE tbl_name = '$TableName'"
          set TableExists [lindex [helpxdb eval $sql] 0]
          if {$TableExists} {
               helpxdb eval "DROP TABLE $TableName"
          }
          helpxdb eval "CREATE TABLE $TableName ([join $TableDef ","])"
     }    
}

proc HelpxNS::DeleteCommand Command {

     set CommandId [CommandIdFor $Command]
     set ::sql "DELETE FROM commands WHERE id = $CommandId"
     QQ $::sql

     # Delete from command_args table
     set ::sql "DELETE FROM command_args WHERE commandid = $CommandId"
     QQ $::sql

     # Delete from command_examples table
     set ::sql "DELETE FROM command_examples WHERE commandid = $CommandId"
     QQ $::sql

     # Delete from commandinfo table
     set ::sql "DELETE FROM commandinfo WHERE commandid = $CommandId"
     QQ $::sql
}

proc HelpxNS::EnterArgumentInfo {Command ArgName ArgDesc {Position -1}} {

     if {[IsEmpty $ArgName]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_EMPTY) ArgName] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_EMPTY)
     }
     set CommandId [CommandIdFor $Command]
     set ::sql "SELECT position FROM command_args WHERE commandid = $CommandId AND argname = '$ArgName'"
     set CurrentPosition [Q1 $::sql]
     if {[NotEmpty $CurrentPosition]} {
          if {($Position == -1)} {
               set Position $CurrentPosition
          } elseif {$Position != $CurrentPosition} {
               error [format $::ErrorMessage(ALREADY_EXISTS) $ArgName ArgName] $::errorInfo $::ErrorCode(ALREADY_EXISTS)
          }
     } elseif {$Position == -1} {
          # If it is command name then get the ID     
          # No position was given so we will figure out what should be the last and use that.
          set ::sql "SELECT max(position) FROM command_args WHERE commandid = $CommandId"
          set Position [Q1 $::sql]
          if {[IsEmpty $Position]} {
               set Position -1
          }
          incr Position
     }
     if {[IsEmpty $Position]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_EMPTY) Position] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_EMPTY)
     }
     if {![IsNumeric $Position] || ![IsNonNegative $Position]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_INVALID) Position $Position] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_INVALID)
     }

     return [RunSqlEnter command_args [dict create commandid $CommandId  position $Position] [dict create argname "'$ArgName'" argdesc "'$ArgDesc'"]]
}

proc HelpxNS::EnterExample {Command ExampleData {Position -1}} {

     set CommandId [CommandIdFor $Command]
     # If it is command name then get the ID
     if {$Position == -1} {
          # No position was given so we will figure out what should be the last and use that.
          set ::sql "SELECT max(position) FROM command_examples WHERE commandid = $CommandId"
          set Position [Q1 $::sql]
          if {[IsEmpty $Position]} {
               set Position -1
          }
          incr Position
     } elseif {[IsEmpty $Position]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_EMPTY) Position] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_EMPTY)
     } elseif {![IsNumeric $Position] || ![IsNonNegative $Position]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_INVALID) Position $Position] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_INVALID)
     }

     return [RunSqlEnter command_examples [dict create commandid $CommandId position $Position] [dict create data "'$ExampleData'"]]
}

proc HelpxNS::EnterInfoData {Command InfoType InfoData} {

     return [RunSqlEnter commandinfo [dict create commandid [CommandIdFor $Command] infotype "'$InfoType'"] [dict create infodata "'$InfoData'"]]

}

proc HelpxNS::EnterMoreInfo {Command MoreInfo} {

     return [EnterInfoData [CommandIdFor $Command] moreinfo $MoreInfo]
}

proc HelpxNS::EnterReturnValue {Command ReturnValueDescription} {

     return [EnterInfoData [CommandIdFor $Command] returnvalue $ReturnValueDescription]
}

proc HelpxNS::EnterSeeAlso {Command SeeAlsoData {Position -1}} {

     set CommandId [CommandIdFor $Command]
     if {$Position == -1} {
          # No position was given, so we will figure out what should be last and use that.
          set ::sql "SELECT max(position) FROM command_seealso WHERE commandid = $CommandId"
          set Position [Q1 $::sql]
          if {[IsEmpty $Position]} {
               set Position -1
          }
          incr Position
     } elseif {[IsEmpty $Position]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_EMPTY) Position] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_EMPTY)
     } elseif {![IsNumeric $Position] || ![IsNonNegative $Position]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_INVALID) Position $Position] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_INVALID)
     }

     return [RunSqlEnter command_seealso [dict create commandid $CommandId position $Position] [dict create data "'$SeeAlsoData'"]]

}

proc HelpxNS::EnterShortDescription {Command ShortDescription} {


     return [EnterInfoData [CommandIdFor $Command] sdesc $ShortDescription]
}

proc HelpxNS::EnterSignature {Command Signature} {

     return [EnterInfoData [CommandIdFor $Command] signature $Signature]
}

proc HelpxNS::EraseArgumentInfo {Command Position} {

     if {[IsEmpty $Position]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_EMPTY) Position] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_EMPTY)
     }
     if {![IsNumeric $Position] || ![IsNonNegative $Position]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_INVALID) Position $Position] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_INVALID)
     }
     set CommandId [CommandIdFor $Command]

     # Determine if position is out-of-range
     set ::sql "SELECT max(position) FROM command_args WHERE commandid = $CommandId"
     set MaxPosition [Q1 $::sql]
     if {$Position > $MaxPosition} {
          error [format $::ErrorMessage(INPUT_OUT_OF_RANGE) $Position] $::errorInfo $::ErrorCode(INPUT_OUT_OF_RANGE)          
     }

     set ::sql "DELETE FROM command_args WHERE commandid = $CommandId AND position = $Position"
     QQ $::sql

     # Update positions so there are no gaps
     set LastPosition -1
     foreach {Id Position} [QQ "SELECT id, position FROM command_args WHERE commandid = $CommandId ORDER BY position ASC"] {
          set ExpectedPosition [expr $LastPosition + 1]
          if {$Position != $ExpectedPosition} {
               set ::sql "UPDATE command_args SET position = $ExpectedPosition WHERE id = $Id"
               QQ $::sql
          }
          set LastPosition $ExpectedPosition
     }
}

proc HelpxNS::EraseExample {Command Position} {

     if {[IsEmpty $Position]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_EMPTY) Position] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_EMPTY)
     }
     if {![IsNumeric $Position] || ![IsNonNegative $Position]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_INVALID) Position $Position] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_INVALID)
     }

     set CommandId [CommandIdFor $Command]

     # Determine if position is out-of-range
     set ::sql "SELECT max(position) FROM command_examples WHERE commandid = $CommandId"
     set MaxPosition [Q1 $::sql]
     if {$Position > $MaxPosition} {
          error [format $::ErrorMessage(INPUT_OUT_OF_RANGE) $Position] $::errorInfo $::ErrorCode(INPUT_OUT_OF_RANGE)          
     }

     set ::sql "DELETE FROM command_examples WHERE commandid = $CommandId AND position = $Position"
     QQ $::sql

     # Update positions so there are no gaps
     set LastPosition -1
     foreach {Id Position} [QQ "SELECT id, position FROM command_examples WHERE commandid = $CommandId ORDER BY position ASC"] {
          set ExpectedPosition [expr $LastPosition + 1]
          if {$Position != $ExpectedPosition} {
               set ::sql "UPDATE command_examples SET position = $ExpectedPosition WHERE id = $Id"
               QQ $::sql
          }
          set LastPosition $ExpectedPosition
     }
}

proc HelpxNS::EraseSeeAlso {Command Position} {

     if {[IsEmpty $Position]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_EMPTY) Position] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_EMPTY)
     }
     if {![IsNumeric $Position] || ![IsNonNegative $Position]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_INVALID) Position $Position] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_INVALID)
     }

     set CommandId [CommandIdFor $Command]

     # Determine if position is out-of-range
     set ::sql "SELECT max(position) FROM command_seealso WHERE commandid = $CommandId"
     set MaxPosition [Q1 $::sql]
     if {$Position > $MaxPosition} {
          error [format $::ErrorMessage(INPUT_OUT_OF_RANGE) $Position] $::errorInfo $::ErrorCode(INPUT_OUT_OF_RANGE)          
     }

     set ::sql "DELETE FROM command_seealso WHERE commandid = $CommandId AND position = $Position"
     QQ $::sql

     # Update positions so there are no gaps
     set LastPosition -1
     foreach {Id Position} [QQ "SELECT id, position FROM command_seealso WHERE commandid = $CommandId ORDER BY position ASC"] {
          set ExpectedPosition [expr $LastPosition + 1]
          if {$Position != $ExpectedPosition} {
               set ::sql "UPDATE command_examples SET position = $ExpectedPosition WHERE id = $Id"
               QQ $::sql
          }
          set LastPosition $ExpectedPosition
     }
}

proc HelpxNS::ExamplesFor Command {

     set ::sql "SELECT data FROM command_examples WHERE commandid = [CommandIdFor $Command] ORDER BY position ASC"
     return [QQ $::sql]
}

proc HelpxNS::InfoDataFor {Command InfoType} {

     set ::sql "SELECT infodata FROM commandinfo WHERE infotype = '$InfoType' AND commandid = [CommandIdFor $Command]"
     return [QQ $::sql]
}

proc HelpxNS::MoreInfoFor Command {

     return [struct::list flatten [InfoDataFor [CommandIdFor $Command] moreinfo]]
}

proc HelpxNS::MultiDatabaseQuery Query {

     variable DatabaseConnectionList
     
     foreach Connection $DatabaseConnectionList {
          set Results [$Connection eval $Query]
          if {[$Results ne ""]} {
               return $Results
          }
     }
     
     return ""
}

proc HelpxNS::RegisterDatabase ConnectionName {

     variable DatabaseConnectionList

     if {[IsEmpty $ConnectionName]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_EMPTY) ConnectionName] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_EMPTY)
     }
     
     if {[lsearch $DatabaseConnectionList $ConnectionName] == -1} {
          lappend DatabaseConnectionList $ConnectionName
     }
}

proc HelpxNS::RenameCommand {Command NewName} {

     if {[IsEmpty $NewName]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_EMPTY) NewName] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_EMPTY)
     }

     if {[SqlRecordExists commands [dict create name "'$NewName'"]]} {
          error [format $::ErrorMessage(ALREADY_EXISTS) $NewName NewName] $::errorInfo $::ErrorCode(ALREADY_EXISTS)
     }

     set ::sql "UPDATE commands SET name = '$NewName' WHERE id = [CommandIdFor $Command]"
     QQ $::sql
}

proc HelpxNS::ReturnValueFor Command {

     return [struct::list flatten [InfoDataFor [CommandIdFor $Command] returnvalue]]
}

proc HelpxNS::SeeAlsoFor Command {

     set ::sql "SELECT data FROM command_seealso WHERE commandid = [CommandIdFor $Command] ORDER BY position ASC"
     set SeeAlsoList [QQ $::sql]
     foreach Element $SeeAlsoList {
          set ::sql "SELECT id FROM commands WHERE name = '$Command'"
          set CommandId [Q1 $::sql]
          if {[IsEmpty $CommandId]} {
               continue
          }
     }

     return $SeeAlsoList
}

proc HelpxNS::ShortDescriptionFor Command {

     return [struct::list flatten [InfoDataFor [CommandIdFor $Command] sdesc]]
}

proc HelpxNS::SignatureFor Command {

     return [struct::list flatten [InfoDataFor [CommandIdFor $Command] signature]]
}

proc HelpxNS::UnregisterDatabase ConnectionName {

     variable DatabaseConnectionList

     if {[IsEmpty $ConnectionName]} {
          error [format $::ErrorMessage(VARIABLE_CONTENTS_EMPTY) ConnectionName] $::errorInfo $::ErrorCode(VARIABLE_CONTENTS_EMPTY)
     }


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
     set CommandName [lindex $args end]
     
    
     # In future, figure out how to deal with multiple commands with same name.
     set Results ""
     set ::sql "SELECT id FROM commands WHERE name = '$CommandName'"
     foreach ConnectionName $HelpxNS::DatabaseConnectionList {
          set Results [$ConnectionName eval $::sql]
          if {$Results ne ""} {
               set TargetConnection $ConnectionName
               set CommandId [lindex $Results 0]
               break
          }
     }
     if {$Results eq ""} {
          puts "$CommandName not found."
          return
     }
     
     set InfoTypes {example more desc signature returnvalue seealso}

     # Based on the options selected, get the data from the database.
     set InfoDict [dict create]
     foreach Option $Options {
          switch $Option {
               -arg {
                    set InfoType args
                    set ::sql "SELECT argname, argdesc FROM command_args WHERE commandid = $CommandId ORDER BY position ASC"
                    dict set InfoDict arguments [$TargetConnection eval $::sql]                    
               }
               -more {
                    set InfoType more
                    set ::sql "SELECT infodata FROM commandinfo WHERE infotype = 'moreinfo' AND commandid = $CommandId"
                    dict set InfoDict more [lindex [$ConnectionName eval $::sql] 0]

               }
               -desc {
                    set InfoType desc
                    set ::sql "SELECT infodata FROM commandinfo WHERE infotype = 'sdesc' AND commandid = $CommandId"
                    dict set InfoDict desc [lindex [$ConnectionName eval $::sql] 0]
               }          
               -ex {
                    set InfoType example
                    set ::sql "SELECT data FROM command_examples WHERE commandid = $CommandId ORDER BY position ASC"
                    dict set InfoDict example [$ConnectionName eval $::sql]
               }
               -ret {
                    set InfoType returnvalue
                    set ::sql "SELECT infodata FROM commandinfo WHERE infotype = 'returnvalue' AND commandid = $CommandId"
                    dict set InfoDict returnvalue [lindex [$ConnectionName eval $::sql] 0]
               }
               -sig {              
                    set InfoType signature
                    set ::sql "SELECT infodata FROM commandinfo WHERE infotype = 'signature' AND commandid = $CommandId"
                    dict set InfoDict signature [lindex [$ConnectionName eval $::sql] 0]
               }
               -see {
                    set InfoType seealso
                    set ::sql "SELECT infodata FROM commandinfo WHERE infotype = 'seealso' AND commandid = $CommandId"
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
     puts 0.2
}

set HelpxDirectory [file dirname [info script]]
sqlite3 helpx-helpxdb $HelpxDirectory/helpx-helpx.db
HelpxNS::RegisterDatabase helpx-helpxdb          
