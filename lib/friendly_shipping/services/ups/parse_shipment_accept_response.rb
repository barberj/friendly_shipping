# frozen_string_literal: true

require 'dry/monads/result'
require 'friendly_shipping/services/ups/parse_money_element'

module FriendlyShipping
  module Services
    class Ups
      class ParseShipmentAcceptResponse
        extend Dry::Monads::Result::Mixin

        class << self
          def call(request:, response:)
            parsing_result = ParseXMLResponse.call(response.body, 'ShipmentAcceptResponse')
            parsing_result.fmap do |xml|
              FriendlyShipping::ApiResult.new(
                build_labels(xml),
                original_request: request,
                original_response: response
              )
            end
          end

          private

          def build_labels(xml)
            packages = xml.xpath('//ShipmentAcceptResponse/ShipmentResults/PackageResults')
            packages.map do |package|
              cost_breakdown = build_cost_breakdown(package)
              FriendlyShipping::Label.new(
                tracking_number: package.at('TrackingNumber').text,
                label_data: Base64.decode64(package.at('LabelImage/GraphicImage').text),
                label_format: package.at('LabelImage/LabelImageFormat/Code').text,
                cost: cost_breakdown.values.sum,
                shipment_cost: get_shipment_cost(xml),
                data: {
                  cost_breakdown: cost_breakdown,
                  negotiated_rate: get_negotiated_rate(xml)
                }.compact
              )
            end
          end

          def build_cost_breakdown(package)
            cost_elements = [
              package.at('BaseServiceCharge'),
              package.at('ServiceOptionsCharges'),
              package.xpath('ItemizedCharges')
            ].flatten

            cost_elements.map { |element| ParseMoneyElement.call(element) }.compact.to_h
          end

          def get_shipment_cost(shipment_xml)
            total_charges_element = shipment_xml.at('ShipmentResults/ShipmentCharges/TotalCharges')
            ParseMoneyElement.call(total_charges_element).last
          end

          def get_negotiated_rate(shipment_xml)
            negotiated_total_element = shipment_xml.at('NegotiatedRates/NetSummaryCharges/GrandTotal')
            ParseMoneyElement.call(negotiated_total_element)&.last
          end
        end
      end
    end
  end
end