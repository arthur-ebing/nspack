# frozen_string_literal: true

module RawMaterials
  module Locations
    module RmtBin
      class ColdstoreEvents
        def self.call(id, remote: true)
          ui_rule = UiRules::Compiler.new(:coldstore_events, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.section do |section|
              section.add_table(rules[:rows],
                                rules[:cols],
                                cell_transformers: {
                                  created_at: ->(a) { a&.strftime('%F %R') }
                                },
                                top_margin: 2,
                                header_captions: rules[:header_captions])
            end

            page.form do |form|
              form.view_only!
              form.no_submit! unless remote
              form.remote! if remote
              form.add_notice 'There are no coldroom events for this bin' if rules[:rows].empty?
            end
          end
        end
      end
    end
  end
end
