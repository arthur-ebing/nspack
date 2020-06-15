# frozen_string_literal: true

module Masterfiles
  module General
    module MasterfileVariant
      class Grid
        def self.call
          ui_rule = UiRules::Compiler.new(:masterfile_variant, :grid)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'New Masterfile Variant',
                                  url: '/masterfiles/general/masterfile_variants/new',
                                  grid_id: 'masterfile_variants',
                                  behaviour: :popup,
                                  style: :button)
            end
            page.add_grid('masterfile_variants',
                          '/masterfiles/general/masterfile_variants/grid',
                          height: 44,
                          caption: 'Masterfile Variants')
          end

          layout
        end
      end
    end
  end
end
