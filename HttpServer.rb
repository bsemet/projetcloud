require 'socket' # Provides TCPServer and TCPSocket classes
require 'uri'
require 'redis' 

db = Redis.new( :host => "localhost", :port => 6379 ) #Localhost si no docker
db.set("iterator",0)
# Initialize a TCPServer object that will listen
# on localhost:2345 for incoming connections.
ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
server = TCPServer.new(ip.ip_address,80)


# Files will be served from this directory
WEB_ROOT = './'

# Map extensions to their content type
CONTENT_TYPE_MAPPING = {
  'html' => 'text/html',
  'txt' => 'text/plain',
  'png' => 'image/png',
  'jpg' => 'image/jpeg'
}

# Treat as binary data if content type cannot be found
DEFAULT_CONTENT_TYPE = 'application/octet-stream'

# This helper function parses the extension of the
# requested file and then looks up its content type.

def add(name)
  name.sub!("+"," ");
  db = Redis.new( :host => "localhost", :port => 6379) #Localhost si no docker
  db.set(db.get("iterator"), name.to_s);
  db.incr("iterator");
end 

def listall()
  db = Redis.new( :host => "localhost", :port => 6379) #Localhost si no docker
  x = db.get("iterator").to_i - 1  
  resp ="";
  for i in 0..x
    resp << i.to_s << " : " << db.get(i).to_s << " <br>"     
  end
  puts resp 
  return resp 
end


def content_type(path)
  ext = File.extname(path).split(".").last
  CONTENT_TYPE_MAPPING.fetch(ext, DEFAULT_CONTENT_TYPE)
end

# This helper function parses the Request-Line and
# generates a path to a file on the server.

def requested_file(request_line)
  request_uri  = request_line.split(" ")[1]
  path         = URI.unescape(URI(request_uri).path)

  clean = []

  # Split the path into components
  parts = path.split("/")

  parts.each do |part|
    # skip any empty or current directory (".") path components
    next if part.empty? || part == '.'
    # If the path component goes up one directory level (".."),
    # remove the last clean component.
    # Otherwise, add the component to the Array of clean components
    part == '..' ? clean.pop : clean << part
  end

  # return the web root joined to the clean path
  File.join(WEB_ROOT, *clean)
end

# Except where noted below, the general approach of
# handling requests and generating responses is
# similar to that of the "Hello World" example
# shown earlier.

loop do
  socket       = server.accept
  request_line = socket.gets

  STDERR.puts request_line

  path = requested_file(request_line)
  path = File.join(path, 'index.html') if File.directory?(path)

  # Make sure the file exists and is not a directory
  # before attempting to open it.
  filename = File.basename(path)


  if filename.include? "prenom.html"
    paramstring = request_line.split('=')[1]     # chop off the verb
    paramstring = paramstring.split(' ')[0] # chop off the HTTP version
    paramarray  = paramstring.split('&')    # only handles two parameters
    
     add(paramarray[0])

    response = "<!doctype html>
    <html>
    <head>
      <meta charset='utf-8'>
      <title>Répertoire des prénoms</title>
    </head>
    <body>
      <h1>Liste des prénoms</h1>"
    response << listall().to_s
      
    response << "<a href='index.html'>Retour à l'accueil</a>
      <p>Projet Cloud par SMAB</p>
    </body>
    </html>"

    socket.print "HTTP/1.1 200 OK\r\n" +
                "Content-Type: text/html\r\n" +
                "Content-Length: #{response.bytesize}\r\n" +
                "Connection: close\r\n"

    socket.print "\r\n"
    socket.print response

  elsif File.exist?(path) && !File.directory?(path)
    File.open(path, "rb") do |file|
      socket.print "HTTP/1.1 200 OK\r\n" +
                   "Content-Type: #{content_type(file)}\r\n" +
                   "Content-Length: #{file.size}\r\n" +
                   "Connection: close\r\n"

      socket.print "\r\n"

      # write the contents of the file to the socket
      IO.copy_stream(file, socket)
    end
  else
    message = "File not found\n"

    # respond with a 404 error code to indicate the file does not exist
    socket.print "HTTP/1.1 404 Not Found\r\n" +
                 "Content-Type: text/plain\r\n" +
                 "Content-Length: #{message.size}\r\n" +
                 "Connection: close\r\n"

    socket.print "\r\n"

    socket.print message
  end

  socket.close
end



