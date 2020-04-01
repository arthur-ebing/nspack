# frozen_string_literal: true

module ProductionApp
  module ReworksFactory
    def create_reworks_run(opts = {})  # rubocop:disable Metrics/AbcSize
      reworks_run_type_id = create_reworks_run_type
      scrap_reason_id = create_scrap_reason

      default = {
        user: Faker::Lorem.unique.word,
        reworks_run_type_id: reworks_run_type_id,
        remarks: Faker::Lorem.word,
        scrap_reason_id: scrap_reason_id,
        pallets_selected: BaseRepo.new.array_of_text_for_db_col(%w[A B C]),
        pallets_affected: BaseRepo.new.array_of_text_for_db_col(%w[A B C]),
        changes_made: {},
        pallets_scrapped: BaseRepo.new.array_of_text_for_db_col(%w[A B C]),
        pallets_unscrapped: BaseRepo.new.array_of_text_for_db_col(%w[A B C])
      }
      DB[:reworks_runs].insert(default.merge(opts))
    end

    def create_reworks_run_type(opts = {})
      default = {
        run_type: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:reworks_run_types].insert(default.merge(opts))
    end
  end
end
