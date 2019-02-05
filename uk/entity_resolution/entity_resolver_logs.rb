require 'csv'

cruft = 'INFO -- : [EntityResolver] Resolution with OpenCorporates changed the company number of Entity with identifiers: '
output = []
data_regex = /(?<identifiers>^\[.+\])\. Old number: (?<old_number>.+)\. New number: (?<new_number>.+)\. Old name: (?<old_name>.+)\. New name: (?<new_name>.+)\./
open('entity_resolver_log_msgs.txt', 'r') do |f|
  f.readlines.each do |line|
    msg = line.sub(cruft, '')
    msg.match(data_regex) do |m|
      output << m.names.zip(m.captures).to_h
    end
  end
end
CSV.open('entity_resolver_logs.csv', 'wb') do |csv|
  csv << output.first.keys
  output.each do |hash|
    csv << hash.values
  end
end
