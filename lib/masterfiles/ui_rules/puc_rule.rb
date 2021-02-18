# frozen_string_literal: true

module UiRules
  class PucRule < Base
    def generate_rules
      @repo = MasterfilesApp::FarmRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'puc'
    end

    def set_show_fields
      fields[:puc_code] = { renderer: :label, caption: 'PUC code' }
      fields[:gap_code] = { renderer: :label, caption: 'GAP code' }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:farms] = { renderer: :list, items: puc_farm_codes }
      fields[:gap_code_valid_from] = { renderer: :label,
                                       caption: 'GAP valid from',
                                       format: :without_timezone_or_seconds }
      fields[:gap_code_valid_until] = { renderer: :label,
                                        caption: 'GAP valid until',
                                        format: :without_timezone_or_seconds }
    end

    def common_fields
      {
        puc_code: { required: true, caption: 'PUC code' },
        gap_code: { caption: 'GAP code' },
        active: { renderer: :checkbox },
        gap_code_valid_from: { renderer: :input,
                               subtype: :date,
                               caption: 'GAP valid from' },
        gap_code_valid_until: { renderer: :input,
                                subtype: :date,
                                caption: 'GAP valid until' }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_puc(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(puc_code: nil,
                                    gap_code: nil,
                                    active: true,
                                    gap_code_valid_from: nil,
                                    gap_code_valid_until: nil)
    end

    def puc_farm_codes
      @repo.find_puc_farm_codes(@options[:id])
    end
  end
end
