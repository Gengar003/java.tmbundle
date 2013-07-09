#!/usr/bin/env bash

# Load in our command-line arguments.
# The type of action to do
SWITCH="$1"
shift
# The .class file to use as our starting point
SOURCE="$1"
shift

# Get filename and extension information from the file that was active when we were invoked.
FILENAME=$(basename "$SOURCE")
EXTENSION=${FILENAME##*.}
CLASS=$(basename -s .$EXTENSION "$SOURCE")

# Use the Habanero Java runtime, if it's a Habanero Java file.
if [ `echo $EXTENSION | tr [:upper:] [:lower:]` = "hj" ]
	then
	HAS_HJ=`which hj`
	if [ -z "$HAS_HJ" ]
		then
		echo "Error: You do not have Habanero Java installed, or it is not in your PATH."
		exit 1
	fi
	
	# Use Habanero Java compiler and runtime
	TM_JAVA=hj
	TM_JAVAC=hjc
	
	# Pass the "abstract execution statistics" through.
	if [ `echo "x$TM_HJ_METRICS" | tr [:upper:] [:lower:]` = "xstats" ]
		then
		HJ_METRICS="-PERF=true"
	elif [ `echo "x$TM_HJ_METRICS" | tr [:upper:] [:lower:]` = "xgraph" ]
		then
		HJ_GRAPH="-dcg"
	elif [ `echo "x$TM_HJ_METRICS" | tr [:upper:] [:lower:]` = "xrace" ]
		then
		HJ_RACEDET="-racedet"
	else
		HJ_METRICS=""
		HJ_GRAPH=""
		HJ_RACEDET=""
	fi
	
	# We need to prefix the rest of our JVM options with -J to get them to java, and not hj.
	PREFIX="-J"
fi

# Are we just printing out our version?
if [ "$1" = "--version" ]
then
	"$TM_JAVA" -version 2>&1 | head -1
    exit 0
fi

# Make sure we've been asked to perform a valid operation.
if [[ "$SWITCH" != "--compile_only" && 
    "$SWITCH" != "--compile_lint" &&
    "$SWITCH" != "--compile_and_run" && 
    "$SWITCH" != "--test" &&
    "$SWITCH" != "--compile_project" && 
    "$SWITCH" != "--compile_project_run" &&
    "$SWITCH" != "--compile_project_test" &&
    "$SWITCH" != "--compile_project_lint" &&
    "$SWITCH" != "--compile_project_class" &&
	"$SWITCH" != "--compile_project_jar" &&
	"$SWITCH" != "--compile_project_bundle_jar" ]]
	then
	echo "Error: '$SWITCH' is not a valid switch. Please use one of the following switches:"
	echo " --compile_and_run"
	echo " --compile_only"
	echo " --compile_lint"
	echo " --compile_project"
	echo " --compile_project_run"
	echo " --compile_project_lint"
	echo " --compile_project_class"
	echo " --complie_project_jar"
	echo " --complie_project_bundle_jar"
	echo " --test"
	exit 0
fi

# If we're compiling with lint, we need to change our output slightly.
# Let's find out if we're compliling with lint, and set that up now.
XLINT=""
XLINGMSG=""
XLINTMSG2=""

if [[ "$SWITCH" == "--compile_lint" || "$SWITCH" == "--compile_project_lint" ]]
	then
	XLINT="-Xlint"
	XLINTMSG=" ( with -Xlint )"
	
	# The following line would be a nice addition to -Xlint compiles, noting that no warnings were found, if that was the case.
	# However, javac -xlint will exit with errorlevel 0 if warnings are present - 
	# so there's no way to detect whether there were or weren't warnings.
	# the -Xstdout flag seems to resist being captured in a shell variable, 
	# which would be necessary to check at a later time whether errors were present or not.
	
	# XLINTMSG2=" or warnings"
	SWITCH=${SWITCH%_lint}
fi

# Allow TM_JAVA_HEAP and TM_JAVA_STACK environment variables to affect the JVM.

JAVA_HEAP=""

# Make sure the heap size is a positive number.
# NOTE: Must also be an INTEGER, but this is not checked.
if [[ $TM_JAVA_HEAP -gt 0 ]]
	then
	JAVA_HEAP="$PREFIX-Xmx${TM_JAVA_HEAP}M"
fi

JAVA_STACK=""

# Make sure the stack size is a posistive number.
# NOTE: Must also be an INTEGER, but this is not checked.
if [[ $TM_JAVA_STACK -gt 0 ]]
	then
	JAVA_STACK="$PREFIX-Xss${TM_JAVA_STACK}M"
fi

# Combine our Stack and Heap into one string.
JAVA_MEMORY="$JAVA_HEAP $JAVA_STACK"

# The (temporary) directory that we're going to compile to...
output="${TMPDIR}tm_javamate.${TM_PID:-$LOGNAME}";

# ... unless we want access to the .class files.
if [[ "$SWITCH" == "--compile_project_class" ]]; then
	output="$TM_PROJECT_DIRECTORY/bin"
	SWITCH="--compile_project"
fi

# Make the output directory.
mkdir -p "$output"

# Our "success" message.
COMPILE_SMSG="Completed with no errors$XLINTMSG2.";

# Factor out encoding, errors with habanero java
ENCODING="-encoding UTF8"
ENCODING=""

# If we're working with just ONE FILE...
if [[ "$SWITCH" == "--compile_and_run" || "$SWITCH" == "--compile_only" || "$SWITCH" == "--test" ]]; then
	
	if [[ "$SWITCH" == "--compile_only" ]]; then
		echo "Compiling...$XLINTMSG"
	fi

	if [ -n "$HAS_HJ" ]
		then
		# Habanero java compiler can't handle spaces in path, regardless of escaping, so eliminate the use of paths.
		cd "$TM_DIRECTORY"
		
		# Habanero java compiler can't process multiple .hj files per compiler invocation, so invoke the compiler once per file.
		# It also requires different command-line flags.
		"$TM_JAVAC" -classpath ./:"$TM_J_PC" -destdir "$output" $ENCODING $HJ_GRAPH $HJ_RACEDET "$CLASS"."$EXTENSION"; rc=$?;
	else
		"$TM_JAVAC" -cp ./:"$TM_J_PC" -d "$output" $ENCODING $XLINT "$SOURCE"; rc=$?;
	fi
	
	if (($rc >= 1)); then exit $rc; else if [[ "$SWITCH" == "--compile_only" ]]; then echo "$COMPILE_SMSG"; fi; fi
fi

# If we're compiling with the whole project... 

# Locate all of the files we'll need:
COMPILE_THESE="${TMPDIR}javamate_files_to_compile.txt"
find "$TM_PROJECT_DIRECTORY" -name \*.$EXTENSION -print | awk '{ print "\"" $0 "\"";}' > "$COMPILE_THESE"
cd "$TM_PROJECT_DIRECTORY"

if [[ "$SWITCH" == "--compile_project" || "$SWITCH" == "--compile_project_run" || "$SWITCH" == "--compile_project_test" || "$SWITCH" = "--compile_project_jar" || "$SWITCH" = "--compile_project_bundle_jar" ]]
	then
	
	# If we're compiling a project, there won't be output from the program. 
	# Provide some, so programmers know that it's working.
	if [[ "$SWITCH" == "--compile_project" ]]; then
		echo "Compiling project...$XLINTMSG"
	fi
	
	# If the project directory is empty, set it to ./
	# ( user probably "compiled project" without a TextMate project open )
	if [[ -z "$TM_PROJECT_DIRECTORY" ]]; then
		TM_PROJECT_DIRECTORY="./"
	fi
	
	# Run the compiler
	if [ -n "$HAS_HJ" ]
		then
		echo "WARNING: 'Compile Project' is not reccommended for Habanero Java. Valid code may fail to compile or run."
		# Habanero java compiler can't handle spaces in path, regardless of escaping, so eliminate the use of paths.
		cd "$TM_PROJECT_DIRECTORY"
		
		# Habanero java compiler can't process multiple .hj files per compiler invocation, so invoke the compiler once per file.
		cat "$COMPILE_THESE" | while read file; do "$TM_JAVAC" -classpath ./:"$TM_J_PC" -destdir "$output" $ENCODING "$CLASS"."$EXTENSION"; export rc=$?; if(($rc >= 1)); then exit $rc; fi; done
		
		rc=$?
	else
		"$TM_JAVAC" -classpath ./:"$TM_J_PC" -d "$output" $ENCODING $XLINT @"$COMPILE_THESE"; rc=$?;
	fi
	
	# Print success message and/or exit based on presence or absence of errors.
	if (($rc >= 1)); then exit $rc; else if [[ "$SWITCH" == "--compile_project" ]]; then echo "$COMPILE_SMSG"; fi; fi
fi

# If we made it this far, we're not just compiling; we're going to run something, too!

# Append our temporary compile directory to our working classpath environment variable.
TM_J_PC="$output:$TM_J_PC"

# $OLDPWD seems to be a thing that Mac OR Bash does. Either way, let's rely on it!
EXECUTION_TARGET_PACKAGE=`cat  "$OLDPWD/$CLASS.$EXTENSION" | grep package | awk '{ print substr($2, 0, index( $2, ";" )-1 ) }'`
EXECUTION_TARGET="$EXECUTION_TARGET_PACKAGE.$CLASS"

# If we're going to run anything...
if [[ "$SWITCH" == "--compile_and_run" || "$SWITCH" == "--compile_project_run" ]]
	then
	
	# Execute the java command, with our parameters, targetting our file.
	
	"$TM_JAVA" -classpath "$TM_J_PC" $HJ_METRICS $JAVA_MEMORY -Dfile.encoding=utf-8 "$EXECUTION_TARGET" "$@"

# Or maybe we're going to run a test case file...
elif [[ "$SWITCH" == "--test" || "$SWITCH" == "--compile_project_test" ]] 
	then
	
	if [ -n "$HAS_HJ" ]
		then
		echo "You cannot test Habanero Java files with JUnit. JUnit's reflection is not aware of Habanero Java's extensions to the syntax, so it doesn't work."
		exit 0
	fi
	# Execute the java command ON JUNIT, targetting our test case.
	# -ea enables assertions, in case someone has mixed JUnit assertions with Java assertions
	# DO WE WANT THIS? Couldn't find any literature on whether this is advisable or not.
	"$TM_JAVA" -classpath "$TM_J_PC" -ea $JAVA_MEMORY -Dfile.encoding=utf-8 org.junit.runner.JUnitCore "$EXECUTION_TARGET"
	
# TODO: Ensure that JAR-making still works, now that we use find to compile everything.
elif [[ "$SWITCH" == "--compile_project_jar" || "$SWITCH" == "--compile_project_bundle_jar" ]]
	then
	
	# 1. Move to our output directory
	cd "$output"
	
	# 2. Make $output/jar directory. If it exists, empty it.
	if [ -d "jar" ]; then
	    rm -rf "$output/jar/"
	else
		mkdir "jar"
	fi
	
	# 3. Copy $output/*.class to $output/jar/ directory
	find . -regex ".*class$" | while read classfile; do cp -f "$classfile" "jar/$classfile"; done;
	
	# 4. Move to the directory with all of our .class files.
	cd "jar"
	
	# If we're going to bundle all jars in our classpath into the resultant jar, we need to extract them to $output/jar
	if [[ "$SWITCH" == "--compile_project_bundle_jar" ]]
		then
		# 1. Identify the .jar files in our classpath
		#	NOTE: Only RELATIVE paths are used here. Absolute paths are assumed to be part of the system, and not unique to this project.
		# 2. Extract them to $output/jar directory
		echo "$CLASSPATH" | tr ":" "\n" | grep "^[^/].*jar$" | while read path
			do echo "Bundling '$path'..."
			jar xf "$TM_PROJECT_DIRECTORY/$path"
		done
	fi
	
	# Get a list of all the .class files.
	LOCAL_CLASSES=$( find . -regex ".*class$" )
	
	# Make a jar from our project files.
	echo "Creating $CLASS.jar..."
	jar cfe "$TM_PROJECT_DIRECTORY"/"$CLASS.jar" "$CLASS" $LOCAL_CLASSES
	
	# Remove $output/jar directory
	rm -rf "$output/jar/"
	
	echo "Done."
	
fi

# We're done here.
rm -f "$COMPILE_THESE"
exit $?