module ProxyHelper
  def proxy_payload
    load_cert('proxy')
  end

  def ca_payload
    load_cert('simple_ca.crt')
  end

  def load_cert(cert_name)
    File.read File.join(File.dirname(__FILE__), '..', 'certs', cert_name)
  end
end