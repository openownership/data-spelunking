#!/usr/bin/env ruby
# frozen_string_literal: true

require 'oj'

headers = %w[self_link title_before forename_before middle_name_before surname_before title_after forename_after middle_name_after surname_after]
puts headers.join(', ')
DEFAULT_SUMMARY = {
  title_before: 'unchanged',
  forename_before: 'unchanged',
  middle_name_before: 'unchanged',
  surname_before: 'unchanged',

  title_after: 'unchanged',
  forename_after: 'unchanged',
  middle_name_after: 'unchanged',
  surname_after: 'unchanged'
}.freeze

def summary(diffs)
  summary = DEFAULT_SUMMARY.dup
  diffs.each do |diff|
    diff_type = diff[0]
    diff_field = diff[1]
    case diff_type
    when '-'
      summary["#{diff_field}_before".to_sym] = diff[2]
      summary["#{diff_field}_after".to_sym] = 'removed'
    when '+'
      summary["#{diff_field}_before".to_sym] = ''
      summary["#{diff_field}_after".to_sym] = diff[2]
    when '~'
      summary["#{diff_field}_before".to_sym] = diff[2]
      summary["#{diff_field}_after".to_sym] = diff[3]
    end
  end
  summary
end

File.open('two-or-more-name-diffs.json', 'r') do |f|
  diffs = Oj.load(f.read)
  diffs.each do |self_link, record_diffs|
    diff_summary = summary(record_diffs)
    puts "#{self_link}, #{diff_summary.values.join(', ')}"
  end
end
