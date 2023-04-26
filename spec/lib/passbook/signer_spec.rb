require 'spec_helper'

describe 'Signer'  do
  context 'signatures' do

    context 'using default config info' do
      before do
        expect(Passbook).to(receive(:password).and_return 'password')
        expect(Passbook).to(receive(:rsa_private_key).and_return 'my_rsa_key')
        expect(Passbook).to(receive(:certificate).and_return 'my_X509_certificate')
        expect(Passbook).to(
          receive(:apple_intermediate_cert)
            .and_return( 'apple_intermediate_cert_file')
        )
      end

      context "getting the default config" do
        context "ignoring signing" do
          before do
            # don't care if signing works yet. just dealing with defaults
            allow_any_instance_of(Passbook::Signer).to(receive(:compute_cert))
          end

          let(:signer){
            Passbook::Signer.new
          }
          it "should contain rsa_private_key" do
            expect(signer.rsa_private_key).to(eq('my_rsa_key'))
          end
          it "should contain certificate" do
            expect(signer.certificate).to(eq('my_X509_certificate'))
          end
          it "should contain apple_intermediate_cert" do
            expect(signer.apple_intermediate_cert).to(eq('apple_intermediate_cert_file'))
          end
          it "should contain password" do
            expect(signer.password).to(eq('password'))
          end
        end
      end
      context "computing cert" do
        before do
            expect(OpenSSL::PKey::RSA).to(
              receive(:new)
                .with('my_rsa_key', 'password')
                .and_return 'my_rsa_key' # bogus example
            )

            expect(OpenSSL::X509::Certificate).to(
                receive(:new)
                .with('my_X509_certificate')
                .and_return 'my_X509_data' # bogus example
            )
        end
        context "signing" do
          let(:signer){Passbook::Signer.new}

          # this is just checking that
          # the inputs and outputs of the cert things
          # are all wired together correctly
          it "should do the signing dance" do

            # 2nd X509 cert loading...
            expect(OpenSSL::X509::Certificate).to(
                receive(:new)
                .with('apple_intermediate_cert_file')
                .and_return 'apples_X509_data' # bogus example
            )

            expect(OpenSSL::PKCS7).to(
                receive(:sign)
                  .with(
                    'my_X509_data', # from above
                    'my_rsa_key',   # also from above
                    'passbook_sign_data', # the param to Signer#sign(...)
                    ['apples_X509_data'],
                    OpenSSL::PKCS7::BINARY | OpenSSL::PKCS7::DETACHED
                  )
                  .and_return('pk7') # bogus example
              )
            expect(OpenSSL::PKCS7).to(
                receive(:write_smime)
                  .with('pk7')
                  .and_return("filename=\"smime.p7s\"\n\nsecret_pk7_stuff\n\n------")
              )
            expect(Base64).to(
              receive(:decode64)
                .with('secret_pk7_stuff') #from above
            )

            # and... kick it all off
            signer.sign('passbook_sign_data')

          end
        end
      end
    end

  end
end
