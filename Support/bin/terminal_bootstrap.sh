#!/usr/bin/env bash

# Shamelessly borrowed from Python bundle
esc () {
STR="$1" ruby <<"RUBY"
   str = ENV['STR']
   str = str.gsub(/'/, "'\\\\''")
   str = str.gsub(/[\\"]/, '\\\\\\0')
   print "'#{str}'"
RUBY
}

# Shamelessly borrowed from Python bundle
osascript <<- APPLESCRIPT
	tell app "Terminal"
		launch
	    activate
	    do script "	cd $(esc "$TM_DIRECTORY"); 
					export TM_JAVA=${TM_JAVA:-java};
					export TM_JAVAC=${TM_JAVAC:-javac};
					export TM_J_PC=$(esc "$CLASSPATH");
					clear; $(esc "$TM_BUNDLE_SUPPORT")/bin/javamate2.sh $1 $(esc "${TM_FILEPATH}")"
		set position of first window to { 100, 100 }
	end tell
APPLESCRIPT