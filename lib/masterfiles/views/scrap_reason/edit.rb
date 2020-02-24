# frozen_string_literal: true

module Masterfiles
  module Quality
    module ScrapReason
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:scrap_reason, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Scrap Reason'
              form.action "/masterfiles/quality/scrap_reasons/#{id}"
              form.remote!
              form.method :update
              form.add_field :scrap_reason
              form.add_field :description
              form.add_field :applies_to_pallets
              form.add_field :applies_to_bins
            end
          end

          layout
        end
      end
    end
  end
end
