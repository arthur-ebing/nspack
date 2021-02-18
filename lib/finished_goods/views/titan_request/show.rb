# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module TitanRequest
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:titan_request, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Titan Request'
              form.view_only!
              form.add_field :load_id
              form.add_field :govt_inspection_sheet_id
              form.add_field :request_type
              form.add_field :created_at
              result_array = ui_rule.form_object.result_array
              unless result_array.empty?
                form.fold_up do |fold|
                  fold.open!
                  fold.caption 'Result'
                  fold.add_table(result_array, %i[column value], top_margin: 3, has_columns: false)
                end
              end

              request_array = ui_rule.form_object.request_array
              unless request_array.empty?
                form.fold_up do |fold|
                  fold.caption 'Request'
                  fold.add_table(request_array, %i[column value], top_margin: 3, has_columns: false)
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
