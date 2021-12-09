# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestPresortGrowerGradingBinInteractor < MiniTestWithHooks
    include PresortGrowerGradingFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::PartyFactory
    include RawMaterialsApp::RmtBinFactory
    include MasterfilesApp::FarmFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(RawMaterialsApp::PresortGrowerGradingRepo)
    end

    def test_presort_grower_grading_bin
      RawMaterialsApp::PresortGrowerGradingRepo.any_instance.stubs(:find_presort_grower_grading_bin).returns(fake_presort_grower_grading_bin)
      entity = interactor.send(:presort_grower_grading_bin, 1)
      assert entity.is_a?(PresortGrowerGradingBin)
    end

    def test_create_presort_grower_grading_bin
      attrs = fake_presort_grower_grading_bin.to_h.reject { |k, _| k == :id }
      res = interactor.create_presort_grower_grading_bin(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PresortGrowerGradingBinFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_presort_grower_grading_bin_fail
      attrs = fake_presort_grower_grading_bin(farm_id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_presort_grower_grading_bin(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:farm_id]
    end

    def test_update_presort_grower_grading_bin
      id = create_presort_grower_grading_bin
      attrs = interactor.send(:repo).find_hash(:presort_grower_grading_bins, id).reject { |k, _| k == :id }
      value = attrs[:maf_count]
      attrs[:maf_count] = 'a_change'
      res = interactor.update_presort_grower_grading_bin(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PresortGrowerGradingBinFlat, res.instance)
      assert_equal 'a_change', res.instance.maf_count
      refute_equal value, res.instance.maf_count
    end

    def test_update_presort_grower_grading_bin_fail
      id = create_presort_grower_grading_bin
      attrs = interactor.send(:repo).find_hash(:presort_grower_grading_bins, id).reject { |k, _| %i[id maf_weight].include?(k) }
      res = interactor.update_presort_grower_grading_bin(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:maf_weight]
    end

    def test_delete_presort_grower_grading_bin
      id = create_presort_grower_grading_bin(force_create: true)
      assert_count_changed(:presort_grower_grading_bins, -1) do
        res = interactor.delete_presort_grower_grading_bin(id)
        assert res.success, res.message
      end
    end

    private

    def presort_grower_grading_bin_attrs
      presort_grower_grading_pool_id = create_presort_grower_grading_pool
      farm_id = create_farm
      rmt_class_id = create_rmt_class
      rmt_size_id = create_rmt_size

      {
        id: 1,
        presort_grower_grading_pool_id: presort_grower_grading_pool_id,
        farm_id: farm_id,
        rmt_class_id: rmt_class_id,
        rmt_size_id: rmt_size_id,
        maf_rmt_code: Faker::Lorem.unique.word,
        maf_article: 'ABC',
        maf_class: 'ABC',
        maf_colour: 'ABC',
        maf_count: 'ABC',
        maf_article_count: 'ABC',
        maf_weight: 1.0,
        maf_tipped_quantity: 1,
        maf_total_lot_weight: 1.0,
        created_by: 'ABC',
        updated_by: 'ABC',
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
    end

    def fake_presort_grower_grading_bin(overrides = {})
      PresortGrowerGradingBin.new(presort_grower_grading_bin_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PresortGrowerGradingBinInteractor.new(current_user, {}, {}, {})
    end
  end
end
