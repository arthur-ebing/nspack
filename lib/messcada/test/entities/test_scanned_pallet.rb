# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MesscadaApp
  class TestScannedPallet < Minitest::Test
    def test_valid_9_18
      scans = %w[
        123456789012345678
        eighteencharacters
        123456789
        ninechars
      ]
      scans.each do |scan|
        ent = ScannedPalletNumber.new(scanned_pallet_number: scan)
        assert_equal scan, ent.pallet_number
      end
    end

    def test_11
      scans = {
        '46ninechars' => 'ninechars',
        '47ninechars' => 'ninechars',
        '48ninechars' => 'ninechars',
        '49ninechars' => 'ninechars'
      }
      scans.each do |scan, expect|
        ent = ScannedPalletNumber.new(scanned_pallet_number: scan)
        assert_equal expect, ent.pallet_number
      end

      assert_raises Crossbeams::InfoError do
        ent = ScannedPalletNumber.new(scanned_pallet_number: '50ninechars')
        ent.pallet_number
      end
    end

    def test_15
      scans = {
        ']C3456ninechars' => 'ninechars'
      }
      scans.each do |scan, expect|
        ent = ScannedPalletNumber.new(scanned_pallet_number: scan)
        assert_equal expect, ent.pallet_number
      end

      assert_raises Crossbeams::InfoError do
        ent = ScannedPalletNumber.new(scanned_pallet_number: 'othersninechars')
        ent.pallet_number
      end
    end

    def test_19_with_0
      scans = {
        '0123456789012345678' => '123456789012345678',
        '0eighteencharacters' => 'eighteencharacters'
      }
      scans.each do |scan, expect|
        ent = ScannedPalletNumber.new(scanned_pallet_number: scan)
        assert_equal expect, ent.pallet_number
      end

      assert_raises Crossbeams::InfoError do
        ent = ScannedPalletNumber.new(scanned_pallet_number: '4123456789012345678')
        ent.pallet_number
      end

      assert_raises Crossbeams::InfoError do
        ent = ScannedPalletNumber.new(scanned_pallet_number: 'notstartingwithzero')
        ent.pallet_number
      end
    end

    def test_20_21_23
      scans = {
        '99123456789012345678' => '123456789012345678',    # 20
        '99eighteencharacters' => 'eighteencharacters',    # 20
        '999123456789012345678' => '123456789012345678',   # 21
        '99999123456789012345678' => '123456789012345678'  # 23
      }
      scans.each do |scan, expect|
        ent = ScannedPalletNumber.new(scanned_pallet_number: scan)
        assert_equal expect, ent.pallet_number
      end
    end

    def test_invalid_lengths
      scans = %w[
        tooshort
        17_characters_pal
        22_characters_palletno
      ]
      scans.each do |scan|
        assert_raises Crossbeams::InfoError do
          ent = ScannedPalletNumber.new(scanned_pallet_number: scan)
          ent.pallet_number
        end
      end
    end
  end
end
