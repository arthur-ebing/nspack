# frozen_string_literal: true

module Crossbeams
  # Export data to file using configuration settings
  # defined in config/export_data_config.yml
  #
  # Run using a valid key form the config file:
  # Crossbeams::ExportData.run('keyname')
  class ExportData # rubocop:disable Metrics/ClassLength
    attr_reader :key, :report, :recs

    class << self
      def run(*args)
        new(*args).run
      end
    end

    def initialize(key)
      @key = key
      raise ArgumentError, "#{key} is not a valid ExportData key" unless valid_key?
      raise ArgumentError, 'ExportData must have "out_dir"' unless valid_dir?

      @current_column = nil
    end

    def run # rubocop:disable Metrics/AbcSize
      set_defaults
      prepare
      run_report
      write_file
      make_zip if config['zip_for_mail']
      send_mail if config['email']
    rescue StandardError => e
      message = if @current_column
                  "Failure in export of #{key} - column #{@current_column}"
                else
                  "Failure in export of #{key}"
                end
      ErrorMailer.send_exception_email(e, subject: "ExportData (#{key}) failed: #{e.message}", message: message)
      puts e.message
    end

    def to_s
      "Key: #{key}, #{config.map { |k, v| "#{k} => #{v.inspect}" }}"
    end

    private

    def set_defaults
      @export_hidden_fields = config['export_hidden_fields'] == true
      @prefix_long_numbers_with_quote = config['prefix_long_numbers_with_quote'].nil? ? true : config['prefix_long_numbers_with_quote']
      @boolean_as_yn = config['boolean_as_yn'].nil? ? true : config['boolean_as_yn']
    end

    def send_mail
      fn = config['zip_for_mail'] ? output_file : "#{output_file}.zip"
      email = config['email']

      DevelopmentApp::SendMailJob.enqueue(to: email['to'],
                                          subject: email['subject'],
                                          body: email['body'],
                                          attachments: [{ path: fn }])
    end

    def run_report
      apply_where_conditions
      @recs = DB[report.runnable_sql].all
    end

    def write_file # rubocop:disable Metrics/AbcSize
      CSV.open(output_file, 'w', headers: ordered_headers, write_headers: true) do |csv|
        recs.each do |rec|
          csv << report.ordered_columns.map do |col|
            @current_column = col.name
            format_column(col, rec[col.name.to_sym])
          end.compact
        end
      end
      @current_column = nil
    end

    def apply_where_conditions
      return unless config['conditions']

      # TODO: IN clause...
      params = []
      config['conditions'].each do |condition|
        params << Crossbeams::Dataminer::QueryParameter.new(condition['col'], Crossbeams::Dataminer::OperatorValue.new(condition['op'], condition['val']))
      end
      report.replace_where(params)
    end

    def make_zip
      `zip -j #{output_file}.zip #{output_file}`
    end

    def format_column(col, val) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return nil if col.hide && !@export_hidden_fields
      return '' if val.nil?
      return boolean_value(val) if col.data_type == :boolean

      if @prefix_long_numbers_with_quote && col.data_type == :string && val.is_a?(String) && val.length > 12 && val.match?(/\A\d+\Z/)
        "'#{val}"
      elsif col.format == :delimited_1000
        UtilityFunctions.delimited_number(val, delimiter: '')
      elsif col.format == :delimited_1000_4
        UtilityFunctions.delimited_number(val, delimiter: '', no_decimals: 4)
      elsif col.data_type == :datetime
        val.to_s.gsub(/:\d\d \+\d\d\d\d$/, '')
      else
        val
      end
    end

    def boolean_value(val)
      if @boolean_as_yn
        val ? 'Y' : 'N'
      else
        val
      end
    end

    def output_file
      @output_file ||= File.join(config['out_dir'], "#{key}.csv")
    end

    def ordered_headers
      report.ordered_columns.map do |col|
        if col.hide && !@export_hidden_fields
          nil
        else
          col.caption
        end
      end.compact
    end

    def prepare
      fn = nil
      fn = File.join('grid_definitions/dataminer_queries', "#{config['grid']}.yml") if config['grid']
      fn = File.join('reports', "#{config['report']}.yml") if config['report']
      raise Crossbeams::FrameworkError, "Export config for #{key} does not have a valid grid or report setting" if fn.nil?

      load_report(fn)
    end

    def load_report(file)
      persistor = Crossbeams::Dataminer::YamlPersistor.new(file)
      @report = Crossbeams::Dataminer::Report.load(persistor)
    end

    def valid_key?
      !config.nil?
    end

    def valid_dir?
      !config['out_dir'].nil?
    end

    def config
      @config || load_config
    end

    def load_config
      raise Crossbeams::FrameworkError, 'There is no export config file named "config/export_data_config.yml"' unless File.exist?('config/export_data_config.yml')

      YAML.load_file('config/export_data_config.yml')[key]
    end
  end
end
