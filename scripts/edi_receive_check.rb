# frozen_string_literal: true

# require 'logger'

# Scan a directory for EDI in files and process them.
class EdiReceiveCheck < BaseScript
  attr_reader :in_dir, :out_dir, :cnt, :processed_files

  def run
    p 'EDI receive' if debug_mode
    @in_dir = args.first
    @out_dir = AppConst::EDI_RECEIVE_DIR
    raise ArgumentError, 'Directory to check was not provided' unless @in_dir
    raise ArgumentError, 'EDI_RECEIVE_DIR has not been set' unless @out_dir

    p "Dirs: #{in_dir} -> #{out_dir}" if debug_mode
    @cnt = 0
    @processed_files = []
    move_files
    success
  end

  private

  def success
    if cnt.zero?
      success_response('No files to process')
    else
      success_response(%(Processed #{cnt} file(s):\n#{processed_files.join("\n")}))
    end
  end

  def move_files
    Dir.glob("#{in_dir.chomp('/')}/*").each do |file|
      next unless File.file?(file)
      next if file.end_with?('.inuse')

      puts "\nFound #{File.basename(file)}" if debug_mode
      log("Processing: #{File.basename(file)}")
      @cnt += 1
      processed_files << file
      action_file(file)
    end
  end

  def action_file(file)
    new_path = File.join(out_dir, File.basename(file))
    puts "moving #{file} to #{new_path}" if debug_mode
    log("Moving: #{file} to #{new_path}")
    FileUtils.mv(file, new_path)
    puts "Enqueuing #{new_path} for EdiApp::Job::ReceiveEdiIn" if debug_mode
    log("Enqueuing #{new_path} for EdiApp::Job::ReceiveEdiIn")
    Que.enqueue new_path, job_class: 'EdiApp::Job::ReceiveEdiIn', queue: AppConst::QUEUE_NAME
  end

  def log(msg)
    logger.info msg
  end

  def logger
    @logger ||= Logger.new(File.join(root_dir, 'log', 'edi_in.log'), 'weekly')
  end
end
