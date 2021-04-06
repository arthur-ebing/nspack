# frozen_string_literal: true

module UiRules
  class MarketingOrderRule < Base
    def generate_rules # rubocop:disable Metrics/AbcSize
      @repo = ProductionApp::OrderRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      @calender_repo = MasterfilesApp::CalendarRepo.new
      make_form_object
      apply_form_values

      @rules[:completed] = form_object.completed
      @rules[:hide_cumulative_work_order_items] = @repo.marketing_order_work_order_items(@options[:id]).empty?

      common_values_for_fields common_fields

      set_edit_fields_for_completed if form_object.completed
      set_show_fields if %i[show reopen].include? @mode

      form_name 'marketing_order'
    end

    def set_show_fields
      customer_party_role_id_label = @repo.get(:party_roles, @form_object.customer_party_role_id, :id)
      season_id_label = @repo.get(:seasons, @form_object.season_id, :season_code)
      fields[:customer_party_role_id] = { renderer: :label, with_value: customer_party_role_id_label, caption: 'Customer Party Role' }
      fields[:season_id] = { renderer: :label, with_value: season_id_label, caption: 'Season' }
      fields[:order_number] = { renderer: :label }
      fields[:order_reference] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:completed] = { renderer: :label, as_boolean: true }
      fields[:completed_at] = { renderer: :label, format: :without_timezone_or_seconds }
    end

    def set_edit_fields_for_completed
      set_show_fields
    end

    def common_fields
      {
        customer_party_role_id: { renderer: :select,
                                  options: @party_repo.for_select_party_roles(AppConst::ROLE_CUSTOMER),
                                  disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_CUSTOMER),
                                  caption: 'Customer',
                                  required: true,
                                  prompt: true },
        season_id: { renderer: :select,
                     options: @calender_repo.for_select_seasons,
                     disabled_options: @calender_repo.for_select_inactive_seasons,
                     caption: 'Season',
                     required: true,
                     prompt: true },
        order_number: { required: true },
        order_reference: { required: true },
        completed: { renderer: :label, as_boolean: true },
        completed_at: { disabled: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_marketing_order(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(customer_party_role_id: nil,
                                    season_id: nil,
                                    order_number: nil,
                                    order_reference: nil,
                                    completed: nil,
                                    completed_at: nil)
    end
  end
end
