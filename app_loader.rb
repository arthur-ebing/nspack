# frozen_string_literal: true

# Load the application for all application uses: WebApp, TCPServer, QueJobs and Console.
# Console:
#   bin/console
# TCPServer:
#   ruby tcp_serv.rb
# Que CLI job server:
#   bundle exec que -q nspack ./app_loader.rb
#   OR (in cron)
#   cd /home/nsld/nspack/current && screen -dmS nspackque bash -c 'source /usr/local/share/chruby/chruby.sh && chruby ruby-2.5.0 && RACK_ENV=production bundle exec que -q nspack ./app_loader.rb'

ENV['RACK_ENV'] ||= 'development'
require 'bundler'
Bundler.require(:default, ENV.fetch('RACK_ENV', 'development'))

require_relative 'config/environment'

require 'base64'
require 'benchmark'
require 'pstore'
require 'net/http'
require 'net/ping'
require 'net/scp'
require 'net/ssh'
require 'uri'
require 'pry' if ENV.fetch('RACK_ENV') == 'development'

# Load any client rules before they are instantiated in AppConst:
Dir['./lib/client_rules/*.rb'].sort.each { |f| require f }

require './config/app_const'
require './config/client_rule_checker'
require './config/extended_column_definitions'
require './config/mail_settings'
require './config/masterfile_extract_config'
require './config/observers_list'
require './config/resource_definition_config'
require './config/status_header_definitions'
require './config/user_permissions'
require './lib/crossbeams_errors'
require './lib/error_mailer'
require './lib/crossbeams_message_bus'
require './lib/types_for_dry'
require './lib/crossbeams_responses'
require './lib/base_que_job'
require './lib/base_repo'
require './lib/base_repo_association_finder'
require './lib/base_interactor'
require './lib/base_service'
require './lib/base_edi_in_service'
require './lib/base_edi_out_service'
require './lib/base_step'
require './lib/doc_search'
require './lib/document_sequence'
require './lib/export_data'
require './lib/help_index_builder'
require './lib/http_calls'
require './lib/http_base_call_logger'
require './lib/http_text_call_logger'
require './lib/local_store' # Will only work for processes running from one dir.
require './lib/rmd_form'
require './lib/robot_responder'
require './lib/json_robot_interface'
require './lib/messcada_xml_interpreter'
require './lib/library_versions'
require './lib/dataminer_connections'
Dir['./helpers/**/*.rb'].sort.each { |f| require f }
require './lib/ui_rules'
Dir['./lib/applets/*.rb'].sort.each { |f| require f }

ENV['ROOT'] = File.dirname(__FILE__)
ENV['VERSION'] = File.read('VERSION')
ENV['GRID_QUERIES_LOCATION'] ||= File.expand_path('grid_definitions/dataminer_queries', __dir__)

DM_CONNECTIONS = DataminerConnections.new

# Ensure the locks dir exists for Que jobs
FileUtils.mkdir_p(File.join(__dir__, 'tmp', 'job_locks'))
