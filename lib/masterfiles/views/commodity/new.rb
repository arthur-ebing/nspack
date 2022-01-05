# frozen_string_literal: true

module Masterfiles
  module Fruit
    module Commodity
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:commodity, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action '/masterfiles/fruit/commodities'
              form.remote! if remote
              form.add_field :commodity_group_id
              form.add_field :code
              form.add_field :description
              form.add_field :hs_code
              form.add_field :requires_standard_counts
              form.add_field :use_size_ref_for_edi
              form.add_field :colour_applies
              form.add_field :allocate_sample_rmt_bins
              form.add_field :derive_rmt_nett_weight
            end
          end

          layout
        end
      end
    end
  end
end
