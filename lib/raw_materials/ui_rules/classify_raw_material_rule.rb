# frozen_string_literal: true

module UiRules
  class ClassifyRawMaterialRule < Base
    def generate_rules
      @repo = MasterfilesApp::AdvancedClassificationsRepo.new
      make_form_object

      @rules[:use_raw_material_code] = AppConst::CR_RMT.use_raw_material_code?

      common_values_for_fields common_fields

      form_name 'classify_raw_material'
    end

    def common_fields
      fields = { rmt_code_id: { renderer: :select,
                                options: @repo.for_select_rmt_codes_for_delivery(@options[:id]),
                                caption: 'Rmt Code',
                                prompt: true,
                                required: true } }
      @form_object.rmt_classification_types.each do |t|
        fields[t.to_sym] = { renderer: :select,
                             options: @repo.for_select_rmt_classifications_for_type(t),
                             caption: t,
                             prompt: true,
                             required: false }
      end
      fields
    end

    def make_form_object
      rmt_code_id, rmt_classifications = @repo.get(:rmt_deliveries, %i[rmt_code_id rmt_classifications], @options[:id])
      rmt_classification_types = AppConst::CR_RMT.classify_raw_material? ? @repo.select_values(:rmt_classification_types, :rmt_classification_type_code) : {}
      attrs = {}
      rmt_classifications&.each do |c|
        type_code = @repo.type_code_for_classification(c)
        attrs[type_code.to_sym] = c
      end
      @form_object = OpenStruct.new(attrs.merge(rmt_classification_types: rmt_classification_types, rmt_code_id: rmt_code_id))
    end
  end
end
