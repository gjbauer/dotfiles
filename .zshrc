# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="re5et"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Function to connect to a UTM VM serial console via picocom
# Usage: utm-serial <VM_NAME or UUID>
utm-serial() {
  local vm_target="$1"

  if [[ -z "$vm_target" ]]; then
    echo "Usage: utm-serial <VM_NAME or UUID>"
    return 1
  fi

  local utmctl="/Applications/UTM.app/Contents/MacOS/utmctl"

  if [[ ! -x "$utmctl" ]]; then
    echo "Error: utmctl not found at $utmctl"
    return 1
  fi

  # Use utmctl attach to get the PTTY path (it prints the path even though it says "not implemented")
  local tty_path
  tty_path=$("$utmctl" attach "$vm_target" 2>&1 | grep -o '/dev/ttys[0-9]*' | head -n 1)

  if [[ -z "$tty_path" ]]; then
    echo "Error: Could not determine PTTY for '$vm_target'."
    echo "Make sure:"
    echo "  1. The VM is running."
    echo "  2. A Serial device is configured with mode 'macOS Pseudo-TTY Device'."
    echo "  3. Check the VM details panel in UTM for the path."
    return 1
  fi

  if [[ ! -e "$tty_path" ]]; then
    echo "Error: Device $tty_path does not exist. Is the VM running?"
    return 1
  fi

  echo "Connecting to $vm_target on $tty_path..."
  picocom -b 115200 "$tty_path"
}

ssh-vm() {
    # Usage: ssh-vm vm_name [ssh_user]
    local vm_name=$1
    local user=${2:-dev}

    # 1. Retrieve the virtual machine's MAC address from UTM via osascript
    local mac=$(osascript -e "
        tell application \"UTM\"
            set vm to virtual machine named \"$vm_name\"
            set config to configuration of vm
            set nic to item 1 of network interfaces of config
            return address of nic
        end tell
    " 2>/dev/null)

    if [ -z "$mac" ]; then
        echo "Error: Could not retrieve MAC address for VM '$vm_name' from UTM."
        return 1
    fi

    # 2. Poll the macOS ARP table to locate the IP (UTM shared networking typically uses 192.168.64.0/24)
    # The MAC address in the output of `arp -a` on macOS may omit leading zeros; this requires handling for compatibility.
    local mac_stripped=$(echo "$mac" | awk -F: '{for(i=1;i<=NF;i++){sub(/^0+/,"",$i); if($i=="") $i="0"; printf "%s%s", $i, (i<NF?":":"")}}')
    local ip=""
    local deadline=$((SECONDS + 30))

    while (( SECONDS < deadline )); do
        ip=$(arp -a 2>/dev/null | awk -v mac="$mac" -v macs="$mac_stripped" '
            tolower($0) ~ tolower(mac) || tolower($0) ~ tolower(macs) {
                gsub(/[()]/,"",$2); print $2; exit
            }
        ')
        [ -n "$ip" ] && break
        sleep 2
    done

    # 3. Final attempt: Ping the broadcast address to refresh the ARP cache, then check again.
    if [ -z "$ip" ]; then
        ping -c 1 -t 1 192.168.64.255 >/dev/null 2>&1
        sleep 1
        ip=$(arp -a 2>/dev/null | awk -v mac="$mac" -v macs="$mac_stripped" '
            tolower($0) ~ tolower(mac) || tolower($0) ~ tolower(macs) {
                gsub(/[()]/,"",$2); print $2; exit
            }
        ')
    fi

    if [ -z "$ip" ]; then
        echo "Error: IP address not found for VM '$vm_name' (MAC: $mac)."
        echo "Ensure the VM is running and has obtained a DHCP lease on the shared network."
        return 1
    fi

    echo "Connecting to $vm_name ($ip) as $user..."
    ssh "${user}@${ip}"
}

export PATH="/opt/homebrew/bin:$PATH"
export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/opt/homebrew";
fpath[1,0]="/opt/homebrew/share/zsh/site-functions";
export FPATH;
eval "$(/usr/bin/env PATH_HELPER_ROOT="/opt/homebrew" /usr/libexec/path_helper -s)"
[ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}";
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
export PATH="$HOME/.rustup/toolchains/nightly-aarch64-apple-darwin/bin:$PATH";
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"

export MVT_STIX2="/Users/gabrielbauer/mvt-indicators/2022-06-23_rcs_lab/rcs.stixs2:/Users/gabrielbauer/mvt-indicators/2023-04-11_quadream/kingspawn.stix2:/Users/gabrielbauer/mvt-indicators/2023-06_01_operation_triangulation/operation_triangulation.stix2:/Users/gabrielbauer/mvt-indicators/2023-07-25_wyrmspy_dragonegg/wyrmspy_dragonegg.stix2:/Users/gabrielbauer/mvt-indicators/2024-12-25_eaglemsgspy/eaglemsgspy.stix2:/Users/gabrielbauer/mvt-indicators/2026-03-03_coruna_cryptowaters/coruna.stix2:/Users/gabrielbauer/mvt-indicators/2026-03-30_darksword/darksword.stix2:/Users/gabrielbauer/mvt-indicators/2026-04-09_sio_spyrtacus/spyrtacus.stix2:/Users/gabrielbauer/mvt-indicators/2026-04-23_ips_morpheus/morpheus.stix2:/Users/gabrielbauer/mvt-indicators/2026-05-26_btmob/btmob.stix2:/Users/gabrielbauer/mvt-indicators/candiru/candiru.stix2:/Users/gabrielbauer/mvt-indicators/cellebrite/cellebrite.stix2:/Users/gabrielbauer/mvt-indicators/intellexa_predator/predator.stix2:/Users/gabrielbauer/mvt-indicators/ResidentBat/residentbat.stix2"
