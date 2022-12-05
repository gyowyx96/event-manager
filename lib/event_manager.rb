require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(cellphone)
  cellphone.to_s.gsub!(/[^0-9]/, '')
  length = cellphone.length
  return 'bad number' if length < 10 || length > 11

  if length == 11
    return cellphone.slice!(1, 10) if cellphone.slice(0) == '1'

    return cellphone = 'bad number'

  end
  cellphone
end

def get_time(date)
  time = DateTime.strptime(date, '%m/%d/%y %H:%M')
  # time = time.strftime("%H:%M")
end

def get_mean_hours
  total = 0
  @hour_array.each do |hour|
    total += hour
  end
  puts total / @hour_array.length
end

def get_best_day
  @days_array.max_by { |day| @days_array.count(day) }
end

def translate_day_from_number(day)
  case day
  when 0
    'sunday'
  when 1
    'monday'
  when 2
    'tuesday'
  when 3
    'wednesday'
  when 4
    'thursday'
  when 5
    'friday'
  when 6
    'saturday'
  end
end
puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
@hour_array = []
@days_array = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  date = get_time(row[:regdate])
  legislators = legislators_by_zipcode(zipcode)

  @hour_array.push(date.hour)
  @days_array.push(date.wday)

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
end

puts translate_day_from_number(get_best_day)
