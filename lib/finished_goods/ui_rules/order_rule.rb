# frozen_string_literal: true

module UiRules
  class OrderRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode
      add_progress_step
      add_controls
      add_behaviours

      form_name 'order'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:order_type] = { renderer: :label }
      fields[:customer] = { renderer: :label }
      fields[:sales_person] = { renderer: :label }
      fields[:contact] = { renderer: :label }
      fields[:currency] = { renderer: :label }
      fields[:deal_type] = { renderer: :label }
      fields[:incoterm] = { renderer: :label }
      fields[:customer_payment_term_set] = { renderer: :label, caption: 'Payment Term Set'  }
      fields[:target_customer] = { renderer: :label }
      fields[:exporter] = { renderer: :label }
      fields[:packed_tm_group] = { renderer: :label, caption: 'Packed TM Group' }
      fields[:final_receiver] = { renderer: :label }
      fields[:marketing_org] = { renderer: :label }
      fields[:allocated] = { renderer: :label, as_boolean: true }
      fields[:shipped] = { renderer: :label, as_boolean: true }
      fields[:completed] = { renderer: :label, as_boolean: true }
      fields[:completed_at] = { renderer: :label, format: :without_timezone_or_seconds }
      fields[:customer_order_number] = { renderer: :label }
      fields[:internal_order_number] = { renderer: :label }
      fields[:remarks] = { renderer: :label }
      fields[:pricing_per_kg] = { renderer: :label,
                                  hide_on_load: !@form_object.pricing_per_kg,
                                  as_boolean: true }
      fields[:pricing_per_carton] = { renderer: :label,
                                      hide_on_load: @form_object.pricing_per_kg,
                                      with_value: !@form_object.pricing_per_kg,
                                      as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      @finance_repo = MasterfilesApp::FinanceRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      @repo = FinishedGoodsApp::OrderRepo.new

      customer_id = @repo.get_id(:customers, customer_party_role_id: @form_object.customer_party_role_id)
      contact_person_ids, currency_ids = @repo.get(:customers, customer_id, %i[contact_person_ids currency_ids])
      deal_type_ids = @repo.select_values(:customer_payment_term_sets, :deal_type_id, customer_id: customer_id)
      incoterm_ids = @repo.select_values(:customer_payment_term_sets, :incoterm_id, customer_id: customer_id)

      {
        order_type_id: { renderer: :select,
                         options: @finance_repo.for_select_order_types,
                         disabled_options: @finance_repo.for_select_inactive_order_types,
                         caption: 'Order Type',
                         prompt: true,
                         required: true },
        customer_party_role_id: { renderer: :select,
                                  options: @party_repo.for_select_party_roles(AppConst::ROLE_CUSTOMER),
                                  disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_CUSTOMER),
                                  caption: 'Customer',
                                  prompt: true,
                                  required: true },
        sales_person_party_role_id: { renderer: :select,
                                      options: @party_repo.for_select_party_roles(AppConst::ROLE_SALES_PERSON),
                                      disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_SALES_PERSON),
                                      caption: 'Sales Person',
                                      prompt: true,
                                      required: true },
        contact_party_role_id: { renderer: :select,
                                 options: @party_repo.for_select_party_roles(
                                   AppConst::ROLE_CUSTOMER_CONTACT_PERSON,
                                   where: { id: Array(contact_person_ids) }
                                 ),
                                 disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_CUSTOMER_CONTACT_PERSON),
                                 caption: 'Contact Person',
                                 prompt: true,
                                 required: true },
        currency_id: { renderer: :select,
                       options: @finance_repo.for_select_currencies(where: { id: Array(currency_ids) }),
                       disabled_options: @finance_repo.for_select_inactive_currencies,
                       caption: 'Currency',
                       prompt: true,
                       required: true },
        deal_type_id: { renderer: :select,
                        options: @finance_repo.for_select_deal_types(where: { id: deal_type_ids }),
                        disabled_options: @finance_repo.for_select_inactive_deal_types,
                        caption: 'Deal Type',
                        prompt: true,
                        required: true },
        incoterm_id: { renderer: :select,
                       options: @finance_repo.for_select_incoterms(where: { id: incoterm_ids }),
                       disabled_options: @finance_repo.for_select_inactive_incoterms,
                       caption: 'Incoterm',
                       prompt: true,
                       required: true },
        customer_payment_term_set_id: { renderer: :select,
                                        options: @finance_repo.for_select_customer_payment_term_sets(
                                          where: { customer_id: customer_id,
                                                   Sequel[:customer_payment_term_sets][:deal_type_id] => @form_object.deal_type_id,
                                                   Sequel[:customer_payment_term_sets][:incoterm_id] => @form_object.incoterm_id }
                                        ),
                                        disabled_options: @finance_repo.for_select_customer_payment_term_sets(active: false),
                                        caption: 'Payment Term Set',
                                        prompt: true,
                                        required: true },
        target_customer_party_role_id: { renderer: :select,
                                         options: @party_repo.for_select_party_roles(AppConst::ROLE_TARGET_CUSTOMER),
                                         disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_TARGET_CUSTOMER),
                                         prompt: true,
                                         caption: 'Target Customer' },
        exporter_party_role_id: { renderer: :select,
                                  options: @party_repo.for_select_party_roles(AppConst::ROLE_EXPORTER),
                                  disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_EXPORTER),
                                  caption: 'Exporter',
                                  prompt: true,
                                  required: true },
        packed_tm_group_id: { renderer: :select,
                              options: MasterfilesApp::TargetMarketRepo.new.for_select_packed_tm_groups,
                              disabled_options: MasterfilesApp::TargetMarketRepo.new.for_select_packed_tm_groups(active: false),
                              caption: 'Packed TM Group',
                              prompt: true,
                              required: false },
        final_receiver_party_role_id: { renderer: :select,
                                        options: @party_repo.for_select_party_roles(AppConst::ROLE_FINAL_RECEIVER),
                                        disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_FINAL_RECEIVER),
                                        caption: 'Final Receiver',
                                        prompt: true,
                                        required: true },
        marketing_org_party_role_id: {  renderer: :select,
                                        options: @party_repo.for_select_party_roles(AppConst::ROLE_MARKETER),
                                        disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_MARKETER),
                                        caption: 'Marketing Org',
                                        prompt: true,
                                        required: true },
        customer_order_number: {},
        internal_order_number: {},
        remarks: {},
        load_id: { hide_on_load: true },
        pricing_per_kg: { renderer: :checkbox }
      }
    end

    def make_form_object
      @repo = FinishedGoodsApp::OrderRepo.new
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_order(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(order_type_id: @repo.get_id(:order_types, order_type: 'SALES_ORDER'),
                                    customer_party_role_id: nil,
                                    sales_person_party_role_id: nil,
                                    contact_party_role_id: nil,
                                    currency_id: nil,
                                    deal_type_id: nil,
                                    incoterm_id: nil,
                                    customer_payment_term_set_id: nil,
                                    target_customer_party_role_id: nil,
                                    exporter_party_role_id: nil,
                                    packed_tm_group_id: nil,
                                    final_receiver_party_role_id: nil,
                                    marketing_org_party_role_id: nil,
                                    allocated: nil,
                                    shipped: nil,
                                    completed: nil,
                                    completed_at: nil,
                                    customer_order_number: nil,
                                    internal_order_number: nil,
                                    remarks: nil,
                                    pricing_per_kg: nil)
    end

    def handle_behaviour
      changed = {
        customer: :customer_changed,
        deal_type: :deal_type_changed,
        incoterm: :incoterm_changed
      }
      changed = changed[@options[:field]]
      return unhandled_behaviour! if changed.nil?

      send(changed)
    end

    private

    def add_progress_step
      steps = ['Allocate Loads', 'Finished Allocating', 'Shipped', 'Finished']
      step = 0
      step = 1 if @form_object.allocated
      step = 2 if @form_object.shipped
      step = 3 if @form_object.completed

      @form_object = OpenStruct.new(@form_object.to_h.merge(steps: steps, step: step))
    end

    def add_controls # rubocop:disable Metrics/AbcSize
      id = @options[:id]
      back = { control_type: :link,
               text: 'Back',
               url: '/list/orders',
               style: :back_button }
      edit = { control_type: :link,
               style: :action_button,
               text: 'Edit',
               url: "/finished_goods/orders/orders/#{id}/edit",
               prompt: 'Are you sure, you want to edit this order?',
               icon: :edit }
      delete = { control_type: :link,
                 style: :action_button,
                 text: 'Delete',
                 url: "/finished_goods/orders/orders/#{id}/delete",
                 prompt: 'Are you sure, you want to delete this order?',
                 icon: :checkoff }
      create_load = { control_type: :link,
                      style: :action_button,
                      text: 'New Load',
                      url: "/finished_goods/orders/orders/#{id}/create_load" }
      close = { control_type: :link,
                style: :action_button,
                text: 'Close Order',
                url: "/finished_goods/orders/orders/#{id}/close",
                icon: :checkon }
      reopen = { control_type: :link,
                 style: :action_button,
                 text: 'Reopen Order',
                 url: "/finished_goods/orders/orders/#{id}/reopen",
                 icon: :checkon }
      refresh_order_lines = { control_type: :link,
                              style: :action_button,
                              text: 'Refresh Order Lines',
                              url: "/finished_goods/orders/orders/#{id}/refresh_order_lines",
                              icon: :checkon }

      case @form_object.step
      when 0
        instance_controls = [back, edit, delete]
        progress_controls = [create_load, refresh_order_lines, close]
      when 1
        instance_controls = [back]
        progress_controls = [reopen]
      when 2
        instance_controls = [back]
        progress_controls = []
      when 3
        instance_controls = [back]
        progress_controls = []
      else
        instance_controls = [back]
        progress_controls = []
      end

      @form_object = OpenStruct.new(@form_object.to_h.merge(progress_controls: progress_controls, instance_controls: instance_controls))
    end

    def add_behaviours
      url = "/finished_goods/orders/orders/change/#{@mode}"
      behaviours do |behaviour|
        behaviour.dropdown_change :customer_party_role_id, notify: [{ url: "#{url}/customer" }]
        behaviour.dropdown_change :deal_type_id, notify: [{ url: "#{url}/deal_type", param_keys: %i[order_incoterm_id order_customer_party_role_id] }]
        behaviour.dropdown_change :incoterm_id, notify: [{ url: "#{url}/incoterm", param_keys: %i[order_deal_type_id order_customer_party_role_id] }]
      end
    end

    def customer_changed # rubocop:disable Metrics/AbcSize
      form_object_merge!(params)
      customer_party_role_id = params[:changed_value].to_i
      @form_object[:customer_party_role_id] = customer_party_role_id
      fields = common_fields
      party_id = MasterfilesApp::PartyRepo.new.find_party_role(customer_party_role_id)&.party_id
      receiver_value = MasterfilesApp::PartyRepo.new.party_role_id_from_role_and_party_id(AppConst::ROLE_FINAL_RECEIVER, party_id)
      sales_person_value = @repo.get_last(:orders, :sales_person_party_role_id, customer_party_role_id: customer_party_role_id)

      json_actions([OpenStruct.new(type: :change_select_value,
                                   dom_id: 'order_sales_person_party_role_id',
                                   value: sales_person_value),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'order_contact_party_role_id',
                                   options_array: fields[:contact_party_role_id][:options]),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'order_deal_type_id',
                                   options_array: fields[:deal_type_id][:options]),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'order_incoterm_id',
                                   options_array: fields[:incoterm_id][:options]),
                    OpenStruct.new(type: :change_select_value,
                                   dom_id: 'order_final_receiver_party_role_id',
                                   value: receiver_value),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'order_currency_id',
                                   options_array: fields[:currency_id][:options])])
    end

    def deal_type_changed
      form_object_merge!(params)
      @form_object[:deal_type_id] = params[:changed_value].to_i
      @form_object[:incoterm_id] = params[:order_incoterm_id].to_i
      @form_object[:customer_party_role_id] = params[:order_customer_party_role_id].to_i
      fields = common_fields

      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'order_customer_payment_term_set_id',
                                   options_array: fields[:customer_payment_term_set_id][:options])])
    end

    def incoterm_changed
      form_object_merge!(params)
      @form_object[:incoterm_id] = params[:changed_value].to_i
      @form_object[:deal_type_id] = params[:order_deal_type_id].to_i
      @form_object[:customer_party_role_id] = params[:order_customer_party_role_id].to_i
      fields = common_fields

      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'order_customer_payment_term_set_id',
                                   options_array: fields[:customer_payment_term_set_id][:options])])
    end
  end
end
