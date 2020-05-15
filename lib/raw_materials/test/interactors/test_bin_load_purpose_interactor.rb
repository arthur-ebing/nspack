# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestBinLoadPurposeInteractor < MiniTestWithHooks
    include BinLoadFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(RawMaterialsApp::BinLoadRepo)
    end

    def test_bin_load_purpose
      RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_purpose).returns(fake_bin_load_purpose)
      entity = interactor.send(:bin_load_purpose, 1)
      assert entity.is_a?(BinLoadPurpose)
    end

    def test_create_bin_load_purpose
      attrs = fake_bin_load_purpose.to_h.reject { |k, _| k == :id }
      res = interactor.create_bin_load_purpose(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(BinLoadPurpose, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_bin_load_purpose_fail
      attrs = fake_bin_load_purpose(purpose_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_bin_load_purpose(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:purpose_code]
    end

    def test_update_bin_load_purpose
      id = create_bin_load_purpose
      attrs = interactor.send(:repo).find_hash(:bin_load_purposes, id).reject { |k, _| k == :id }
      value = attrs[:purpose_code]
      attrs[:purpose_code] = 'a_change'
      res = interactor.update_bin_load_purpose(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(BinLoadPurpose, res.instance)
      assert_equal 'a_change', res.instance.purpose_code
      refute_equal value, res.instance.purpose_code
    end

    def test_update_bin_load_purpose_fail
      id = create_bin_load_purpose
      attrs = interactor.send(:repo).find_hash(:bin_load_purposes, id).reject { |k, _| %i[id purpose_code].include?(k) }
      res = interactor.update_bin_load_purpose(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:purpose_code]
    end

    def test_delete_bin_load_purpose
      id = create_bin_load_purpose
      assert_count_changed(:bin_load_purposes, -1) do
        res = interactor.delete_bin_load_purpose(id)
        assert res.success, res.message
      end
    end

    private

    def bin_load_purpose_attrs
      {
        id: 1,
        purpose_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_bin_load_purpose(overrides = {})
      BinLoadPurpose.new(bin_load_purpose_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= BinLoadPurposeInteractor.new(current_user, {}, {}, {})
    end
  end
end
