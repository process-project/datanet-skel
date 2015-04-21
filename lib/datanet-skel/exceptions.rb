module Datanet
  module Skel
    class CollectionNotFoundException < StandardError; end
    class EntityNotFoundException < StandardError; end
    class EntityAttributeNotFoundException < StandardError; end
    class ValidationError < StandardError; end
    class WrongModelLocationError < StandardError; end
    class FileStorageException < StandardError; end

    class Unauthenticated < StandardError; end
    class Unauthorized < StandardError; end
    class PermissionDenied < StandardError; end
  end
end
