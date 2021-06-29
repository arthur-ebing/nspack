# frozen_string_literal: true

module Labels
  module Labels
    module Label
      class Variables
        def self.call # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:label_variables, id: nil)
          rules   = ui_rule.compile

          col_defs = Crossbeams::DataGrid::ColumnDefiner.new.make_columns do |mk|
            mk.col 'variable', 'Variable name'
            mk.col 'resolver', 'Resolver'
            mk.col 'group', 'Group name' # , groupable: true, group_by_seq: 1
          end

          Crossbeams::Layout::Page.build(rules) do |page|
            page.add_text 'Available Label variables', wrapper: :h2

            rules[:data].each do |variable_set|
              page.add_text variable_set[:set], wrapper: :h3

              variable_set[:apps].each do |app|
                page.add_grid "grd_#{variable_set[:set].downcase.gsub(' ', '_')}_#{app[:app].downcase.gsub(' ', '_')}",
                              nil,
                              caption: "Variables for #{app[:app]} labels",
                              col_defs: col_defs,
                              row_defs: app[:rows]
              end
            end
          end
        end
      end
    end
  end
end
