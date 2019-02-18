require 'net/http/persistent'
require 'json'
require 'pry'

IDS_WITH_PAGINATION = %i[
  13230
  9910
  8087
  22775
  7427
  27165
  23581
  5243
  5244
  8967
  9524
  22231
  10276
  26887
  17651
  1945
  18626
  6395
  9971
  23147
  6659
  8533
  25576
  18359
  9727
  9732
  9734
  9736
  9738
  14343
  9716
  11249
  8506
  26368
  7049
  23210
  5619
  4805
  8135
  8136
  24832
  10624
  6799
  6800
  10614
  9147
  2979
  10200
  6263
  10454
  25814
  6239
  24648
  22095
  970
  7031
  18841
  9113
  16752
  2533
  8490
  23438
  24246
  17192
  7257
  9378
  7018
  6208
  18686
  10361
  16241
  5115
  19772
  24916
  23462
  17278
  27242
  27249
  4154
  4160
  23451
  10132
  7502
  9663
  16403
  14932
  18524
  8849
  11496
  9655
  9659
  8443
  9809
  19548
  23725
  13759
  9414
  16226
  12564
  9850
  19584
  19589
  15583
  4365
  4367
  12101
  18488
  8414
  17310
  11355
  5891
  23506
  19918
  2210
  9638
  7709
  7096
  12327
  16160
  830
  5572
  17938
  4759
  7110
  25724
  18928
  18933
  12388
  17742
  4948
  6145
  18462
  17995
  8581
  19115
  6170
  14272
  19364
  18145
  11086
  11093
  24297
].freeze

http = Net::HTTP::Persistent.new

lengths = {}

IDS_WITH_PAGINATION.each do |id|
  uri = URI("https://rpvs.gov.sk/OpenData/Partneri(#{id})?$expand=KonecniUzivateliaVyhod($expand=*)")
  puts "loading #{uri}"
  response = http.request(uri)
  unless response.is_a?(Net::HTTPSuccess)
    puts "#{response.code} received when request id #{id}"
  end
  json = JSON.parse(response.body)
  lengths[id] = json['KonecniUzivateliaVyhod'].length
end

puts "Individual numbers of people:"
puts lengths.inspect

counts = Hash.new(0)
lengths.each { |k,v| counts[v] +=1 }

puts "Total numbers in descending order :"
puts counts.sort_by { |count, occurence| count }.reverse.inspect

puts "Total numbers and how often they occur, in descending order of occurence:"
puts counts.sort_by { |count, occurence| occurence }.reverse.inspect

pry
