# frozen_string_literal: true

require 'spec_helper'
require 'friendly_shipping/services/usps_international/rate_estimate_package_options'

RSpec.describe FriendlyShipping::Services::UspsInternational::RateEstimatePackageOptions do
  subject { described_class.new(package_id: package_id) }
  let(:package_id) { 'my_package_id' }

  [
    :commercial_pricing,
    :commercial_plus_pricing,
    :container,
    :mail_type,
    :rectangular,
    :shipping_method,
    :transmit_dimensions
  ].each do |message|
    it { is_expected.to respond_to(message) }
  end

  describe 'commercial_pricing' do
    it 'is Y when true' do
      expect(described_class.new(
          package_id: package_id,
          commercial_pricing: true,
        ).commercial_pricing).to eq("Y")
    end

    it 'is N when false' do
      expect(described_class.new(
          package_id: package_id,
        ).commercial_pricing).to eq("N")
    end
  end

  describe 'commercial_plus_pricing' do
    it 'is Y when true' do
      expect(described_class.new(
          package_id: package_id,
          commercial_plus_pricing: true,
        ).commercial_plus_pricing).to eq("Y")
    end

    it 'is N when false' do
      expect(described_class.new(
          package_id: package_id,
        ).commercial_plus_pricing).to eq("N")
    end
  end

  describe 'container' do
    it 'is VARIABLE by default' do
      expect(described_class.new(
        package_id: package_id,
      ).container).to eq("VARIABLE")
    end

    it 'raises an exception when not recognized type' do
      expect{ described_class.new(
        container: :invalid,
        package_id: package_id,
      ) }.to raise_error(KeyError)
    end
  end

  describe 'mail_type' do
    it 'is ALL by default' do
      expect(described_class.new(
        package_id: package_id,
      ).mail_type).to eq("ALL")
    end

    it 'raises an exception when not recognized type' do
      expect{ described_class.new(
        mail_type: :invalid,
        package_id: package_id,
      ) }.to raise_error(KeyError)
    end
  end

  describe 'rectangular' do
    it 'is false if container is ROLL' do
      expect(described_class.new(
        package_id: package_id,
        container: :roll,
      ).rectangular).to be(false)
    end

    it 'is true by default' do
      expect(described_class.new(
        package_id: package_id,
      ).rectangular).to be(true)
    end
  end
end
