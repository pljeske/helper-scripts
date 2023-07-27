#!/bin/sh

# prints a sorted list of all files and directories and their respective sizes (including hidden ones)
du -sh .[^.]* * 2> /dev/null | sort -h
