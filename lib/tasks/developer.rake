# frozen_string_literal: true

require File.expand_path('../../config/client_settings_loader.rb', __dir__)
require File.expand_path('../../helpers/utility_functions.rb', __dir__)

# Rake tasks for setting up development environment.
class AppDevTasks
  include Rake::DSL

  def initialize # rubocop:disable Metrics/AbcSize , Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    namespace :developers do
      desc 'Create or update .env.local and copy ".example" files'
      task :setup do
        @logs = []
        puts '1. Mail settings'
        setup_mail_settings
        puts ''
        puts '2. Dataminer settings'
        setup_dm_settings
        puts ''
        puts '3. Environment variables'
        setup_env
        puts '4. Required paths'
        prep_required_paths
        @logs.unshift "\n----------" unless @logs.empty?
        @logs.push '----------' unless @logs.empty?
        puts @logs.join("\n") unless @logs.empty?
      end

      desc 'Client settings: list of all possible ENV variables'
      task :client_settings do
        puts AppClientSettingsLoader.new_env_var_file
      end

      desc 'Client settings: list only required ENV variables'
      task :client_settings_required do
        puts AppClientSettingsLoader.new_env_var_file(required_values_only: true)
      end

      desc 'Client rules'
      task client_rules: :load_app do
        s = "#{AppConst::CLIENT_SET[AppConst::CLIENT_CODE]} (#{AppConst::CLIENT_CODE})"
        puts '*' * s.length
        puts s
        puts '*' * s.length
        AppConst.constants.grep(/CR_/).sort.each do |const|
          kl = AppConst.const_get(const)
          next unless kl.class.name.start_with?('Crossbeams::')

          s = "#{kl.rule_name} (AppConst::#{const})"
          puts "\n#{'=' * s.length}"
          puts s
          puts '=' * s.length

          kl.to_table.each do |h|
            puts "#{h[:method].to_s.ljust(50)} > #{h[:value].to_s.ljust(80)} |"
            puts h[:description].length > 130 ? "   #{h[:description]}" : "   #{h[:description].ljust(130)} |"
            puts '-' * 135
          end
        end
      end

      desc 'Clear the SQL log file'
      namespace :log do
        task :clear do
          fn = 'log/sql.log'
          if File.exist?(fn)
            file = File.new(fn)
            puts "SQL log file is #{UtilityFunctions.filesize(file.size)} in size.\nTruncating."
          else
            puts 'No SQL log file. Creating.'
          end
          `cat /dev/null > #{fn}`
        end
      end
    end
  end

  def root_path
    @root_path ||= File.expand_path('../..', __dir__)
  end

  def log(msg)
    @logs << msg
  end

  def setup_mail_settings
    example = File.join(root_path, 'config', 'mail_settings.rb.example')
    target = File.join(root_path, 'config', 'mail_settings.rb')
    return unless File.exist?(example) && !File.exist?(target)

    copy(example, target)
    log "Please configure mail settings in #{target}"
  end

  def setup_dm_settings
    example = File.join(root_path, 'config', 'dataminer_connections.yml.example')
    target = File.join(root_path, 'config', 'dataminer_connections.yml')
    return unless File.exist?(example) && !File.exist?(target)

    copy(example, target)
    log "Please configure dataminer settings in #{target}"
  end

  def setup_env
    target = File.join(root_path, '.env.local')
    FileUtils.touch(target) unless File.exist?(target)

    File.open(target, 'a') { |f| f << AppClientSettingsLoader.new_env_var_file(required_values_only: true) }
  end

  def prep_required_paths
    linked_dirs = %w[log tmp public/assets public/tempfiles public/downloads/jasper prepared_reports].map do |path|
      File.join(root_path, path)
    end
    paths = FileUtils.mkdir_p(linked_dirs)
    log 'Setting up paths:'
    paths.each { |p| log p }
  end

  def copy(from, to)
    puts "...Copying #{from} to #{to}."
    FileUtils.copy(from, to)
  end
end

AppDevTasks.new
