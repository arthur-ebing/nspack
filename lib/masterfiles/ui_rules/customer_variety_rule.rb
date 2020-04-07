# frozen_string_literal: true

module UiRules
  class CustomerVarietyRule < Base
    def generate_rules
      @repo = MasterfilesApp::MarketingRepo.new
      make_form_object
      apply_form_values

      # common_values_for_fields common_fields
      common_values_for_fields @mode == :new ? common_fields : edit_fields

      set_show_fields if %i[show reopen].include? @mode

      add_behaviours if %i[new].include? @mode

      form_name 'customer_variety'
    end

    def set_show_fields
      variety_as_customer_variety_id_label = @repo.find_hash(:marketing_varieties, @form_object.variety_as_customer_variety_id)[:marketing_variety_code]
      packed_tm_group_id_label = @repo.find_hash(:target_market_groups, @form_object.packed_tm_group_id)[:target_market_group_name]
      fields[:variety_as_customer_variety_id] = { renderer: :label, with_value: variety_as_customer_variety_id_label, caption: 'Variety As Customer Variety' }
      fields[:packed_tm_group_id] = { renderer: :label, with_value: packed_tm_group_id_label, caption: 'Packed Tm Group' }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:marketing_varieties] = { renderer: :list, items: customer_variety_marketing_varieties }
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

    def customer_variety_marketing_varieties
      @repo.find_customer_variety_marketing_varieties(@options[:id])
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :variety_as_customer_variety_id, notify: [{ url: '/masterfiles/marketing/customer_varieties/variety_as_customer_variety_changed' }]
      end
    end
  end
end
