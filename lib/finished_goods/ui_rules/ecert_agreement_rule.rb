# frozen_string_literal: true

module UiRules
  class EcertAgreementRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::EcertRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'ecert_agreement'
    end

    def set_show_fields
      fields[:code] = { renderer: :label }
      fields[:name] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:start_date] = { renderer: :label }
      fields[:end_date] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        code: { required: true },
        name: { required: true },
        description: {},
        start_date: {},
        end_date: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_ecert_agreement(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(code: nil,
                                    name: nil,
                                    description: nil,
                                    start_date: nil,
                                    end_date: nil)
    end
  end
end
