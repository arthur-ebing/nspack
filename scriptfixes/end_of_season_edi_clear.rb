# frozen_string_literal: true

# What this script does:
# ----------------------
# Zips the EDI folders and then deletes all the files.
#
# Reason for this script:
# -----------------------
# To clear the EDI files from disk at the end of the season.
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb EndOfSeasonEdiClear
# Live  : RACK_ENV=production ruby scripts/base_script.rb EndOfSeasonEdiClear
# Dev   : ruby scripts/base_script.rb EndOfSeasonEdiClear
#
class EndOfSeasonEdiClear < BaseScript
  def run # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    config_path = File.expand_path('../config/edi_out_config.yml', __dir__)
    hash = YAML.load_file(config_path)
    raise "No EDI config at #{config_path}" unless hash && hash[:root]

    top_path = hash[:root].sub('$ROOT', ENV['HOME'])
    target = File.join(ENV['HOME'], 'end_of_season', "edi_ftp_files_#{Time.now.year}.zip")
    zip = "zip -r #{target} #{top_path}/"
    files = nil

    if debug_mode
      puts zip
      puts "\nDelete all files below #{top_path}, but retain the directories:"
      files = `find #{top_path} -type f`
    else
      puts `#{zip}`
      raise "Zip command failed, exitstatus is #{$?.exitstatus}" unless $?.success? # rubocop:disable Style/SpecialGlobalVars

      files = `find #{top_path} -type f`
      `find #{top_path} -type f -delete`
      raise "Delet command failed, exitstatus is #{$?.exitstatus}" unless $?.success? # rubocop:disable Style/SpecialGlobalVars

      puts "\n Deleted files:"
    end
    puts files

    infodump = <<~STR
      Script: EndOfSeasonEdiClear

      What this script does:
      ----------------------
      Zips the EDI folders and then deletes all the files.

      Reason for this script:
      -----------------------
      To clear the EDI files from disk at the end of the season.

      Results:
      --------
      ZIPFILE: #{target}

      Zipped and deleted the following files:
      #{files}
      .
    STR

    log_infodump(:end_of_season,
                 :edi_files,
                 :clear,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('FTP files archived and cleared')
    end
  end
end
