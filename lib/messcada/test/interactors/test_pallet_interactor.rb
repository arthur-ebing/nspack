# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MesscadaApp
  class TestPalletInteractor < MiniTestWithHooks
    # include MesscadaFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::FarmFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::LocationFactory
    include MasterfilesApp::PackagingFactory
    include MasterfilesApp::FruitFactory
    include ProductionApp::ResourceFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MesscadaApp::MesscadaRepo)
    end

    def test_pallet
      MesscadaApp::MesscadaRepo.any_instance.stubs(:find_pallet).returns(fake_pallet)
      entity = interactor.send(:pallet, 1)
      assert entity.is_a?(Pallet)
    end

    def test_pallet_flat
      MesscadaApp::MesscadaRepo.any_instance.stubs(:find_pallet_flat).returns(fake_pallet_flat)
      entity = interactor.send(:pallet_flat, 1)
      assert entity.is_a?(PalletFlat)
    end

    # def test_create_pallet
    #   attrs = fake_pallet.to_h.reject { |k, _| k == :id }
    #   res = interactor.create_pallet(attrs)
    #   assert res.success, "#{res.message} : #{res.errors.inspect}"
    #   assert_instance_of(Pallet, res.instance)
    #   assert res.instance.id.nonzero?
    # end
    #
    # def test_create_pallet_fail
    #   attrs = fake_pallet(pallet_number: nil).to_h.reject { |k, _| k == :id }
    #   res = interactor.create_pallet(attrs)
    #   refute res.success, 'should fail validation'
    #   assert_equal ['must be filled'], res.errors[:pallet_number]
    # end
    #
    # def test_update_pallet
    #   id = create_pallet
    #   attrs = interactor.send(:repo).find_hash(:pallets, id).reject { |k, _| k == :id }
    #   value = attrs[:pallet_number]
    #   attrs[:pallet_number] = 'a_change'
    #   res = interactor.update_pallet(id, attrs)
    #   assert res.success, "#{res.message} : #{res.errors.inspect}"
    #   assert_instance_of(Pallet, res.instance)
    #   assert_equal 'a_change', res.instance.pallet_number
    #   refute_equal value, res.instance.pallet_number
    # end
    #
    # def test_update_pallet_fail
    #   id = create_pallet
    #   attrs = interactor.send(:repo).find_hash(:pallets, id).reject { |k, _| %i[id pallet_number].include?(k) }
    #   res = interactor.update_pallet(id, attrs)
    #   refute res.success, "#{res.message} : #{res.errors.inspect}"
    #   assert_equal ['is missing'], res.errors[:pallet_number]
    # end
    #
    # def test_delete_pallet
    #   id = create_pallet
    #   assert_count_changed(:pallets, -1) do
    #     res = interactor.delete_pallet(id)
    #     assert res.success, res.message
    #   end
    # end

    private

    def pallet_attrs
      location_id = create_location
      pm_product_id1 = create_pm_product
      pm_product_id2 = create_pm_product
      pallet_format_id = create_pallet_format
      packhouse_resource_id = create_plant_resource
      line_resource_id = create_plant_resource
      plant_resource_id = create_plant_resource

      {
        id: 1,
        pallet_number: Faker::Lorem.unique.word,
        exit_ref: 'ABC',
        scrapped_at: '2010-01-01 12:00',
        location_id: location_id,
        shipped: false,
        in_stock: false,
        inspected: false,
        shipped_at: '2010-01-01 12:00',
        govt_first_inspection_at: '2010-01-01 12:00',
        govt_reinspection_at: '2010-01-01 12:00',
        last_govt_inspection_sheet_id: 1,
        stock_created_at: '2010-01-01 12:00',
        phc: 'ABC',
        intake_created_at: '2010-01-01 12:00',
        first_cold_storage_at: '2010-01-01 12:00',
        build_status: 'ABC',
        gross_weight: 1.0,
        gross_weight_measured_at: '2010-01-01 12:00',
        palletized: false,
        partially_palletized: false,
        palletized_at: '2010-01-01 12:00',
        partially_palletized_at: '2010-01-01 12:00',
        fruit_sticker_pm_product_id: pm_product_id1,
        allocated: false,
        allocated_at: '2010-01-01 12:00',
        reinspected: false,
        scrapped: false,
        pallet_format_id: pallet_format_id,
        carton_quantity: 1,
        govt_inspection_passed: false,
        plt_packhouse_resource_id: packhouse_resource_id,
        plt_line_resource_id: line_resource_id,
        nett_weight: 1.0,
        load_id: nil,
        fruit_sticker_pm_product_2_id: pm_product_id2,
        last_govt_inspection_pallet_id: 1,
        temp_tail: 'ABC',
        depot_pallet: false,
        edi_in_transaction_id: nil,
        edi_in_consignment_note_number: 'ABC',
        re_calculate_nett: false,
        edi_in_inspection_point: 'ABC',
        repacked: false,
        repacked_at: '2010-01-01 12:00',
        palletizing_bay_resource_id: plant_resource_id,
        has_individual_cartons: false,
        nett_weight_externally_calculated: false,
        target_customer: 'ABC',
        oldest_pallet_sequence_id: 1,
        pallet_sequence_ids: [1, 2, 3],
        active: true
      }
    end

    def fake_pallet(overrides = {})
      Pallet.new(pallet_attrs.merge(overrides))
    end

    def fake_pallet_flat(overrides = {})
      PalletFlat.new(pallet_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= MesscadaInteractor.new(current_user, {}, {}, {})
    end
  end
end
