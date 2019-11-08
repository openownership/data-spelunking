class DkInterestsExplorer
  EXPECTED_INTERESTS = [
    0.05,
    0.1,
    0.15,
    0.2,
    0.25,
    0.33,
    0.5,
    0.6667,
    0.9,
    1.0,
  ].freeze

  def call
    data_source = DataSource.find('dk-cvr-register')
    imports = Import.where(data_source: data_source).pluck(:_id).map(&:to_s)

    @has_expected_interest = []
    @has_differing_interest = []
    @other_interests = Hash.new(0)
    @interest_type = Hash.new(0)
    @real_owners = 0

    total = RawDataRecord.where(:import_ids.in => imports).count
    puts "Total records: #{total}"

    @processed = 0

    RawDataRecord.where(:import_ids.in => imports).each do |record|
      raw_data = Oj.load(record.raw_data, mode: :rails)

      raw_data['virksomhedSummariskRelation'].each do |item|
        next if item['virksomhed']['fejlRegistreret'] # ignore if errors discovered

        item['organisationer'].each do |o|
          o['medlemsData'].each do |md|
            md['attributter'].each do |a|
              next unless a['type'] == 'FUNKTION'

              real_owner_role = most_recent(
                a['vaerdier'].select { |v| v['vaerdi'] == 'Reel ejer' },
              )

              next if real_owner_role.blank?

              @real_owners += 1

              process_interests(md['attributter'], record)
              break
            end
          end
        end
      end

      @processed += 1
      puts "Processed: #{@processed}" if (@processed % 10000).zero?
    end

    puts "Real owners: #{@real_owners}"
    puts "Interests with banded value: #{@has_expected_interest.size}"
    puts "Interests with different value: #{@has_differing_interest.size}"
    puts "Number of different values: #{@other_interests.size}"
    puts "Top ten different values: #{@other_interests.sort_by { |k,v| -v}.take(10) }"

    binding.pry
  end

  private

  def process_interests(attributes, record)
    attributes.each do |a|
      case a['type']
      when 'EJERANDEL_PROCENT', 'EJERANDEL_STEMMERET_PROCENT'
        interest = most_recent(a['vaerdier'])['vaerdi'].to_f
        if EXPECTED_INTERESTS.include? interest
          @has_expected_interest << record.id.to_s
        else
          @has_differing_interest << record.id.to_s
          @other_interests[interest] += 1
        end
      end
    end
  end

  def most_recent(items)
    return unless items.all?

    sort_by_period(items).first
  end

  def sort_by_period(items)
    items.sort do |x, y|
      # Convert to strings to handle `nil` values
      y['periode']['gyldigFra'].to_s <=> x['periode']['gyldigFra'].to_s
    end
  end
end
