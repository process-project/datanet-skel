require 'datanet-skel/transaction'
require 'datanet-skel/action'

describe Datanet::Skel::Transaction do

  it "shows example transaction" do
    Datanet::Skel::Transaction.in_transaction do |container|

      Class.new(Datanet::Skel::Action) do

        def execute
          puts "abrakadabra"
        end

        def rollback
          puts "abrakadabra rolled back"
        end

      end.new(container).start

      Class.new(Datanet::Skel::Action) do

        def execute
          puts "abrakadabra2"
        end

        def rollback
          puts "abrakadabra2 rolled back"
        end

      end.new(container).start

      Class.new(Datanet::Skel::Action) do

        def execute
          puts "failing"
          throw "Failing"
        end

        def rollback
          puts "failing rolled back"
        end

      end.new(container).start


    end
  end

end
