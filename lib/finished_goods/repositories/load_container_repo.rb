# frozen_string_literal: true

module FinishedGoodsApp
  class LoadContainerRepo < BaseRepo
    build_for_select :load_containers,
                     label: :container_code,
                     value: :id,
                     order_by: :container_code
    build_for_select :container_stack_types,
                     label: :stack_type_code,
                     value: :id,
                     order_by: :stack_type_code

    build_inactive_select :load_containers,
                          label: :container_code,
                          value: :id,
                          order_by: :container_code
    build_inactive_select :container_stack_types,
                          label: :stack_type_code,
                          value: :id,
                          order_by: :stack_type_code

    crud_calls_for :load_containers, name: :load_container, wrapper: LoadContainer

    def find_stack_type_id(stack_type_code)
      DB[:container_stack_types].where(stack_type_code: stack_type_code).get(:id)
    end

    def find_load_container_from(load_id:)
      DB[:load_containers].where(load_id: load_id).get(:id)
    end

    def actual_payload_from(load_id:)
      ds = DB[:pallets].where(load_id: load_id)
      return failed_response('pallets without weight', ds.where(nett_weight: nil).select_map(:pallet_number)) if ds.select_map(:nett_weight).any?(&:nil?)

      success_response('ok', ds.select_map(:nett_weight).sum)
    end
  end
end
