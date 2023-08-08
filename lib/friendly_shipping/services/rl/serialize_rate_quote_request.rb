# frozen_string_literal: true

module FriendlyShipping
  module Services
    class RL
      class SerializeRateQuoteRequest
        class << self
          # @param [Physical::Shipment] shipment
          # @param [FriendlyShipping::Services::RL::QuoteOptions] options
          # @return [Hash]
          def call(shipment:, options:)
            {
              RateQuote: {
                PickupDate: options.pickup_date.strftime('%m/%d/%Y'),
                Origin: serialize_location(shipment.origin),
                Destination: serialize_location(shipment.destination),
                Items: serialize_items(shipment.packages, options),
                DeclaredValue: options.declared_value,
                AdditionalServices: options.additional_service_codes,
                Pallets: serialize_pallets(shipment.pallets)
              }.compact
            }.compact
          end

          private

          # @param [Physical::Location] location
          # @return [Hash]
          def serialize_location(location)
            {
              City: location.city,
              StateOrProvince: location.region.code,
              ZipOrPostalCode: location.zip,
              CountryCode: location.country.alpha_3_code
            }.compact
          end

          # @param [Array<Physical::Package>] packages
          # @param [FriendlyShipping::Services::RL::QuoteOptions] options
          # @return [Array<Hash>]
          def serialize_items(packages, options)
            item_hashes = packages.flat_map do |package|
              package_options = options.options_for_package(package)
              package.items.map do |item|
                item_options = package_options.options_for_item(item)
                {
                  Class: item_options.freight_class,
                  Weight: item.weight.convert_to(:pounds)
                }
              end
            end
            group_items(item_hashes)
          end

          # Group items by freight class. The R&L API has a limit on the number of items
          # we can submit to the API, so this helps reduce the number of items.
          #
          # @param [Array<Hash>] item_hashes
          # @return [Array<Hash>]
          def group_items(item_hashes)
            item_hashes.group_by do |item_hash|
              item_hash[:Class]
            end.map do |freight_class, grouped_item_hashes|
              {
                Class: freight_class,
                Weight: grouped_item_hashes.sum { |e| e[:Weight] }.value.ceil,
                Quantity: grouped_item_hashes.size
              }
            end
          end

          # @param [Array<Physical::Pallet>] pallets
          # @return [Array<Hash>]
          def serialize_pallets(pallets)
            pallets.group_by do |pallet|
              pallet.weight.convert_to(:pounds).value.ceil
            end.map do |weight, grouped_pallets|
              {
                Code: "0001",
                Weight: weight,
                Quantity: grouped_pallets.size
              }
            end
          end
        end
      end
    end
  end
end