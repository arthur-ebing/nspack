# frozen_string_literal: true

module UiRules
  class RmtSizeRule < Base
    def generate_rules
      @repo = MasterfilesApp::RmtSizeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'rmt_size'
    end

    def set_show_fields
      fields[:size_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
    end

    def common_fields
      {
        size_code: { required: true },
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_rmt_size(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(size_code: nil,
                                    description: nil)
    end
  end
end
