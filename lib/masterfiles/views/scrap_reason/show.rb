# frozen_string_literal: true

module Masterfiles
  module Quality
    module ScrapReason
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:scrap_reason, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Scrap Reason'
              form.view_only!
              form.add_field :scrap_reason
              form.add_field :description
              form.add_field :applies_to_pallets
              form.add_field :applies_to_bins
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
