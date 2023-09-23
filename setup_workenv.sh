#!/usr/bin/env bash

function log() {
  local component="$1"
  local msg="$2"
  printf "[%s] - %s\n" "$component" "$msg"
}

function log_title() {
  local msg="  $1  "
  local term_width=$(tput cols)
  local msg_len=${#msg}
  local pad_len=$(( (term_width - msg_len) / 2 ))
  local padding=$(printf "%0.s#" $(seq 1 $pad_len))
  printf "%s%s%s\n" "$padding" "$msg" "$padding"
}

function configure_shell_for_pyenv() {
  profile_file="$1"
  # shellcheck disable=SC2016
  {
    echo 'export PYENV_ROOT="$HOME/.pyenv"'
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"'
    echo 'eval "$(pyenv init -)"'
  } >> "$profile_file"
}

function install_pyenv() {
  log_title "pyenv"
  # build environment dependencies
  log "pyenv" "installing build enviornment dependencies"
  apt-get install -y \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    curl \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev > /dev/null

  # pyenv installation script
  log "pyenv" "running pyenv installation script"
  curl https://pyenv.run | bash > /dev/null

  # configure bashrcapt
  log "pyenv" "configuring bash/zsh for use with pyenv"
  configure_shell_for_pyenv "$HOME/.bashrc"
  configure_shell_for_pyenv "$HOME/.zshrc"

  profile_file="${HOME}/.bash_profile"
  [ -f "$profile_file" ] || profile_file="${HOME}/.profile"
  if [ -f "$profile_file" ]; then
    configure_shell_for_pyenv "$profile_file"
  fi
}

function install_zsh() {
  log_title "zsh"
  log "zsh" "installing zsh"
  local username
  local line
  # install zsh & make it default shell
  apt-get install -y zsh > /dev/null

  if [ -n "$SUDO_USER" ]; then
    log "zsh" "change default shell for user $SUDO_USER to $(which zsh)"
    usermod --shell "$(which zsh)" "$SUDO_USER"
  fi

  # install oh-my-zsh
  log "zsh" "installing oh-my-zsh"
  wget -O install_zsh.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh && chmod a+x install_zsh.sh
  ./install_zsh.sh > /dev/null
  rm install_zsh.sh
}

function install_common_tools() {
  log_title "common tools"
  local arch="$1"

  log "tools" "installing kubectl"
  if [ "$arch" == 'armv*' ] || [ "$arch" == 'aarch64' ]; then
    wget -O /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl" > /dev/null
  elif [ "$arch" == 'x86_64' ]; then
    wget -O /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" > /dev/null
  else
    echo "Processor architecture $PROCESSOR_ARCH not supported"
    exit 1
  fi
  chmod a+x /usr/local/bin//kubectl

  log "tools" "installing various tools via apt"
  apt-get install -y curl wget iputils-ping traceroute nmap net-tools dnsutils jq nano unzip zip mergerfs git > /dev/null

  log "tools" "installing yq"
  wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 > /dev/null
  chmod a+x /usr/local/bin/yq
}

function install_sdkman() {
  log_title "sdkman"
  log "sdkman" "running sdkman installation script"
  curl -s "https://get.sdkman.io" | bash > /dev/null
  log "sdkman" "initializing sdkman"
  chmod u+x ~/.sdkman/bin/sdkman-init.sh
  source ~/.sdkman/bin/sdkman-init.sh
}

log_title "INITIALIZATION"
# check for required privileges
[ "$EUID" -eq 0 ] || { echo "This script must be run as root or with sudo privileges."; exit 1; }

# processor architecture
arch=$(uname -i)

# update apt cache
log "init" "upgrading packages"
apt-get update > /dev/null
apt-get upgrade -y > /dev/null
apt-get install -y curl > /dev/null

install_common_tools "$arch"
install_zsh
install_pyenv
install_sdkman

log_title "docker"
curl -s https://get.docker.com | bash > /dev/null
if [ -n "$SUDO_USER" ]; then
  usermod -aG docker "$SUDO_USER"
fi

log_title "scripts"
log "scripts" "downloading 'try' script"
wget -O /usr/local/bin/try https://raw.githubusercontent.com/binpash/try/main/try > /dev/null
chmod a+x /usr/local/bin/try
