module Datanet
module Skel
  class CollectionNotFoundException < Exception; end
  class EntityNotFoundException < Exception; end
  class ValidationError < Exception; end
  class WrongModelLocationError < Exception; end
end
end