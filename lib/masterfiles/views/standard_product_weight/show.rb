# frozen_string_literal: true

module Masterfiles
  module Fruit
    module StandardProductWeight
      class Show
        def self.call(id)  # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:standard_product_weight, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Standard Product Weight'
              form.view_only!
              form.add_field :commodity_id
              form.add_field :standard_pack_id
              form.add_field :gross_weight
              form.add_field :nett_weight
              form.add_field :standard_carton_nett_weight
              form.add_field :ratio_to_standard_carton
              form.add_field :is_standard_carton
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
