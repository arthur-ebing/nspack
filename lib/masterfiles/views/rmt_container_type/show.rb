# frozen_string_literal: true

module Masterfiles
  module Farms
    module RmtContainerType
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:rmt_container_type, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'RMT Container Type'
              form.view_only!
              form.add_field :rmt_inner_container_type
              form.add_field :container_type_code
              form.add_field :description
              form.add_field :tare_weight
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
