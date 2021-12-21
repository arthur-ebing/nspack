# frozen_string_literal: true

module RawMaterialsApp
  class  SeasonalDeliveryQcSamples < BaseService
    attr_reader :repo, :rmt_delivery_id, :response

    def initialize(rmt_delivery_id)
      @rmt_delivery_id = rmt_delivery_id
      @repo = QualityApp::QcRepo.new
    end

    def call
      qc_fruit = repo.get_value(:qc_sample_types, :required_for_first_orchard_delivery, qc_sample_type_name: AppConst::QC_SAMPLE_100_FRUIT)
      qc_prog = repo.get_value(:qc_sample_types, :required_for_first_orchard_delivery, qc_sample_type_name: AppConst::QC_SAMPLE_PROGRESSIVE)
      hash = { AppConst::QC_SAMPLE_100_FRUIT => { required: qc_fruit }, AppConst::QC_SAMPLE_PROGRESSIVE => { required: qc_prog } }
      hash[AppConst::QC_SAMPLE_100_FRUIT][:has_test] = existing_test_for?(AppConst::QC_SAMPLE_100_FRUIT) if qc_fruit
      hash[AppConst::QC_SAMPLE_PROGRESSIVE][:has_test] = existing_test_for?(AppConst::QC_SAMPLE_PROGRESSIVE) if qc_prog
      Responder.new(hash)
    end

    private

    def existing_test_for?(sample_type)
      # Check season + cultivar + orchard
      repo.rmt_delivery_has_first_sample?(rmt_delivery_id, sample_type)
    end

    class Responder
      attr_reader :tests_state

      def initialize(tests_state)
        @tests_state = tests_state
      end

      def first_test_outstanding?
        tests_state.any? { |_, v| v[:required] && !v[:has_test] }
      end

      def need_to_make_a_sample?(type)
        raise ArgumentError, "Invalid sample type: #{type}" unless [AppConst::QC_SAMPLE_100_FRUIT, AppConst::QC_SAMPLE_PROGRESSIVE].include?(type)

        return true unless tests_state[type][:required]
        return true unless tests_state[type][:has_test]

        false
      end
    end
  end
end
