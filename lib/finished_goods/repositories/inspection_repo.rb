# frozen_string_literal: true

module FinishedGoodsApp
  class InspectionRepo < BaseRepo
    # INSPECTIONS
    # --------------------------------------------------------------------------
    build_for_select :inspections, abel: :remarks,  value: :id, order_by: :remarks
    build_inactive_select :inspections, label: :remarks, value: :id, order_by: :remarks
    crud_calls_for :inspections, name: :inspection, wrapper: Inspection, exclude: %i[create]

    def find_inspection(id)
      hash = find_with_association(:inspections, id,
                                   parent_tables: [{ parent_table: :inspection_types,
                                                     foreign_key: :inspection_type_id,
                                                     columns: [:inspection_type_code],
                                                     flatten_columns: { inspection_type_code: :inspection_type_code } },
                                                   { parent_table: :inspectors,
                                                     foreign_key: :inspector_id,
                                                     columns: [:inspector_party_role_id],
                                                     flatten_columns: { inspector_party_role_id: :inspector_party_role_id } }])
      return nil if hash.nil?

      hash[:inspector] = DB.get(Sequel.function(:fn_party_role_name, hash[:inspector_party_role_id]))
      hash[:inspected] = !hash[:inspector_id].nil?
      hash[:pallet_number] = get(:pallets, hash[:pallet_id], :pallet_number)
      hash[:failure_reasons] = select_values(:inspection_failure_reasons, :failure_reason, id: hash[:inspection_failure_reason_ids].to_a)

      Inspection.new(hash)
    end

    def create_inspection(params)
      pallet_id = get_id(:pallets, pallet_number: params[:pallet_number] || params)
      inspection_type_ids = select_values(:inspection_types, :id, active: true)

      ids = []
      inspection_type_ids.each do |inspection_type_id|
        args = { pallet_id: pallet_id, inspection_type_id: inspection_type_id }
        next if exists?(:inspections, args)

        id = create_inspection_for_tm_group(args)
        id ||= create_inspection_for_grades(args)
        id ||= create_inspection_for_cultivars(args)
        id ||= create_inspection_for_orchards(args)
        ids << id
      end
      ids
    end

    def create_inspection_for_tm_group(params)
      applies_to_all_tm_groups = get(:inspection_types, params[:inspection_type_id], :applies_to_all_tm_groups)
      return create(:inspections, params) if applies_to_all_tm_groups

      applicable_tm_group_ids = get(:inspection_types, params[:inspection_type_id], :applicable_tm_group_ids).to_a
      tm_group_ids = select_values(:pallet_sequences, :packed_tm_group_id, pallet_id: params[:pallet_id])
      create(:inspections, params) if tm_group_ids.any? { |tm_group_id| applicable_tm_group_ids.include?(tm_group_id) }
    end

    def create_inspection_for_grades(params)
      applies_to_all_grades = get(:inspection_types, params[:inspection_type_id], :applies_to_all_grades)
      return create(:inspections, params) if applies_to_all_grades

      applicable_grade_ids = get(:inspection_types, params[:inspection_type_id], :applicable_grade_ids).to_a
      grade_ids = select_values(:pallet_sequences, :grade_id, pallet_id: params[:pallet_id])
      create(:inspections, params) if grade_ids.any? { |grade_id| applicable_grade_ids.include?(grade_id) }
    end

    def create_inspection_for_cultivars(params)
      applies_to_all_cultivars = get(:inspection_types, params[:inspection_type_id], :applies_to_all_cultivars)
      return create(:inspections, params) if applies_to_all_cultivars

      applicable_cultivar_ids = get(:inspection_types, params[:inspection_type_id], :applicable_cultivar_ids).to_a
      cultivar_ids = select_values(:pallet_sequences, :cultivar_id, pallet_id: params[:pallet_id])
      create(:inspections, params) if cultivar_ids.any? { |cultivar_id| applicable_cultivar_ids.include?(cultivar_id) }
    end

    def create_inspection_for_orchards(params)
      applies_to_all_orchards = get(:inspection_types, params[:inspection_type_id], :applies_to_all_orchards)
      return create(:inspections, params) if applies_to_all_orchards

      applicable_orchard_ids = get(:inspection_types, params[:inspection_type_id], :applicable_orchard_ids).to_a
      orchard_ids = select_values(:pallet_sequences, :orchard_id, pallet_id: params[:pallet_id])
      create(:inspections, params) if orchard_ids.any? { |orchard_id| applicable_orchard_ids.include?(orchard_id) }
    end
  end
end
