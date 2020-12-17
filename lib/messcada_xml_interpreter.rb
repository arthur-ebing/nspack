# frozen_string_literal: true

class MesscadaXMLInterpreter
  attr_reader :schema

  def initialize(request_or_string, as_string: false)
    @schema = if as_string
                Nokogiri::XML(request_or_string)
              else
                Nokogiri::XML(request_or_string.body.gets)
              end
  end

  def list_input_attributes
    # Take XML fragment and list all attributes as key/value pairs...
    puts schema.children.first.node_name
    puts schema.children.first.attributes.map { |k, v| "#{k} = #{v.value}" }.join("\n")
  end

  def params_for_carton_labeling
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
    root = 'ProductLabel'
    validate_root_and_attributes(root)
    device = schema.xpath(".//#{root}").attribute('Module').value
    identifier = schema.xpath(".//#{root}").attribute('Input2').value
    # TODO: Input1 is the scan code representing the "pack button" (if this is in format "B1", we can use it as the button...
    { device: device, card_reader: '', identifier: identifier }
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

  def validate_root_and_attributes(root, attrs = {}) # rubocop:disable Metrics/AbcSize
    raise Crossbeams::FrameworkError, %(XML root "#{schema.children.first.node_name}" is expected to be "#{root}".) unless schema.children.first.node_name == root

    attrs.each do |key, val|
      xml_val = schema.xpath(".//#{root}").attribute(key).value
      raise Crossbeams::FrameworkError, %(XML attribute "#{key}" has unexpected value ("#{xml_val}" instead of "#{val}").) unless xml_val == val
    end
    true
  end
end
__END__
          schema = Nokogiri::XML(request.body.gets)
          device = schema.xpath('.//ProductLabel').attribute('Module').value
          identifier = schema.xpath('.//ProductLabel').attribute('Input2').value
          # TODO: Input1 is the scan code representing the "pack button" (if this is in format "B1", we can use it as the button...
          params = { device: device, card_reader: '', identifier: identifier }
          res = MesscadaApp::AddSystemResourceIncentiveToParams.call(params, has_button: true)
          res = interactor.maf_carton_labeling(res.instance) if res.success
