# frozen_string_literal: true

module RawMaterialsApp
  module ViewHelpers
    module QC
      # Display the QC section in a show / edit view.
      def qc_section(page, rules) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        page.add_notice 'First delivery QC test is outstanding for this season, cultivar and orchard', caption: 'NB', inline_caption: true if rules[:first_qc_sample_outstanding]
        page.fold_up do |fold|
          fold.caption 'QC'
          fold.section do |section|
            section.add_control(control_type: :dropdown_button, text: '100 Fruit Sample', items: rules[:items_fruit]) unless rules[:items_fruit].empty?
            section.add_control(control_type: :dropdown_button, text: 'Progressive defects', items: rules[:items_prog]) unless rules[:items_prog].empty?
            section.add_control(control_type: :dropdown_button, text: 'Producer starch', items: rules[:items_prod]) unless rules[:items_prod].empty?
            section.add_control(control_type: :dropdown_button, text: 'MRL', items: rules[:items_mrl]) unless rules[:items_mrl].empty?
            section.row do |row|
              unless rules[:items_fruit].empty?
                row.column do |col|
                  col.add_text '100 Fruit Sample', wrapper: :h3, css_classes: 'mid-gray'
                  if rules[:qc_summary_100_fruit_sample].empty?
                    col.add_text 'No sample', wrapper: :em
                  else
                    col.add_table rules[:qc_summary_100_fruit_sample],
                                  %i[key sample_size status summary],
                                  alignment: { sample_size: :right }
                  end
                end
              end

              unless rules[:items_prog].empty?
                row.column do |col|
                  col.add_text 'Progressive Defects', wrapper: :h3, css_classes: 'mid-gray'
                  if rules[:qc_summary_delivery_progressive_tests].empty?
                    col.add_text 'No sample', wrapper: :em
                  else
                    col.add_table rules[:qc_summary_delivery_progressive_tests],
                                  %i[key sample_size status summary],
                                  alignment: { sample_size: :right }
                  end
                end
              end

              unless rules[:items_prod].empty?
                row.column do |col|
                  col.add_text 'Producer Starch', wrapper: :h3, css_classes: 'mid-gray'
                  if rules[:qc_summary_producer].empty?
                    col.add_text 'No sample', wrapper: :em
                  else
                    col.add_table rules[:qc_summary_producer],
                                  %i[key sample_size status summary],
                                  alignment: { sample_size: :right }
                  end
                end
              end
            end

            section.row do |row|
              unless rules[:items_mrl].empty?
                row.column do |col|
                  col.add_text 'MRL Results', wrapper: :h3, css_classes: 'mid-gray'
                  if rules[:mrl_test_result].empty?
                    col.add_text 'No MRL Result', wrapper: :em
                  else
                    col.add_table rules[:mrl_test_result],
                                  %i[lab_code sample_type_code sample_number reference_number mrl_sample_passed max_num_chemicals_passed result_received_at]
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
