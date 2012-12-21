require 'spec_helper'

describe Datanet::Skel::RelationInspector do

	def inspector(model_name = 'book')
		@inspector ||= Datanet::Skel::RelationInspector.new(model_path(model_name))
	end

	describe 'relations attr reader' do
		it 'returns list of references attributes and target model name' do
			inspector.relations.should == {'authId' => 'author', 'publisherId' => 'publisher'}
		end

		it 'return empty references list when links section does not exist in model' do
			inspector('user').relations.should == {}
		end

		it 'return empty references list when list does not contain relation with targetSchema' do
			inspector('address').relations.should == {}
		end
	end
end