# frozen_string_literal: true

module UiRules
  class CustomerVarietyRule < Base
    def generate_rules
      @repo = MasterfilesApp::MarketingRepo.new
      make_form_object
      apply_form_values

      # common_values_for_fields common_fields
      common_values_for_fields @mode == :new ? common_fields : edit_fields

      set_show_fields if %i[show].include? @mode

      add_behaviours if %i[new].include? @mode

      form_name 'customer_variety'
    end

    def set_show_fields
      fields[:variety_as_customer_variety] = { renderer: :label,
                                               caption: 'Variety As Customer Variety' }
      fields[:packed_tm_group] = { renderer: :label,
                                   caption: 'Packed TM Group' }
      fields[:marketing_varieties] = { renderer: :list,
                                       items: @form_object.marketing_varieties }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        variety_as_customer_variety_id: { renderer: :select,
                                          options: MasterfilesApp::CultivarRepo.new.for_select_marketing_varieties,
                                          disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_marketing_varieties,
                                          caption: 'Variety as Customer Variety',
                                          required: true },
        packed_tm_group_id: { renderer: :select,
                              options: MasterfilesApp::TargetMarketRepo.new.for_select_packed_tm_groups,
                              disabled_options: MasterfilesApp::TargetMarketRepo.new.for_select_inactive_tm_groups,
                              caption: 'Packed TM Group',
                              required: true },
        customer_variety_varieties: { renderer: :multi,
                                      options: MasterfilesApp::CultivarRepo.new.for_select_marketing_varieties,
                                      selected: @form_object.customer_variety_varieties,
                                      caption: 'Linked Marketing Varieties',
                                      required: true }
      }
    end

    def edit_fields
      {
        variety_as_customer_variety_id: { renderer: :select,
                                          options: MasterfilesApp::CultivarRepo.new.for_select_marketing_varieties,
                                          disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_marketing_varieties,
                                          caption: 'Variety as Customer Variety',
                                          required: true },
        packed_tm_group_id: { renderer: :select,
                              options: MasterfilesApp::TargetMarketRepo.new.for_select_packed_tm_groups,
                              disabled_options: MasterfilesApp::TargetMarketRepo.new.for_select_inactive_tm_groups,
                              caption: 'Packed TM Group',
                              required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_customer_variety(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(variety_as_customer_variety_id: nil,
                                    packed_tm_group_id: nil,
                                    customer_variety_varieties_ids: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :variety_as_customer_variety_id, notify: [{ url: '/masterfiles/marketing/customer_varieties/variety_as_customer_variety_changed' }]
      end
    end
  end
end
