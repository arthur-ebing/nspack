# frozen_string_literal: true

module Crossbeams
  class RobotResponder
    attr_accessor :display_lines, :extra_elements
    attr_reader :robot_feedback

    def initialize(robot_feedback)
      @robot_feedback = robot_feedback
      # raise if msg && any lines...

      @display_lines = AppConst::ROBOT_DISPLAY_LINES
      @display_lines = lookup_display_lines if @display_lines.zero?
      @extra_elements = {}
    end

    def render
      log_feedback
      log_confirmation

      if @display_lines == 4
        render_4_lines
      else
        render_6_lines
      end
    end

    def to_s
      if @display_lines == 4
        show_4_lines
      else
        show_6_lines
      end
    end

    private

    def log_feedback
      return unless AppConst::VERBOSE_ROBOT_FEEDBACK_LOGGING

      msgs = %i[msg short1 short2 short3 short4 line1 line2 line3 line4 line5 line6].map { |a| robot_feedback.send(a) }.compact.join('; ')
      puts "DEVICE: #{robot_feedback.device} RDR: #{robot_feedback.reader_id} FEEDBACK: #{msgs}"
    end

    def log_confirmation
      return unless AppConst::VERBOSE_ROBOT_FEEDBACK_LOGGING
      return if robot_feedback.confirm_text.nil?

      puts "CONFIRM: #{robot_feedback.confirm_text} - Y: #{robot_feedback.confirm_url} - N: #{robot_feedback.cancel_url}"
    end

    def lookup_display_lines
      MesscadaApp::MesscadaRepo.new.display_lines_for(@robot_feedback.device)
    end

    def long_message(msg)
      return msg if msg.nil_or_empty?

      if msg.to_s.include?(AppConst::ROBOT_MSG_SEP)
        msg.split(AppConst::ROBOT_MSG_SEP).first.sub('Validation error - ', '')
      else
        msg.to_s.sub('Validation error - ', '')
      end
    end

    def short_message(msg)
      return msg if msg.nil_or_empty?

      if msg.to_s.include?(AppConst::ROBOT_MSG_SEP)
        msg.split(AppConst::ROBOT_MSG_SEP).last.sub('Validation error - ', '')
      else
        msg.to_s.sub('Validation error - ', '')
      end
    end

    def render_4_lines
      line1, line2, line3, line4 = @robot_feedback.four_lines
      orange = @robot_feedback.orange || false
      <<~XML
        <robot_feedback>
          <status>#{@robot_feedback.status}</status>
          <red>#{@robot_feedback.red}</red>
          <green>#{@robot_feedback.green}</green>
          <orange>#{orange}</orange>
          <lcd1>#{short_message(@robot_feedback.msg || line1)}</lcd1>
          <lcd2>#{short_message(line2)}</lcd2>
          <lcd3>#{short_message(line3)}</lcd3>
          <lcd4>#{short_message(line4)}</lcd4>#{confirmation}#{extra_render}
        </robot_feedback>
      XML
    end

    def render_6_lines # rubocop:disable Metrics/AbcSize
      orange = @robot_feedback.orange || false
      <<~XML
        <robot_feedback>
          <status>#{@robot_feedback.status}</status>
          <red>#{@robot_feedback.red}</red>
          <green>#{@robot_feedback.green}</green>
          <orange>#{orange}</orange>
          <msg>#{long_message(@robot_feedback.msg)}</msg>
          <lcd1>#{long_message(@robot_feedback.line1)}</lcd1>
          <lcd2>#{long_message(@robot_feedback.line2)}</lcd2>
          <lcd3>#{long_message(@robot_feedback.line3)}</lcd3>
          <lcd4>#{long_message(@robot_feedback.line4)}</lcd4>
          <lcd5>#{long_message(@robot_feedback.line5)}</lcd5>
          <lcd6>#{long_message(@robot_feedback.line6)}</lcd6>#{confirmation}#{extra_render}
        </robot_feedback>
      XML
    end

    def show_4_lines
      line1, line2, line3, line4 = @robot_feedback.four_lines
      cnt = 0
      lines = [line1, line2, line3, line4].map do |l|
        cnt += 1
        txt = long_message(l)
        txt.nil? ? nil : "line#{cnt}: #{txt}"
      end.compact
      "robot feedback - status: #{@robot_feedback.status}, msg: #{long_message(@robot_feedback.msg)} #{lines.join(' ')}#{confirmation}#{extra_render}"
    end

    def show_6_lines
      cnt = 0
      lines = [@robot_feedback.line1, @robot_feedback.line2, @robot_feedback.line3, @robot_feedback.line4, @robot_feedback.line5, @robot_feedback.line6].map do |l|
        cnt += 1
        txt = long_message(l)
        txt.nil? ? nil : "line#{cnt}: #{txt}"
      end.compact
      "robot feedback - status: #{@robot_feedback.status}, msg: #{long_message(@robot_feedback.msg)} #{lines.join(' ')}#{confirmation}#{extra_render}"
    end

    def confirmation
      return '' unless @robot_feedback.confirm_text

      <<~XML
        \n  <confirm>
            <text>#{@robot_feedback.confirm_text}</text>
            <yes_url>#{@robot_feedback.yes_url}</yes_url>
            <no_url>#{@robot_feedback.no_url}</no_url>
          </confirm>
      XML
    end

    # Any key/values in the "extra_render" hash will be added to the XML as elements:
    # { a: 'b', c: 'd' } => <a>b</a><c>d</c>
    def extra_render
      return '' if extra_elements.empty?

      "\n  #{extra_elements.map { |e, v| "<#{e}>#{v}</#{e}>" }.join("\n  ")}"
    end
  end
end
