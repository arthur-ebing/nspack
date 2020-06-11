# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestMasterfileVariantInteractor < MiniTestWithHooks
    include MasterfileVariantFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::MasterfileVariantRepo)
    end

    def test_masterfile_variant
      MasterfilesApp::MasterfileVariantRepo.any_instance.stubs(:find_masterfile_variant_flat).returns(fake_masterfile_variant)
      entity = interactor.send(:masterfile_variant, 1)
      assert entity.is_a?(MasterfileVariant)
    end

    def test_create_masterfile_variant
      attrs = fake_masterfile_variant.to_h.reject { |k, _| k == :id }
      res = interactor.create_masterfile_variant(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(MasterfileVariantFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_masterfile_variant_fail
      attrs = fake_masterfile_variant(masterfile_table: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_masterfile_variant(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:masterfile_table]
    end

    def test_update_masterfile_variant
      id = create_masterfile_variant
      attrs = interactor.send(:repo).find_hash(:masterfile_variants, id).reject { |k, _| k == :id }
      value = attrs[:variant_code]
      attrs[:variant_code] = 'a_change'
      res = interactor.update_masterfile_variant(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(MasterfileVariantFlat, res.instance)
      assert_equal 'a_change', res.instance.variant_code
      refute_equal value, res.instance.masterfile_table
    end

    def test_update_masterfile_variant_fail
      id = create_masterfile_variant
      attrs = interactor.send(:repo).find_hash(:masterfile_variants, id).reject { |k, _| %i[id variant_code].include?(k) }
      res = interactor.update_masterfile_variant(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:variant_code]
    end

    def test_delete_masterfile_variant
      id = create_masterfile_variant
      assert_count_changed(:masterfile_variants, -1) do
        res = interactor.delete_masterfile_variant(id)
        assert res.success, res.message
      end
    end

    private

    def masterfile_variant_attrs
      {
        id: 1,
        masterfile_table: 'target_market_groups',
        variant_code: 'ABC',
        masterfile_id: 1
      }
    end

    def fake_masterfile_variant(overrides = {})
      MasterfileVariant.new(masterfile_variant_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= MasterfileVariantInteractor.new(current_user, {}, {}, {})
    end
  end
end
