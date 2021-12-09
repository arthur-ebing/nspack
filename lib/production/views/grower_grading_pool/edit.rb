# frozen_string_literal: true

module Production
  module GrowerGrading
    module GrowerGradingPool
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:grower_grading_pool, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Grower Grading Pool'
              form.action "/production/grower_grading/grower_grading_pools/#{id}"
              form.remote!
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :pool_name
                  col.add_field :production_run_code
                  col.add_field :bin_quantity
                  col.add_field :gross_weight
                end
                row.column do |col|
                  col.add_field :description
                  col.add_field :inspection_type_id
                  col.add_field :pro_rata_factor
                  col.add_field :nett_weight
                end
              end
            end
          end
        end
      end
    end
  end
end
