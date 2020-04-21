# frozen_string_literal: true

module MesscadaApp
  class RobotFeedback < Dry::Struct
    attribute :device, Types::String
    attribute :status, Types::Bool
    attribute? :orange, Types::Bool
    attribute? :msg, Types::String
    attribute? :line1, Types::String
    attribute? :line2, Types::String
    attribute? :line3, Types::String
    attribute? :line4, Types::String
    attribute? :line5, Types::String
    attribute? :line6, Types::String
    attribute? :short1, Types::String
    attribute? :short2, Types::String
    attribute? :short3, Types::String
    attribute? :short4, Types::String
    attribute? :reader_id, Types::String

    def red
      !status
    end

    def green
      status
    end

    # Re-work lines to fit a device only capable of 4 lines of text display.
    def four_lines # rubocop:disable Metrics/AbcSize
      return [short1, short2, short3, short4] unless [short1, short2, short3, short4].all?(&:nil_or_empty?)
      return [line1, line2, line3, line4] if line5.nil_or_empty? && line6.nil_or_empty?

      ar = [line1, line2, line3, line4, line5, line6].compact
      return ar if ar.length < 5

      if ar.length == 6
        [line1, line2, "#{line3} #{line4}", "#{line5} #{line6}"]
      else
        [ar[0], ar[1], ar[2], "#{ar[3]} #{ar[4]}"]
      end
    end
  end
end
