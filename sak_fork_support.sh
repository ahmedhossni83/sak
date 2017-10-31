#!/usr/bin/expect

###############################################################################
##  Program:  sak
##  Author :  Rebecca Robinson   becca@robinson-consulting.net
##  Info   :  Multipurpose Expect script for performing multiple different
##            day to day administration tasks.
##  Repo   :  https://github.com/itgrl/sak/
##
###############################################################################
### Debug mode
#exp_internal 1

### Base Parameters
set myname "sak"
set user ""
set pass ""
set forkcount 0
set maxforks 5
set children 0
### Help Message
set helpmessage "
$myname is a universal tool to aid in day to day adhoc tasks across 1 or more servers.\n

Usage:
  Multi-server:
    sak -f=filename.txt -c=\"cat /etc/motd\" -l=server.list
  Single-server:
    sak -f=scriptname.txt -c=\"sudo cp scriptname.txt /root/bin/scriptname.sh\" <ip or fqdn>

Options:
  -h or --help          Print this message.
  -c or --command       Command to execute on target server(s).
  -f or --file          Specify file to place on target server(s), in your homedir.
  -r or --retrieve      Retrieve a file from the target server(s).  (Specify full path).
  -l or --list          Server list to execute commands against.
  -t or --timeout       Expect time to wait between commands.
"
### Print Help Message if no arguments given.
if {[llength $argv] == 0} {
  send_user "$helpmessage\n"
  exit 1
}

### Define Functions

proc eval_options { server } {
  #Map options in above scop.
  upvar 1 command mycommand
  upvar 1 file myfile
  upvar 1 remotefile myremotefile
  upvar 1 helpmessage myhelpmessage

  # Evaluate if an action option was set.
  if {[info exists myfile]} {
    if {$myfile eq ""} {
      # The flag was set, but no value supplied.
      puts "I think you forgot something.\n  The -f flag was set, but a value was not supplied.\n"
      exit 1
    } else {
      # Set flag to prevent double execution if command isn't present.
      set frunonce "1"
      # Perform action
      copy_file $server $myfile "up"
    }
  } elseif {[info exists mycommand]} {
    if {$mycommand eq ""} {
      # The flag was set, but no value supplied.
      puts "I think you forgot something.\n  The -c flag was set, but a value was not supplied.\n"
      exit 1
    } else {
      set crunonce "1"
      # Perform action
      exec_command $server
    }
  } elseif {[info exists myremotefile]} {
    if {$myremotefile eq ""} {
      # The flag was set, but no value supplied.
      puts "I think you forgot something.\n  The -r flag was set, but a value was not supplied.\n"
      exit 1
    } else {
      # Set flag to prevent double execution if file or command is not present.
      set rrunonce "1"
      # Perform action
      copy_file $server $myremotefile "down"
    }
  } else {
    exec clear >@ stdout
    puts "You didn't tell me what to do?!?!
      Please specify an action such as -r -c or -f\n\n"
    puts $myhelpmessage
    exit 1
  }

  # Evaluate if there are additional actions.
  if {[info exists myfile]} {
    # Check to see if this action was already ran.
    if {[info exists frunonce]} {
      if {$frunonce == "1"} {
        puts "File: I already ran this"
      }
    } elseif {$myfile eq ""} {
      # The flag was set, but no value supplied.
      puts "I think you forgot something.\n  The -f flag was set, but a value was not supplied.\n"
      exit 1
    } else {
      # Perform action
      set frunonce "1"
      copy_file $server $myfile "up"
    }
  }
  
  if {[info exists mycommand]} {
    # Check to see if this action was already ran.
    if {[info exists crunonce]} {
      if {$crunonce == "1"} {
        puts "File: I already ran this"
      }
    } elseif {$mycommand eq ""} {
      # The flag was set, but no value supplied.
      puts "I think you forgot something.\n  The -c flag was set, but a value was not supplied.\n"
      exit 1
    } else {
      # Perform action
      set crunonce "1"
      exec_command $server
    }
  }
  
  if {[info exists myremotefile]} {
    # Check to see if this action was already ran.
    if {[info exists rrunonce]} {
      if {$rrunonce == "1"} {
        puts "RemoteFile: I already ran this"
      }
    } elseif {$myremotefile eq ""} {
      # The flag was set, but no value supplied.
      puts "I think you forgot something.\n  The -r flag was set, but a value was not supplied.\n"
      exit 1
    } else {
      # Perform action
      set rrunonce "1"
      copy_file $server $myremotefile "down"
    }
  }
}


proc copy_file { myserver myfile mydirection } {
  # Map variables
  upvar 2 user myuser
  upvar 2 pass mypass

  if { $mydirection eq "down" } {
    file mkdir $myserver
    spawn scp $myuser@$myserver:/$myfile ./$myserver/
    expect {
      "RSA key fingerprint" { send "yes\r"; exp_continue }
      "assword: " { send -- "$mypass\r"; exp_continue }
    }
  }

  if { $mydirection eq "up" } {
    spawn scp $myfile $myuser@$myserver:~/
    expect {
      "RSA key fingerprint" { send "yes\r"; exp_continue }
      "assword: " { send -- "$mypass\r"; exp_continue }
    }
  }

}

proc exec_command { myserver } {
  # Map variables
  upvar 2 user myuser
  upvar 2 pass mypass
  upvar 2 command mycommand

  spawn ssh -XY $myuser@$myserver -t $mycommand
  expect {
   "RSA key fingerprint" { send "yes\r"; exp_continue }
   "assword: " { send -- "$mypass\r"; exp_continue }
   "sudo* password for*: " { send -- "$mypass\r"; exp_continue }
}
  return
}

### Parse Command Line options
foreach arg $argv {
  switch -glob -- $arg {
    "-h*" -
    "--help*" {
      send_user "$helpmessage\n"
      exit 1
    }
    "-c*" -
    "--command*" {
      set command [lindex [split $arg "="] 1]
      continue
    }
    "-f*" -
    "--file*" {
      set file [lindex [split $arg "="] 1]
    }
    "-r*" -
    "--retrieve" {
      set remotefile [lindex [split $arg "="] 1]
    }
    "-l*" -
    "--list" {
      set list [lindex [split $arg "="] 1]
    }
    "-t*" -
    "--timeout" {
      set timeout [lindex [split $arg "="] 1]
    }
    default {
      set server $arg
    }
  }

}

### Prompt user for the credentials to connect as.

# grab the user
#stty -echo
exec clear >@ stdout
send_user -- "Username to connect as: "
expect_user -re "(.*)\n"
send_user "\n"
#stty echo
set user $expect_out(1,string)

# Validate the user was set.
if {$user eq ""} {
  exec clear >@ stdout
  puts "You must specify a user.\n"
  exit 1
} else {
  # grab the password
  stty -echo
  exec clear >@ stdout
  send_user -- "Password for $user: "
  expect_user -re "(.*)\n"
  send_user "\n"
  stty echo
  set pass $expect_out(1,string)
}

if {$pass eq ""} {
  exec clear >@ stdout
  puts "You didn't specify password for $user.\n"
  exit 1
}

### Execute the script

# Evalutate if a server or server list was set.
if {[info exists list]} {
  set firstrun "0"
  puts "Server list specified\n"
  # Open the server list and slurp contents
  set lst [open "$list" r]
  set file_data [read $lst]
  close $lst
  # Process server list
  set data [split $file_data "\n"]
  foreach line $data {
    if {$line eq ""} {
      if {$firstrun eq "0"} {
        puts "Oops, it looks like your list starts with blank lines."
      }
      puts "Blank line found, assuming the end and exiting."
      break
    } else {
	
	if {$maxforks eq $forkcount} {
		wait
		incr children -1
	}
	
	set forkattempts 0
 	set pid [fork]
        switch $pid {
            -1 { incr forkattempts
                puts "Fork attempt #$forkattempts failed."
            }
	    0 {
		incr children
		incr forkcount
		puts "new child  process forked - total forked processes : $forkcount"
	        eval_options $line
            }
	    default {
                 puts "parent process forked child process $pid"
		 exit
            }

        }
    }
    set firstrun "1"
  }
} elseif {[info exists server]} {
  puts "Server specified\n"
  eval_options $server
} else {
  send_user "You must specify a server or a server list.\n"
  puts $helpmessage
  exit 1
}
  

