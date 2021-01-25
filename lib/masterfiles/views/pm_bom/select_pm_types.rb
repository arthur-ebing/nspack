# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PmBom
      class SelectPmTypes
        def self.call(form_values: nil, form_errors: nil, remote: true)  # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:pm_bom, :select_pm_types, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back to PM BOMs',
                                  url: '/list/pm_boms',
                                  style: :back_button)
            end
            page.form do |form|
              form.caption 'Select PM Types'
              form.submit_captions 'Next'
              form.action '/masterfiles/packaging/pm_boms/select_pm_types'
              form.remote! if remote
              form.add_field :pm_type_ids
            end
          end

          layout
        end
      end
    end
  end
end
