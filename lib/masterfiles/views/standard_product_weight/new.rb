# frozen_string_literal: true

module Masterfiles
  module Fruit
    module StandardProductWeight
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:standard_product_weight, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Standard Product Weight'
              form.action '/masterfiles/fruit/standard_product_weights'
              form.remote! if remote
              form.add_field :commodity_id
              form.add_field :standard_pack_id
              form.add_field :gross_weight
              form.add_field :nett_weight
              form.add_field :standard_carton_nett_weight
              # form.add_field :ratio_to_standard_carton
              form.add_field :is_standard_carton
            end
          end

          layout
        end
      end
    end
  end
end
