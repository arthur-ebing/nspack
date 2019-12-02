# frozen_string_literal: true

module UiRules
  class ReworksRunSequenceRule < Base # rubocop:disable ClassLength
    def generate_rules
      @repo = ProductionApp::ReworksRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new

      make_form_object
      apply_form_values

      if @mode == :edit_production_run
        make_reworks_run_pallet_header_table
        set_edit_production_run_fields
      end

      set_pallet_sequence_fields if @mode == :edit_farm_details

      add_behaviours if %i[edit_production_run].include? @mode
      edit_farm_details_behaviours if %i[edit_farm_details].include? @mode

      form_name 'reworks_run_sequence'
    end

    def make_reworks_run_pallet_header_table
      compact_header(columns: %i[production_run_id packhouse line farm puc orchard cultivar_group cultivar],
                     display_columns: 4)
    end

    def set_edit_production_run_fields
      fields[:production_run_id] = { renderer: :select,
                                     options: ProductionApp::ReworksRepo.new.for_select_production_runs(@options[:old_production_run_id]),
                                     caption: 'Pdn Runs',
                                     prompt: 'Select New Pdn Run',
                                     searchable: true,
                                     remove_search_for_small_list: false }
      fields[:pallet_sequence_id] = { renderer: :hidden }
      fields[:old_production_run_id] = { renderer: :hidden }
      fields[:reworks_run_type_id] = { renderer: :hidden }
    end

    def set_pallet_sequence_fields  # rubocop:disable Metrics/AbcSize
      cultivar_group_id_label = @cultivar_repo.find_cultivar_group(@form_object.cultivar_group_id)&.cultivar_group_code
      pucs = if @form_object.farm_id.nil_or_empty?
               []
             else
               @farm_repo.selected_farm_pucs(@form_object.farm_id)
             end
      orchards = if @form_object.farm_id.nil_or_empty? || @form_object.puc_id.nil_or_empty?
                   []
                 else
                   @farm_repo.selected_farm_orchard_codes(@form_object.farm_id, @form_object.puc_id)
                 end
      fields[:pallet_sequence_id] = { renderer: :hidden }
      fields[:reworks_run_type_id] = { renderer: :hidden }
      fields[:farm_id] = { renderer: :select,
                           options: @farm_repo.for_select_farms,
                           disabled_options: @farm_repo.for_select_inactive_farms,
                           caption: 'Farm',
                           prompt: true,
                           required: true }
      fields[:puc_id] = { renderer: :select,
                          options: pucs,
                          disabled_options: @farm_repo.for_select_inactive_pucs,
                          caption: 'Puc',
                          required: true }
      fields[:orchard_id] = { renderer: :select,
                              options: orchards,
                              disabled_options: @farm_repo.for_select_inactive_orchards,
                              caption: 'Orchard' }
      fields[:cultivar_group_id] = { renderer: :hidden }
      fields[:cultivar_group] = { renderer: :label,
                                  with_value: cultivar_group_id_label,
                                  caption: 'Cultivar Group' }
      fields[:cultivar_id] = { renderer: :select,
                               options: @cultivar_repo.for_select_cultivars(where: { cultivar_group_id: @form_object.cultivar_group_id }),
                               disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_cultivars,
                               caption: 'Cultivar' }
      fields[:season_id] = { renderer: :select,
                             options: MasterfilesApp::CalendarRepo.new.for_select_seasons_for_cultivar_group(@form_object.cultivar_group_id),
                             disabled_options: MasterfilesApp::CalendarRepo.new.for_select_inactive_seasons,
                             caption: 'Season',
                             required: true }
    end

    def make_form_object
      if @mode == :edit_farm_details
        make_pallet_sequence_form_object
        return
      end

      @form_object = OpenStruct.new(reworks_run_sequence_data(@options[:pallet_sequence_id]).to_h.merge(pallet_sequence_id: @options[:pallet_sequence_id],
                                                                                                        reworks_run_type_id: @options[:reworks_run_type_id],
                                                                                                        old_production_run_id: @options[:old_production_run_id]))
    end

    def make_pallet_sequence_form_object
      res = ProductionApp::ReworksRepo.new.where_hash(:pallet_sequences, id: @options[:pallet_sequence_id])
      @form_object = OpenStruct.new(farm_id: res[:farm_id],
                                    puc_id: res[:puc_id],
                                    orchard_id: res[:orchard_id],
                                    cultivar_group_id: res[:cultivar_group_id],
                                    cultivar_id: res[:cultivar_id],
                                    season_id: res[:season_id],
                                    pallet_sequence_id: @options[:pallet_sequence_id],
                                    reworks_run_type_id: @options[:reworks_run_type_id])
    end

    def reworks_run_sequence_data(id)
      @repo.reworks_run_pallet_seq_data(id)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :production_run_id,
                                  notify: [{ url: "/production/reworks/pallet_sequences/#{@options[:pallet_sequence_id]}/production_run_changed" }]
      end
    end

    def edit_farm_details_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :farm_id,
                                  notify: [{ url: "/production/reworks/pallet_sequences/#{@options[:pallet_sequence_id]}/farm_changed" }]
        behaviour.dropdown_change :puc_id,
                                  notify: [{ url: "/production/reworks/pallet_sequences/#{@options[:pallet_sequence_id]}/puc_changed",
                                             param_keys: %i[reworks_run_sequence_farm_id] }]
        behaviour.dropdown_change :orchard_id,
                                  notify: [{ url: "/production/reworks/pallet_sequences/#{@options[:pallet_sequence_id]}/orchard_changed",
                                             param_keys: %i[reworks_run_sequence_cultivar_group_id] }]
      end
    end
  end
end
