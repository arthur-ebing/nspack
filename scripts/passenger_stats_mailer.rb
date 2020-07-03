# frozen_string_literal: true

# require 'logger'

# Scan a directory for EDI in files and process them.
class PassengerStatsMailer < BaseScript
  attr_reader :in_dir, :out_dir, :cnt, :processed_files

  def run
    status = check_status
    memory = check_memory
    top = check_top

    send_error_email(subject: 'INFO: Passenger-stats', message: "#{status}\n\n\n#{memory}\n\n\n#{top}", recipients: 'james@nosoft.biz,hans@nosoft.biz')
    success_response('Mail sent')
  end

  private

  def check_status
    `echo "#{ENV['NSPACKSUDO']}" | sudo -S passenger-status` # rubocop:disable Lint/Env
  end

  def check_memory
    `echo "#{ENV['NSPACKSUDO']}" | sudo -S passenger-memory-stats` # rubocop:disable Lint/Env
  end

  def check_top
    # `top -b -n 1 -o +%CPU -E g` # per-gig option only from 20.04 on...
    `top -b -n 1 -o +%CPU`
  end
end
