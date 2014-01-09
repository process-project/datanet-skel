require 'spec_helper'

describe Datanet::Skel::StreamingBody do
  let(:collection) { double('collection') }
  let(:id) { '123' }
  let(:user_proxy) { 'user_proxy' }

  subject { Datanet::Skel::StreamingBody.new(collection, id, user_proxy) }

  describe '#each' do
    before { expect(collection).to receive(:get_file).with(id, user_proxy).and_yield('ala ').and_yield('ma ').and_yield('kota') }

    it 'yields file data' do
      result = ''
      subject.each { |d| result += d }
      expect(result).to eq 'ala ma kota'
    end
  end

  it 'does not respond to #to_s' do
    expect(subject.respond_to?(:to_str)).to eq false
  end
end