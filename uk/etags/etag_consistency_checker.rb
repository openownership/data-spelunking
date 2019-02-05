#!/usr/bin/env ruby
# frozen_string_literal: true

require 'xxhash'
require 'oj'
require 'parallel'
require 'active_support/all'

files = %w[
  persons-with-significant-control-snapshot-2019-01-16.txt
  persons-with-significant-control-snapshot-2019-01-21.txt
]

def progress(index)
  return if (index % 10_000).positive?
  print "Processing: #{index}                    \r"
  $stdout.flush
end

def process_file(file)
  done = []
  finish = lambda { |_, _, x| done << x }
  begin
    Parallel.map_with_index(File.foreach(file), finish: finish) do |line, i|
      begin
        progress(i)
        process_line(line)
      rescue StandardError => e
        puts "Caught error in file: #{file}, line: #{i} error: #{e.message}"
      end
    end
  rescue Interrupt
  end
  done
end

def process_line(line)
  record = Oj.load(line)
  return if record.dig('data', 'kind') == 'totals#persons-of-significant-control-snapshot'
  self_link = record.dig('data', 'links', 'self')
  etag = record.dig('data', 'etag')
  return if self_link.nil? || etag.nil?
  digest = record_digest(record)
  { self_link: self_link, etag: etag, digest: digest, data: record }
end

def record_digest(record)
  # We don't trust this data, so don't include it
  record['data'].delete('links')
  record['data'].delete('etag')
  # It doesn't really matter how we hash this, so long as it's consistent
  # but we have to do it millions of times, hence the speedy hash lib
  XXhash.xxh32(record.sort.to_s)
end

def summarise_result(self_link, result, summary)
  return unless result.keys.length > 1

  etags = result.values.map { |h| h[:etag] }
  digests = result.values.map { |h| h[:digest] }

  different_etags = etags.uniq.length > 1
  different_digests = digests.uniq.length > 1

  differences_agree = []
  if different_etags || different_digests
    differences_agree = step_through_differences(etags, digests)
  end

  summary[:in_multiple_files] << self_link
  summary[:differences] << self_link if different_etags || different_digests
  summary[:no_differences] << self_link if !different_etags && !different_digests
  summary[:agreeing_differences] << self_link if differences_agree.any? && differences_agree.all?
  summary[:different_etags_same_digests] << self_link if different_etags && !different_digests
  summary[:different_digests_same_etags] << self_link if !different_etags && different_digests
end

# Produce an array of booleans denoting whether, when an etag or digest
# changes (in one of the given arrays of etags) the corresponding digest/etag
# in the other array also changed.
# i.e.
# Given: [1, 2, 2], [a, b, b]
# Returns: [true]
# Given [1, 2, 3], [a, b, c]
# Returns: [true, true]
# Given: [1, 2, 2], [a, a, b]
# Returns: [false, false]
# This allows us to make sure that when CH say data changed, we also think it
# changed.
def step_through_differences(etags, digests)
  differences_agree = []
  etags.zip(digests).each_with_index do |zipped, i|
    next unless i.positive?
    etag, digest = zipped
    if etag != etags[i - 1]
      differences_agree << digest != digests[i - 1]
    elsif digest != digests[i - 1]
      differences_agree << etag != etags[i - 1]
    end
  end
  differences_agree
end

def summarise_results(results, summary)
  i = 0
  results.each do |self_link, result|
    progress(i)
    summarise_result(self_link, result, summary)
    i += 1
  end
end

results = {}
summary = {
  in_multiple_files: [],
  differences: [],
  no_differences: [],
  different_etags_same_digests: [],
  different_digests_same_etags: [],
  agreeing_differences: []
}

files.each do |file|
  puts "Processing: #{file}"
  cached_file = "#{file}.processed.json"
  if ARGV.include?('--cached') && File.exist?(cached_file)
    file_results = Oj.load(File.read(cached_file))
  else
    file_results = process_file(file)
    File.open(cached_file, 'w') do |f|
      f.write(Oj.dump(file_results))
    end
  end
  file_results.each do |result|
    next if result.nil?
    results[result[:self_link]] ||= {}
    results[result[:self_link]][file] = {
      etag: result[:etag],
      digest: result[:digest],
      data: result[:data]
    }
  end
end

summarise_results(results, summary)

puts "Total records: #{results.keys.length}"
puts "In multiple files: #{summary[:in_multiple_files].length}"
puts "No differences: #{summary[:no_differences].length}"
puts "Differences that agree: #{summary[:agreeing_differences].length}"
puts "Etags that shouldn't have changed but did: #{summary[:different_etags_same_digests].length}"
puts "Etags that should have changed but didn't: #{summary[:different_digests_same_etags].length}"
