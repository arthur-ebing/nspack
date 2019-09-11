# frozen_string_literal: true

module Masterfiles
  module Farms
    module RmtContainerType
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:rmt_container_type, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Rmt Container Type'
              form.action '/masterfiles/farms/rmt_container_types'
              form.remote! if remote
              form.add_field :rmt_inner_container_type_id
              form.add_field :container_type_code
              form.add_field :description
              form.add_field :tare_weight
            end
          end

          layout
        end
      end
    end
  end
end
