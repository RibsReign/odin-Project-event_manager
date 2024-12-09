#  frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_number(number)
  return false unless number

  number = number.scan(/\d+/).join
  return number[1..10] if number.length == 11 && number.to_s[0] == '1'
  return number if number.length == 10

  false
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = File.read('api').strip

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  begin
    Dir.mkdir('output')
  rescue Errno::EEXIST
    # Directory already exists, no action needed
  end

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end
# Load attendees
puts 'EventManager initialized.'
contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

# Open make template
template_letter = File.read('form_letter.html')
erb_template = ERB.new template_letter
time = []

contents.each_with_index do |row, index|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_number(row[:homephone])
  regdate = row[:regdate]
  begin
    time = DateTime.strptime(regdate, '%m/%d/%y %H:%M').strftime('%k:%M')
    puts time
  rescue ArgumentError
    puts "Invalid date for row #{index}: #{regdate}"
  end

  # legislators = legislators_by_zipcode(zipcode)

  # form_letter = erb_template.result(binding)
  # save_thank_you_letter(id, form_letter)
end
# contents = File.read('event_attendees.csv')
# puts contents
# lines = File.readlines('event_attendees.csv')
# lines.each_with_index do |line, index|
#   next if index == 0

#   columns = line.split(',')
#   name = columns[2]
#   puts name
# end
