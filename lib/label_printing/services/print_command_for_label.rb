# frozen_string_literal: true

module LabelPrintingApp
  # Apply an instance's values to a label template's variable rules and produce a print command string.
  class PrintCommandForLabel < BaseService
    include LabelContent

    attr_reader :label_name, :instance

    def initialize(label_name, instance)
      @label_name = label_name
      @instance = instance
      raise ArgumentError, 'PrintCommandForLabel requires a label name' if label_name.nil?
    end

    def call
      lbl_required = fields_for_label
      vars = values_from(lbl_required)
      build_command_string(vars)
    rescue Crossbeams::FrameworkError => e
      failed_response(e.message)
    end

    private

    def build_command_string(vars)
      cmd = vars.map { |k, v| "#{k}='#{v}'" }.join(' ')
      success_response('ok', OpenStruct.new(print_command: cmd))
    end
  end
end
