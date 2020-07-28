# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtBin
      class LabelsPrintedConfirm
        def self.call(form_values: nil, notice: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:pre_print_bin_label, :confirm, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.add_text rules[:compact_header]
            page.form do |form|
              form.no_submit!
              form.remote! if remote

              form.add_text notice
            end

            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Yes',
                                  url: "/raw_materials/deliveries/create_bin_labels?#{form_values.map { |k, v| "#{k}=#{v}" }.join('&')}",
                                  visible: true,
                                  style: :button)
              section.add_control(control_type: :link,
                                  text: 'No',
                                  url: '/raw_materials/deliveries/pre_printing_unsuccessful',
                                  visible: true,
                                  style: :button)
            end
          end

          layout
        end
      end
    end
  end
end
