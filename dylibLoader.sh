#!/bin/bash
# This script is part of the MerlinMake repository
# Copyright (C) 2020 Tango Golf Digital, LLC
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# This script searches upwards from the current directory looking for the
# first make.sh file found.  If found, executes that file passing any
# specified parameters after inserting --mode=list-dylib-paths.
# The results are collected and used to generate a loader script
# which can then be used to execute the executables associated with
# this project.

set -eu

# Read the list of dynamic libraries and collect quoted results
libraryList=""
makePath=$(upfind -name 'make.sh' -executable 2> /dev/null | head -n 1)
if [[ -f $makePath ]]; then
    makeCommandLine="'$makePath' --mode=list-dylib-paths $@"
    commandOutput=$(eval \$$makeCommandLine)
    while ifs= read -r line
    do
	if [ ! -z "$line" ]; then
	    libraryList+="$line:"
	fi
    done <<< "$commandOutput"
else
    echo "make.sh not found from here"
    exit 1
fi

baseFilename="$(basename $(dirname $makePath))"
executableFilename="$baseFilename.bin"
loaderFilename="$baseFilename.loader"
loaderPathname="$(dirname $makePath)/$loaderFilename"

# Create a new configuration file (unless list is empty)
if [ ! -z "$libraryList" ]; then
    echo "set -eu"                              > "$loaderPathname"
    echo "export LD_LIBRARY_PATH=$libraryList" >> "$loaderPathname"
    echo "$executableFilename \"\$@\""         >> "$loaderPathname"
    chmod a+rx "$loaderPathname"
    echo "Done"
else
    echo "Not creating loader file because dylib list is empty."
fi
