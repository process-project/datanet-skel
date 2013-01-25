require 'rack/multipart'

module Datanet
  module Skel
    module MultipartParser
      def self.call(object, env)
        env[:input] = object
        { :multipart => Datanet::Skel::Multipart.new(env) }
      end
    end
  end
end