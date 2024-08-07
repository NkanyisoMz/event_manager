require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_phone_number(phone_number)
  # Remove any non-digit characters from the phone number
  digits = phone_number.gsub(/\D/, '')

  if digits.length == 10
    # If the phone number is exactly 10 digits, it's good
    digits
  elsif digits.length == 11 && digits[0] == '1'
    # If the phone number is 11 digits and the first digit is 1, trim the 1
    digits[1..10]
  else
    # Any other case is considered a bad number
    'Invalid Number'
  end
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def peak_hours(hrs, dict)
  hr = DateTime.strptime(hrs, '%m/%d/%y %H:%M').strftime('%H')
  if dict.key?(hr)
    dict[hr] += 1
  else
    dict[hr] = 1
  end
end

def peak_days(day, dic)
  d = Time.strptime(day, '%m/%d/%y %H:%M').strftime('%A')
  if dic.key?(d)
    dic[d] += 1
  else
    dic[d] = 1
  end
end

def max_count(hash)
  max_val = hash.values.max
  hash.select { |k, v| v == max_val }.keys
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
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

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hour_counts = {}
day_counts = {}

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  regdate = row[:regdate]

  peak_hours(regdate, hour_counts)
  peak_days(regdate, day_counts)

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end

busy_hours = max_count(hour_counts)
busy_days = max_count(day_counts)

puts "Peak registration hours: #{busy_hours}"
puts "Peak registration days: #{busy_days}"



#max_hours = dict.select{|k,v| v ==dict.values.max}.map{|x x[0]}

# contents.each do |row|
#   name = row[2]
#   puts name
# end







# contents = File.read('event_attendees.csv')
# puts contents
#puts File.exist? "event_attendees.csv"

# lines = File.readlines('event_attendees.csv')
# lines.each_with_index do |line,index|
#   next if index == 0
#   columns = line.split(",")
#   name = columns[2]
#   puts name
# end