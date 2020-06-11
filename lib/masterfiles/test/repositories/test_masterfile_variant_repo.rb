# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestMasterfileVariantRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_mf_variant
    end

    def test_crud_calls
      test_crud_calls_for :masterfile_variants, name: :masterfile_variant, wrapper: MasterfileVariant
    end

    private

    def repo
      MasterfileVariantRepo.new
    end
  end
end
