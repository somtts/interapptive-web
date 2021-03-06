class App.Lib.DateTimeHelper

  # Formats a date time string in human readable format.
  # TODO: WA: Extend this helper to support more formats.
  # Take inspiration from
  # http://api.rubyonrails.org/classes/DateTime.html#method-i-to_default_s
  @timeToHuman: (dateString) ->
    d = new Date(dateString)

    hour = d.getHours()
    if hour > 12
      meridiem = 'pm'
      hour = hour - 12
    else
      meridiem = 'am'
    hour_padding = ''
    if hour < 10
      hour_padding = '0'

    minutes = d.getMinutes()
    minutes_padding = ''
    if minutes < 10
      minutes_padding = '0'

    "#{@dateToHuman(dateString)} #{hour_padding}#{hour}:#{minutes_padding}#{minutes}#{meridiem}"


  # Formats a date string in human readable format.
  # TODO: WA: Extend this helper to support more formats.
  @dateToHuman: (dateString) ->
    d = new Date(dateString)

    year = d.getFullYear()

    month = d.getMonth()
    month++ # Month numbers start with 0 while day start with 1. Fucking Javascript!
    month_padding = ''
    if month < 10
      month_padding = '0'

    date = d.getDate()
    date_padding = ''
    if date < 10
      date_padding = '0'

    "#{year}-#{month_padding}#{month}-#{date_padding}#{date}"


  @secondsToDuration: (seconds) ->
    hours = Math.floor(seconds / 3600)
    seconds %= 3600
    minutes = Math.floor(seconds / 60)
    seconds %= 60
    seconds = Math.floor(seconds)
    if hours < 1 then hours = 0
    if hours < 10 then hours_padding = '0' else hours_padding = ''

    if minutes < 1 then minutes = 0
    if minutes < 10 then minutes_padding = '0' else minutes_padding = ''

    if seconds < 1 then seconds = 0
    if seconds < 10 then seconds_padding = '0' else seconds_padding = ''

    "#{hours_padding}#{hours}:#{minutes_padding}#{minutes}:#{seconds_padding}#{seconds}"
