require 'zip'
require 'fileutils'
module Passbook
  class PKMultiPass
    def self.create_multipass(pk_passes, multipass_file_path)
      raise "Too many passes" if pk_passes.size > 10
      raise "No passes provided" if pk_passes.size < 1
      raise "multipass files must have the .pkpasses extension" \
            unless multipass_file_path.end_with? ".pkpasses"
      raise "passes must be PKPass objects" \
            unless pk_passes.all? { |pass| pass.is_a? Passbook::PKPass }
      temp_dir = Dir.mktmpdir
      pass_counter = 0
      Zip::File.open(multipass_file_path, create: true) do |zipfile|
        pk_passes.each do | pass |
            pass_counter += 1
            file_name = "#{pass_counter}.pkpass"
            pkpass_path = pass.file(file_name: file_name, directory: temp_dir)
            zipfile.add(file_name, pkpass_path)
        end
      end
      FileUtils.remove_dir(temp_dir, true)
      multipass_file_path
    end
  end
end
