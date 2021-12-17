# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module QualityApp
  class TestQcSampleInteractor < MiniTestWithHooks
    include QcFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(QualityApp::QcRepo)
    end

    def test_qc_sample
      QualityApp::QcRepo.any_instance.stubs(:find_qc_sample).returns(fake_qc_sample)
      entity = interactor.send(:qc_sample, 1)
      assert entity.is_a?(QcSample)
    end

    def test_create_qc_sample
      attrs = fake_qc_sample.to_h.reject { |k, _| k == :id }
      res = interactor.create_qc_sample(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(QcSample, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_qc_sample_fail
      attrs = fake_qc_sample(presort_run_lot_number: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_qc_sample(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:presort_run_lot_number]
    end

    def test_update_qc_sample
      id = create_qc_sample
      attrs = interactor.send(:repo).find_hash(:qc_samples, id).reject { |k, _| k == :id }
      value = attrs[:presort_run_lot_number]
      attrs[:presort_run_lot_number] = 'a_change'
      res = interactor.update_qc_sample(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(QcSample, res.instance)
      assert_equal 'a_change', res.instance.presort_run_lot_number
      refute_equal value, res.instance.presort_run_lot_number
    end

    def test_update_qc_sample_fail
      id = create_qc_sample
      attrs = interactor.send(:repo).find_hash(:qc_samples, id).reject { |k, _| %i[id presort_run_lot_number].include?(k) }
      res = interactor.update_qc_sample(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:presort_run_lot_number]
    end

    def test_delete_qc_sample
      id = create_qc_sample(force_create: true)
      assert_count_changed(:qc_samples, -1) do
        res = interactor.delete_qc_sample(id)
        assert res.success, res.message
      end
    end

    private

    def qc_sample_attrs
      qc_sample_type_id = create_qc_sample_type
      rmt_delivery_id = create_rmt_delivery
      location_id = create_location
      production_run_id = create_production_run
      orchard_id = create_orchard

      {
        id: 1,
        qc_sample_type_id: qc_sample_type_id,
        rmt_delivery_id: rmt_delivery_id,
        coldroom_location_id: location_id,
        production_run_id: production_run_id,
        orchard_id: orchard_id,
        presort_run_lot_number: Faker::Lorem.unique.word,
        ref_number: 'ABC',
        short_description: 'ABC',
        sample_size: 1,
        editing: false,
        completed: false,
        completed_at: '2010-01-01 12:00',
        drawn_at: '2010-01-01 12:00',
        rmt_bin_ids: [1, 2, 3]
      }
    end

    def fake_qc_sample(overrides = {})
      QcSample.new(qc_sample_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= QcSampleInteractor.new(current_user, {}, {}, {})
    end
  end
end
