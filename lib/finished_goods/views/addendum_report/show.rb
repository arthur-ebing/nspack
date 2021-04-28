# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module Report
      class AddendumPlaceOfIssue
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:addendum_place_of_issue, :new)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Addendum Place of Issue'
              form.action "/finished_goods/reports/addendum_place_of_issue/#{id}"
              form.add_field :place_of_issue
            end
          end

          layout
        end
      end
    end
  end
end
