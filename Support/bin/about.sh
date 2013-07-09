#!/usr/bin/env bash

. "$TM_SUPPORT_PATH/lib/webpreview.sh"
html_header "Java-Plus Bundle Help" "Java-Plus"

"$TM_SUPPORT_PATH/lib/markdown_to_help.rb" <<'MARKDOWN'

# Introduction
The Java-Plus bundle is designed to replace TextMate's default Java bundle, expanding its capabilities to facilitate Java development. 
The primary new features are a host of compile-and-run keyboard shortcuts.
# Compilation Commands

Most compilation commands have two versions, one for dealing with only the currently active .java file, and the other for dealing with all .java files in the same directory as the currently active file.

## Compile Only
<ul>
	<li>File: ⌥⌘C</li>
	<li>Project: ⌃⌥⌘C</li>
</ul>
Will compile the java file(s) into TextMate's temporary directory.

## Compile & Run
<ul>
	<li>File: ⌘R</li>
	<li>Project: ⌃⌥⌘R</li>
</ul>
Will compile the java file(s) into TextMate's temporary directory, and run the currently active file.

## Compile & Run (with args)
<ul>
	<li>File: ⇧⌘R</li>
	<li>Project: ⌃⌥⇧⌘C</li>
</ul>
Will compile the java file(s) into TextMate's temporary directory, and run the currently active file. Before the JVM is started, you will be prompted for command-line arguments to feed into your Java proram.

## Compile & Run in Terminal
<ul>
	<li>File: ⇧⌘E</li>
	<li>Project: ⌃⌥⌘E</li>
</ul>
Will compile the java file(s) into TextMate's temporary directory, and run the currently active file in a Terminal window. If your program interacts with users on the command-line, you will need to use this instead of the normal "Compile & Run."

## Compile & Test
<ul>
	<li>File: ⌘T</li>
	<li>Project: ⌃⌥⌘T</li>
</ul>
Will compile the java file(s) into TextMate's temporary directory, and run the currently active file as a JUnit Test Case. JUnit must be installed and in TextMate's CLASSPATH.

## Compile (with Xlint)
<ul>
	<li>File: ⌥⌘L</li>
	<li>Project: ⌃⌥⌘L</li>
</ul>
Will compile the java file(s) with the "-Xlint" flag, causing the compiler to report warnings in addition to errors.

## Compile (with .class)
<ul>
	<li>File: N/A</li>
	<li>Project: ⌃⌥⇧⌘C</li>
</ul>
Will compile the java file(s) into a folder named "bin" in the same directory as the currently active file, instead of into TextMate's temporary directory.

## Compile to JAR
<ul>
	<li>File: N/A</li>
	<li>Project: ⌃⌥⌘J</li>
</ul>
Will create a .jar file of your project's .class files, in the same directory as your source files. The .jar file's name will be the name of whichever source file was active when you invoked this command. 
<br/><br/>
The default main class in the .jar file will be the file that was active when you invoked this command.
<br/><br/>
This command completely ignores classpaths. Anyone trying to run the .jar must have all of the required classes and jars in their classpath when they try to run the .jar. 
<br/><br/>
There are two ways to run the .jar created by this command:
<ol>
	<li><u>java -jar YourProject.jar</u>: Your $CLASSPATH environment variable must contain everything necessary for your project.<br/><br/></li>
	<li><u>java -cp ...:YourProject.jar MainClass</u>: where you specify at the command-line all necessary classes for your project, include your project's .jar at the end, and specify the class inside your jar (MainClass) to run</li>
</ol>

## Compile to JAR Bundle
<ul>
	<li>File: N/A</li>
	<li>Project: ⌃⌥⇧⌘J</li>
</ul>
<span style="color:#FF0000;font-weight:bold;">WARNING:</span> this may not always work! Please read carefully!
<br/><br/>
This creates a .jar file of your project in a similar manner to the "Compile to JAR" command. This command, however, attempts to make specifying or worrying about the proper classpath for your .jar unneccessary.
<br/><br/>This will attempt to extract the .class files inside any .jar files used in your project and bundle them next to your classes, in a single .jar. The end result is that your .jar would not require any special classpath to run, as all of its dependencies are included. A simple <u>java -jar YourProject.jar</u> would suffice.
<br/><br/>
<b>Downsides and Caveats:</b><br/>
Example Classpath: <u>libone.jar:libtwo.jar:/System/Library/libthree.jar</u>
<ul>
	<li>Only .jar files referenced by a relative path will be included. <u>libone.jar</u> and <u>libtwo.jar</u> would be included, but <u>libthree.jar</u> would not.<br/><br/></li>
	<li>Duplicate files will be overwritten with no warning.<br/><br/></li>
	<li>Your .jar file could be very large.<br/><br/></li>
	<li>You may be in violation of the licenses of some of the .jars you used, if you distribute the .jar that this creates.<br/><br/></li>
</ul>

# Environment Variables
The following <i>Environment Variables</i> can be added to the global TextMate environment, or to an individual project's environment to affect the way that TextMate handles Java programs.
<ul>

	<li>
	<b>CLASSPATH</b><br/>
	<i>string</i><br/>
	The Java classpath to use for compiling (javac) and running (java). This is explicitly specified on the command-line with the "-cp" option.
	<br/><br/>
	</li>
	
	<li>
	<b>TM_JAVA</b><br/>
	<i>string</i><br/>
	If specified, TextMate will use the java binary specified by this path to run your java files, instead of the system default.
	<br/><br/>
	</li>
	
	<li>
	<b>TM_JAVAC</b><br/>
	<i>string</i><br/>
	If specified, TextMate will use the javac binary specified by this path to compile your java files, instead of the system default.
	<br/><br/>
	</li>
	
	<li>
	<b>TM_JAVA_STACK</b><br/>
	<i>integer</i><br/>
	Specifies the stack size to use for the JVM, in megabytes. Uses the -Xss flag.
	<br/><br/>
	</li>
	
	<li>
	<b>TM_JAVA_HEAP</b><br/>
	<i>integer</i><br/>
	Specifies the maximum heap size to use for the JVM, in megabytes. Uses the -Xmx flag.
	<br/><br/>
	</li>
</ul>

# Habanero Java
<a href="http://habanero.rice.edu/hj.html">Habanero Java</a> is an extension to the Java programming language that allows code to be written for parallel-processing and multi-core environments. This bundle includes support for compiling and running Habanero Java files. In order for this to work, you must:

<ol>
	<li><a href="https://wiki.rice.edu/confluence/display/PARPROG/HJDownload">Download</a> the Habanero Java Runtime for Mac OS.</li>
	<li>Make sure sure that the following environment variables are set:</li>
</ol>

<ul>
	<li>
	<b>JAVA_HOME</b><br/>
	<i>string</i><br/>
	The path to your Java JDK/JRE. It will probably be <u>/System/Library/Frameworks/JavaVM.Framework/Versions/<b>VERSION</b>/Home</u>, where <b>VERSION</b> is the JDK version that you want Habanero Java to be based off. This path cannot include any symlinks; you cannot use the CurrentJDK symlink that Mac OS provides.
	<br/><br/>
	</li>
	
	<li>
	<b>HJ_HOME</b><br/>
	<i>string</i><br/>
	The path to your Habanero Java runtime files. They can be anywhere on your system, as long as HJ_HOME is set properly.
	<br/><br/>
	</li>
</ul>

## Environment Variables
The following <i>Environment Variables</i> can be added to the global TextMate environment, or to an individual project's environment to affect the way that TextMate handles Habanero Java programs.

<ul>
	<li>
	<b>TM_HJ_METRICS</b><br/>
	<i>string:</i><br/>
	<ol>
		<li><u>graph</u>: Create a computation graph for the HJ program.</li>
		<li><u>stats</u>: Print abstract performance metrics for the HJ program.</li>
		<li><u>race</u>: Enable data-race detection for the HJ program.</li>
	</ol>
	<br/><br/>
	</li>
</ul>

## Web Resources
<ol>
	<li>Habanero Java homepage: <a href="http://habanero.rice.edu/hj.html">http://habanero.rice.edu/hj.html</a></li>
	<li>Habanero Java Runtime download: <a href="https://wiki.rice.edu/confluence/display/PARPROG/HJDownload">https://wiki.rice.edu/confluence/display/PARPROG/HJDownload</a></li>
</ol>
MARKDOWN

html_footer