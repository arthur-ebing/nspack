# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCartonsPerPalletInteractor < MiniTestWithHooks
    include PackagingFactory
    include FruitFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::PackagingRepo)
    end

    def test_cartons_per_pallet
      MasterfilesApp::PackagingRepo.any_instance.stubs(:find_cartons_per_pallet).returns(fake_cartons_per_pallet)
      entity = interactor.send(:cartons_per_pallet, 1)
      assert entity.is_a?(CartonsPerPallet)
    end

    def test_create_cartons_per_pallet
      attrs = fake_cartons_per_pallet.to_h.reject { |k, _| k == :id }
      res = interactor.create_cartons_per_pallet(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(CartonsPerPallet, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_cartons_per_pallet_fail
      attrs = fake_cartons_per_pallet(layers_per_pallet: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_cartons_per_pallet(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:layers_per_pallet]
    end

    def test_update_cartons_per_pallet
      id = create_cartons_per_pallet
      attrs = interactor.send(:repo).find_cartons_per_pallet(id)
      attrs = attrs.to_h
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_cartons_per_pallet(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(CartonsPerPallet, res.instance)
      assert_equal 'a_change', res.instance.description
      refute_equal value, res.instance.description
    end

    def test_update_cartons_per_pallet_fail
      id = create_cartons_per_pallet
      attrs = interactor.send(:repo).find_cartons_per_pallet(id)
      attrs = attrs.to_h
      attrs.delete(:layers_per_pallet)
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_cartons_per_pallet(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      # assert_equal ['is missing'], res.errors[:description]
      after = interactor.send(:repo).find_cartons_per_pallet(id)
      after = after.to_h
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_cartons_per_pallet
      id = create_cartons_per_pallet
      assert_count_changed(:cartons_per_pallet, -1) do
        res = interactor.delete_cartons_per_pallet(id)
        assert res.success, res.message
      end
    end

    private

    def cartons_per_pallet_attrs
      pallet_format_id = create_pallet_format
      basic_pack_code_id = create_basic_pack

      {
        id: 1,
        description: Faker::Lorem.unique.word,
        pallet_format_id: pallet_format_id,
        basic_pack_id: basic_pack_code_id,
        cartons_per_pallet: 1,
        layers_per_pallet: 1,
        active: true,
        basic_pack_code: 'ABC',
        pallet_formats_description: 'ABC'
      }
    end

    def fake_cartons_per_pallet(overrides = {})
      CartonsPerPallet.new(cartons_per_pallet_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= CartonsPerPalletInteractor.new(current_user, {}, {}, {})
    end
  end
end
