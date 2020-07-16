# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class CloneCarton
        def self.call(id, form_values: nil, form_errors: nil)  # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:reworks_run_carton, :clone_carton, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.add_text rules[:compact_header]
            page.form do |form|
              form.action "/production/reworks/cartons/#{id}/clone_carton"
              form.remote!
              form.add_field :carton_id
              form.add_field :pallet_id
              form.add_field :pallet_sequence_id
              form.add_field :no_of_clones
            end
          end

          layout
        end
      end
    end
  end
end
