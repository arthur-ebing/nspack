# frozen_string_literal: true

module Production
  module Resources
    module SystemResource
      class ShowXml
        def self.call(res, id = nil)
          rules = {}

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.section do |section|
              section.add_control control_type: :link, text: 'Back', url: '/list/system_resources', style: :back_button
              section.add_control control_type: :link, text: 'Download', url: "/production/resources/system_resources/#{id}/download_xml_config", style: :button, icon: :download if res.instance[:config]
            end

            if res.instance[:config]
              page.add_text "#{res.instance[:config][:module]} config.xml", wrapper: :h2
              page.add_text res.instance[:config][:xml], syntax: :xml
            end

            if res.instance[:modules]
              page.add_text 'MODULES', wrapper: :h2
              # page.add_text 'Example', wrapper: :em
              # page.add_text '<Module Name="BTM-01" 	Type="robot-nspi" 	Function="rmt-bin-tip" 			Alias="PH1BT" 		NetworkInterface="172.17.2.89"  Port="2000" MacAddress="" TTL="15000" CycleTime="15000" Publishing="false" Login="false" Logoff="false" URL="/messcada/rmt/bin_tipping/weighing?" Par1="device" Par2="bin_number" Par3="identifier" Par4="gross_weight" Par5="measurement_unit"   ReaderID="" ContainerType="bin" WeightUnits="Kg" Printer="" PrinterTypes="" />', wrapper: :em, syntax: :xml
              page.add_text res.instance[:modules], syntax: :xml
            end

            if res.instance[:peripherals]
              page.add_text 'PRINTERS', wrapper: :h2
              # page.add_text 'Example', wrapper: :em
              # page.add_text '<Printer Name="PRN-01" Function="NSLD-Printing" Alias="PRN-01-NSLD" Type="argox" Model="argox" ConnectionType="TCP" NetworkInterface="172.17.2.148" Port="9100" TTL="10000" CycleTime="15000" Language="pplz" Username="admin" Password="1234" PixelsMM="8" />', wrapper: :em, syntax: :xml
              page.add_text res.instance[:peripherals], syntax: :xml
            end
          end

          layout
        end
      end
    end
  end
end
