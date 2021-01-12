module Masterfiles
  module Packaging
    module PmCompositionLevel
      class Reorder
        def self.call
          composition_levels = MasterfilesApp::BomRepo.new.composition_levels

          layout = Crossbeams::Layout::Page.build do |page|
            page.form do |form|
              form.action '/masterfiles/packaging/pm_composition_levels/save_reorder'
              form.remote!
              form.add_text 'Drag and drop to re-order. Press submit to save the new order.'
              form.add_sortable_list('p', composition_levels)
            end
          end

          layout
        end
      end
    end
  end
end
