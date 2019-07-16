require 'socket'
require 'json'

def listen_to_tts()
  tts_listener = TCPServer.new("0.0.0.0", 39998)
  loop do
    Thread.start(tts_listener.accept) do |client|
      tts_handle(client)
    end
  end
end

def tts_handle(client)
  lasterr = nil
  errcount = 0
  while (inp = JSON.load(client)) != nil do
    case inp["messageID"]
    when 1
      puts("TTS Loaded new game")
    when 2
      puts("Debug: #{inp["message"]}")
    when 3
      err = inp["error"]
      if lasterr != err then
        errcount = 0
        lasterr = err
        puts("!! #{lasterr}")
      end
      errcount = errcount + 1
      if errcount == 10 then
        puts("!! #{lasterr} x 10")
      elsif errcount == 50 then
        puts("!! #{lasterr} x 50")
      elsif (errcount % 100) == 0 then
        puts("!! #{lasterr} x #{errcount}")
      end
    when 4
      puts("Custom message: #{inp["customMessage"]}")
    when 5
      puts("Result of execution: #{inp["returnValue"]}")
    else
      puts("Unknown inp?")
    end
  end
end

# $tts_sender = sock = TCPSocket.new("localhost", 39999)
def sendTTS(mid, args)
  sock = TCPSocket.new("localhost", 39999)
  args["messageID"] = "#{mid}"
  body = JSON.dump(args)
  len = sock.send(body, 0) 
  if len == body.length then
    puts("sent #{mid} (#{len})")
  else
    puts("!!! sent #{mid} (#{len} vs #{body.length})")
  end
  sock.close()
end

$linemaps = []
def parseFile(body)
  body.split(/\n/).each_with_index do |line, lnum|
    if line =~ /^##FILESTART:(\w+\.lua)/ then
      $linemaps << [lnum, $1]
    end
  end
end

def handle(sock)
  puts "Editor conn"
  obj = JSON.load(sock)
  cmd = obj["command"]
  body = obj["body"]
  ret = {
    "ok" => true
  }
  puts("Editor: #{cmd}")
  case cmd
  when "newscript"
    parseFile(body)
    sendTTS(1, scriptStates: [{
      guid: "-1",
      script: body,
      ui: "<!-- comment -->",
    }])
  when "exec"
    sendTTS(3, guid: "-1", script: body)
  when "pull"
    ret["file"] = IO.read("editor_proxy.rb")
  when "neweditor"
    IO.write("editor_proxy.rb", body)
    load("editor_proxy.rb")
  else
    ret["ok"] = false
  end
  rbody = JSON.dump(ret)
  len = sock.send(rbody, 0) 
  sock.close()
  puts(len)
end

if $editor_listener.nil? then
  puts "Starting TTS Listener"
  Thread.start do
    listen_to_tts()
  end

  puts "Starting Editor listener"
  $editor_listener = TCPServer.new("0.0.0.0", 33133)
  puts "All good."
  loop do
    sock = $editor_listener.accept()
    handle(sock)
  end
else
  puts "Loaded changes"
end
