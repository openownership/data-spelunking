# frozen_string_literal: true

require 'json'

DOWNLOAD_DIR = 'sk-downloads'
OUTPUT_FILE = 'sk-data.json'

results = []
Dir.entries(DOWNLOAD_DIR).reject { |f| File.directory? f }.each do |e|
  File.open("#{DOWNLOAD_DIR}/#{e}", 'r') do |f|
    results.concat JSON.parse(f.read)['value']
  end
end
File.open(OUTPUT_FILE, 'w') do |f|
  f << JSON.pretty_generate(results)
end
