# frozen_string_literal: true

module UiRules
  class PresortGrowerGradingPoolRule < Base
    def generate_rules
      @repo = RawMaterialsApp::PresortGrowerGradingRepo.new
      make_form_object

      @rules[:completed] = @form_object.completed

      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      set_manage_pool_details if %i[manage confirm].include? @mode

      form_name 'presort_grower_grading_pool'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      season_id_label = @repo.get(:seasons, @form_object.season_id, :season_code)
      commodity_id_label = @repo.get(:commodities, @form_object.commodity_id, :code)
      farm_id_label = @repo.get(:farms, @form_object.farm_id, :farm_code)
      fields[:maf_lot_number] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:track_slms_indicator_code] = { renderer: :label,
                                             caption: 'Track Indicator Code' }
      fields[:season_id] = { renderer: :label,
                             with_value: season_id_label,
                             caption: 'Season' }
      fields[:commodity_id] = { renderer: :label,
                                with_value: commodity_id_label,
                                caption: 'Commodity' }
      fields[:farm_id] = { renderer: :label,
                           with_value: farm_id_label,
                           caption: 'Farm' }
      fields[:rmt_bin_count] = { renderer: :label }
      fields[:rmt_bin_weight] = { renderer: :label }
      fields[:pro_rata_factor] = { renderer: :label }
      fields[:completed] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:created_by] = { renderer: :label }
      fields[:updated_by] = { renderer: :label }
      fields[:created_at] = { renderer: :label,
                              format: :without_timezone_or_seconds }
      fields[:updated_at] = { renderer: :label,
                              format: :without_timezone_or_seconds }
    end

    def common_fields
      season_id_label = @repo.get(:seasons, @form_object.season_id, :season_code)
      commodity_id_label = @repo.get(:commodities, @form_object.commodity_id, :code)
      farm_id_label = @repo.get(:farms, @form_object.farm_id, :farm_code)
      {
        maf_lot_number: { required: true },
        description: {},
        track_slms_indicator_code: { renderer: :label,
                                     caption: 'Track Indicator Code' },
        season_id: { renderer: :label,
                     with_value: season_id_label,
                     caption: 'Season' },
        commodity_id: { renderer: :label,
                        with_value: commodity_id_label,
                        caption: 'Commodity' },
        farm_id: { renderer: :label,
                   with_value: farm_id_label,
                   caption: 'Farm' },
        rmt_bin_count: { renderer: :label,
                         caption: 'Bin Count' },
        rmt_bin_weight: { renderer: :label,
                          caption: 'Bin Weight' },
        pro_rata_factor: { renderer: :label,
                           caption: 'Pro Rata Factor' },
        completed: { renderer: :checkbox },
        created_by: {},
        updated_by: {}
      }
    end

    def set_manage_pool_details(columns = nil, display_columns = 3)
      compact_header(columns: columns || %i[maf_lot_number description track_slms_indicator_code season_code
                                            commodity_code farm_code rmt_bin_count rmt_bin_weight total_graded_weight
                                            active completed created_by updated_by created_at updated_at],
                     display_columns: display_columns,
                     header_captions: {
                       maf_lot_number: 'Maf Lot Number',
                       description: 'Description',
                       track_slms_indicator_code: 'Track Indicator Code',
                       season_code: 'Season',
                       commodity_code: 'Commodity',
                       farm_code: 'Farm'
                     })
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_presort_grower_grading_pool(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(RawMaterialsApp::PresortGrowerGradingPool)
    end
  end
end
