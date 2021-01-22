# frozen_string_literal: true

module UiRules
  class PmMarkRule < Base
    def generate_rules
      @repo = MasterfilesApp::BomRepo.new
      @rules[:composition_levels] = @repo.list_pm_composition_levels
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'pm_mark'
    end

    def set_show_fields
      fields[:mark_id] = { renderer: :label,
                           with_value: @form_object.mark_code,
                           caption: 'Fruitspec Mark' }
      fields[:description] = { renderer: :label }
      rules[:composition_levels].each do |k, v|
        fields[v.to_sym] = { renderer: :label,
                             caption: "#{v} Mark",
                             with_value: @form_object.packaging_marks[k - 1].to_s }
      end
      fields[:active] = { renderer: :label,
                          as_boolean: true }
    end

    def common_fields
      fields = {
        mark_id: { renderer: :select,
                   options: MasterfilesApp::MarketingRepo.new.for_select_marks,
                   disabled_options: MasterfilesApp::MarketingRepo.new.for_select_inactive_marks,
                   caption: 'Fruitspec Mark',
                   required: true },
        description: { required: true }
      }
      rules[:composition_levels].each do |k, v|
        fields[v.to_sym] = { force_uppercase: true,
                             caption: "#{v} Mark",
                             value: @form_object.packaging_marks[k - 1].to_s }
      end
      fields
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      hash = @repo.find_pm_mark(@options[:id]).to_h
      rules[:composition_levels].each { |k, v| hash[v] = hash[:packaging_marks][k - 1] }
      @form_object = OpenStruct.new(hash)
    end

    def make_new_form_object
      @form_object = OpenStruct.new(mark_id: nil,
                                    packaging_marks: [],
                                    description: nil)
    end
  end
end
