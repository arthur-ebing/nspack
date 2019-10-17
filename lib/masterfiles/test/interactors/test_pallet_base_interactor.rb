# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPalletBaseInteractor < MiniTestWithHooks
    include PackagingFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::PackagingRepo)
    end

    def test_pallet_base
      MasterfilesApp::PackagingRepo.any_instance.stubs(:find_pallet_base).returns(fake_pallet_base)
      entity = interactor.send(:pallet_base, 1)
      assert entity.is_a?(PalletBase)
    end

    def test_create_pallet_base
      attrs = fake_pallet_base.to_h.reject { |k, _| k == :id }
      res = interactor.create_pallet_base(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PalletBase, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_pallet_base_fail
      attrs = fake_pallet_base(pallet_base_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_pallet_base(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:pallet_base_code]
    end

    def test_update_pallet_base
      id = create_pallet_base
      attrs = interactor.send(:repo).find_hash(:pallet_bases, id).reject { |k, _| k == :id }
      value = attrs[:pallet_base_code]
      attrs[:pallet_base_code] = 'a_change'
      res = interactor.update_pallet_base(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PalletBase, res.instance)
      assert_equal 'a_change', res.instance.pallet_base_code
      refute_equal value, res.instance.pallet_base_code
    end

    def test_update_pallet_base_fail
      id = create_pallet_base
      attrs = interactor.send(:repo).find_hash(:pallet_bases, id).reject { |k, _| %i[id pallet_base_code].include?(k) }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_pallet_base(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:pallet_base_code]
      after = interactor.send(:repo).find_hash(:pallet_bases, id)
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_pallet_base
      id = create_pallet_base
      assert_count_changed(:pallet_bases, -1) do
        res = interactor.delete_pallet_base(id)
        assert res.success, res.message
      end
    end

    private

    def pallet_base_attrs
      {
        id: 1,
        pallet_base_code: Faker::Lorem.unique.word,
        description: 'ABC',
        length: 1,
        width: 1,
        edi_in_pallet_base: 'ABC',
        edi_out_pallet_base: 'ABC',
        cartons_per_layer: 1,
        material_mass: 1.0,
        active: true
      }
    end

    def fake_pallet_base(overrides = {})
      PalletBase.new(pallet_base_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PalletBaseInteractor.new(current_user, {}, {}, {})
    end
  end
end
