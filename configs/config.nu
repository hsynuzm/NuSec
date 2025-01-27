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
let go_usr_path = $"/home/($env.USER)/go/bin"
$env.PATH ++= [$go_usr_path]

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

# Use NUPM
let nupm_path = $"/home/($env.USER)/nupm/nupm"
use $nupm_path

# Gather information about the target IP address
def checkip [ipaddr: string] {
    curl -s $"http://ipinfo.io/($ipaddr)" | jq
}

# Start HTTPSERVER
alias hs = python3 -m http.server

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

# You have to install https://github.com/FMotalleb/nu_plugin_port_list
# List listening ports
alias lp = port list -p -l -4 -t

# List connections
alias lc = port list -p -t -4

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
def tfox [dtype: string] {
    let buffer = http get https://threatfox.abuse.ch/export/json/urls/recent/ | values
    if $dtype == "all" {
        for data in ($buffer) {
            print $"(ansi blue_bold)($data.ioc_value)(ansi white) | ($data.threat_type) | (ansi purple_bold)($data.malware)(ansi white) | ($data.malware_printable) | (ansi green_bold)($data.tags)(ansi white) | ($data.reference)"
        }
    } else if $dtype == "url" {
        for data in ($buffer) {
            print $"($data | get 0 | get ioc_value | to text)"
        }
    } else {
        "You must use: all/url"
    }
}

# You have to execute => "go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest"
# Perform httpx scan against list of urls
def hx [listfile: string] {
    httpx -l $listfile -silent -td -title -sc
}