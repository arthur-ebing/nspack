require File.join(File.expand_path('./../', __FILE__), 'test_helper')

class TestRobotResponder < Minitest::Test

  def test_render
    exp = <<~XML
        <robot_feedback>
          <status>true</status>
          <red>false</red>
          <green>true</green>
          <orange>false</orange>
          <msg></msg>
          <lcd1>1</lcd1>
          <lcd2>2</lcd2>
          <lcd3>3</lcd3>
          <lcd4>4</lcd4>
          <lcd5>5</lcd5>
          <lcd6>6</lcd6>
        </robot_feedback>
    XML
    ent = MesscadaApp::RobotFeedback.new(device: 'CLM-01',
                                         status: true,
                                         line1: '1',
                                         line2: '2',
                                         line3: '3',
                                         line4: '4',
                                         line5: '5',
                                         line6: '6')
    responder = Crossbeams::RobotResponder.new(ent)
    responder.display_lines = 6
    assert_equal exp, responder.render
  end
end
