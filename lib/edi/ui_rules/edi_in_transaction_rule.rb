# frozen_string_literal: true

module UiRules
  class EdiInTransactionRule < Base
    def generate_rules
      @repo = EdiApp::EdiInRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      form_name 'edi_in_transaction'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:file_name] = { renderer: :label }
      fields[:flow_type] = { renderer: :label }
      fields[:complete] = { renderer: :label, as_boolean: true }
      fields[:error_message] = { renderer: :label, invisible: @form_object.error_message.nil? }
      fields[:backtrace] = { renderer: :label, invisible: @form_object.backtrace.nil?, format: :preformat }
      fields[:schema_valid] = { renderer: :label, as_boolean: true }
      fields[:newer_edi_received] = { renderer: :label, as_boolean: true }
      fields[:has_missing_master_files] = { renderer: :label, as_boolean: true }
      fields[:valid] = { renderer: :label, as_boolean: true }
      fields[:has_discrepancies] = { renderer: :label, as_boolean: true }
      fields[:reprocessed] = { renderer: :label, as_boolean: true }
      fields[:notes] = { renderer: :label, invisible: @form_object.notes.nil? }
      fields[:match_data] = { renderer: :label }
    end

    def common_fields
      {
        file_name: { required: true },
        flow_type: {},
        complete: { renderer: :checkbox },
        error_message: {},
        backtrace: {},
        schema_valid: { renderer: :checkbox },
        newer_edi_received: { renderer: :checkbox },
        has_missing_master_files: { renderer: :checkbox },
        valid: { renderer: :checkbox },
        has_discrepancies: { renderer: :checkbox },
        reprocessed: { renderer: :checkbox },
        notes: {},
        match_data: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_edi_in_transaction(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(file_name: nil,
                                    flow_type: nil,
                                    complete: nil,
                                    error_message: nil,
                                    backtrace: nil,
                                    schema_valid: nil,
                                    newer_edi_received: nil,
                                    has_missing_master_files: nil,
                                    valid: nil,
                                    has_discrepancies: nil,
                                    reprocessed: nil,
                                    notes: nil,
                                    match_data: nil)
    end
  end
end
