# frozen_string_literal: true

module Quality
  module Qc
    module QcTest
      class Starch
        def self.call(id, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:qc_test, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            # page.add_table rules[:rows], rules[:cols]
            page.add_text rules[:compact_header]
            page.form do |form|
              form.caption 'Starch test'
              form.action "/quality/qc/qc_tests/#{id}/starch"
              form.remote! if remote
              form.method :update

              # form.row do |row|
              #   # row.column do |col|
              #   #   # sample desc + size
              #   #   #
              #   #   # col.add_field :qc_measurement_type_id
              #   #   # col.add_field :qc_sample_id
              #   #   col.add_field :qc_test_type_id
              #   # end
              #   # row.column do |col|
              #   #   # col.add_field :instrument_plant_resource_id
              #   #   # button to change sample size
              #   # end
              # end
              form.row do |row|
                row.column do |col|
                  col.add_field :sample_size
                  # col.add_field :editing
                  # col.add_field :completed
                  # col.add_field :completed_at
                  #
                  # percentages
                  # 5 10 20 25 30 40 60 70 80
                  #
                  col.add_field :percentage5
                  col.add_field :percentage10
                  col.add_field :percentage20
                  col.add_field :percentage25
                  col.add_field :percentage30
                  col.add_field :percentage40
                  col.add_field :percentage60
                  col.add_field :percentage70
                  col.add_field :percentage80
                end
                row.blank_column
              end
            end
          end
        end
      end
    end
  end
end
