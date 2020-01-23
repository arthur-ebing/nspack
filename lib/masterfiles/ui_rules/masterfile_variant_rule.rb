# frozen_string_literal: true

module UiRules
  class MasterfileVariantRule < Base
    def generate_rules
      @repo = MasterfilesApp::MasterfileVariantRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'masterfile_variant'
    end

    def set_show_fields
      code = @repo.lookup_mf_code(@form_object.id)
      fields[:masterfile_table] = { renderer: :label }
      fields[:code] = { renderer: :label }
      fields[:masterfile_id] = { renderer: :label }
      fields[:masterfile_code] = { renderer: :label, with_value: code }
    end

    def common_fields
      mf_table_render = if @mode == :edit
                          { renderer: :label }
                        else
                          { renderer: :select, options: AppConst::MF_VARIANT_TABLES, required: true }
                        end
      {
        masterfile_table: mf_table_render,
        code: { required: true },
        masterfile_id: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = OpenStruct.new(@repo.find_masterfile_variant(@options[:id]).to_h)
    end

    def make_new_form_object
      @form_object = OpenStruct.new(masterfile_table: nil,
                                    code: nil,
                                    masterfile_id: nil)
    end
  end
end
