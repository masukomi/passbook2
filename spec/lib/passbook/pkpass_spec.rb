require 'spec_helper'
require 'tempfile'
require 'tmpdir'

describe Passbook do
  let(:content) do
    {
      formatVersion: 1,
      passTypeIdentifier: 'pass.passbook.test',
      serialNumber: '001',
      teamIdentifier: ENV['APPLE_TEAM_ID'],
      relevantDate: '2012-10-02',
      locations: [ # TODO
        {
          longitude: 2.35403,
          latitude: 48.893855
        }
      ],
      organizationName: 'WorldCo',
      description: 'description',
      foregroundColor: 'rgb(227,210,18)',
      backgroundColor: 'rgb(60, 65, 76)',
      logoText: 'Event',
      eventTicket: {
        primaryFields: [
          {
            key: 'date',
            label: 'DATE',
            value: 'date'
          }
        ],
        backFields: [
          {
            key: 'description',
            label: 'DESCRIPTION',
            value: 'description'
          },
          {
            key: 'aboutUs',
            label: 'MORE',
            value: 'about us'
          }
        ]
      }
    }
  end

  let(:signer) { double 'signer' }
  let(:pass) { Passbook::PKPass.new content.to_json, signer }
  let(:base_path) { 'spec/data' }
  let(:entries) { ['pass.json', 'manifest.json', 'signature', 'icon.png', 'icon@2x.png', 'logo.png', 'logo@2x.png'] }

  before :each do
    allow(signer).to(receive(:sign).and_return('Signed by the Honey Badger'))
  end
  describe '#file' do
    context 'when adding a file as File' do
      before do
        pass.add_file(File.new("#{base_path}/icon.png"))
        pass.add_files(
          [
            "#{base_path}/icon@2x.png",
            "#{base_path}/logo.png",
            "#{base_path}/logo@2x.png"
          ].map { |x| File.new(x) }
        )
      end

      it 'should work with no options', :aggregate_failures do
        temp_file = pass.file
        expect(File.basename(temp_file.path)).to(eq('pass.pkpass'))
        expect(File.dirname(temp_file)).to(eq(Dir.tmpdir))
      end
    end
    context 'when adding files as strings' do
      before do
        pass.add_file("#{base_path}/icon.png")
        pass.add_files(
          [
            "#{base_path}/icon@2x.png",
            "#{base_path}/logo.png",
            "#{base_path}/logo@2x.png"
          ]
        )
      end

      it 'should work with no options', :aggregate_failures do
        temp_file = pass.file
        expect(File.basename(temp_file.path)).to(eq('pass.pkpass'))
        expect(File.dirname(temp_file)).to(eq(Dir.tmpdir))
      end
      it 'should honor the file_name specified' do
        temp_file = pass.file(file_name: 'foo.pkpass')
        expect(File.basename(temp_file)).to(eq('foo.pkpass'))
      end

      it 'should honor the directory specified as a string' do
        Dir.mktmpdir do |dir| # dir is a String
          temp_file = pass.file(directory: dir)
          expect(File.dirname(temp_file)).to(eq(dir))
        end
      end

      it 'should honor the directory specified as a Dir' do
        Dir.mktmpdir do |dir|
          temp_file = pass.file(directory: Dir.new(dir))
          expect(File.dirname(temp_file)).to(eq(dir))
        end
      end
      context 'outputs' do
        before do
          @file_entries = []
          Zip::InputStream.open(zip_path) do |io|
            while (entry = io.get_next_entry)
              @file_entries << entry.name
            end
          end
        end

        context 'zip file' do
          let(:zip_path) { pass.file.path }

          it 'should have the expected files' do
            expect(entries).to(eq(@file_entries))
          end
        end

        context 'StringIO' do
          let(:temp_file) { Tempfile.new('pass.pkpass') }
          let(:zip_path) do
            zip_out = pass.stream
            expect(zip_out.class).to(eq(StringIO))
            # creating file, re-reading zip to see if correctly formed
            temp_file.write zip_out.string
            temp_file.close
            temp_file.path
          end

          it 'should contain the expected files' do
            expect(entries).to(eq(@file_entries))
          end

          after do
            temp_file.delete
          end
        end
      end
    end
  end

  # TODO: find a proper way to do this
  context 'Error catcher' do
    context 'formatVersion' do
      let(:base_path) { 'spec/data' }

      before :each do
        pass.add_files ["#{base_path}/icon.png", "#{base_path}/icon@2x.png", "#{base_path}/logo.png",
                       "#{base_path}/logo@2x.png"]
        tpass = JSON.parse(pass.pass)
        tpass['formatVersion'] = 'It should be a numeric'
        pass.pass = tpass.to_json
      end

      it 'raise an error' do
        expect { pass.build }.to raise_error('Format Version should be a numeric')
      end
    end
  end
end
