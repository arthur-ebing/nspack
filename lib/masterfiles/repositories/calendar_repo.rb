# frozen_string_literal: true

module MasterfilesApp
  class CalendarRepo < BaseRepo
    build_for_select :season_groups,
                     label: :season_group_code,
                     value: :id,
                     order_by: :season_group_code
    build_inactive_select :season_groups,
                          label: :season_group_code,
                          value: :id,
                          order_by: :season_group_code

    build_for_select :seasons,
                     label: :season_code,
                     value: :id,
                     order_by: :season_code
    build_inactive_select :seasons,
                          label: :season_code,
                          value: :id,
                          order_by: :season_code

    crud_calls_for :season_groups, name: :season_group, wrapper: SeasonGroup
    crud_calls_for :seasons, name: :season, wrapper: Season

    def for_select_seasons_for_cultivar_group(cultivar_group_id)
      DB[:seasons]
        .join(:cultivars, commodity_id: :commodity_id)
        .where(cultivar_group_id: cultivar_group_id)
        .where(season_year: Time.now.year)
        .order(:season_code)
        .distinct
        .select_map([:season_code, Sequel[:seasons][:id]])
    end
  end
end
