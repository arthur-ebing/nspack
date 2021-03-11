# frozen_string_literal: true

module Masterfiles
  module General
    module MasterfileTransformation
      class Grid
        def self.call(form_values: {})
          ui_rule = UiRules::Compiler.new(:masterfile_transformation, :grid, form_values: form_values)
          rules   = ui_rule.compile

          grid_url = '/masterfiles/general/masterfile_transformations/grid'
          new_url = '/masterfiles/general/masterfile_transformations/new'

          unless form_values.empty?
            append_url = "?masterfile_table=#{form_values[:masterfile_table]}&masterfile_id=#{form_values[:masterfile_id]}"
            grid_url += append_url
            new_url += append_url
          end

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: "New #{ui_rule.form_object.transformation} Transformation",
                                  url: new_url,
                                  grid_id: 'masterfile_transformations',
                                  behaviour: :popup,
                                  style: :button)
            end
            page.add_grid('masterfile_transformations',
                          grid_url,
                          height: 44,
                          caption: 'Masterfile Transformations')
          end

          layout
        end
      end
    end
  end
end
