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
        start_hr = attrs[:start_hour]
        end_hr = attrs[:end_hour]
        similar_shift_type_hours = @repo.similar_shift_type_hours(attrs)

        values = []
        similar_shift_type_hours.each do |set|
          st = set[:start_hour]
          ed = set[:end_hour]
          values << st
          values << ed
          ed -= 1
          st += 1

          return failed_response('Start hour overlaps current time slot') if (st..ed).include?(start_hr)
          return failed_response('End hour overlaps current time slot') if (st..ed).include?(end_hr)
        end

        values.uniq.each do |val|
          return failed_response('Time slot overlaps current time slot') if (start_hr + 1..end_hr - 1).include?(val)
        end

        success_response('Valid shift type', attrs)
      end
    end
  end
end
