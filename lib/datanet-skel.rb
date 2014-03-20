require "datanet-skel/version"
# require 'grape_formatter'

module Datanet
  module Skel
    autoload :API,                          'datanet-skel/api'
    autoload :API_v1,                       'datanet-skel/api_v1'
    autoload :ConfigurationApi,             'datanet-skel/configuration_api'
    autoload :APIHelpers,                   'datanet-skel/helper'
    autoload :MapperDecorator,              'datanet-skel/decorator'
    autoload :RelationInspector,            'datanet-skel/relation_inspector'
    autoload :RepositoryAuth,               'datanet-skel/repository_auth'
    autoload :GridProxyAuth,                'datanet-skel/grid_proxy_auth'
    autoload :Search,                       'datanet-skel/search'
    autoload :AttrWrapper,                  'datanet-skel/attr_wrapper'
    autoload :StreamingBody,                'datanet-skel/streaming_body'

    autoload :CollectionNotFoundException,  'datanet-skel/exceptions'
    autoload :EntityNotFoundException,      'datanet-skel/exceptions'
    autoload :ValidationError,              'datanet-skel/exceptions'
    autoload :WrongModelLocationError,      'datanet-skel/exceptions'
    autoload :FileStorageException,         'datanet-skel/exceptions'

    autoload :Unauthenticated,              'datanet-skel/exceptions'
    autoload :Unauthorized,                 'datanet-skel/exceptions'
  end
end
