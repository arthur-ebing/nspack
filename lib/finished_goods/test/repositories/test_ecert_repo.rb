# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestEcertRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_ecert_agreements
    end

    def test_crud_calls
      test_crud_calls_for :ecert_agreements, name: :ecert_agreement, wrapper: EcertAgreement
    end

    private

    def repo
      EcertRepo .new
    end
  end
end
