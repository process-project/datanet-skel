require "datanet-skel/version"

module Datanet
  module Skel
    autoload :API, 													'datanet-skel/api'
    autoload :API_v1, 											'datanet-skel/api_v1'
    autoload :MapperDecorator,							'datanet-skel/decorator'

    autoload :CollectionNotFoundException,	'datanet-skel/exceptions'
    autoload :EntityNotFoundException,			'datanet-skel/exceptions'
    autoload :ValidationError,							'datanet-skel/exceptions'
    autoload :WrongModelLocationError, 			'datanet-skel/exceptions'
  end
end
