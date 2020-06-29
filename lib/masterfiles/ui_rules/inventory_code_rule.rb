# frozen_string_literal: true

module UiRules
  class InventoryCodeRule < Base
    def generate_rules
      @repo = MasterfilesApp::FruitRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'inventory_code'
    end

    def set_show_fields
      fields[:inventory_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:edi_out_inventory_code] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:fruit_item_incentive_rate] = { renderer: :label }
    end

    def common_fields
      {
        inventory_code: { required: true },
        description: {},
        edi_out_inventory_code: {},
        fruit_item_incentive_rate: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_inventory_code(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(inventory_code: nil,
                                    description: nil,
                                    edi_out_inventory_code: nil,
                                    fruit_item_incentive_rate: nil)
    end
  end
end
