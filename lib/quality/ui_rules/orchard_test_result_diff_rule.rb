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

    def set_diff_fields # rubocop:disable Metrics/AbcSize
      if @mode == :orchards
        right_caption = 'Orchards'
        puc_ids = @repo.select_values(:orchards, :puc_id).uniq
        id_arrays = @repo.select_values(:orchards, %i[puc_id id cultivar_ids], puc_id: puc_ids).uniq
      else
        right_caption = 'Pallet Sequences'
        puc_ids = @repo.select_values(:pallet_sequences, :puc_id).uniq
        id_arrays = @repo.select_values(:pallet_sequences, %i[puc_id orchard_id cultivar_id], puc_id: puc_ids).uniq
      end

      nspack = @repo.puc_orchard_cultivar(id_arrays)

      res = QualityApp::PhytCleanOrchardDiff.call(puc_ids)
      phyto = res.success ? res.instance.slice(*nspack.keys) : { 'error': res.message }

      fields[:header] = { left_caption: 'Phyto Data',
                          right_caption: right_caption,
                          left_record: phyto,
                          right_record: nspack }
    end

    def make_form_object
      @form_object = OpenStruct.new(header: nil)
    end
  end
end
