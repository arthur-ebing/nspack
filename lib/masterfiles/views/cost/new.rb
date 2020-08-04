# frozen_string_literal: true

module Masterfiles
  module Costs
    module Cost
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:cost, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Cost'
              form.action '/masterfiles/costs/costs'
              form.remote! if remote
              form.add_field :cost_type_id
              form.add_field :cost_code
              form.add_field :default_amount
              form.add_field :description
            end
          end

          layout
        end
      end
    end
  end
end
