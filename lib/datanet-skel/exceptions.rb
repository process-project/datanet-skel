module Datanet
module Skel
  class CollectionNotFoundException < Exception; end
  class EntityNotFoundException < Exception; end
  class EntityAttributeNotFoundException < Exception; end
  class ValidationError < Exception; end
  class WrongModelLocationError < Exception; end
  class FileStorageException < Exception; end
end
end