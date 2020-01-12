# frozen_string_literal: true

# Base class for running scripts that have access to the config, database and job queue.
#
# Scripts inheriting from BaseScript must implement a method named "run".
# Command line parameters are available in the "args" variable.
# The script must return a Crossbeams::Responses object.
#
# Call a script like this:
#
#     ruby scripts/base_script.rb EgScript one 2 three
#
# Where the first parameter is the script class and
# following parameters are args for the script itself.
#
# To get more visibility, use the DEBUG env var:
#
#     DEBUG=y ruby scripts/base_script.rb EgScript one 2 three
#
# In scripts, the variable "debug_mode" will be set to true.

ENV['RACK_ENV'] ||= 'development'
require 'bundler'
Bundler.require(:default, ENV.fetch('RACK_ENV', 'development'))

require_relative '../config/environment'
require_relative '../config/app_const'
require_relative '../lib/crossbeams_errors'
require_relative '../lib/crossbeams_responses'
require_relative '../lib/error_mailer'

class BaseScript
  include Crossbeams::Responses
  attr_reader :args, :root_dir, :debug_mode

  def initialize(args)
    @args = args
    @root_dir = File.expand_path('../', __dir__)
    @debug_mode = !ENV['DEBUG'].nil?
    return unless debug_mode

    puts "Running #{self.class} in debug mode"
    puts "Args: #{args.inspect}"
    puts "Root dir: #{root_dir}"
    puts '---'
  end

  def exec # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    res = run
    puts '---' if debug_mode
    puts "Run response: #{res.inspect}" if debug_mode
    puts res.message if res.success && res.message && debug_mode
    exit if res.success

    abort "Failed: #{res.message}"
  rescue StandardError => e
    puts "Exception: #{e.message}\n#{e.backtrace.join("\n")}" if debug_mode
    ErrorMailer.send_exception_email(e, subject: "Script #{self.class} failed", message: "Script args: #{args.inspect}\n")
    abort "Failed: #{e.message}"
  end

  def send_exception_email(error, subject: nil, message: nil)
    ErrorMailer.send_exception_email(error, subject, message)
  end

  def send_error_email(subject: nil, message: nil)
    ErrorMailer.send_error_email(subject, message)
  end
end

class EgScript < BaseScript
  def run
    puts 'In EG'
    p root_dir
    p args
    # raise Crossbeams::InfoError, 'ScriptInfoError'
    # p DB[:users].get(:id)
    # raise 'Scriptbang'
    # failed_response('Did not work')
    ok_response
  end
end

Dir['./scripts/*.rb'].each { |f| require f unless f.match?(/base_script/) }

klass = ARGV.shift
script = Module.const_get(klass).send(:new, ARGV)
script.exec
