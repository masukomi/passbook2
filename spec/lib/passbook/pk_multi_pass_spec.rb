require 'spec_helper'
require 'tmpdir'
require 'zip'

describe Passbook do
  let(:content) do
    {
      formatVersion: 1,
      passTypeIdentifier: 'pass.passbook.test',
      serialNumber: '001',
      teamIdentifier: ENV['APPLE_TEAM_ID'],
      organizationName: 'WorldCo',
      description: 'description',
      eventTicket: {
        primaryFields: [
          {
            key: 'date',
            label: 'DATE',
            value: 'date'
          }
        ]
      }
    }
  end

  let(:signer) { double 'signer' }
  let(:pass) { Passbook::PKPass.new( content.to_json, signer) }
  let(:base_path) { 'spec/data' }
  let(:entries) { ['pass.json', 'manifest.json', 'signature', 'icon.png', 'icon@2x.png', 'logo.png', 'logo@2x.png'] }
  let(:passes){ [pass, pass] }

  before :each do
    pass.addFiles(
      [
        "#{base_path}/icon.png",
        "#{base_path}/icon@2x.png",
        "#{base_path}/logo.png",
        "#{base_path}/logo@2x.png"
      ]
    )
    allow(signer).to(receive(:sign).and_return('Signed by the Honey Badger'))
  end

  describe ".create_multi_pass" do
    it "should create a file where specified" do
      Dir.mktmpdir do |dir|
        temp_file = Passbook::PKMultiPass.create_multipass(
          passes,
          File.join(dir, "foo.pkpasses")
        )
        expect(File.exist?(temp_file)).to(eq(true))
      end
    end

    it "should contain 2 files", :aggregate_failures do
      Dir.mktmpdir do |dir|
        temp_file = Passbook::PKMultiPass.create_multipass(
          passes,
          File.join(dir, "foo.pkpasses")
        )
        entries = Zip::File.open(temp_file).entries
        expect(entries.count).to(eq(2))
        expect(entries.map(&:name)).to(match_array(["1.pkpass", "2.pkpass"]))
      end
    end
  end
end
