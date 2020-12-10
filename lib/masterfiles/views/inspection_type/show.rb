# frozen_string_literal: true

module Masterfiles
  module Quality
    module InspectionType
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:inspection_type, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Inspection Type'
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :inspection_type_code
                  col.add_field :description
                  col.add_field :inspection_failure_type_id
                  col.add_field :active
                end
                row.column do |col|
                  col.add_field :applies_to_all_tm_groups
                  col.add_field :applicable_tm_group_ids

                  col.add_field :applies_to_all_cultivars
                  col.add_field :applicable_cultivar_ids

                  col.add_field :applies_to_all_orchards
                  col.add_field :applicable_orchard_ids
                end
              end
            end
          end

          layout
        end
      end
    end
  end
end
