# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestProductionRunPermission < Minitest::Test
    include Crossbeams::Responses
    include ProductionRunFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        farm_id: 1,
        puc_id: 1,
        packhouse_resource_id: 1,
        production_line_id: 1,
        season_id: 1,
        orchard_id: 1,
        cultivar_group_id: 1,
        cultivar_id: 1,
        product_setup_template_id: 1,
        cloned_from_run_id: 1,
        active_run_stage: Faker::Lorem.unique.word,
        started_at: '2010-01-01 12:00',
        closed_at: '2010-01-01 12:00',
        re_executed_at: '2010-01-01 12:00',
        completed_at: '2010-01-01 12:00',
        allow_cultivar_mixing: false,
        allow_orchard_mixing: false,
        reconfiguring: false,
        closed: false,
        setup_complete: false,
        completed: false,
        running: false,
        active: true
      }
      ProductionApp::ProductionRun.new(base_attrs.merge(attrs))
    end

    def test_create
      res = ProductionApp::TaskPermissionCheck::ProductionRun.call(:create)
      assert res.success, 'Should always be able to create a production_run'
    end

    def test_edit
      ProductionApp::ProductionRunRepo.any_instance.stubs(:find_production_run).returns(entity)
      res = ProductionApp::TaskPermissionCheck::ProductionRun.call(:edit, 1)
      assert res.success, 'Should be able to edit a production_run'
    end

    def test_delete
      ProductionApp::ProductionRunRepo.any_instance.stubs(:find_production_run).returns(entity)
      res = ProductionApp::TaskPermissionCheck::ProductionRun.call(:delete, 1)
      assert res.success, 'Should be able to delete a production_run'
    end
  end
end
