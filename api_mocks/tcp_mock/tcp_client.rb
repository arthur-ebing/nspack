require 'socket'

# server = TCPServer.new(2050)
#
# loop do
#   Thread.fork(server.accept) do |client|
#     request = client.gets.chomp
#     puts request # route_handler::action::params (maybe format too? (xml/json/html/whatever)
#     # route, action, params = request.split('::') # --- also userID?
#     # load a route_handler for the request.
#     # Object.const_get("#{route.to_s.split('_').map(&:capitalize).join}TcpRoute").new(action, params).call -- or something like this...
#     # inflector = Dry::Inflector.new
#     # Object.const_get(inflector.classify("#{route}TcpRoute")).new(action, params).call -- or something like this...
#
#     # repo = SecurityApp::SecurityGroupRepo.new
#     # ids = repo.select_values('SELECT id FROM security_groups')
#     # grp = repo.find_security_group(ids.sample)
#     #
#     # client.puts("Route  : #{route}", "Action : #{action}", "Params : #{params.split(',').inspect}", "FROM DB: #{grp.security_group_name}", 'All Done!')
#     client.close
#   end
# end

4.times do
  sock = TCPSocket.open('192.168.50.21', 2000)
  # ID="1"                           NB: ID only appears in the Logon packet if one (or more) card readers are used
  request = <<~XML
    <Logon PID="40"
    Module="CLM-01"
    Name="11A1-101L"
    Value="1020201"
    />\r\n
  XML
  # request = 'pallet::build_up::pno=1234,usr=22'
  puts "\nREQUESTED: #{request}"

  sock.puts request
  puts '...wait...'
  result = sock.read
  puts '...have read...'

  puts "Response from server:\n\n#{result}"
  # while (line = sock.gets)
  #   puts "received : #{line.chop}"
  # end
  sock.close
end
