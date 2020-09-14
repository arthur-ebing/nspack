# frozen_string_literal: true

module MasterfilesApp
  module CalendarFactory
    def create_season_group(opts = {})
      default = {
        season_group_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        season_group_year: Time.now.year,
        active: true
      }
      DB[:season_groups].insert(default.merge(opts))
    end

    def create_season(opts = {})
      season_group_id = create_season_group
      commodity_id = create_commodity

      default = {
        season_group_id: season_group_id,
        commodity_id: commodity_id,
        season_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        season_year: '2010',
        start_date: '2010-01-01',
        end_date: Date.today + 1,
        active: true
      }
      DB[:seasons].insert(default.merge(opts))
    end
  end
end
