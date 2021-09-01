# frozen_string_literal: true

module UiRules
  class TargetMarketRule < Base
    def generate_rules
      @repo = MasterfilesApp::TargetMarketRepo.new
      @destination_repo = MasterfilesApp::DestinationRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      form_name 'target_market'
    end

    def set_show_fields
      fields[:target_market_name] = { renderer: :label }
      fields[:tm_group_ids] = { renderer: :list, caption: 'Groups', items: @repo.target_market_group_names_for(@options[:id]) }
      fields[:country_ids] = { renderer: :list, caption: 'Countries', items: @repo.destination_country_names_for(@options[:id]) }
      fields[:description] = { renderer: :label }
      fields[:inspection_tm] = { renderer: :label, as_boolean: true }
      fields[:target_customer_ids] = { renderer: :list,
                                       caption: 'Target Customers',
                                       invisible: !AppConst::CR_PROD.link_target_markets_to_target_customers?,
                                       items: @repo.target_customer_party_role_names_for(@options[:id]) }
      fields[:protocol_exception] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        target_market_name: { required: true, caption: 'Target Market Name' },
        tm_group_ids: { renderer: :multi, options: @repo.for_select_tm_groups, selected: @form_object.tm_group_ids, caption: 'Groups', required: true },
        country_ids: { renderer: :multi, options: @destination_repo.for_select_destination_countries, selected: @form_object.country_ids, caption: 'Countries' },
        description: {},
        inspection_tm: { renderer: :checkbox },
        target_customer_ids: { renderer: :multi,
                               options: @party_repo.for_select_party_roles(AppConst::ROLE_TARGET_CUSTOMER),
                               selected: @form_object.target_customer_ids,
                               invisible: !AppConst::CR_PROD.link_target_markets_to_target_customers?,
                               caption: 'Target Customers' },
        protocol_exception: { renderer: :checkbox }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_target_market(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::TargetMarket)
    end
  end
end
