# frozen_string_literal: true

module Crossbeams
  class RobotResponder
    attr_accessor :display_lines

    def initialize(robot_feedback)
      @robot_feedback = robot_feedback
      # raise if msg && any lines...

      @display_lines = AppConst::ROBOT_DISPLAY_LINES
      @display_lines = lookup_display_lines if @display_lines.zero?
    end

    def render
      if @display_lines == 4
        render_4_lines
      else
        render_6_lines
      end
    end

    private

    def lookup_display_lines
      MesscadaApp::MesscadaRepo.new.display_lines_for(@robot_feedback.device)
    end

    def long_message(msg)
      return msg if msg.nil_or_empty?

      if msg.include?(AppConst::ROBOT_MSG_SEP)
        msg.split(AppConst::ROBOT_MSG_SEP).first
      else
        msg
      end
    end

    def short_message(msg)
      return msg if msg.nil_or_empty?

      if msg.include?(AppConst::ROBOT_MSG_SEP)
        msg.split(AppConst::ROBOT_MSG_SEP).last
      else
        msg
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
          <lcd4>#{short_message(line4)}</lcd4>#{confirmation}
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
          <lcd6>#{long_message(@robot_feedback.line6)}</lcd6>#{confirmation}
        </robot_feedback>
      XML
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
  end
end
