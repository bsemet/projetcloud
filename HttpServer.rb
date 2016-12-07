require 'socket' # Provides TCPServer and TCPSocket classes

# Initialize a TCPServer object that will listen
# on localhost:2345 for incoming connections.
ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
server = TCPServer.new(ip.ip_address,80)

# loop infinitely, processing one incoming
# connection at a time.
loop do

  # Wait until a client connects, then return a TCPSocket
  # that can be used in a similar fashion to other Ruby
  # I/O objects. (In fact, TCPSocket is a subclass of IO.)
  socket = server.accept

  # Read the first line of the request (the Request-Line)
  request = socket.gets

  # Log the request to the console for debugging
  STDERR.puts request

  response = "<!doctype html>
    <html>
    <head>
      <meta charset='utf-8'>
      <title>Répertoire des prénoms</title>
    </head>
    <body>
      <h1>Répertoire des prénoms</h1>
      <p>Entrez votre prénom ici : </p>
      <form action='todo.js'>
        <input type='text' name='prenom'>
      <input type='submit' value='Validez'><br>
      <p>Projet Cloud par SMAB</p>
    </body>
    </html>"

  # We need to include the Content-Type and Content-Length headers
  # to let the client know the size and type of data
  # contained in the response. Note that HTTP is whitespace
  # sensitive, and expects each header line to end with CRLF (i.e. "\r\n")
  socket.print "HTTP/1.1 200 OK\r\n" +
               "Content-Type: text/html\r\n" +
               "Content-Length: #{response.bytesize}\r\n" +
               "Connection: close\r\n"

  # Print a blank line to separate the header from the response body,
  # as required by the protocol.
  socket.print "\r\n"

  # Print the actual response body, which is just "Hello World!\n"
  socket.print response

  # Close the socket, terminating the connection
  socket.close
end

