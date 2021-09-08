# frozen_string_literal: true

module FinishedGoods
  module PalletBuildup
    class Show
      def self.call(id)
        ui_rule = UiRules::Compiler.new(:pallet_buildup, :show, id: id)
        rules   = ui_rule.compile

        layout = Crossbeams::Layout::Page.build(rules) do |page|
          page.form_object ui_rule.form_object
          page.form do |form|
            form.view_only!
            form.add_field :created_by
            form.add_field :completed_at
            form.add_field :destination_pallet_number

            ui_rule.form_object[:source_pallets].each do |s|
              form.add_list ui_rule.form_object[:cartons_moved][s], caption: "Ctns Moved From Pallet: #{s}"
            end
          end
        end

        layout
      end
    end
  end
end
