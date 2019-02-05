#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'oj'
require 'hashdiff'

def progress(index)
  return if (index % 10_000).positive?
  print "Processing: #{index}                    \r"
  $stdout.flush
end

def process_line(line)
  return if line =~ /totals#persons-of-significant-control-snapshot/
  json = Oj.load(line)
  {
    self_link: json.dig('data', 'links', 'self'),
    names: json.dig('data', 'name_elements')
  }
end

def all_data_present?(data)
  data && data[:self_link] && data[:names]
end

def names(file)
  i = 0
  names = {}
  File.foreach(file) do |line|
    progress(i)
    data = process_line(line)
    names[data[:self_link]] = data[:names] if all_data_present?(data)
    i += 1
  end
  names
end

# Test files to make sure we're picking up the right changes
# files = %w[
#   test-names-2.txt
#   test-names-1.txt
# ]

files = %w[
  persons-with-significant-control-snapshot-2019-01-16.txt
  persons-with-significant-control-snapshot-2019-01-21.txt
]

results = {}
files.each do |file|
  puts "Processing #{file}"
  names(file).each do |k, v|
    results[k] ||= {}
    results[k][file] = v
  end
end

puts "Total results: #{results.keys.length}"

# diff each file with the previous one
differences = {}
results.each do |self_link, file_data|
  names = file_data.values
  diff = HashDiff.diff(names[1], names[0])
  differences[self_link] = diff if diff.length > 1
end

puts "2 or more name elements changed: #{differences.keys.length}"

pry
