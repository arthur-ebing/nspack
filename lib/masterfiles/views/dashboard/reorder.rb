# frozen_string_literal: true

module Masterfiles
  module Config
    module Dashboard
      class Reorder
        def self.call(key)
          # this_repo = SecurityApp::MenuRepo.new
          # progfuncs = this_repo.program_functions_for_select(id)
          ui_rule = UiRules::Compiler.new(:dashboard, :reorder, key: key)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build do |page|
            page.form do |form|
              form.action "/masterfiles/config/dashboards/#{key}/save_reorder"
              form.remote!
              form.add_text 'Drag and drop to re-order. Press submit to save the new order.'
              form.add_sortable_list('pages', rules[:dash_items])
            end
          end

          layout
        end
      end
    end
  end
end
