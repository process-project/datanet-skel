require 'net/sftp'

module Datanet
  module Skel
    class SftpConnection

      attr_accessor :sftp_user

      def initialize(sftp_host, sftp_user, sftp_password)
        @sftp_host = sftp_host
        @sftp_user = sftp_user
        @sftp_password= sftp_password
      end

      def in_session
        start_session!
        yield @sftp
        close_session!
      end

    private

      def prepare_directory
        @sftp.opendir() do |response|
          response.ok? == false
          @sftp.mkdir!(@path)
        end
      end

      def start_session!
        if @ssh.nil?
          @ssh = Net::SSH.start(@sftp_host, @sftp_user, :password => @sftp_password, :keys => [] )
          @sftp = @ssh.sftp
        end
      end

      def close_session!
        unless @ssh.nil?
          @ssh.close
          @ssh = @sftp = nil
        end
      end

    end
  end
end
