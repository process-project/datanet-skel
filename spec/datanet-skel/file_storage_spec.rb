require 'spec_helper'
require 'datanet-skel/file_storage'

describe Datanet::Skel::FileStorage do

  let(:user) { 'plguser' }
  let(:base_path) { '/mnt/auto/people' }
  let(:folder_name) { '.datanet' }
  let(:full_path) { "#{base_path}/#{user}/#{folder_name}" }
  let(:gftp_client) { double }
  let(:proxy) { double(proxy_payload: 'proxy payload', username: user) }
  let(:file_path) { "#{full_path}/file" }

  before do
    GFTP::Client.stub(:new).and_return gftp_client
  end

  subject { Datanet::Skel::FileStorage.new(base_path, folder_name) }

  describe '#store_payload' do
    let(:payload_stream) { double }

    context 'when base directory exists' do
      before do
        expect(gftp_client).to receive(:exists).with(full_path).and_yield(true)
        expect(gftp_client).to_not receive(:mkdir!)
        expect(gftp_client).to receive(:put).and_yield(1)
        expect(payload_stream).to receive(:read).with(1).twice
      end

      it 'uploads payload stream' do
        subject.store_payload(proxy, payload_stream)
      end
    end

    context 'when base directory does not exist' do
      before do
        expect(gftp_client).to receive(:exists).with(full_path).and_yield(false)
      end

      context 'and it is possible to create missing directory' do
        before do
          expect(gftp_client).to receive(:mkdir!).with(full_path).and_yield(true)
          expect(gftp_client).to receive(:put).and_yield(1)
          expect(payload_stream).to receive(:read).with(1).twice
        end

        it 'uploads payload stream' do
          subject.store_payload(proxy, payload_stream)
        end
      end

      context 'and unable to create missing directory' do
        before do
          expect(gftp_client).to receive(:mkdir!).with(full_path).and_yield(false)
        end

        it 'throws storage exception' do
          expect {
            subject.store_payload(proxy, payload_stream)
          }.to raise_error(Datanet::Skel::FileStorageException, "Unable to create #{full_path}")
        end
      end
    end
  end

  describe '#delete_file' do
    context 'when file exists' do
      before do
        expect(gftp_client).to receive(:delete).with(file_path).and_yield(true)
      end

      it 'deletes file' do
        subject.delete_file(proxy, file_path)
      end
    end

    context 'when file does not exists' do
      before do
        expect(gftp_client).to receive(:delete).with(file_path).and_yield(false)
      end

      it 'throws file storage exception' do
        expect {
          subject.delete_file(proxy, file_path)
        }.to raise_error(Datanet::Skel::FileStorageException, "Unable to delete #{file_path} file")
      end
    end
  end

  describe '#get_file' do
    context 'when file exists' do
      before do
        expect(gftp_client).to receive(:get).with(file_path).and_yield('file ').and_yield('payload')
      end

      it 'gets file payload in chunks' do
        payload = ''
        subject.get_file(proxy, file_path) do |data|
          payload += data
        end
        expect(payload).to eq 'file payload'
      end
    end

    context 'when file does not exists' do
      before do
        expect(gftp_client).to receive(:get).with(file_path).and_raise(GFTP::GlobusError.new)
      end

      it 'thros file storage exception' do
        expect {
          subject.get_file(proxy, file_path)
        }.to raise_error(Datanet::Skel::FileStorageException, "Unable to read #{file_path} file")
      end
    end
  end
end