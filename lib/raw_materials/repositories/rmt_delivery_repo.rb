# frozen_string_literal: true

module RawMaterialsApp
  class RmtDeliveryRepo < BaseRepo
    build_for_select :rmt_deliveries,
                     label: :truck_registration_number,
                     value: :id,
                     order_by: :truck_registration_number
    build_inactive_select :rmt_deliveries,
                          label: :truck_registration_number,
                          value: :id,
                          order_by: :truck_registration_number

    build_for_select :rmt_bins,
                     label: :status,
                     value: :id,
                     order_by: :status
    build_inactive_select :rmt_bins,
                          label: :status,
                          value: :id,
                          order_by: :status

    crud_calls_for :rmt_deliveries, name: :rmt_delivery, wrapper: RmtDelivery
    crud_calls_for :rmt_bins, name: :rmt_bin, wrapper: RmtBin

    def farm_pucs(farm_id)
      DB[:pucs].where(id: DB[:farms_pucs].where(farm_id: farm_id).select(:puc_id)).map { |p| [p[:puc_code], p[:id]] }
    end

    def orchard_cultivars(orchard_id)
      DB["SELECT cultivars.*
         FROM cultivars
         JOIN orchards ON cultivars.id = ANY (orchards.cultivar_ids)
         WHERE orchards.id = ?", orchard_id].map { |o| [o[:cultivar_name], o[:id]] }
    end

    def rmt_delivery_season(cultivar_id, date_delivered)
      hash = DB["SELECT s.*
         FROM seasons s
          JOIN cultivars c on c.commodity_id=s.commodity_id
         WHERE c.id = #{cultivar_id} and '#{date_delivered}' between start_date and end_date"].first
      return nil if hash.nil?

      hash[:id]
    end

    def orchards(farm_id, puc_id)
      DB[:orchards].where(farm_id: farm_id, puc_id: puc_id).map { |o| [o[:orchard_code], o[:id]] }
    end

    def cultivar_by_delivery_id(delivery_id)
      DB[:cultivars].where(id: DB[:rmt_deliveries].where(id: delivery_id).select(:cultivar_id)).map { |p| p[:id] }.first
    end

    def orchard_by_delivery_id(delivery_id)
      DB[:orchards].where(id: DB[:rmt_deliveries].where(id: delivery_id).select(:orchard_id)).map { |p| p[:id] }.first
    end

    def rmt_container_type_by_container_type_code(container_type_code)
      DB[:rmt_container_types].where(container_type_code: container_type_code).first
    end

    def rmt_container_type_rmt_inner_container_type(container_type_id)
      DB[:rmt_container_types].where(id: container_type_id).map { |r| r[:rmt_inner_container_type_id] }.first
    end

    def default_farm_puc
      default_farm = AppConst::DELIVERY_DEFAULT_FARM
      return { farm_id: nil, puc_id: nil } if default_farm.nil?

      farm_pucs = DB[:farms_pucs].where(farm_id: DB[:farms].where(farm_code: default_farm).select(:id)).all
      return farm_pucs[0] if farm_pucs.length == 1

      { farm_id: farm_pucs[0][:farm_id], puc_id: nil }
    end

    # TO DO: Should this be OR are only dealing with organizations????
    # LEFT OUTER JOIN people p ON p.id = pr.person_id
    def find_container_material_owners_by_container_material_type(container_material_type_id)
      DB["SELECT co.id, COALESCE(o.short_description ||' - ' || r.name, p.first_name || ' ' || p.surname ||' - ' || r.name) AS party_name
          FROM rmt_container_material_owners co
          JOIN party_roles pr on pr.id=co.rmt_material_owner_party_role_id
          LEFT OUTER JOIN organizations o ON o.id = pr.organization_id
          LEFT OUTER JOIN people p ON p.id = pr.person_id
          LEFT OUTER JOIN roles r ON r.id = pr.role_id
          WHERE co.rmt_container_material_type_id = ?", container_material_type_id].map { |o| [o[:party_name], o[:id]] }
    end

    def find_rmt_container_material_owner(id)
      DB["SELECT co.id, COALESCE(o.short_description ||' - ' || r.name, p.first_name || ' ' || p.surname ||' - ' || r.name) AS container_material_owner
          FROM rmt_container_material_owners co
          JOIN party_roles pr on pr.id=co.rmt_material_owner_party_role_id
          LEFT OUTER JOIN organizations o ON o.id = pr.organization_id
          LEFT OUTER JOIN people p ON p.id = pr.person_id
          LEFT OUTER JOIN roles r ON r.id = pr.role_id
          WHERE co.id = ?", id].first
    end

    def find_rmt_delivery_by_bin_id(id)
      OpenStruct.new DB[:rmt_deliveries].where(id: DB[:rmt_bins].where(id: id).select(:rmt_delivery_id)).first
    end
  end
end
