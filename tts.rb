#!/usr/bin/ruby
#
#

HOST = "10.0.0.155"
PORT = 33133

LUACONF = "LUACHECKRC"
OUTFILE = "starrealms.lua"

require 'json'
require 'socket'

COMMANDS = {}

def addCommand(name, help, &block)
  COMMANDS[name] = {
    help: help,
    block: block,
  }
end

def doCommand(name)
  COMMANDS[name][:block].call
end

def gamefiles
  IO.readlines("loadorder").map { |i| i.chomp.gsub(/\s.*$/,'') }.select { |i| i =~ /^\w*\.lua/ }
end

def die(msg)
  puts "!!!!"
  puts
  puts msg
  puts
  puts "!!!!"
  exit(1)
end

addCommand("build", "Build #{OUTFILE}") do
  File.open(OUTFILE, "w") do |fout|
    fout.puts "-- AUTO GENERATED FILE, DO NOT EDIT --"
    fout.puts "--------------------------------------"

    gamefiles.each do |fn|
      next unless fn =~ /^(\w*\.lua)/
      fn = $1
      fout.puts "-- ##FILESTART:#{fn}"
      fout.puts IO.read("src/#{fn}")
    end
  end
  puts "BUILD: #{OUTFILE} built"
end

def sendEditor(cmd, body=nil)
  obj = {}
  obj["command"] = cmd
  obj["body"] = body or ""
  str = JSON.dump(obj)
  sock = TCPSocket.new(HOST, PORT)
  sock.send(str, 0)
  sock.close_write()
  r = JSON.load(sock)
  if r["file"] then
    puts r["file"]
    return
  end
  puts "Return: #{r["ok"]}"
end

addCommand("pushProxy", "Push a new version of editor_proxy.rb") do
  body = IO.read("editor_proxy.rb")
  sendEditor("neweditor", body)
end

addCommand("check", "Run checklua to lint the src/ code") do
  good = true
  bads = []
  gamefiles.each do |file|
    inp = `luacheck --config LUACHECKRC --codes src/#{file}`
    unless $?.success?
      bads << inp
    end
  end
  if bads.length > 0 then
    die(bads.join("\n"))
  end
  puts "luacheck all files: OK"
end

addCommand("checkbuild", "Run checklua to lint the build output") do
  inp = `luacheck --config LUACHECKRC --codes #{OUTFILE}`
  unless $?.success?
    die inp
  end
  puts "luacheck #{OUTFILE}: OK"
end

addCommand("make", "refresh check build checkbuild push") do
  doCommand("refresh")
  doCommand("check")
  doCommand("build")
  doCommand("checkbuild")
  doCommand("push")
end

addCommand("refresh", "Refresh autogenerated files for debug") do
  funcs = {}
  vars = {}
  
  gamefiles.each do |file|
    next if file =~ /debug_functions/

    IO.readlines("src/#{file}").each_with_index do |i|
      if i =~ /^function (\w+)\(/ then
        die "Duplicate function #{$1}" if funcs[$1]
        funcs[$1] = true
      elsif i =~ /^(?:local\s+)?([A-Z]\w+)\s*=/ then
        puts "Duplicate function #{$1}" if vars[$1]
        vars[$1] = true
      end
    end
  end
  curfile = IO.readlines(LUACONF)
  File.open(LUACONF, "w") do |fout|
    curfile.each do |line|
      fout.puts line
      break if line =~ /-- GLOBALS START --/
    end
    (funcs.keys + vars.keys).each do |key|
      fout.puts %Q[  "#{key}",]
    end
    doprint = false
    curfile.each do |line|
      next unless doprint or line =~ /-- GLOBALS END --/
      doprint = true
      fout.puts line
    end
  end
  true
end

addCommand("push", "Push #{OUTFILE} to TTS via proxy") do
  body = IO.read(OUTFILE)
  sendEditor("newscript", body)
end

addCommand("help", "help") do
  puts <<EOT
Usage: #{$0} command [...args...]

Available commands:

EOT
  COMMANDS.each do |k,v|
    puts "  #{k.rjust(20)}: #{v[:help]}"
  end
end

cmd = ARGV.pop or "help"
if COMMANDS.has_key?(cmd) then
  doCommand(cmd)
end
