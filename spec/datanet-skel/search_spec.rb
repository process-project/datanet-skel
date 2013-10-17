require 'spec_helper'

describe Datanet::Skel::Search do
  let(:collection) { double }

  before do
    collection.stub(:attr_type).with('age').and_return(:integer)
    collection.stub(:attr_type).with('weight').and_return(:number)
    collection.stub(:attr_type).with('active').and_return(:boolean)
    collection.stub(:attr_type).with('name').and_return(:string)
    collection.stub(:attr_type).with('tags').and_return(:array)
    collection.stub(:attr_type).with('id').and_return(nil)
  end

  context 'simple query' do
    it 'returns integer query' do
      result = subject.decode({'age' => '2'}, collection)
      result['age'].should == 2
    end

    it 'returns number query' do
      result = subject.decode({'weight' => '3.5'}, collection)
      result['weight'].should == 3.5
    end

    context 'when boolean attribute' do
      it 'converts true string into true' do
        result = subject.decode({'active' => 'true'}, collection)
        result['active'].should == true
      end

      it 'converts yes string into true' do
        result = subject.decode({'active' => 'yes'}, collection)
        result['active'].should == true
      end

      it 'converts 1 into true' do
        result = subject.decode({'active' => '1'}, collection)
        result['active'].should == true
      end

      it 'converts other strings into false' do
        result = subject.decode({'active' => 'false'}, collection)
        result['active'].should == false
      end
    end

    it 'returns string query' do
      result = subject.decode({'name' => 'marek'}, collection)
      result['name'].should == 'marek'
    end

    it 'returns raw value for unknown attributes (e.g. id)' do
      result = subject.decode({'id' => '123dfa2'}, collection)
      result['id'].should == '123dfa2'
    end
  end

  context 'with operator' do
    context 'with number' do
      it 'creates > query' do
        result = subject.decode({'age' => '>3'}, collection)
        result['age'].should == {value: 3, operator: :>}
      end

      it 'creates >= query' do
        result = subject.decode({'age' => '>=3'}, collection)
        result['age'].should == {value: 3, operator: :>=}
      end

      it 'creates < query' do
        result = subject.decode({'age' => '<3'}, collection)
        result['age'].should == {value: 3, operator: :<}
      end

      it 'creates <= query' do
        result = subject.decode({'age' => '<=3'}, collection)
        result['age'].should == {value: 3, operator: :<=}
      end

      it 'creates != query' do
        result = subject.decode({'age' => '!=3'}, collection)
        result['age'].should == {value: 3, operator: :!=}
      end
    end

    context 'with string' do
      it 'creates regexp search' do
        result = subject.decode({'name' => '/m.*/'}, collection)
        result['name'].should == {value: 'm.*', operator: :regexp}
      end
    end

    context 'with array' do
      it 'creates arrays search' do
        result = subject.decode({'tags' => 't1,t2,t3'}, collection)
        result['tags'].should == {value: ['t1', 't2', 't3'], operator: :contains}
      end
    end
  end

  context 'complex query' do
    it 'returns 2 conditions for age between 2 and 5' do
      result = subject.decode({'age' => ['>2', '<5']}, collection)
      result['age'].should == [{value: 2, operator: :>}, {value: 5, operator: :<}]
    end

    it 'returns ids search' do
      result = subject.decode({'id' => ['1', '2']}, collection)
      result['id'].should == ['1', '2']
    end
  end
end