# frozen_string_literal: true

# Gather settings for a Jasper Report and apply defaults.
class JasperParams
  attr_reader :report_name, :user_name, :params, :parent_folder
  attr_accessor :file_name, :mode, :printer, :return_full_path, :output_dir

  def initialize(report_name, user_name, params = {})
    @report_name = report_name
    @user_name = user_name
    @params = params
    setup_defaults
  end

  def parent_folder=(value)
    # Only set the folder if the target report exists inside it
    @parent_folder = value if File.exist?(File.join(AppConst::JASPER_REPORTS_PATH, value, report_name))
  end

  private

  def setup_defaults
    @mode = :pdf
    @file_name = report_name
    @parent_folder = nil
    @output_dir = nil
    @printer = nil
    @return_full_path = false
  end
end
