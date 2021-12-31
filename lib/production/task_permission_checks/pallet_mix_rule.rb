# frozen_string_literal: true

module ProductionApp
  module TaskPermissionCheck
    class PalletMixRule < BaseService
      attr_reader :task, :repo, :rule, :new_sequence, :oldest_sequence, :carton_number

      def initialize(scope, new_sequence, oldest_sequence, carton_number)
        @repo = ProductionRunRepo.new
        @new_sequence = new_sequence
        @carton_number = carton_number
        @oldest_sequence = oldest_sequence
        cond = { scope: scope }
        cond = { packhouse_plant_resource_id: oldest_sequence[:packhouse_resource_id] } if scope == AppConst::PALLETIZING_BAYS_PALLET_MIX
        @rule = repo.all_hash(:pallet_mix_rules, cond).first
      end

      CHECKS = {
        mix_tm_group: :mix_tm_group_check,
        mix_grade: :mix_grade_check,
        mix_mark: :mix_mark_check,
        mix_size_ref: :mix_size_ref_check,
        mix_pack: :mix_pack_check,
        mix_size_count: :mix_size_count_check,
        mix_inventory: :mix_inventory_check,
        mix_cultivar: :mix_cultivar_check,
        mix_cultivar_group: :mix_cultivar_group_check,
        mix_puc: :mix_puc_check,
        mix_orchard: :mix_orchard_check
      }.freeze

      def call
        return failed_response 'Pallet Mix Rule record not found' unless @rule

        CHECKS.each_key do |task|
          check = CHECKS[task]
          raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}." if check.nil?

          res = send(check)
          return res unless res.success
        end
        all_ok
      end

      private

      def error(mix_type, orig, new)
        # PALLETIZING_BAYS error format
        return failed_response('mix_rule error', { mix_rule_error: true, carton_number: carton_number.to_s, rule_column: mix_type.to_s.upcase, new_value: new, old_value: orig }) if @rule[:scope] == AppConst::PALLETIZING_BAYS_PALLET_MIX

        # BUILDUP error format
        failed_response(format('Pallet %<mt1>s: %<orig>s. You are adding a sequence with %<mt2>s: %<new>s. Mixing is not allowed', mt1: mix_type, orig: orig, mt2: mix_type, new: new))
      end

      def mix_tm_group_check
        return ok_response if rule[:allow_tm_mix]
        return ok_response if new_sequence[:packed_tm_group_id] == oldest_sequence[:packed_tm_group_id]

        new = repo.get(:target_market_groups, :target_market_group_name, new_sequence[:packed_tm_group_id])
        error('tm_group', oldest_sequence[:target_market_group_name], new)
      end

      def mix_grade_check
        return ok_response if rule[:allow_grade_mix]
        return ok_response if new_sequence[:grade_id] == oldest_sequence[:grade_id]

        new = repo.get(:grades, :grade_code, new_sequence[:grade_id])
        error('grade', oldest_sequence[:grade_code], new)
      end

      def mix_mark_check
        return ok_response if rule[:allow_mark_mix]
        return ok_response if new_sequence[:mark_id] == oldest_sequence[:mark_id]

        new = repo.get(:marks, :mark_code, new_sequence[:mark_id])
        error('mark', oldest_sequence[:mark_code], new)
      end

      def mix_size_ref_check
        return ok_response if rule[:allow_size_ref_mix]
        return ok_response if new_sequence[:fruit_size_reference_id] == oldest_sequence[:fruit_size_reference_id]

        new = repo.get(:fruit_size_references, :size_reference, new_sequence[:fruit_size_reference_id])
        error('size_ref', oldest_sequence[:size_reference], new)
      end

      def mix_pack_check
        return ok_response if rule[:allow_pack_mix]
        return ok_response if new_sequence[:standard_pack_code_id] == oldest_sequence[:standard_pack_code_id]

        new = repo.get(:standard_pack_codes, :standard_pack_code, new_sequence[:standard_pack_code_id])
        error('pack', oldest_sequence[:standard_pack_code], new)
      end

      def mix_size_count_check
        return ok_response if rule[:allow_std_count_mix]
        return ok_response if new_sequence[:std_fruit_size_count_id] == oldest_sequence[:std_fruit_size_count_id]

        new = repo.get(:std_fruit_size_counts, :size_count_value, new_sequence[:std_fruit_size_count_id])
        error('size_count', oldest_sequence[:size_count_value], new)
      end

      def mix_inventory_check
        return ok_response if rule[:allow_inventory_code_mix]
        return ok_response if new_sequence[:inventory_code_id] == oldest_sequence[:inventory_code_id]

        new = repo.get(:inventory_codes, :inventory_code, new_sequence[:inventory_code_id])
        error('inventory', oldest_sequence[:inventory_code], new)
      end

      def mix_cultivar_check
        return ok_response if rule[:allow_cultivar_mix]
        return ok_response if new_sequence[:cultivar_id] == oldest_sequence[:cultivar_id]

        new = repo.get(:cultivars, :cultivar_name, new_sequence[:cultivar_id])
        error('cultivar', oldest_sequence[:cultivar_name], new)
      end

      def mix_cultivar_group_check
        return ok_response if rule[:allow_cultivar_group_mix]
        return ok_response if new_sequence[:cultivar_group_id] == oldest_sequence[:cultivar_group_id]

        new = repo.get(:cultivar_groups, :cultivar_group_code, new_sequence[:cultivar_group_id])
        error('cultivar_group', oldest_sequence[:cultivar_group_code], new)
      end

      def mix_puc_check
        return ok_response if rule[:allow_puc_mix]
        return ok_response if new_sequence[:puc_id] == oldest_sequence[:puc_id]

        new = repo.get(:pucs, :puc_code, new_sequence[:puc_id])
        error('puc', oldest_sequence[:puc_code], new)
      end

      def mix_orchard_check
        return ok_response if rule[:allow_orchard_mix]
        return ok_response if new_sequence[:orchard_id] == oldest_sequence[:orchard_id]

        new = repo.get(:orchards, :orchard_code, new_sequence[:orchard_id])
        error('orchard', oldest_sequence[:orchard_code], new)
      end
    end
  end
end
