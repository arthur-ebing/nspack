# frozen_string_literal: true

module MesscadaApp
  class ParseString < BaseService
    attr_reader :parse_string

    def initialize(parse_string)
      @parse_string = parse_string
    end

    def call
      array = UtilityFunctions.parse_string_to_array(parse_string)
      return failed_response('Validation empty.') if array.empty?

      errors = UtilityFunctions.non_numeric_elements(array)
      return failed_response "#{errors.join(', ')} must be numeric." unless errors.empty?

      success_response('Parsed successfully', array)
    end
  end
end
