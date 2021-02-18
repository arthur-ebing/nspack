# frozen_string_literal: true

module Masterfiles
  module Farms
    module Puc
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:puc, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Puc'
              form.action '/masterfiles/farms/pucs'
              form.remote! if remote
              form.add_field :puc_code
              form.add_field :gap_code
              form.add_field :gap_code_valid_from
              form.add_field :gap_code_valid_until
            end
          end

          layout
        end
      end
    end
  end
end
