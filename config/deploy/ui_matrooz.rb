# VM instance at Unifrutti Matroozefontein
server '172.18.0.20', user: 'nspack', roles: %w[app db web]
set :deploy_to, '/home/nspack/nspack'
set :chruby_ruby, 'ruby-2.5.5'
