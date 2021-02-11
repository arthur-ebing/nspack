# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestBinLoadInteractor < MiniTestWithHooks
    include BinLoadFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::FarmFactory
    include MasterfilesApp::DepotFactory
    include MasterfilesApp::RmtContainerMaterialTypeFactory
    include RawMaterialsApp::RmtBinFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(RawMaterialsApp::BinLoadRepo)
    end

    def test_bin_load
      RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_flat).returns(fake_bin_load)
      entity = interactor.send(:bin_load, 1)
      assert entity.is_a?(BinLoad)
    end

    def test_create_bin_load
      attrs = fake_bin_load.to_h.reject { |k, _| k == :id }
      res = interactor.create_bin_load(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(BinLoadFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_bin_load_fail
      attrs = fake_bin_load(id: nil).to_h.reject { |k, _| k == :customer_party_role_id }
      res = interactor.create_bin_load(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['is missing'], res.errors[:customer_party_role_id]
    end

    def test_update_bin_load
      id = create_bin_load
      attrs = interactor.send(:repo).find_hash(:bin_loads, id).reject { |k, _| k == :id }
      value = attrs[:bin_load_purpose_id]
      bin_load_purpose_id = create_bin_load_purpose
      attrs[:bin_load_purpose_id] = bin_load_purpose_id
      res = interactor.update_bin_load(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(BinLoadFlat, res.instance)
      assert_equal bin_load_purpose_id, res.instance.bin_load_purpose_id
      refute_equal value, bin_load_purpose_id
    end

    def test_update_bin_load_fail
      id = create_bin_load
      attrs = interactor.send(:repo).find_hash(:bin_loads, id).reject { |k, _| %i[id bin_load_purpose_id].include?(k) }
      res = interactor.update_bin_load(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:bin_load_purpose_id]
    end

    def test_delete_bin_load
      id = create_bin_load(add_product: false)
      assert_count_changed(:bin_loads, -1) do
        res = interactor.delete_bin_load(id)
        assert res.success, res.message
      end
    end

    private

    def bin_load_attrs
      bin_load_purpose_id = create_bin_load_purpose
      customer_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_CUSTOMER)
      transporter_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_TRANSPORTER)
      depot_id = create_depot

      {
        id: 1,
        bin_load_purpose_id: bin_load_purpose_id,
        customer_party_role_id: customer_party_role_id,
        transporter_party_role_id: transporter_party_role_id,
        dest_depot_id: depot_id,
        qty_bins: 1,
        shipped_at: '2010-01-01 12:00',
        shipped: false,
        completed_at: '2010-01-01 12:00',
        completed: false,
        active: true
      }
    end

    def fake_bin_load(overrides = {})
      BinLoad.new(bin_load_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= BinLoadInteractor.new(current_user, {}, {}, {})
    end
  end
end
