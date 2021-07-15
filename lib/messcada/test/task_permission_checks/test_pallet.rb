# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestLoadPermission < MiniTestWithHooks
    include Crossbeams::Responses


    def test_exist
      res = FinishedGoodsApp::TaskPermissionCheck::Pallet.call(:exists)
      assert res.success, 'Pallet should exist'
    end


  end
end
