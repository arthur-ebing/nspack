# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestPackingSpecificationRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_packing_specifications
      assert_respond_to repo, :for_select_packing_specification_items
    end

    def test_crud_calls
      test_crud_calls_for :packing_specifications, name: :packing_specification, wrapper: PackingSpecification
      test_crud_calls_for :packing_specification_items, name: :packing_specification_item, wrapper: PackingSpecificationItem
    end

    private

    def repo
      PackingSpecificationRepo.new
    end
  end
end
