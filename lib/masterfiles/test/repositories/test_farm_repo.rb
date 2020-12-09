# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestFarmRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_production_regions
      assert_respond_to repo, :for_select_farm_groups
      assert_respond_to repo, :for_select_farms
      assert_respond_to repo, :for_select_orchards
      assert_respond_to repo, :for_select_pucs
      assert_respond_to repo, :for_select_registered_orchards
    end

    def test_crud_calls
      test_crud_calls_for :production_regions, name: :production_region, wrapper: ProductionRegion
      test_crud_calls_for :farm_groups, name: :farm_group, wrapper: FarmGroup
      test_crud_calls_for :farms, name: :farm, wrapper: Farm
      test_crud_calls_for :orchards, name: :orchard, wrapper: Orchard
      test_crud_calls_for :pucs, name: :puc, wrapper: Puc
      test_crud_calls_for :registered_orchards, name: :registered_orchard, wrapper: RegisteredOrchard
    end

    private

    def repo
      FarmRepo.new
    end
  end
end
