#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root or with superuser permissions."
  exit 1
fi

# identify package manager and install packages
if command -v apt-get >/dev/null 2>&1; then
  apt-get update
  apt-get install -y dnsutils iputils-ping curl nmap net-tools wget socat tcpdump
elif command -v dnf >/dev/null 2>&1; then
  dnf makecache
  dnf install -y --skip-broken bind-utils iputils curl nmap net-tools wget socat tcpdump
elif command -v yum >/dev/null 2>&1; then
  yum makecache
  yum install -y --skip-broken bind-utils iputils curl nmap net-tools wget socat tcpdump
elif command -v apk >/dev/null 2>&1; then
  apk update
  apk add bind-tools iputils curl nmap net-tools wget socat tcpdump
else
  echo "Your package manager is not supported by this script. Please install the required packages manually."
  exit 1
fi