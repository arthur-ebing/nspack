# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MesscadaApp
  class TestRobotFeedback < Minitest::Test
    def test_red_and_green
      assert_raises(Dry::Struct::Error) { RobotFeedback.new(device: 'CLM-01') }

      ent = RobotFeedback.new(device: 'CLM-01', status: true)
      assert ent.green
      refute ent.red

      ent = RobotFeedback.new(device: 'CLM-01', status: false)
      assert ent.red
      refute ent.green
    end

    # rubocop:disable Style/WordArray
    def test_4_line_permutations
      [
        { actual: ['1', '2', '3', '4', nil, nil], expect: ['1', '2', '3', '4'] },
        { actual: ['1', '2', '3', '4', '5', '6'], expect: ['1', '2', '3 4', '5 6'] },
        { actual: ['1', '2', '3', '4', nil, '6'], expect: ['1', '2', '3', '4 6'] },
        { actual: ['1', nil, '3', '4', '5', '6'], expect: ['1', '3', '4', '5 6'] },
        { actual: ['1', nil, '3', '4', nil, nil], expect: ['1', nil, '3', '4'] }
      ].each do |tst|
        act = tst[:actual]
        exp = tst[:expect]
        ent = RobotFeedback.new(device: 'CLM-01',
                                status: true,
                                line1: act[0],
                                line2: act[1],
                                line3: act[2],
                                line4: act[3],
                                line5: act[4],
                                line6: act[5])
        assert_equal exp, ent.four_line
      end
    end
    # rubocop:enable Style/WordArray
  end
end
