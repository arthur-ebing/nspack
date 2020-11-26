# Pack Materials DEVELOPMENT server at Kromco.
server '172.16.16.4', user: 'nsld', roles: %w[app db web]
set :deploy_to, '/home/nsld/nspack'
set :chruby_ruby, 'ruby-2.5.0'
