#!/usr/bin/env ruby

require ENV["TM_SUPPORT_PATH"] + "/lib/tm/executor"
require ENV["TM_SUPPORT_PATH"] + "/lib/tm/save_current_document"
require ENV["TM_SUPPORT_PATH"] + "/lib/ui"
require "shellwords"
require "pstore"
require 'pathname'

class JavaMatePrefs
  @@prefs = PStore.new(File.expand_path( "~/Library/Preferences/com.macromates.textmate.javamate"))
  def self.get(key)
    @@prefs.transaction { @@prefs[key] }
  end
  def self.set(key,value)
    @@prefs.transaction { @@prefs[key] = value }
  end
end

TextMate.save_current_document
TextMate::Executor.make_project_master_current_document

# MODIFICATIONS TO ORIGINAL

javamate_type=ENV[ 'TM_JAVAMATE_TYPE' ]

# Extract the proper verb for the window that's going to pop up.
# Default: Running the file
javamate_verb = "Running"

case javamate_type
when "--compile_only", "--compile_lint", "--compile_project", "--compile_project_lint", "--compile_project_class"
   javamate_verb = "Compiling"
when "--test", "--compile_project_test"
   javamate_verb = "Testing"
when "--compile_project_jar", "--compile_project_bundle_jar"
  javamate_verb = "Making JAR from"
end

# Note if we're acting on the whole project, or just an indiviudal file.
case javamate_type.index( 'project' )
when nil
  javamate_verb = javamate_verb
else
  javamate_verb << " project"
end

cmd = [ 'javamate2.sh' ]
cmd << ENV[ 'TM_JAVAMATE_TYPE' ]
cmd << ENV[ 'TM_FILEPATH' ]

# javamate2.sh --compile /path/to/source.java
# etc...

# END MODIFICATIONS

script_args = []
if ENV.include? 'TM_JAVAMATE_GET_ARGS'
  prev_args = JavaMatePrefs.get("prev_args")
  args = TextMate::UI.request_string(:title => "JavaMate", :prompt => "Enter any command line options:", :default => prev_args)
  JavaMatePrefs.set("prev_args", args)
  script_args = Shellwords.shellwords(args)
end
cwd = Pathname.new(Pathname.new(Dir.pwd).realpath)

package = nil
File.open(ENV['TM_FILEPATH'], "r") do |f|
  while (line = f.gets)
    if line =~ /\s*package\s+([^\s;]+)/
      package = $1
      break
    end
  end
end

#cmd << package if package
ENV["TM_JAVA_PACKAGE"] = package
extension = File.extname( ENV[ 'TM_FILEPATH' ] )
  
# As of OS X 10.5 and above, interactive input doesn't work by default.
# As of OS X 10.6 and above, interactive input doesn't work.
# Go Tiger!
TextMate::Executor.run(cmd, :version_args => [ ENV[ 'TM_JAVAMATE_TYPE' ], ENV[ 'TM_FILEPATH' ], "--version" ], :script_args => script_args, :interactive_input => true, :verb => javamate_verb) do |line, type|
  case type
    when :err
      line.chomp!
      # Java errors:
      
      # If it's the line that tells us where the error was in the source
      if line =~ /(.+#{extension}):(\d+):(.*)$/ or # Standard java errors
          line =~ /(.+#{extension}):[\d]*?-?(\d+):(.*)$/ # Subset of Habanero java errors
        path = Pathname.new($1)
        line_no = $2
        error = $3
        abs_path = Pathname.new(path.realpath)
        line = "<a href='txmt://open?url=file://#{abs_path}&line=#{line_no}'>#{htmlize((path.to_s =~ /^\.\//) ? path : abs_path.relative_path_from(cwd))}:#{line_no}</a>:#{htmlize(error)}";
      else
        # If it's just more Java error output, but not pointing to a location in the source.
        line = htmlize(line)
      end
      
      # Color error lines red.
      line = "<span style='color: red'>#{line}</span><br>"
    else
      # Not printed to stderr
      # Catch Soot and Polyglot errors in Habanero Java
      if line =~ /[*]{4}Error: (.+#{extension}):(\d+):(\d+)[:0-9\-]*(.*)$/
        path = Pathname.new($1)
        line_no = $2
        col_no = $3
        error = $4
        abs_path = Pathname.new( path.realpath )
        # Add column markers
        line = "<a href='txmt://open?url=file://#{abs_path}&line=#{line_no}&column=#{col_no}'>#{htmlize((path.to_s =~ /^\.\//) ? path : abs_path.relative_path_from(cwd))}:#{line_no}</a>:#{htmlize(error)}";
        # Color error lines red.
        line = "<span style='color: red'>#{line}</span><br>"
      end
  end
end