# frozen_string_literal: true

module Masterfiles
  module Quality
    module ScrapReason
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:scrap_reason, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Scrap Reason'
              form.action '/masterfiles/quality/scrap_reasons'
              form.remote! if remote
              form.add_field :scrap_reason
              form.add_field :description
              form.add_field :applies_to_pallets
              form.add_field :applies_to_bins
              form.add_field :applies_to_cartons
            end
          end

          layout
        end
      end
    end
  end
end
