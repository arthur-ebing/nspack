# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module Voyage
      class Show
        def self.call(id, back_url: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:voyage, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)
            end
            page.form do |form|
              # form.caption 'Voyage'
              form.view_only!
              form.no_submit!
              form.row do |row|
                row.column do |col|
                  col.add_field :vessel_id
                  col.add_field :voyage_type_id
                  col.add_field :voyage_number
                  col.add_field :voyage_code
                end
                row.column do |col|
                  col.add_field :year
                  col.add_field :completed
                  col.add_field :completed_at
                  col.add_field :active
                end
              end
            end
            page.section do |section|
              section.add_grid('voyage_ports',
                               "/list/voyage_ports/grid?key=standard&voyage_id=#{id}",
                               caption: 'Voyage Ports')
            end
          end

          layout
        end
      end
    end
  end
end
