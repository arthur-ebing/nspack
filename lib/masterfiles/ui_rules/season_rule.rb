# frozen_string_literal: true

module UiRules
  class SeasonRule < Base
    def generate_rules
      @repo = MasterfilesApp::CalendarRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      add_behaviours if %i[new edit].include? @mode

      form_name 'season'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:season_group_id] = { renderer: :label,
                                   with_value: @repo.find_season_group(@form_object.season_group_id)&.season_group_code }
      fields[:commodity_id] = { renderer: :label,
                                with_value: MasterfilesApp::CommodityRepo.new.find_commodity(@form_object.commodity_id)&.code }
      fields[:season_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:season_year] = { renderer: :label }
      fields[:start_date] = { renderer: :label }
      fields[:end_date] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        season_group_id: { renderer: :select,
                           options: @repo.for_select_season_groups,
                           disabled_options: @repo.for_select_inactive_season_groups,
                           required: true },
        commodity_id: { renderer: :select,
                        options: MasterfilesApp::CommodityRepo.new.for_select_commodities,
                        disabled_options: MasterfilesApp::CommodityRepo.new.for_select_inactive_commodities,
                        required: true },
        season_code: { renderer: :hidden,
                       required: true },
        description: {},
        season_year: { renderer: :hidden,
                       subtype: :integer },
        start_date: { renderer: :input,
                      subtype: :date,
                      required: true },
        end_date: { renderer: :input,
                    subtype: :date,
                    required: true },
        active: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_season(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(season_group_id: nil,
                                    commodity_id: nil,
                                    season_code: nil,
                                    description: nil,
                                    season_year: Time.now.year,
                                    start_date: Time.now,
                                    end_date: Time.now + (60 * 60 * 24 * 365),
                                    active: true)
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.lose_focus :start_date,
                             notify: [{ url: '/masterfiles/calendar/seasons/start_date_changed' }]
      end
    end
  end
end
