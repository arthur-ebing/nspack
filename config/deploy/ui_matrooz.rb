# VM instance at Unifrutti Matroozefontein
server '192.168.100.241', user: 'nspack', roles: %w[app db web]
set :deploy_to, '/home/nspack/nspack'
set :chruby_ruby, 'ruby-2.5.5'
