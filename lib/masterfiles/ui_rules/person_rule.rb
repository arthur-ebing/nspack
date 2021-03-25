# frozen_string_literal: true

module UiRules
  class PersonRule < Base
    def generate_rules
      @repo = MasterfilesApp::PartyRepo.new
      @tm_repo = MasterfilesApp::TargetMarketRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields if %i[new edit].include?(@mode)

      set_show_fields if @mode == :show

      form_name 'person'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:party_name] = { renderer: :label, caption: 'Full Name' }
      fields[:surname] = { renderer: :label }
      fields[:first_name] = { renderer: :label }
      fields[:title] = { renderer: :label }
      fields[:vat_number] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:specialised_role_names] = { renderer: :list,
                                          items: @form_object.specialised_role_names,
                                          hide_on_load: @form_object.specialised_role_names.empty?,
                                          caption: 'Specialised Roles' }
      fields[:role_names] = { renderer: :list,
                              caption: 'Roles',
                              hide_on_load: @form_object.role_names.empty?,
                              items: @form_object.role_names }
      fields[:target_market_ids] = { renderer: :list,
                                     caption: 'Target Markets',
                                     invisible: !show_target_markets_link(@form_object.role_names),
                                     items: @repo.target_market_names_for(@repo.party_role_id_from_role_and_party_id(AppConst::ROLE_TARGET_CUSTOMER, @form_object[:party_id])) }
    end

    def common_fields
      {
        surname: { required: true },
        first_name: { required: true },
        title: { required: true },
        vat_number: {},
        active: { renderer: :checkbox },
        specialised_role_names: { renderer: :list,
                                  items: @form_object.specialised_role_names,
                                  hide_on_load: @form_object.specialised_role_names.empty?,
                                  caption: 'Specialised Roles' },
        role_ids: { renderer: :multi,
                    caption: 'Roles',
                    options: @repo.for_select_roles,
                    selected: @form_object.role_ids,
                    required: false },
        target_market_ids: { renderer: :multi,
                             options: @tm_repo.for_select_target_markets,
                             selected: @form_object.target_market_ids,
                             invisible: !show_target_markets_link(@form_object.role_names),
                             caption: 'Target Markets' }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_person(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(surname: nil,
                                    first_name: nil,
                                    title: nil,
                                    vat_number: nil,
                                    active: true,
                                    specialised_role_names: [],
                                    role_ids: [],
                                    target_market_ids: [])
    end

    def show_target_markets_link(role_names)
      return false if role_names.nil_or_empty?

      show = role_names.include?(AppConst::ROLE_TARGET_CUSTOMER)
      show = false unless AppConst::CR_PROD.kromco_target_markets_customers_link?
      show
    end
  end
end
