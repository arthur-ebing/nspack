# frozen_string_literal: true

module UiRules
  class WorkOrderRule < Base
    def generate_rules # rubocop:disable Metrics/AbcSize
      @repo = ProductionApp::OrderRepo.new
      make_form_object
      apply_form_values

      @rules[:marketing_order_id] = @form_object.marketing_order_id
      @rules[:completed] = form_object.completed

      common_values_for_fields common_fields

      build_confirm_message if @mode == :confirm
      set_edit_fields_for_completed if form_object.completed
      set_new_fields_for_parent if @options[:marketing_order_id]
      set_show_fields if %i[show reopen].include? @mode

      form_name 'work_order'
    end

    def build_confirm_message
      @rules[:confirm_message] = 'You have deselected the ff product_setup_templates. Work order items belonging to these will be deleted'
      ProductionApp::OrderRepo.new.find_work_order_items_by_templates(@options[:deselected_setup_templates]).group_by { |r| r[:template_name] }.map do |k, v|
        @rules[:confirm_message] += "<br>#{k}(#{v.size})"
      end
    end

    def set_show_fields
      # marketing_order_id_label = ProductionApp::MarketingOrderRepo.new.find_marketing_order(@form_object.marketing_order_id)&.order_number
      # marketing_order_id_label = @repo.find(:marketing_orders, ProductionApp::MarketingOrder, @form_object.marketing_order_id)&.order_number
      marketing_order_id_label = @repo.get(:marketing_orders, @form_object.marketing_order_id, :order_number)
      fields[:marketing_order_id] = { renderer: :label, with_value: marketing_order_id_label, caption: 'Marketing Order' }
      fields[:start_date] = { renderer: :label }
      fields[:end_date] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:completed] = { renderer: :label, as_boolean: true }
      fields[:completed_at] = { renderer: :label, format: :without_timezone_or_seconds }
    end

    def set_edit_fields_for_completed
      set_show_fields
    end

    def set_new_fields_for_parent
      fields[:marketing_order_id] = { renderer: :select, options: @repo.for_select_marketing_orders(where: { id: @options[:marketing_order_id] }), caption: 'Marketing Order', required: true }
    end

    def common_fields
      {
        marketing_order_id: { renderer: :select, options: @repo.for_select_marketing_orders, caption: 'Marketing Order', required: true, prompt: true },
        start_date: { renderer: :date, required: true },
        end_date: { renderer: :date, required: true },
        active: { renderer: :checkbox },
        completed: { renderer: :label, as_boolean: true },
        completed_at: { renderer: :label, format: :without_timezone_or_seconds }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_work_order(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(marketing_order_id: nil,
                                    start_date: nil,
                                    end_date: nil,
                                    completed: nil,
                                    completed_at: nil)
    end

    # private

    # def add_approve_behaviours
    #   behaviours do |behaviour|
    #     behaviour.enable :reject_reason, when: :approve_action, changes_to: ['r']
    #   end
    # end
  end
end
