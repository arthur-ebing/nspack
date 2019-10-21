# frozen_string_literal: true

module Masterfiles
  module Farms
    module Orchard
      class New
        def self.call(farm_id, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:orchard, :new, farm_id: farm_id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Orchard'
              form.action "/masterfiles/farms/farms/#{farm_id}/orchards"
              form.remote! if remote
              form.form_id 'orchard_form'
              form.row do |row|
                row.column do |col|
                  col.add_field :farm
                  col.add_field :farm_id
                  col.add_field :orchard_code
                end
                row.column do |col|
                  col.add_field :puc_id
                  col.add_field :description
                end
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :cultivar_ids
                  col.add_notice('Use the close button of the dialog when finished.')
                end
              end

              form.submit_captions 'Add', 'Adding'
            end
          end

          layout
        end
      end
    end
  end
end
