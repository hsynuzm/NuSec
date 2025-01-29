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
    let go_usr_path = $"/home/($env.USER)/go/bin"
    $env.PATH ++= [$go_usr_path]
    $env.PATH ++= ["/usr/local/go/bin"]
}

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
    let abs_path = ($path | str trim)
    if $path != null {
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
def tfox [--dtype: string] {
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
        "You must use: --dtype all/url"
    }
}

# Perform httpx scan against list of urls
def hx [listfile: string] {
    if (($"/home/($env.USER)/go/bin/httpx" | path exists) == false) {
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

# Hunt possible C2 domains usng hednsextractor
def hdns [target_domain: string] {
    if (($"/home/($env.USER)/go/bin/hednsextractor" | path exists) == false) {
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
    sudo apt autoremove -y
    sudo apt autoclean -y
    sudo rm -rf ~/.cache/*
    echo "System Cleaned!"
}