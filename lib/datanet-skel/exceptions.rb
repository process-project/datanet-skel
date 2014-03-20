module Datanet
module Skel
  class CollectionNotFoundException < Exception; end
  class EntityNotFoundException < Exception; end
  class EntityAttributeNotFoundException < Exception; end
  class ValidationError < Exception; end
  class WrongModelLocationError < Exception; end
  class FileStorageException < Exception; end

  class Unauthenticated < Exception; end
  class Unauthorized < Exception; end
end
end