require 'datanet-skel/exceptions'


module Datanet
  module Skel

    # Transaction class is used to yield rollback of succeeded atomic actions
    # after any exception is raised during execution of another action.
    #
    # After the failing transaction is rolled back the exception which causes the failure
    # is raised again.
    #
    class Transaction

      def initialize
        @success_list = Array.new
      end

      # TODO check what heppens if executed twice (probably works well)
      # Executes a code block in transaction
      def in_transaction
        begin
          yield self
        rescue Exception => e
          # TODO log action failure - puts "Action failed: #{e.message}"
          # TODO rethink error handling mechanism (rollback in any case or just in case of specific exception)
          rollback
          raise e
        end
      end

      # Rolls back succeeded atomic actions
      def rollback
        until @success_list.empty?
          begin
            @success_list.pop.run_rollback
          rescue
            # TODO log rollback failure (we should ignore failing rollback)
          end
        end
      end

      # Is called AUTOMATICALLY by any atomic action when it finishes succesfully
      def succeeded atomic
        @success_list.push atomic
      end

    end

    # AtomicAction is a class allowing for definition of invocation in context of surrounding transaction.
    # Transaction contains atomics and manages rollbacks in a situation of failure.
    #
    # action method should be implemented in such a way that will either succeed or in a case of failure
    # revert object to the previous state and throw exception after that
    # (rollback will not be called for the failing action)
    #
    # rollback will be performed to revert SUCCEEDED atomic action to the previous state in case of
    # failure (raise exception) in the current transaction.
    #
    # Each atomic action has it's own inner transaction which can be used via in_transaction method.
    class AtomicAction

      def initialize (enclosing_transaction = nil)
        @enclosing_transaction = enclosing_transaction
        @inner_transaction = nil
      end

      # To be called in order to start executing the action
      def run_action
        retval = action
        @enclosing_transaction.succeeded(self) if @enclosing_transaction
        retval
      end

      # This method is called by enclosing Transaction to run rollback
      def run_rollback
        rollback
        @inner_transaction.rollback if @inner_transaction
      end

      protected

      # Method to be implemented to perform atomic action
      # will be rolled back only if it ends with success
      def action
        raise "Method not implemented"
      end

      # Method to be implemented to revert all changes
      # rolls back succeeded action
      # ATTENTION: inner transaction is already rolled back automatically - do not do that on your own
      def rollback
      end

      private

      # This can be used in the action method to run code in the inner transaction
      # ATTENTION: do not use in rollback method
      def in_transaction
        @inner_transaction ||= Datanet::Skel::Transaction.new
        @inner_transaction.in_transaction do
          yield @inner_transaction
        end
      end

    end

  end
end
