#!/bin/bash

# Ubuntu Security Tools Installation Script
# This script installs various security analysis tools on Ubuntu
# Tools: nmap, ncat, ping, binwalk, impacket, obsidian, smbclient, 
#        netexec, certipy, dnstool, i3, hashcat, java, zsh + oh-my-zsh, 
#        kitty, polybar

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[*]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_status "Starting security tools installation..."

# Update system
print_status "Updating package lists..."
apt update

print_status "Upgrading existing packages..."
apt upgrade -y

# Install essential build tools and dependencies
print_status "Installing essential dependencies..."
apt install -y \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    pipx \
    git \
    curl \
    wget \
    libssl-dev \
    libffi-dev \
    python3-dev \
    python3-setuptools \
    libpcap-dev \
    libgmp3-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    ocl-icd-libopencl1 \
    opencl-headers \
    clinfo \
    fonts-powerline \
    fonts-font-awesome \
    tmux \
    ncat \
    nmap \
    iputils-ping \
    binwalk \
    smbclient \
    dnsutils \
    default-jre \
    openjdk-8-jre \
    dnsrecon \
    python3-ldapdomaindump \
    pyrebase4 \
    adcli \
    nbtscan

# 6. Install hashcat
print_status "Installing hashcat..."
apt install -y hashcat || {
    print_warning "Hashcat not found in repositories, installing from source..."
    # Install hashcat from source as fallback
    cd /tmp
    git clone https://github.com/hashcat/hashcat.git
    cd hashcat
    make
    make install
    cd ..
    rm -rf hashcat
}

# 7. Install DNS enumeration tools
print_status "Installing DNS enumeration tools..."
# Install dnsrecon via pip
python3 -m pip install dnsrecon || print_warning "Failed to install dnsrecon"

# Install dnsenum manually
print_status "Installing dnsenum..."
cd /tmp
git clone https://github.com/fwaeytens/dnsenum.git || print_warning "Failed to clone dnsenum"
if [ -d "dnsenum" ]; then
    cd dnsenum
    chmod +x dnsenum.pl
    cp dnsenum.pl /usr/local/bin/dnsenum
    cd ..
    rm -rf dnsenum
fi

# 8. Install i3 window manager
print_status "Installing i3 window manager..."
apt install -y i3 i3status i3lock xss-lock dmenu

# 9. Install polybar
print_status "Installing polybar..."
apt install -y polybar

# Create basic polybar config
print_status "Configuring polybar..."
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    POLYBAR_CONFIG_DIR="$USER_HOME/.config/polybar"
    mkdir -p "$POLYBAR_CONFIG_DIR"
    
    # Create launch script
    cat > "$POLYBAR_CONFIG_DIR/launch.sh" << 'EOF'
#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch polybar
polybar main &

echo "Polybar launched..."
EOF
    chmod +x "$POLYBAR_CONFIG_DIR/launch.sh"
    
    # Create basic polybar config
    cat > "$POLYBAR_CONFIG_DIR/config.ini" << 'EOF'
[colors]
background = #282A2E
background-alt = #373B41
foreground = #C5C8C6
primary = #F0C674
secondary = #8ABEB7
alert = #A54242
disabled = #707880

[bar/main]
width = 100%
height = 24pt
radius = 0

background = ${colors.background}
foreground = ${colors.foreground}

line-size = 3pt

border-size = 0
border-color = #00000000

padding-left = 0
padding-right = 1

module-margin = 1

separator = |
separator-foreground = ${colors.disabled}

font-0 = monospace;2
font-1 = Font Awesome 6 Free:pixelsize=12;2
font-2 = Font Awesome 6 Free Solid:pixelsize=12;2
font-3 = Font Awesome 6 Brands:pixelsize=12;2

modules-left = i3 xwindow
modules-center = date
modules-right = network network-wireless cpu memory battery

cursor-click = pointer
cursor-scroll = ns-resize

enable-ipc = true

[module/i3]
type = internal/i3
pin-workspaces = true
show-urgent = true
strip-wsnumbers = true
index-sort = true

format = <label-state> <label-mode>

label-focused = %index%
label-focused-background = ${colors.background-alt}
label-focused-underline= ${colors.primary}
label-focused-padding = 1

label-unfocused = %index%
label-unfocused-padding = 1

label-visible = %index%
label-visible-underline = ${colors.secondary}
label-visible-padding = 1

label-urgent = %index%
label-urgent-background = ${colors.alert}
label-urgent-padding = 1

[module/xwindow]
type = internal/xwindow
label = %title:0:60:...%

[module/cpu]
type = internal/cpu
interval = 2
format-prefix = "CPU "
format-prefix-foreground = ${colors.primary}
label = %percentage:2%%

[module/memory]
type = internal/memory
interval = 2
format-prefix = "MEM "
format-prefix-foreground = ${colors.primary}
label = %percentage_used:2%%

[module/network]
type = internal/network
interface-type = wired
interval = 3.0

format-connected = <label-connected>
format-connected-prefix = "NET "
format-connected-prefix-foreground = ${colors.primary}
label-connected = %ifname% %local_ip%

format-disconnected = <label-disconnected>
label-disconnected = disconnected
label-disconnected-foreground = ${colors.disabled}

[module/network-wireless]
type = internal/network
interface-type = wireless
interval = 3.0

format-connected = <label-connected>
format-connected-prefix = "WIFI "
format-connected-prefix-foreground = ${colors.primary}
label-connected = %essid% %local_ip%

format-disconnected = <label-disconnected>
label-disconnected = no wifi
label-disconnected-foreground = ${colors.disabled}

[module/battery]
type = internal/battery
battery = BAT0
adapter = AC
full-at = 98

format-charging = <label-charging>
format-charging-prefix = "BAT+ "
format-charging-prefix-foreground = ${colors.secondary}
label-charging = %percentage%%

format-discharging = <label-discharging>
format-discharging-prefix = "BAT "
format-discharging-prefix-foreground = ${colors.primary}
label-discharging = %percentage%%

format-full-prefix = "FULL "
format-full-prefix-foreground = ${colors.secondary}
label-full = %percentage%%

[module/date]
type = internal/date
interval = 1

date = %Y-%m-%d %H:%M:%S
date-alt = %A, %B %d, %Y %H:%M:%S

label = %date%
label-foreground = ${colors.primary}

[settings]
screenchange-reload = true
pseudo-transparency = false
EOF
    
    # Update i3 config to use polybar instead of i3status
    USER_I3_CONFIG="$USER_HOME/.config/i3/config"
    if [ -f "$USER_I3_CONFIG" ]; then
        # Comment out i3bar section
        sed -i '/^bar {/,/^}/ s/^/#/' "$USER_I3_CONFIG"
        
        # Add polybar launch command
        if ! grep -q "polybar/launch.sh" "$USER_I3_CONFIG"; then
            echo "" >> "$USER_I3_CONFIG"
            echo "# Launch polybar" >> "$USER_I3_CONFIG"
            echo "exec_always --no-startup-id \$HOME/.config/polybar/launch.sh" >> "$USER_I3_CONFIG"
        fi
    else
        # If i3 config doesn't exist yet, make sure it will launch polybar when created
        mkdir -p "$USER_HOME/.config/i3"
        echo "# Launch polybar" > "$USER_HOME/.config/i3/polybar-autostart"
        echo "exec_always --no-startup-id \$HOME/.config/polybar/launch.sh" >> "$USER_HOME/.config/i3/polybar-autostart"
        chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME/.config/i3"
    fi
    
    chown -R "$SUDO_USER:$SUDO_USER" "$POLYBAR_CONFIG_DIR"
fi

# 10. Install zsh and make it default shell
print_status "Installing zsh..."
apt install -y zsh

# Set zsh as default shell for root and current sudo user
print_status "Setting zsh as default shell..."
chsh -s /usr/bin/zsh
if [ -n "$SUDO_USER" ]; then
    chsh -s /usr/bin/zsh "$SUDO_USER"
    print_status "Set zsh as default shell for $SUDO_USER"
fi

# Install Oh My Zsh
print_status "Installing Oh My Zsh..."
# Function to install Oh My Zsh for a specific user
install_oh_my_zsh() {
    local USER_NAME=$1
    local USER_HOME=$2
    
    if [ -d "$USER_HOME/.oh-my-zsh" ]; then
        print_warning "Oh My Zsh already installed for $USER_NAME"
        return
    fi
    
    # Download and install Oh My Zsh non-interactively
    su - "$USER_NAME" -c "
        export RUNZSH=no
        export CHSH=no
        export KEEP_ZSHRC=yes
        sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" || \
        sh -c \"\$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\"
    " || {
        print_warning "Failed to install Oh My Zsh for $USER_NAME, trying alternative method..."
        # Alternative method: clone directly
        git clone https://github.com/ohmyzsh/ohmyzsh.git "$USER_HOME/.oh-my-zsh"
        cp "$USER_HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$USER_HOME/.zshrc"
        chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.oh-my-zsh" "$USER_HOME/.zshrc"
    }
    
    # Configure .zshrc with useful plugins and theme
    if [ -f "$USER_HOME/.zshrc" ]; then
        # Backup original
        cp "$USER_HOME/.zshrc" "$USER_HOME/.zshrc.backup"
        
        # Set theme to agnoster (good for security work)
        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' "$USER_HOME/.zshrc"
        
        # Enable useful plugins for security work
        sed -i 's/plugins=(git)/plugins=(git docker python pip nmap ssh-agent sudo tmux colored-man-pages command-not-found extract z)/' "$USER_HOME/.zshrc"
        
        # Add custom aliases for security tools
        cat >> "$USER_HOME/.zshrc" << 'EOF'

# Add local bin to PATH if not already there
export PATH="$HOME/.local/bin:$PATH"

# Security tool aliases
alias nse='ls /usr/share/nmap/scripts/ | grep'
alias smbmap='smbclient -L'
alias hashcat64='hashcat'
alias serve='python3 -m http.server'
alias pyserve='python3 -m http.server'
alias phpserve='php -S 0.0.0.0:8000'

# Network aliases
alias ports='netstat -tulanp'
alias listening='netstat -tlnp'
alias myip='curl -s ifconfig.me'

# Useful functions
extract_all() {
    for file in "$@"; do
        if [ -f "$file" ]; then
            case $file in
                *.tar.bz2)   tar xjf "$file"     ;;
                *.tar.gz)    tar xzf "$file"     ;;
                *.bz2)       bunzip2 "$file"     ;;
                *.rar)       unrar e "$file"     ;;
                *.gz)        gunzip "$file"      ;;
                *.tar)       tar xf "$file"      ;;
                *.tbz2)      tar xjf "$file"     ;;
                *.tgz)       tar xzf "$file"     ;;
                *.zip)       unzip "$file"       ;;
                *.Z)         uncompress "$file"  ;;
                *.7z)        7z x "$file"        ;;
                *)           echo "'$file' cannot be extracted" ;;
            esac
        else
            echo "'$file' is not a valid file"
        fi
    done
}

# Quick base64 encode/decode
b64e() { echo -n "$1" | base64; }
b64d() { echo -n "$1" | base64 -d; }

# Quick URL encode/decode
urlencode() { python3 -c "import urllib.parse; print(urllib.parse.quote('$1'))"; }
urldecode() { python3 -c "import urllib.parse; print(urllib.parse.unquote('$1'))"; }
EOF
        
        chown "$USER_NAME:$USER_NAME" "$USER_HOME/.zshrc"
    fi
}

# Install for root
install_oh_my_zsh "root" "/root"

# Install for sudo user
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    install_oh_my_zsh "$SUDO_USER" "$USER_HOME"
fi

# 11. Install kitty terminal
print_status "Installing kitty terminal..."
apt install -y kitty

# Configure kitty as default terminal for i3
print_status "Configuring kitty as default terminal for i3..."
# Create i3 config directory if it doesn't exist
I3_CONFIG_DIR="/etc/i3"
if [ -d "$I3_CONFIG_DIR" ]; then
    # Backup original config
    cp "$I3_CONFIG_DIR/config" "$I3_CONFIG_DIR/config.backup" 2>/dev/null || true
    
    # Update terminal binding in system-wide i3 config
    sed -i 's/bindsym \$mod+Return exec i3-sensible-terminal/bindsym \$mod+Return exec kitty/' "$I3_CONFIG_DIR/config" 2>/dev/null || true
    sed -i 's/bindsym \$mod+Return exec terminal/bindsym \$mod+Return exec kitty/' "$I3_CONFIG_DIR/config" 2>/dev/null || true
fi

# Also create user config template
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    USER_I3_DIR="$USER_HOME/.config/i3"
    mkdir -p "$USER_I3_DIR"
    chown "$SUDO_USER:$SUDO_USER" "$USER_I3_DIR"
    
    # Create a basic i3 config with kitty as default if it doesn't exist
    if [ ! -f "$USER_I3_DIR/config" ]; then
        cat > "$USER_I3_DIR/config" << 'EOF'
# i3 config file (v4)
# Set mod key (Mod1=Alt, Mod4=Windows key)
set $mod Mod4

# Font for window titles
font pango:monospace 8

# Start kitty terminal
bindsym $mod+Return exec kitty

# Kill focused window
bindsym $mod+Shift+q kill

# Start dmenu
bindsym $mod+d exec dmenu_run

# Launch polybar
exec_always --no-startup-id $HOME/.config/polybar/launch.sh

# Copy remaining config from system default
EOF
        # Append the rest of the default config, skipping the terminal binding and i3bar
        if [ -f "$I3_CONFIG_DIR/config" ]; then
            grep -v "bindsym \$mod+Return" "$I3_CONFIG_DIR/config" | \
            grep -v "^#.*config file" | \
            grep -v "^set \$mod" | \
            grep -v "^font pango" | \
            grep -v "bindsym \$mod+d exec dmenu" | \
            grep -v "bindsym \$mod+Shift+q kill" | \
            sed '/^bar {/,/^}/ d' >> "$USER_I3_DIR/config"
        fi
        chown "$SUDO_USER:$SUDO_USER" "$USER_I3_DIR/config"
    fi
fi

# Set kitty as the default x-terminal-emulator alternative
update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/kitty 50
update-alternatives --set x-terminal-emulator /usr/bin/kitty

# Create basic kitty config for better defaults
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    KITTY_CONFIG_DIR="$USER_HOME/.config/kitty"
    mkdir -p "$KITTY_CONFIG_DIR"
    
    if [ ! -f "$KITTY_CONFIG_DIR/kitty.conf" ]; then
        cat > "$KITTY_CONFIG_DIR/kitty.conf" << 'EOF'
# Kitty Configuration
# Font configuration
font_family      monospace
font_size        11.0

# Shell integration
shell /usr/bin/zsh
shell_integration enabled

# Terminal bell
enable_audio_bell no

# Theme
background_opacity 0.95
background #1e1e1e

# Scrollback
scrollback_lines 10000

# URL handling
open_url_with default
detect_urls yes

# Performance
repaint_delay 10
input_delay 3
sync_to_monitor yes
EOF
        chown -R "$SUDO_USER:$SUDO_USER" "$KITTY_CONFIG_DIR"
    fi
fi

# 12. Install Python-based tools
print_status "Setting up Python environment for security tools..."

# Ensure pipx path is in PATH
pipx ensurepath

# Install impacket
print_status "Installing impacket..."
pipx install impacket

# Install netexec (formerly crackmapexec)
print_status "Installing netexec..."
python3 -m pip install netexec

# Install certipy-ad
print_status "Installing certipy..."
python3 -m pip install certipy-ad

# 13. Install Obsidian
print_status "Installing Obsidian..."
# Check if snap is installed, if not install it
if ! command -v snap &> /dev/null; then
    print_warning "Snap not found, installing..."
    apt install -y snapd
    systemctl enable --now snapd.socket
    # Create symlink for classic snap support
    ln -s /var/lib/snapd/snap /snap 2>/dev/null || true
fi

# Install Obsidian via snap
snap install obsidian --classic

# Add Python scripts to PATH
print_status "Configuring PATH..."

# Create profile.d script to ensure Python scripts are in PATH
cat > /etc/profile.d/security-tools.sh << 'EOF'
# Add Python user base bin to PATH
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Add Python3 scripts to PATH
if [ -d "/usr/local/bin" ]; then
    export PATH="/usr/local/bin:$PATH"
fi
EOF

chmod +x /etc/profile.d/security-tools.sh

# Create symbolic links for Python tools if needed
print_status "Creating symbolic links for Python tools..."

# Find where pip installed the tools
PYTHON_BIN=$(python3 -m site --user-base)/bin

# Create symlinks in /usr/local/bin for system-wide access
for tool in impacket netexec certipy; do
    # Find the actual binary
    if [ -f "$PYTHON_BIN/$tool" ]; then
        ln -sf "$PYTHON_BIN/$tool" /usr/local/bin/
    elif [ -f "/usr/local/bin/$tool" ]; then
        print_status "$tool already in /usr/local/bin"
    else
        # Try to find it in the system Python path
        TOOL_PATH=$(find /usr -name "$tool" -type f -executable 2>/dev/null | grep -E "(bin|scripts)" | head -1)
        if [ -n "$TOOL_PATH" ]; then
            ln -sf "$TOOL_PATH" /usr/local/bin/
        fi
    fi
done

# Verify installations
print_status "Verifying installations..."
echo ""
echo "=== Installation Status ==="

# Function to check if command exists
check_tool() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 installed successfully"
        $1 --version 2>/dev/null || $1 -v 2>/dev/null || echo "   Version info not available"
    else
        echo -e "${RED}✗${NC} $1 installation failed or not in PATH"
    fi
}

check_tool nmap
check_tool ncat
check_tool ping
check_tool binwalk
check_tool smbclient
check_tool hashcat
check_tool java
check_tool i3
check_tool polybar
check_tool zsh
check_tool kitty

# Check Python tools
echo ""
echo "Python tools:"
python3 -m pip show impacket &>/dev/null && echo -e "${GREEN}✓${NC} impacket installed" || echo -e "${RED}✗${NC} impacket not found"
command -v netexec &>/dev/null && echo -e "${GREEN}✓${NC} netexec installed" || echo -e "${RED}✗${NC} netexec not found"
command -v certipy &>/dev/null && echo -e "${GREEN}✓${NC} certipy installed" || echo -e "${RED}✗${NC} certipy not found"

# Check Obsidian
if command -v obsidian &>/dev/null || [ -f /usr/local/bin/obsidian ]; then
    echo -e "${GREEN}✓${NC} Obsidian installed"
else
    echo -e "${RED}✗${NC} Obsidian not found"
fi

# Check DNS tools
echo ""
echo "DNS tools:"
check_tool nslookup
check_tool dig
check_tool dnsrecon
check_tool dnsenum

# Show Java versions
echo ""
echo "Java versions installed:"
update-alternatives --list java 2>/dev/null || echo "No Java alternatives configured"

# Show shell information
echo ""
echo "Shell configuration:"
echo "Current shell: $SHELL"
echo "Zsh location: $(which zsh)"
if [ -n "$SUDO_USER" ]; then
    echo "Default shell for $SUDO_USER: $(getent passwd "$SUDO_USER" | cut -d: -f7)"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    [ -d "$USER_HOME/.oh-my-zsh" ] && echo -e "${GREEN}✓${NC} Oh My Zsh installed for $SUDO_USER" || echo -e "${RED}✗${NC} Oh My Zsh not found for $SUDO_USER"
fi
[ -d "/root/.oh-my-zsh" ] && echo -e "${GREEN}✓${NC} Oh My Zsh installed for root" || echo -e "${RED}✗${NC} Oh My Zsh not found for root"

print_status "Installation complete!"
print_warning "Please log out and log back in for shell changes to take effect and PATH to be updated."
print_warning "Alternatively, run: source /etc/profile.d/security-tools.sh && exec zsh"

# Additional notes
echo ""
echo "=== Additional Notes ==="
echo "1. Python tools installed via pipx (impacket, netexec, certipy-ad)"
echo "2. You may need to run some Python tools with 'python3 -m' prefix"
echo "3. For Obsidian, if using AppImage, you may need to install additional dependencies"
echo "4. Some tools may require additional configuration for full functionality"
echo "5. i3 window manager: Kitty is set as default terminal. Config locations:"
echo "   - System: /etc/i3/config"
echo "   - User: ~/.config/i3/config"
echo "6. Java: Installed default JRE and OpenJDK 8. To switch versions use: sudo update-alternatives --config java"
echo "7. Hashcat: For NVIDIA GPUs, install CUDA. For AMD GPUs, install ROCm for better performance"
echo "8. Zsh with Oh My Zsh: Installed with agnoster theme and security-focused plugins"
echo "   - Config: ~/.zshrc"
echo "   - Custom aliases: nse, smbmap, serve, pyserve, ports, myip"
echo "   - Custom functions: extract_all, b64e/b64d, urlencode/urldecode"
echo "   - Plugins: git, docker, python, nmap, ssh-agent, tmux, z, and more"
echo "9. Kitty: Configured as default terminal. Config file: ~/.config/kitty/kitty.conf"
echo "10. Polybar: Configured to replace i3bar with system monitoring modules"
echo "    - Config: ~/.config/polybar/config.ini"
echo "    - Launch script: ~/.config/polybar/launch.sh"
echo "    - Modules: workspaces, window title, CPU, memory, network, battery, date/time"
