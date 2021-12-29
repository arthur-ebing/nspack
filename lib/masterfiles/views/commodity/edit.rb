# frozen_string_literal: true

module Masterfiles
  module Fruit
    module Commodity
      class Edit
        def self.call(id, form_values = nil, form_errors = nil)
          ui_rule = UiRules::Compiler.new(:commodity, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/masterfiles/fruit/commodities/#{id}"
              form.remote!
              form.method :update
              form.add_field :commodity_group_id
              form.add_field :code
              form.add_field :description
              form.add_field :hs_code
              form.add_field :requires_standard_counts
              form.add_field :use_size_ref_for_edi
              form.add_field :colour_applies
              form.add_field :allocate_sample_rmt_bins
            end

            if rules[:colour_applies]
              page.section do |section|
                section.add_grid('colour_percentages',
                                 "/list/colour_percentages/grid?key=commodity_code&commodity_id=#{id}",
                                 height: 16,
                                 caption: 'Colour Percentages')
              end
            end
          end

          layout
        end
      end
    end
  end
end
