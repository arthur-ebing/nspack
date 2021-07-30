# VM instance at NoSoft offices
server '192.168.50.54', user: 'nspack', roles: %w[app db web]
set :deploy_to, '/home/nspack/nspack'
set :branch, 'feature/scan_legacy'
set :chruby_ruby, 'ruby-2.5.5'
