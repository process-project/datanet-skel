module Datanet
	module Skel
		class MapperMock
			def collections
			end

			def collection(entity_type)
			end
		end

		class CollectionMock
			def ids
			end

			def add(json_doc)
			end

			def get(id)
			end

			def remove(id)
			end

			def update(id)
			end

			def replace(id, json_doc)
			end		
		end
	end
end