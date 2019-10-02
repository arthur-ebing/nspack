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

    def find_season(id)
      hash = find_with_association(:seasons,
                                   id,
                                   parent_tables: [{ parent_table: :season_groups,
                                                     columns: [:season_group_code],
                                                     flatten_columns: { season_group_code: :season_group_code } },
                                                   { parent_table: :commodities,
                                                     columns: [:code],
                                                     flatten_columns: { code: :commodity_code } }])
      return nil if hash.nil?

      Season.new(hash)
    end

    def for_select_seasons_for_cultivar_group(cultivar_group_id)
      DB[:seasons]
        .join(:cultivars, commodity_id: :commodity_id)
        .where(cultivar_group_id: cultivar_group_id)
        .where(season_year: Time.now.year)
        .order(:season_code)
        .distinct
        .select_map([:season_code, Sequel[:seasons][:id]])
    end

    def one_year_from_start_date(start_date)
      dte = Date.parse start_date
      dte + 364
    end

    def season_code(season_year, commodity_id)
      "#{season_year}_#{DB[:commodities].where(id: commodity_id).get(:code)}"
    end
  end
end
