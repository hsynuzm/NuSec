# config.nu
#
# Installed by:
# version = "0.101.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# This file is loaded after env.nu and before login.nu
#
# You can open this file in your default editor using:
# config nu
#
# See `help config nu` for more options
#
# You can remove these comments if you want or leave
# them for future reference.

# Start with neofetch
neofetch

$env.config.buffer_editor = "code" # Can be anything for ex. (nvim, nano, ...)
$env.config.show_banner = false

# Add go path
if (($env.PATH | to text | str contains "/go/bin") == false) {
    let go_usr_path = $"($env.HOME)/go/bin"
    $env.PATH ++= [$go_usr_path]
    $env.PATH ++= ["/usr/local/go/bin"]
}

# Skeleton of the prompt
def left_prompt [] {
    # Function to get the username
    let username = (whoami | str trim)

    # Function to get the hostname
    let hostname = (hostname | str trim)

    # Function to get the current directory
    let current_dir = (pwd)
    $"\n(ansi blue_bold)<----- ($username)@($hostname) ----->\n[(ansi red)($current_dir)(ansi blue_bold)]"
}

# Apply the custom prompt
$env.PROMPT_COMMAND = { left_prompt }
$env.PROMPT_INDICATOR = $"(ansi blue_bold)>> "

# Gather information about the target IP address
def checkip [ipaddr: string] {
    http get http://ipinfo.io/($ipaddr)/json
}

# Start HTTPSERVER
def hs [--path: string] {
    if $path != null {
        let abs_path = ($path | str trim)
        python3 -m http.server -d $abs_path
    } else {
        python3 -m http.server 
    }
}

# Output with syntax highlighting
def catt [targetfile: string] {
    python3 -m rich.syntax $targetfile
}

# Get Ifaces
alias ifc = sys net

# Get disks
alias sd = sys disks

# Verbose LS for disk usage checks
def lsv [] {
    ls -a -d -l | sort-by size
}

# Verbose LS for last created file and mime checks
def lsl [] {
    ls -a -m | sort-by modified
}

# Access shell of a docker image
def dosh [image_id: string] {
    docker run -it $image_id /bin/bash
}

# Remove selected docker image
def drmi [target_id: string] {
    docker rmi --force $target_id
}

# Install desired package
def aget [target_package: string] {
    sudo apt install -y $target_package
}

# Remove package
def arem [target_package: string] {
    sudo apt remove $target_package
}


# List listening ports
def lp [] {
    if ((plugin list | get filename | to text | str contains "nu_plugin_port_list") == true) {
        portlist -p -l -4 -t
    } else {
        print $"(ansi cyan_bold)[(ansi red_bold)+(ansi cyan_bold)](ansi reset) Looks like you have a missing plugin! Installing it for you..."
        git clone https://github.com/hsynuzm/nu_plugin_port_list
        cd nu_plugin_port_list
        cargo build -r
        cp target/release/nu_plugin_port_list $"($env.HOME)/.cargo/bin"
        plugin add $"($env.HOME)/.cargo/bin/nu_plugin_port_list"
        cd ..
        rm -rf nu_plugin_port_list
        print $"\n(ansi cyan_bold)[(ansi red_bold)+(ansi cyan_bold)](ansi reset) Installation completed. (ansi yellow_bold)You must restart nushell!"
    }
}

# List connections
def lc [] {
    if ((plugin list | get filename | to text | str contains "nu_plugin_port_list") == true) {
        portlist -p -4 -t
    } else {
        print $"(ansi cyan_bold)[(ansi red_bold)+(ansi cyan_bold)](ansi reset) Looks like you have a missing plugin! Installing it for you..."
        git clone https://github.com/hsynuzm/nu_plugin_port_list
        cd nu_plugin_port_list
        cargo build -r
        cp target/release/nu_plugin_port_list $"($env.HOME)/.cargo/bin"
        plugin add $"($env.HOME)/.cargo/bin/nu_plugin_port_list"
        cd ..
        rm -rf nu_plugin_port_list
        print $"\n(ansi cyan_bold)[(ansi red_bold)+(ansi cyan_bold)](ansi reset) Installation completed. (ansi yellow_bold)You must restart nushell!"
    }
}

# Fetch last 50 C2 panel from Viriback
def vrb [] {
    http get https://tracker.viriback.com/last50.php | to json | from json
}

# Fetch data from URLHAUS
def haus [datatype: string] {
    if $datatype == "normal" {
        http get https://urlhaus.abuse.ch/downloads/text
    } else if $datatype == "online" {
        http get https://urlhaus.abuse.ch/downloads/text_online
    } else {
        "You must use: normal/online"
    }
}

# Fetch data from ThreatFox
def tfox [--dtype: string] {
    let buffer = http get https://threatfox.abuse.ch/export/json/urls/recent/ | values
    mut data_array = []
    if $dtype == "all" {
        for data in ($buffer) {
            $data_array ++= [{
                "ioc": $data.ioc_value.0, 
                "threat_type": $data.threat_type.0, 
                "malware": $data.malware.0, 
                "malware_printable": $data.malware_printable.0, 
                "tags": $data.tags, 
                "reference": $data.reference
            }]
        }
        $data_array | table
    } else if $dtype == "url" {
        for data in ($buffer) {
            $data_array ++= [($data | get 0 | get ioc_value | to text)]
        }
        $data_array
    } else {
        "You must use: --dtype all/url"
    }
}

# Perform httpx scan against list of urls
def hx [listfile: string] {
    if (($"($env.HOME)/go/bin/httpx" | path exists) == false) {
        go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
    } else {
        httpx -l $listfile -silent -td -title -sc
    }
}

# Projectdiscovery tool downloader
def pdsc [tool_name: string] {
    print $"(ansi cyan_bold)[(ansi red_bold)+(ansi cyan_bold)](ansi reset) Installing: (ansi green_bold)($tool_name)"
    go install -v github.com/projectdiscovery/($tool_name)/cmd/($tool_name)@latest
}

# Get user defined commands/aliases
def hlp [--verbose (-v)] {
    if ($verbose) {
        help commands | where category =~ "default" | select name description params
    } else {
        help commands | where category =~ "default" | select name description
    }    
}

# Enumerate subdomains using subfinder/httpx combination
def shx [target_domain: string] {
    subfinder -silent -d $target_domain | httpx -silent -mc 200 -sc -title -td
}

# Base64 decoder
def bdc [pattern: string] {
    echo $pattern | base64 -d
}

# Hunt possible C2 domains using hednsextractor
def hdns [target_domain: string] {
    if (($"($env.HOME)/go/bin/hednsextractor" | path exists) == false) {
        go install -v github.com/HuntDownProject/hednsextractor/cmd/hednsextractor@latest
    } else {
        echo $target_domain | hednsextractor -silent -only-domains
    }
}

# Get latest config.nu from repository
def upc [] {
    http get https://raw.githubusercontent.com/CYB3RMX/NuShell/refs/heads/main/configs/config.nu | save -f $nu.config-path
    print $"(ansi cyan_bold)[(ansi red_bold)+(ansi cyan_bold)](ansi reset) Config updated successfully!"
    nu # Restart shell
}

#System Cleaner
def clean [] {
    let confirm = (input $"(ansi red_bold)System cache will be cleaned. Are you sure? [Y/n]: (ansi reset)" | str trim | str downcase)
    if $confirm == "y" or $confirm == "" {
        sudo apt autoremove -y
        sudo apt autoclean -y
        sudo rm -rf ~/.cache/*
        echo "System Cleaned!"
    } else {
        echo "Operation cancelled."
    }
}

# Get ARP table with style!
def arpt [] {
    arp -a | lines | split column " " | select column2 column4 column5 column7 | rename IP_Address MAC_Address Proto Interface
}

# Search for target file in the system
def ff [target_file: string] {
    let command_state = (which fdfind)
    if ($command_state | to text | str contains "/usr/bin/fdfind") {
        fdfind -H --glob -t f $target_file / | lines
    } else {
        print $"(ansi cyan_bold)[(ansi red_bold)+(ansi cyan_bold)](ansi red_bold) fd-find not found installing it automatically!(ansi reset)"
        aget fd-find
    }
}

# List active and inactive services
def serv [] {
    let services = (ls /etc/init.d/ | get name) 
    $services | each { |serv_path|
        let serv_name = ($serv_path | path basename | str trim)
        let status_output = (try { systemctl is-active $serv_name } catch { 'unknown' })
        if ($status_output == "active") {
            let status = $"(ansi green_bold)active(ansi reset)"
            { service: $serv_name, status: $status }
        } else {
            let status = $"(ansi red_bold)inactive(ansi reset)"
            { service: $serv_name, status: $status }
        }
    }
}

# List disk partitions (lsblk with style!)
def dls [] {
    lsblk -r | lines | split column " " | skip 1 |select column1 column2 column3 column4 column5 column6 column7 | rename NAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS
}

# Format/fix USB or USB like devices
def fixu [target_disk: string] {
    print $"(ansi cyan_bold)[(ansi red_bold)+(ansi cyan_bold)](ansi reset) Formatting: (ansi green_bold)($target_disk)(ansi reset)"
    sudo wipefs --all $target_disk
    sudo mkfs.vfat -F 32 $target_disk
    print $"(ansi cyan_bold)[(ansi red_bold)+(ansi cyan_bold)](ansi green_bold) ($target_disk)(ansi reset) formatted successfully!"
}

# Perform YARA scan against the given file
def yrs [target_file: string] {
    # Check rules first!
    if (($"($env.HOME)/rules" | path exists) == true ) {
        print $"(ansi cyan_bold)[(ansi red_bold)+(ansi cyan_bold)](ansi reset) Performing YARA scan against: (ansi green_bold)($target_file)(ansi reset) Please wait!"
        let rule_arr = (glob $"($env.HOME)/rules/**")
        mut matched_rules = []
        for rul in ($rule_arr) {
            if (($rul | str contains ".yar") == true) {
                try {
                    let rulz = (yara -w $rul $target_file err> /dev/null | str replace --all $target_file "")
                    for rr in ($rulz) {
                        if (($matched_rules | to text | str contains $rr) == false) {
                            $matched_rules ++= [$rr]
                        }
                    }
                } catch {}
            }
        }
        $matched_rules | split row "\n" | uniq | table
    } else {
        print $"(ansi cyan_bold)[(ansi red_bold)+(ansi cyan_bold)](ansi reset) Downloading latest YARA rules from: (ansi green_bold)https://github.com/Yara-Rules/rules(ansi reset)"
        git clone https://github.com/Yara-Rules/rules $"($env.HOME)/rules"
        print $"\n(ansi cyan_bold)[(ansi red_bold)+(ansi cyan_bold)](ansi reset) Download complete. (ansi yellow_bold)You must re-execute the command!"
    }
}