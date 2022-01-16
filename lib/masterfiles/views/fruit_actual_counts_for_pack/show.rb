# frozen_string_literal: true

module Masterfiles
  module Fruit
    module FruitActualCountsForPack
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:fruit_actual_counts_for_pack, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.view_only!
              form.add_field :std_fruit_size_count
              form.add_field :basic_pack_code
              form.add_field :actual_count_for_pack
              form.add_field :active
              form.add_field :standard_packs
              form.add_field :size_references
            end
          end
        end
      end
    end
  end
end
