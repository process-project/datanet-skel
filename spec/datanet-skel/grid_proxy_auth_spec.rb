require 'spec_helper'

describe Datanet::Skel::GridProxyAuth do
  include ProxyHelper

  subject { Datanet::Skel::GridProxyAuth.new(ca_payload) }

  describe '#authenticate' do
    before do
      Time.stub(:now).and_return(Time.new(2013, 12, 4, 12, 0, 0, "+01:00"))
    end

    it 'returns true on valid proxy' do
      expect(subject.authenticate(proxy_payload)).to eq true
    end

    it 'returns false for empty creds' do
      expect(subject.authenticate(nil)).to eq false
    end

    it 'returns false for corrupted proxy' do
      expect(subject.authenticate('not valid proxy payload')).to eq false
    end
  end

  describe '#username' do
    it 'returns username from valid proxy' do
      expect(subject.username(proxy_payload)).to eq 'plgkasztelnik'
    end

    it 'returns nil when proxy is not valid' do
      expect(subject.username(nil)).to eq nil
    end
  end
end