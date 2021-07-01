# frozen_string_literal: true

module UiRules
  class ChangeBinDeliveryRule < Base
    def generate_rules
      @repo = ProductionApp::ReworksRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_change_bin_delivery_details if @mode == :details

      form_name 'change_bin_delivery'
    end

    def common_fields
      reworks_run_type_id_label = @form_object.reworks_run_type_id.nil_or_empty? ? '' : @repo.find_hash(:reworks_run_types, @form_object.reworks_run_type_id)[:run_type]
      {
        reworks_run_type_id: { renderer: :hidden },
        reworks_run_type: { renderer: :label,
                            with_value: reworks_run_type_id_label,
                            caption: 'Reworks Run Type' },
        from_delivery_id: { renderer: :integer,
                            required: true,
                            caption: 'From Delivery' },
        to_delivery_id: { renderer: :integer,
                          required: true,
                          caption: 'To Delivery' }
      }
    end

    def set_change_bin_delivery_details
      reworks_run_type_id_label = @form_object.reworks_run_type_id.nil_or_empty? ? '' : @repo.find_hash(:reworks_run_types, @form_object.reworks_run_type_id)[:run_type]
      fields[:reworks_run_type_id] = { renderer: :hidden }
      fields[:reworks_run_type] = { renderer: :label,
                                    with_value: reworks_run_type_id_label,
                                    caption: 'Reworks Run Type' }
      fields[:from_delivery_id] = { renderer: :label }
      fields[:to_delivery_id] = { renderer: :label }
    end

    def make_form_object
      if %i[new].include? @mode
        make_new_form_object
        return
      end

      @form_object = OpenStruct.new(@options[:attrs].to_h)
    end

    def make_new_form_object
      @form_object = OpenStruct.new(reworks_run_type_id: @options[:reworks_run_type_id],
                                    from_delivery_id: nil,
                                    to_delivery_id: nil)
    end
  end
end
