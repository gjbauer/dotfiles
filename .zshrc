# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="/usr/local/share/ohmyzsh"

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
alias token="cat ~/.token"
alias gr="grep -r"
alias lock="~/.config/sway/lock.sh"
alias restart-wifi="~/.scripts/restart-wifi.sh"
alias serial="doas picocom -b 115200 /dev/nmdm0B"

# ssh-vm function to easily ssh into our development VMs
ssh-vm() {
    # Usage: ssh-vm vm_name [ssh_user]
    local vm_name=$1
    local user=${2:-dev}

    # 1. Get the host tap interface assigned to this VM name via virsh
    local tap_if=$(virsh -c "bhyve:///system" domiflist "$vm_name" 2>/dev/null | grep -E "tap|vnet" | awk '{print $1}')

    if [ -z "$tap_if" ]; then
        echo "Error: Could not find network interface for VM '$vm_name'."
        return 1
    fi

    # 2. Get the MAC address of that specific interface from the host system
    local mac=$(ifconfig "$tap_if" 2>/dev/null | grep ether | awk '{print $2}')

    if [ -z "$mac" ]; then
        echo "Error: Could not retrieve MAC address for interface $tap_if."
        return 1
    fi

    # 3. Match the host MAC address to your active ARP table
    local ip=$(arp -an | grep -i "$mac" | awk '{print $2}' | tr -d '()')

    if [ -z "$ip" ]; then
        # Fallback: Try matching the libvirt VM MAC address directly if host mapping fails
        local vm_mac=$(virsh -c "bhyve:///system" domiflist "$vm_name" 2>/dev/null | grep -E "tap|vnet" | awk '{print $5}')
        ip=$(arp -an | grep -i "$vm_mac" | awk '{print $2}' | tr -d '()')
    fi

    if [ -z "$ip" ]; then
        echo "Error: IP address not found in host ARP cache. Try pinging the subnet or checking if VM is up."
        return 1
    fi

    echo "Connecting to $vm_name ($ip) as $user..."
    ssh "${user}@${ip}"
}

