require 'openssl'
require 'base64'

module Passbook
  class Signer
    attr_accessor :certificate,
                  :password,
                  :rsa_private_key,
                  :apple_intermediate_cert,
                  :p12_cert
    attr_reader :key_hash

    def initialize(params = {})

      # Path to your X509 cert. This is downloaded after generating
      # a certificate from your apple Pass Type ID on apple's developer site
      @certificate = params[:certificate] || Passbook.certificate

      # Path to the .pem file generated from public key of the RSA keypair
      # that was generated when you made a Certificate Signing Request
      # It'll be in your keychain under the "Common Name" you specified
      # for the signing request.
      @rsa_private_key         = params[:rsa_private_key] || Passbook.rsa_private_key

      # this should be the password that goes along with the rsa public key
      @password    = params[:password] || Passbook.password

      # "Apple Intermediate Certificate Worldwide Developer Relations" certificate
      # downloaded from here <https://www.apple.com/certificateauthority/>
      # Path to your Apple Intermediate Certificate Worldwide Developer Relations
      # cert.
      # downloaded from here https://www.apple.com/certificateauthority/
      # download that .cer file (binary)
      @apple_intermediate_cert   = params[:apple_intermediate_cert] || Passbook.apple_intermediate_cert
      compute_cert
    end

    def sign(data)
      apple_cert  = OpenSSL::X509::Certificate.new file_data(apple_intermediate_cert)
      # In PKCS#7 SignedData, attached and detached formats are supported… In
      # detached format, data that is signed is not embedded inside the
      # SignedData package instead it is placed at some external location…

      pk7   = OpenSSL::PKCS7.sign(
        key_hash[:certificate],
        key_hash[:rsa_private_key],
        data.to_s,
        [apple_cert],
        OpenSSL::PKCS7::BINARY | OpenSSL::PKCS7::DETACHED
      )
      pk7_data  = OpenSSL::PKCS7.write_smime pk7

      str_debut = "filename=\"smime.p7s\"\n\n"
      pk7_data      = pk7_data[pk7_data.index(str_debut)+str_debut.length..pk7_data.length-1]
      str_end   = "\n\n------"
      pk7_data      = pk7_data[0..pk7_data.index(str_end)-1]

      Base64.decode64(pk7_data)
    end

    def compute_cert
      @key_hash = {
        rsa_private_key: OpenSSL::PKey::RSA.new(file_data(rsa_private_key), password),
        certificate: OpenSSL::X509::Certificate.new(file_data(certificate))
      }
    end

    def file_data(data)
      raise "file_data passed nil" if data.nil?
      return data if data.is_a? String

      data.respond_to?(:read) ? data.read : File.read(data)
    end
  end
end
