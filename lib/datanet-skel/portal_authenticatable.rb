require 'net/https'
require 'digest/sha1'
require 'base64'
require 'datanet-logger'

module Datanet
  module Skel
    # Special authentication strategy to allow user auth with the 3rd party PLGrid Portal.
    class PortalAuthenticatable

      def initialize(portal_base_url, portal_shared_key)
        @portal_base_url = portal_base_url
        @portal_shared_key = portal_shared_key
      end

      def plgrid_portal_user_check(login, password)
        status, token = plgrid_portal_auth(login, password)
        status
      end

      # Assuming we already know who's the user, we authenticate her again with the portal, to start a new session
      # Returns: [is_ok, token] - if is_ok == true (the user auth is a success), token == the portal token issued for this user session
      def plgrid_portal_auth(login, password)
        status, response = do_https("#{full_portal_endpoint}userchallenge/#{login}")
        return [false,response] unless status

        salt = parse_response(response, "challenge")
        return [false,nil] unless status

        s = [salt].pack('H*')
        hash = Base64.encode64(Digest::SHA1.digest(password+s)+s).chomp!

        status, response = do_https("#{full_portal_endpoint}userlogin/#{login}", false, hash)
        return [false,nil] unless status

        [true, parse_response(response, "token")]
      end

      # Not only authenticates the user with the PLGrid Portal but also retrieves all user data to populate the locel DB
      # Returns: [is_ok, content]
      #   - if is_ok (the user auth is a success), user == the 'resource', the new user object in the model
      #   - if !is_ok,  content is either nil or the error message
      def full_plgrid_portal_check(login, password)
        is_ok, response = plgrid_portal_auth(login, password)
        return [false,response] unless is_ok

        user = update_user_info_from_portal(login, response)
        return [false,nil] if user.nil?

        [true, user]
      end


      # Given a valid portal token, contacts the portal in order to retrieve user details and populate with it the local DB.
      # If the user does not exist, it creates one with the retrieved data, otherwise it updates user's fields in DB.
      # Returns the user record in DB or nil if both no previous user record was found locally and the portal does not respond with the data.
      def update_user_info_from_portal(login, token)
        # TG: sleep might be useful for testing portal token timeout
        #sleep 200

        status, response = do_https("#{full_portal_endpoint}userdata/#{token}")

        # If we can't get to portal for some reason, we try to work with what we have now in local DB
        unless status
          logger.warn "[PortalAuth] Problem with retrieval of user data from Portal. Code (#{response.code}). Trying to rely on local DB for now."
          return User.find_by_login(login)
        end

        # The structure of user data returned from Portal:

        #<userData>
        #  <login>plggubala</login>
        #  <name>Tomasz</name>
        #  <surname>Gubala</surname>
        #  <email>plggubala@email.com</email>
        #<teams><group><name>MAPPER</name><systemGroup>plggmapper</systemGroup><status>ACTIVE</status><leader>false</leader></group><group><name>MultiSCaLE Application Developers</name><systemGroup>plggmuscle</systemGroup><status>ACTIVE</status><leader>false</leader></group><group><name>siRNA</name><systemGroup>plggsirna</systemGroup><status>ACTIVE</status><leader>true</leader></group></teams>
        #</userData>

        main_data = response.body[/userData.*<\/email>/]
        user_data = {
          :login => get_xml_content(main_data, "login"),
          :name => get_xml_content(main_data, "name"),
          :surname => get_xml_content(main_data, "surname"),
          :email => get_xml_content(main_data, "email")
        }

        logger.debug "[PortalAuth] Retrived full data of (#{authentication_hash[:login]}): #{user_data}."
        user = User.where(:login => login).first_or_create(user_data)
        user.update_attributes(user_data)
        user
      end


      # Assumes the response is a correct HTTPSuccess body message.
      # Returns the XML element body for 'word' element name
      def parse_response(response, word)
        get_xml_content(response.body.to_s, word)
      end


      # Tests if the Portal responsed with HTTPSuccess and if the operation itself was successful (the status attribute == "OK")
      # Returns: [is_ok, value]
      #   * when !is_ok, value may be either nil of server exaplanation of what happened (the failure message)
      #   * when is_ok (the API call is a success), value is nil
      def check_response_success(response)
        # NOTE: see other HTTPResponse cases: http://www.ensta-paristech.fr/~diam/ruby/online/ruby-doc-stdlib/libdoc/net/http/rdoc/classes/Net/HTTPResponse.html
        return [false,:portal_access_probelm] if response.nil?
        if (not response.kind_of?(Net::HTTPSuccess)) or response.kind_of?(Net::HTTPNoContent)
          logger.warn "[PortalAuth] Application layer error in communication with Portal. Code (#{response.code})."
          if response.class.body_permitted?
            logger.warn "[PortalAuth] " + response.body.to_s
          else
            logger.logger "[PortalAuth] No response 'body' supplied."
          end
          return [false,:portal_access_probelm]
        end
        status = get_attribute(response.body, "response", "status")
        if status == "failed"
          cause = get_xml_content(response.body.to_s, "cause")
          logger.warn "[PortalAuth] Portal API call failed. Cause: #{cause}. Full response body below."
          logger.warn response.body
          return [false,cause]
        end
        [true,nil]
      end


      def get_xml_content(body, marker)
        return nil if !body.include? marker
        body[/<#{marker}>.*<\/#{marker}>/][(marker.length+2)..-marker.length-4]
      end

      def get_attribute(body, element, attribute)
        body[/#{element}.*>/][/#{attribute}=".*"/][(attribute.length+2)..-2]
      end

      # Performs the low-lever HTTPS API call
      # Returns: [is_ok, content]
      #   * when !is_ok, content contains nil or the explanation of the problem(s) encountered
      #   * when is_ok,  content contains the response HTTPS message
      def do_https(endpoint, is_get = true, pass_hash = nil)
        logger.debug "[PortalAuth] Performing https get on endpoint: #{endpoint} ."
        uri = URI(endpoint)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        portal_request = Net::HTTP::Get.new(uri.path)

        portal_request = is_get ? Net::HTTP::Get.new(uri.path) : Net::HTTP::Post.new(uri.path)
        portal_request.set_form_data('sshaPassword' => pass_hash) unless is_get

        begin
          response = http.request(portal_request)
          status, message = check_response_success(response)
          unless status
            # TG: I know this is kind of pathetic but that's the only "protocol" with Portal we have now
            # TODO: improve when the Portal REST protocol is able to give specific error codes
            case message
            when "Given shared key is not valid"
              raise message
            when "User login or password wrong"
              return [false, nil]
            else
              raise "Unknown Portal communication protocol error (#{message})."
            end
          end
          [true, response]
        rescue Exception => e
          logger.error "[PortalAuth] [ERROR] Transport layer error in communication with Portal."
          logger.error "[PortalAuth] [ERROR] Exception message: [#{e.message}]. Stacktrace:"
          logger.error e.backtrace.inspect
          # TG: call the doctor! (here: 'request' means the user's webapp request, not our request to the portal)
          #ExceptionNotifier::Notifier.exception_notification(request.env, e, :data => {:description => "Error in communication with Portal.", :message => e.message, :portal_endpoint => endpoint}).deliver
          [false, :portal_access_probelm]
        end
      end

      def full_portal_endpoint
        # TG: host firewall timeout testing example
          #"https://zeus47.cyf-kr.edu.pl:8443/aruliferay/api/external/" + PORTAL_SHARED_KEY + "/"
        # TG: wrong host API endpoint testing example
        #"https://zeus41.cyf-kr.edu.pl:8443/aruliferay/api/badapiurl/" + PORTAL_SHARED_KEY + "/"
        # TG: wrong API endpoint shared key
        #Integromics::Application.config.plgrid_portal_base_url + PORTAL_SHARED_KEY[5,5] + "/"

        # TG: the correct value for production
        #Integromics::Application.config.plgrid_portal_base_url + PORTAL_SHARED_KEY + "/"
        #PORTAL_BASE_URL + PORTAL_SHARED_KEY + "/"
        @portal_base_url + @portal_shared_key + "/"
      end

      def logger
        Logger.logger
      end

    end
  end
end