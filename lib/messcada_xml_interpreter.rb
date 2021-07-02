# frozen_string_literal: true

class MesscadaXMLInterpreter
  attr_reader :schema

  def initialize(request_or_string, as_string: false)
    @schema = if as_string
                puts "MESSCADA XML - received: #{request_or_string}"
                Nokogiri::XML(request_or_string)
              else
                s = request_or_string.body.gets
                puts "MESSCADA XML - received: #{s}"
                Nokogiri::XML(s)
              end
  end

  def list_input_attributes
    # Take XML fragment and list all attributes as key/value pairs...
    puts schema.children.first.node_name
    puts schema.children.first.attributes.map { |k, v| "#{k} = #{v.value}" }.join("\n")
  end

  def params_for_login_mode_switch
    # <XMLData device="LBL-3A" />
    root = 'XMLData'
    validate_root_and_attributes(root)
    device = schema.xpath(".//#{root}").attribute('device').value
    { device: device }
  end

  # def params_for_packer_role
  #   # <XMLData device="LBL-3A" identifier="1234" role="Pakker" />
  #   root = 'XMLData'
  #   validate_root_and_attributes(root)
  #   device = schema.xpath(".//#{root}").attribute('device').value
  #   identifier = schema.xpath(".//#{root}").attribute('identifier').value
  #   role = schema.xpath(".//#{root}").attribute('role').value
  #   { device: device, identifier: identifier, role: role }
  # end

  def params_for_carton_labeling # rubocop:disable Metrics/AbcSize
    # mode = schema.xpath('.//ProductLabel').attribute('Mode').value
    # mode 6: 10:
    #          Input modes i.e. choose one of the following
    # - 1 = Pack station barcode
    # - 2 = Pack station barcode + Packer barcode
    # - 3 = Pack station barcode + any other barcode (undefined length also)
    # - 4 = Pack station barcode + mass
    # - 5 = Pack station barcode + Packer barcode + mass
    # - 6 = Pack station barcode + undefined length Packer barcode + mass
    # - 7 = Product (carton) label scan (i.e. already labelled and in DBMS) + mass (mode 9 transaction)
    #         Therefore Mode=
    #             - 1 = Pack station barcode                       <--- Therefore Input1="Pack station barcode" Input2="" Mass="0.0"
    #             - 2 = Pack station barcode + Packer barcode      <--- Therefore Input1="Pack station barcode" Input2="Packer barcode" Mass="0.0"
    #             - 3 = Pack station barcode + any other barcode (undefined length also)    etc.
    #             - 4 = Pack station barcode + mass
    #             - 5 = Pack station barcode + Packer barcode + mass
    #             - 6 = Pack station barcode + undefined length Packer barcode + mass
    #             - 7 = Product (carton) label scan (i.e. already labelled and in DBMS) + mass (mode 9 transaction)
    #                         - Mode7/9 became a hybrid for some reason way back
    #                         - Ie MesScada processes it as Mode=7 and MidWare understands Mode=9 (or vice verse - cannot remember why exactly)
    #
    # Mode 10 came much later with Kromco DP and is therefore not listed above but is an automated Dedicated Pack transaction where:
    #                     Input1="labelLine + DP + two_digit(labelLine)
    #                     Input2="personnelID"
    #                     Mass="0.0"
    root = 'ProductLabel'
    validate_root_and_attributes(root)
    device = schema.xpath(".//#{root}").attribute('Module').value
    packpoint = schema.xpath(".//#{root}").attribute('Input1').value # DPK-41-DP-1A
    identifier = schema.xpath(".//#{root}").attribute('Input2').value
    attr = schema.xpath(".//#{root}").attribute('BinNumber')
    bin_number = attr.nil? ? nil : attr.value
    # App 32625 output: MESSCADA XML - received: <ProductLabel PID="223"  Module="DPK-45" Name="172.16.35.204_45" TransactionType="" Op="" Su="" Mode="10" BinNumber="50985140" LotNumber="1196395" Input1="45DP45" Input2="DPK-45-A-2021-03-09-15:38:30" LabelRenderAmount="1" Store="false" Printer="PRN-45" Mass="0.0" />
    { device: device, packpoint: packpoint, card_reader: '', bin_number: bin_number, identifier: identifier, identifier_is_person: true }
  end

  def params_for_can_bin_be_tipped
    # <ContainerMove PID="200" Mode="5" Module="localIP_tipperLine" Name="localIP_tipperLine" TransactionType="" Op="" Su="" BinNumber="tipperBin1" LotNumber="" />
    root = 'ContainerMove'
    validate_root_and_attributes(root, 'Mode' => '5')
    device = schema.xpath(".//#{root}").attribute('Module').value
    bin_number = schema.xpath(".//#{root}").attribute('BinNumber').value
    { device: device, bin_number: bin_number }
  end

  def params_for_tipped_bin
    # <ContainerMove PID="200" Mode="6"  Module="localIP_tipperLine" Name="localIP_tipperLine" TransactionType="" Op="" Su="" BinNumber="tipperBin1" LotNumber="tipperLot" />
    root = 'ContainerMove'
    validate_root_and_attributes(root, 'Mode' => '6')
    device = schema.xpath(".//#{root}").attribute('Module').value
    bin_number = schema.xpath(".//#{root}").attribute('BinNumber').value
    { device: device, bin_number: bin_number }
  end

  private

  def validate_root_and_attributes(root, attrs = {})
    raise Crossbeams::FrameworkError, %(XML root "#{schema.children.first.node_name}" is expected to be "#{root}".) unless schema.children.first.node_name == root

    attrs.each do |key, val|
      xml_val = schema.xpath(".//#{root}").attribute(key).value
      raise Crossbeams::FrameworkError, %(XML attribute "#{key}" has unexpected value ("#{xml_val}" instead of "#{val}").) unless xml_val == val
    end
    true
  end
end
