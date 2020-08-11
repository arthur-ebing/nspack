# VM instance at Sitrusrand Addo (presort)
server '192.168.20.6', user: 'nspack', roles: %w[app db web]
set :deploy_to, '/home/nspack/nspack'
set :chruby_ruby, 'ruby-2.5.8'
