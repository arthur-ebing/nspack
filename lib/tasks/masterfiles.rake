# frozen_string_literal: true

namespace :app do
  namespace :masterfiles do
    desc 'Update Phytclean Standard Data'
    task update_phytclean_standard_data: [:load_app] do
      if Date.today <= Date.parse(AppConst::PHYT_CLEAN_SEASON_END_DATE || Date.today.to_s)
        res = QualityApp::PhytCleanStandardData.call
        if res.success
          puts "SUCCESS: #{res.message}"
        else
          puts "FAILURE: #{res.message}"
        end
      end
    end

    desc 'Import Phytclean Glossary'
    task import_phytclean_glossary: [:load_app] do
      res = QualityApp::PhytCleanStandardDataGlossary.call
      if res.success
        puts "SUCCESS: #{res.message}"
      else
        puts "FAILURE: #{res.message}"
      end
    end
    desc 'Import locations'
    task :import_locations, [:fn] => [:load_app] do |_, args|
      res = MasterfilesApp::ImportLocations.call(args.fn)
      if res.success
        puts "SUCCESS: #{res.message}"
      else
        puts "FAILURE: #{res.message}"
      end
    end

    desc 'Import resources'
    task :import_resources, %i[site mod_fn prn_fn] => [:load_app] do |_, args|
      res = ProductionApp::ImportResources.call(args.site, args.mod_fn, args.prn_fn)
      if res.success
        puts "SUCCESS: #{res.message}"
      else
        puts "FAILURE: #{res.message}"
      end
    end

    desc 'SQL Extract of Masterfiles'
    task extract: [:load_app] do
      # Todo - allow list of specific tables
      extractor = SecurityApp::DataToSql.new(nil)
      Crossbeams::Config::MF_BASE_TABLES.each do |table|
        puts "-- #{table.to_s.upcase} --"
        extractor.sql_for(table, nil)
        puts ''
      end

      Crossbeams::Config::MF_TABLES_IN_SEQ.each do |table|
        puts "-- #{table.to_s.upcase} --"
        extractor.sql_for(table, nil)
        puts ''
      end
    end

    desc 'SQL Extract of single Masterfile'
    task :extract_single, [:table] => [:load_app] do |_, args|
      table = args.table
      extractor = SecurityApp::DataToSql.new(nil)
      puts "-- #{table.to_s.upcase} --"
      extractor.sql_for(table.to_sym, nil)
      puts ''
    end
  end

  # Just trying something... TODO: get the rest of the params passed in
  namespace :jasper do
    desc 'Run a Jasper report'
    task :run_report, %i[rpt fname] => [:load_app] do |_, args|
      jasper_params = JasperParams.new(args.rpt,
                                       'rakeU',
                                       load_id: 278,
                                       place_of_issue: AppConst::ADDENDUM_PLACE_OF_ISSUE)
      jasper_params.file_name = args.fname
      res = CreateJasperReport.call(jasper_params)

      if res.success
        puts "REPORT CREATED: #{res.instance}"
      else
        puts "ERROR: #{res.message}"
      end
    end
  end
end

# class AppMfTasks
#   include Rake::DSL
#
#   def initialize
#     namespace :app do
#       namespace :masterfiles do
#         desc 'AAA'
#         task :import_locations do
#           puts 'In DSL'
#         end
#       end
#     end
#   end
# end
# # Instantiate the class to define the tasks:
# AppMfTasks.new
