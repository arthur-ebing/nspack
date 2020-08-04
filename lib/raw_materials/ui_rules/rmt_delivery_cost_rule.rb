# frozen_string_literal: true

module UiRules
  class RmtDeliveryCostRule < Base
    def generate_rules
      @repo = RawMaterialsApp::RmtDeliveryRepo.new
      make_form_object
      apply_form_values

      add_behaviours if %i[new edit].include? @mode

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'rmt_delivery_cost'
    end

    def set_show_fields
      cost_id_label = @repo.find(:costs, MasterfilesApp::Cost, @form_object[:cost_id])&.cost_code
      fields[:cost_id] = { renderer: :label, with_value: cost_id_label, caption: 'Cost' }
      fields[:amount] = { renderer: :label }
      fields[:description] = { renderer: :label }
    end

    def common_fields
      {
        cost_id: { renderer: :select, options: @repo.for_select_costs, caption: 'Cost', required: true, prompt: 'Select Cost', hide_on_load: @mode == :edit },
        amount: {},
        description: { renderer: :label, hide_on_load: @mode == :new }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_rmt_delivery_cost_flat(@options[:rmt_delivery_id], @options[:cost_id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(rmt_delivery_id: nil,
                                    cost_id: nil,
                                    description: nil,
                                    amount: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :cost_id, notify: [{ url: '/raw_materials/deliveries/rmt_delivery_costs/cost_changed' }]
      end
    end
  end
end
