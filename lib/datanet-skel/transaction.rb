
module Datanet
  module Skel
    class Transaction

      def self.in_transaction
        container = Datanet::Skel::Container.new
        begin
          yield container
        rescue Exception => e
          puts "Action failed: #{e}"
          container.rollback_succeeded
        end
      end

    end

    class Container

      def initialize
        @success_list = Array.new
      end

      def succeeded action
        @success_list.push action
      end

      def rollback_succeeded
        until @success_list.empty?
          @success_list.pop.rollback
        end
      end

    end
  end
end
