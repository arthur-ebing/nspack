# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestReworksRunPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        user: Faker::Lorem.unique.word,
        reworks_run_type_id: 1,
        remarks: 'ABC',
        scrap_reason_id: 1,
        pallets_selected: %w[A B C],
        pallets_affected: %w[A B C],
        changes_made: {},
        pallets_scrapped: %w[A B C],
        pallets_unscrapped: %w[A B C]
      }
      ProductionApp::ReworksRun.new(base_attrs.merge(attrs))
    end

    def test_create
      res = ProductionApp::TaskPermissionCheck::ReworksRun.call(:create)
      assert res.success, 'Should always be able to create a reworks_run'
    end

    def test_edit
      ProductionApp::ReworksRepo.any_instance.stubs(:find_reworks_run).returns(entity)
      res = ProductionApp::TaskPermissionCheck::ReworksRun.call(:edit, 1)
      assert res.success, 'Should be able to edit a reworks_run'
    end

    def test_delete
      ProductionApp::ReworksRepo.any_instance.stubs(:find_reworks_run).returns(entity)
      res = ProductionApp::TaskPermissionCheck::ReworksRun.call(:delete, 1)
      assert res.success, 'Should be able to delete a reworks_run'
    end
  end
end
