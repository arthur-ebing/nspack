# frozen_string_literal: true

module UiRules
  class OrchardTestResultDiffRule < Base
    def generate_rules
      @repo = QualityApp::OrchardTestRepo.new
      make_form_object
      apply_form_values

      set_diff_fields

      form_name 'orchard_test_result_diff'
    end

    def set_diff_fields
      if @mode == 'orchards'
        right_caption = 'Orchards'
        right_record = @repo.puc_orchard_cultivar('orchards')
      else
        right_caption = 'Pallet Sequences'
        right_record = @repo.puc_orchard_cultivar('pallet_sequences')
      end
      fields[:diff] = { left_caption: 'Phyto Data',
                        right_caption: right_caption,
                        left_record: @options[:phyto_res],
                        right_record: right_record }
    end

    def make_form_object
      @form_object = OpenStruct.new(diff: nil)
    end
  end
end
