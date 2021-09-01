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

    build_inactive_select :seasons,
                          label: :season_code,
                          value: :id,
                          order_by: :season_code

    crud_calls_for :season_groups, name: :season_group, wrapper: SeasonGroup
    crud_calls_for :seasons, name: :season, exclude: %i[create update]

    def find_season(id)
      find_with_association(
        :seasons, id,
        parent_tables: [{ parent_table: :season_groups,
                          flatten_columns: { season_group_code: :season_group_code } },
                        { parent_table: :commodities,
                          flatten_columns: { code: :commodity_code } }],
        wrapper: Season
      )
    end

    def create_season(res)
      attrs = res.to_h
      attrs[:season_year] = parse_season_year(attrs[:end_date])
      attrs[:season_code] = assemble_season_code(attrs[:season_year], attrs[:commodity_id])

      create(:seasons, attrs)
    end

    def update_season(id, res)
      attrs = res.to_h
      attrs[:season_year] = parse_season_year(attrs[:end_date])
      attrs[:season_code] = assemble_season_code(attrs[:season_year], attrs[:commodity_id])

      update(:seasons, id, attrs)
    end

    def parse_season_year(end_date)
      Date.parse(end_date.to_s).year
    end

    def assemble_season_code(season_year, commodity_id)
      "#{season_year}_#{DB[:commodities].where(id: commodity_id).get(:code)}"
    end

    def get_season_id(cultivar_id, date)
      raise ArgumentError, 'get_season_id: cultivar_id and date required' unless cultivar_id && date

      cultivar_group_id = get(:cultivars, cultivar_id, :cultivar_group_id)
      commodity_id = get(:cultivar_groups, cultivar_group_id, :commodity_id)
      DB[:seasons].where(commodity_id: commodity_id).where(Sequel.lit('? between start_date and end_date', date)).get(:id)
    end

    def for_select_seasons(where: {}, exclude: {}) # rubocop:disable Metrics/AbcSize
      DB[:seasons]
        .join(:cultivar_groups, commodity_id: :commodity_id)
        .join(:cultivars, cultivar_group_id: :id)
        .where(convert_empty_values(where))
        .exclude(convert_empty_values(exclude))
        .where(Sequel.lit('start_date').< Time.now)
        .where(Sequel.lit('end_date').> Time.now)
        .distinct
        .select_map([:season_code, Sequel[:seasons][:id]])
    end

    def one_year_from_start_date(start_date)
      return nil if start_date.nil_or_empty?

      dte = Date.parse start_date
      UtilityFunctions.days_since(dte, 365)
    end

    def find_season_by_variant(variant_code, commodity_code)
      DB[:masterfile_variants]
        .join(:seasons, id: :masterfile_id)
        .join(:commodities, id: :commodity_id)
        .where(variant_code: variant_code, code: commodity_code)
        .get(Sequel[:seasons][:id])
    end

    def find_cultivar_by_season_code_and_commodity_code(season_code, commodity_code)
      DB[:seasons]
        .join(:commodities, id: :commodity_id)
        .where(season_code: season_code, code: commodity_code)
        .get(Sequel[:seasons][:id])
    end
  end
end
