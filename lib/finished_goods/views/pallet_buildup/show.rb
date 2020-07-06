# frozen_string_literal: true

module FinishedGoods
  module PalletBuildup
    class Show
      def self.call(id) # rubocop:disable Metrics/AbcSize
        ui_rule = UiRules::Compiler.new(:pallet_buildup, :show, id: id)
        rules   = ui_rule.compile

        layout = Crossbeams::Layout::Page.build(rules) do |page|
          page.form_object ui_rule.form_object
          page.form do |form|
            # form.caption 'Pallet Buildup'
            form.view_only!
            # form.add_field :qty_cartons_to_move
            form.add_field :created_by
            form.add_field :completed_at
            # form.add_field :source_pallets
            # form.add_field :cartons_moved
            # form.add_field :completed
            form.add_field :destination_pallet_number

            ui_rule.form_object[:source_pallets].each do |s|
              form.add_text "Ctns Moved From Pallet: #{s}", css_classes: 'b mid-gray'
              ui_rule.form_object[:cartons_moved][s].to_a.each do |c|
                form.add_field c.to_sym
              end
            end
          end
        end

        layout
      end
    end
  end
end
