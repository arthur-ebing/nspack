# frozen_string_literal: true

module Crossbeams
  class RobotResponder
    attr_accessor :display_lines

    def initialize(robot_feedback)
      @robot_feedback = robot_feedback
      # raise if msg && any lines...
      # get device capabilities from MesscadaRepo to decide if display is 4 or 6...
      # AppConst can override if all robots at installation are the same.
      @display_lines = display_lines
    end

    def render
      if @display_lines == 4
        render_4_lines
      else
        render_6_lines
      end
    end

    def render_4_lines
      line1, line2, line3, line4 = @robot_feedback.four_lines
      <<~XML
        <robot_feedback>
          <status>#{@robot_feedback.status}</status>
          <red>#{@robot_feedback.red}</red>
          <green>#{@robot_feedback.green}</green>
          <orange>false</orange>
          <lcd1>#{@robot_feedback.msg || line1}</lcd1>
          <lcd2>#{line2}</lcd2>
          <lcd3>#{line3}</lcd3>
          <lcd4>#{line4}</lcd4>
        </robot_feedback>
      XML
    end

    def render_6_lines
      <<~XML
        <robot_feedback>
          <status>#{@robot_feedback.status}</status>
          <red>#{@robot_feedback.red}</red>
          <green>#{@robot_feedback.green}</green>
          <orange>false</orange>
          <msg>#{@robot_feedback.msg}</msg>
          <lcd1>#{@robot_feedback.line1}</lcd1>
          <lcd2>#{@robot_feedback.line2}</lcd2>
          <lcd3>#{@robot_feedback.line3}</lcd3>
          <lcd4>#{@robot_feedback.line4}</lcd4>
          <lcd5>#{@robot_feedback.line5}</lcd5>
          <lcd6>#{@robot_feedback.line6}</lcd6>
        </robot_feedback>
      XML
    end
  end
end
