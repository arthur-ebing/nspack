# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestTitanRequestPermission < Minitest::Test
    include Crossbeams::Responses
    include TitanFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        load_id: 1,
        govt_inspection_sheet_id: 1,
        request_doc: {},
        result_doc: {},
        request_array: [],
        result_array: [],
        request_type: Faker::Lorem.unique.word,
        inspection_message_id: 1,
        transaction_id: 1,
        request_id: '1',
        success: true,
        created_at: Time.now
      }
      FinishedGoodsApp::TitanRequest.new(base_attrs.merge(attrs))
    end

    def test_delete
      FinishedGoodsApp::TitanRepo.any_instance.stubs(:find_titan_request).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::TitanRequest.call(:delete, 1)
      assert res.success, 'Should be able to delete a titan_request'
    end
  end
end
