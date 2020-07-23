# frozen_string_literal: true

module MasterfilesApp
  module HumanResources
    class Validator
      include Crossbeams::Responses
      def initialize
        @repo = HumanResourcesRepo.new
      end

      def validate_shift_type_params(params)
        res = ShiftTypeSchema.call(params)
        return validation_failed_response(res) unless res.messages.empty?

        validate_shift_type(res.to_h)
      end

      def validate_shift_type(attrs) # rubocop:disable Metrics/AbcSize
        return success_response('Valid shift type', attrs) if custom_shift_type?(attrs)

        start_hr = attrs[:start_hour]
        end_hr = attrs[:end_hour]
        similar_shift_type_hours = @repo.similar_shift_type_hours(attrs)

        values = []
        similar_shift_type_hours.each do |set|
          st = set[:start_hour]
          ed = set[:end_hour]
          values << st
          values << ed

          range = time_range(st + 1, ed - 1)
          return failed_response('Start hour overlaps current time slot') if range.include?(start_hr)
          return failed_response('End hour overlaps current time slot') if range.include?(end_hr)
        end

        range = time_range(start_hr + 1, end_hr - 1)
        values.uniq.each do |val|
          return failed_response('Time slot overlaps current time slot') if range.include?(val)
        end

        success_response('Valid shift type', attrs)
      end

      def custom_shift_type?(attrs)
        attrs[:day_night_or_custom] == 'C'
      end

      def time_range(start_hr, end_hr)
        cycle = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
                 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23]
        start_index = cycle.find_index(start_hr)
        sub_cycle = cycle[start_index..-1]
        end_index = sub_cycle.find_index(end_hr)
        sub_cycle[0..end_index]
      end

      def validate_shift_type_ids(params)
        res = ShiftTypeIdsSchema.call(params)
        res.messages.empty? ? res : validation_failed_response(res)
      end
    end
  end
end
