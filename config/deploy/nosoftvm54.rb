# VM instance at NoSoft offices
server '192.168.50.54', user: 'nspack', roles: %w[app db web]
set :deploy_to, '/home/nspack/nspack'
set :branch, 'develop'
set :chruby_ruby, 'ruby-2.5.5'
append :linked_files, '.env.cfg', '.env.kr'
