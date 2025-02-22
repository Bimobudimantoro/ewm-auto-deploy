#!/usr/bin/expect -f

proc generate_random_string {length} {
    set chars [list A B C D E F G H I J K L M N O P Q R S T U V W X Y Z]
    set result ""
    for {set i 0} {$i < $length} {incr i} {
        append result [lindex $chars [expr {int(rand() * [llength $chars])}]]
    }
    return $result
}

# Source the .env file
set env_file [open ".env"]
while {[gets $env_file line] >= 0} {
    if {[string match {*=*} $line]} {
        set key [lindex [split $line =] 0]
        set value [lindex [split $line =] 1]
        set env($key) $value
    }
}
close $env_file

# Clone the repository if it doesn't exist
if {[file exists "ewm-auto-deploy"]} {
    cd ewm-auto-deploy
} else {
    spawn git clone https://github.com/Bimobudimantoro/ewm-auto-deploy.git
    expect {
        "Cloning into" {
            exp_continue
        }
    }
    cd ewm-auto-deploy
}

# Install dependencies
spawn npm install
expect {
    "added" {
        exp_continue
    }
}

# Define max runs per day and initialize the run count
set max_runs 1000
set run_count 0

while {true} {
    if {$run_count >= $max_runs} {
        puts "Daily limit of $max_runs runs reached. Sleeping until tomorrow..."

        # Calculate the number of seconds until midnight
        set now [clock seconds]
        set tomorrow [expr {$now + 86400}]
        set midnight [clock scan "00:00" -base $tomorrow]
        set sleep_time [expr {$midnight - $now}]
        sleep $sleep_time

        # Reset run count for the next day
        set run_count 0
    }

    spawn npm start
    expect {
        "Select a network (enter number):" {
            send "1\r"
            exp_continue
        }
        "Enter token name:" {
            set token_name [generate_random_string 4]
            send "$token_name\r"
            exp_continue
        }
        "Enter token symbol:" {
            set token_symbol [generate_random_string 4]
            send "$token_symbol\r"
            exp_continue
        }
        "Enter token supply:" {
            send "1000000\r"
            exp_continue
        }
        "invalid private key" {
            puts "Error: Invalid private key. Please check your private key configuration."
            exit
        }
        eof {
            sleep 5
            incr run_count
        }
    }
}
