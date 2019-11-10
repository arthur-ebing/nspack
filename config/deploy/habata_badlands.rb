# VM instance at NoSoft offices
server '192.168.9.50', user: 'habata', roles: %w[app db web]
set :deploy_to, '/home/habata/nspack'
set :chruby_ruby, 'ruby-2.5.5'
