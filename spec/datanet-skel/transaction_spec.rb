require 'datanet-skel/transaction'
require 'datanet-skel/exceptions'

describe Datanet::Skel::Transaction do

  it "verifies proper transaction rollback handling" do

    expect {

      Datanet::Skel::Transaction.new.in_transaction do |transaction|

        atomic1 = Class.new(Datanet::Skel::AtomicAction) do
          # methods will be mocked
        end.new(transaction)

        atomic1.should_receive(:rollback).exactly(1)
        atomic1.should_receive(:action).exactly(1).and_return(:a)

        atomic2 = Class.new(Datanet::Skel::AtomicAction) do
          # methods will be mocked
        end.new(transaction)

        atomic2.should_receive(:rollback).exactly(1)
        atomic2.should_receive(:action).exactly(1).and_return(:b)

        atomic3 = Class.new(Datanet::Skel::AtomicAction) do
          # methods will be mocked
        end.new(transaction)

        atomic3.should_receive(:rollback).exactly(0)
        atomic3.should_receive(:action).exactly(1).and_raise(Datanet::Skel::ActionFailedException.new("Fail message"))

        atomic1.run_action.should == :a
        atomic2.run_action.should == :b
        atomic3.run_action

      end

    }.to raise_error

  end

  it "verifies proper transaction status values" do

    transaction = Datanet::Skel::Transaction.new
    transaction.in_transaction do

      atomic = Class.new(Datanet::Skel::AtomicAction) do
        # methods will be mocked
      end.new(transaction)

      atomic.should_receive(:action).exactly(1).and_return(:a)
      atomic.should_receive(:rollback).exactly(0)
      atomic.run_action

    end.should_not.nil?

  end

  it "shows how to use transactions" do

    expect {

      Datanet::Skel::Transaction.new.in_transaction do |transaction|

        atomic1 = Class.new(Datanet::Skel::AtomicAction) do
          def action
            "this will be executed"
          end
          def rollback
            "this will rolled back executed"
          end
        end.new(transaction)

        atomic2 = Class.new(Datanet::Skel::AtomicAction) do
          def action
            raise Datanet::Skel::ActionFailedException.new("this raises exception")
          end
          def rollback
            "this will not be rolled back"
            fail
          end
        end.new(transaction)

        atomic3 = Class.new(Datanet::Skel::AtomicAction) do
          def action
            "this will not be executed at all"
            fail
          end
          def rollback
            "and will of course will not be rolled back"
          end
        end.new(transaction)

        atomic1.run_action
        atomic2.run_action

        # these lines will not be called at all
        atomic3.run_action

      end

     }.to raise_error

  end

  it "shows transaction in transaction" do

    trans = Datanet::Skel::Transaction.new

    expect {

      trans.in_transaction do |transaction|

        atomic1 = Class.new(Datanet::Skel::AtomicAction) do
          def action
            in_transaction do |trans|
              atomic = Class.new(Datanet::Skel::AtomicAction) do ; end.new(trans)
              atomic.should_receive(:action).exactly(1).and_return(:a)
              atomic.should_receive(:rollback).exactly(1)
              atomic.run_action
            end
          end
        end.new(transaction)

        atomic2 = Class.new(Datanet::Skel::AtomicAction) do
          def action
            raise "failed"
          end
        end.new(transaction)

        atomic2.should_receive(:rollback).exactly(0)

        atomic1.run_action
        atomic2.run_action

      end
    }.to raise_error

  end

  #
  #it "shows transaction in transaction" do
  #
  #  expect {
  #  Datanet::Skel::Transaction.new.in_transaction do |transaction|
  #
  #    Class.new(Datanet::Skel::AtomicAction) do
  #      def action
  #        puts "outer1"
  #        in_transaction do |inner_transaction|
  #
  #          Class.new(Datanet::Skel::AtomicAction) do
  #            def action
  #              puts "inner1"
  #            end
  #            def rollback
  #              puts "inner_rollback1"
  #            end
  #          end.new(inner_transaction).run_action
  #
  #          Class.new(Datanet::Skel::AtomicAction) do
  #            def action
  #              puts "inner2"
  #            end
  #            def rollback
  #              puts "inner_rollback2"
  #            end
  #          end.new(inner_transaction).run_action
  #
  #        end
  #      end
  #      def rollback
  #        puts "outer_rollback1"
  #      end
  #    end.new(transaction).run_action
  #
  #    Class.new(Datanet::Skel::AtomicAction) do
  #      def action
  #        puts "outer_failing"
  #        raise "failed"
  #      end
  #    end.new(transaction).run_action
  #
  #  end
  #  }.to raise_error
  #end

end
