" date and time library.

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V)
  let s:V = a:V

  if s:V.is_windows()
    let s:win_tz =
    \  -(split(s:V.system(printf('reg query "%s" /v Bias | findstr REG_DWORD',
    \ 'HKLM\System\CurrentControlSet\Control\TimeZoneInformation')))[-1] * 60)
  endif

  " default values
  call extend(s:DateTime, {
  \   '_year': 0,
  \   '_month': 1,
  \   '_day': 1,
  \   '_hour': 0,
  \   '_minute': 0,
  \   '_second': 0,
  \   '_timezone': s:timezone(),
  \ })
  call extend(s:TimeDelta, {
  \   '_days': 0,
  \   '_time': 0,
  \   '_sign': 0,
  \ })
endfunction

" Creates a DateTime object with now time.
function! s:now(...)
  return call('s:from_unix_time', [localtime()] + a:000)
endfunction

" Creates a DateTime object from specified unix time.
function! s:from_unix_time(unix_time, ...)
  return call('s:from_date',
  \   map(split(strftime('%Y %m %d %H %M %S', a:unix_time)),
  \       'str2nr(v:val, 10)') + a:000)
endfunction

" Creates a DateTime object from specified date and time.
" @param year = 1970
" @param month = 1
" @param day = 1
" @param hour = 0
" @param minute = 0
" @param second = 0
" @param timezone = ''
function! s:from_date(...)
  let o = copy(s:DateTime)
  let [o._year, o._month, o._day, o._hour, o._minute, o._second, tz] =
  \   a:000 + [1970, 1, 1, 0, 0, 0, ''][a:0 :]
  let o._timezone = s:timezone(tz)
  return o._normalize()
endfunction

" Creates a DateTime object from format.
function! s:from_format(string, format, ...)
  let o = copy(s:DateTime)
  let locale = a:0 ? a:1 : ''
  let remain = a:string
  for f in s:_split_format(a:format)
    if s:V.is_string(f)
      let matched_len = len(f)
      if f !=# remain[: matched_len - 1]
        throw "Vital.DateTime: Parse error:\n" .
        \     'input: ' . a:string . "\nformat: " . a:format
        break
      endif
    elseif s:V.is_list(f)
      let [d, flag, width] = f
      let info = s:format_info[d]
      let key = '_' . info[0]
      if !has_key(o, key)
        let key = '_'
      endif
      if s:V.is_funcref(info[1])
        let pattern = call(info[1], [locale], {})
        if s:V.is_list(pattern)
          let values = pattern
          let l:['pattern'] = '\%(' . join(values, '\|') . '\)'
        endif
      elseif s:V.is_list(info[1])
        if width ==# ''
          let width = info[1][1]
        endif
        let pattern = '\d\{1,' . width . '}'
        if flag == '_'
          let pattern = '\s*' . pattern
        endif
      elseif s:V.is_string(info[1])
        let pattern = info[1]
      endif

      let value = matchstr(remain, '^' . pattern)
      let matched_len = len(value)

      if exists('values')
        let value = index(values, value)
        unlet values
      elseif s:V.is_list(info[1])
        let value = str2nr(value, 10)
      endif

      if 4 <= len(info)
        let l:['value'] = eval(info[3])
      endif
      if key !=# '_'
        let o[key] = value
      endif
      unlet value pattern
    endif
    let remain = remain[matched_len :]
    unlet f
  endfor
  return o._normalize()
endfunction

" Creates a DateTime object from Julian day.
function! s:from_julian_day(jd, ...)
  let tz = call('s:timezone', a:000)
  let second = 0
  if s:V.is_float(a:jd)
    let jd = float2nr(floor(a:jd))
    let second = float2nr(s:SECONDS_OF_DAY * (a:jd - jd))
  else
    let jd = a:jd
  endif
  let [year, month, day] = s:_jd2g(jd)
  return s:from_date(year, month, day, 12, 0, second, '+0000').to(tz)
endfunction

" Creates a new TimeZone object.
function! s:timezone(...)
  let info = a:0 ? a:1 : ''
  if s:_is_class(info, 'TimeZone')
    return info
  endif
  if type(info) != type(0) && empty(info)
    unlet info
    let info = s:_default_tz()
  endif
  let tz = copy(s:TimeZone)
  if type(info) == type(0)
    let tz._offset = info
  elseif info =~# '^[+-]\d\{2}:\?\d\{2}$'
    let list = matchlist(info, '\v([+-])(\d{2})(\d{2})')
    let tz._offset = str2nr(list[1] . '60') *
    \                (str2nr(list[2]) * 60 + str2nr(list[3], 10))
  else
    " TODO: TimeZone names
    throw 'Vital.DateTime: Unknown timezone: ' . string(info)
  endif
  return tz
endfunction

" Creates a new TimeDelta object.
function! s:delta(...)
  let info = a:0 ? a:1 : ''
  if s:_is_class(info, 'TimeDelta')
    return info
  endif
  let d = copy(s:TimeDelta)
  if a:0 == 2 && type(a:1) == type(0) && type(a:2) == type(0)
    let d._days = a:1
    let d._time = a:2
  else
    let a = copy(a:000)
    while 2 <= len(a) && type(a[0]) == type(0) && type(a[1]) == type('')
      let [value, unit] = remove(a, 0, 1)
      if unit =~? '^seconds\?$'
        let d._time += value
      elseif unit =~? '^minutes\?$'
        let d._time += value * s:NUM_SECONDS
      elseif unit =~? '^hours\?$'
        let d._time += value * s:SECONDS_OF_HOUR
      elseif unit =~? '^days\?$'
        let d._days += value
      elseif unit =~? '^weeks\?$'
        let d._days += value * s:NUM_DAYS_OF_WEEK
      endif
    endwhile
  endif
  return d._normalize()
endfunction

function! s:compare(d1, d2)
  return a:d1.compareTo(a:d2)
endfunction

" Returns month names according to the current or specified locale.
" @param fullname = false
" @param locale = ''
function! s:month_names(...)
  return s:_names(s:MONTHS, a:0 && a:1 ? '%B' : '%b', get(a:000, 1, ''))
endfunction

" Returns weekday names according to the current or specified locale.
" @param fullname = false
" @param locale = ''
function! s:weekday_names(...)
  return s:_names(s:WEEKS, a:0 && a:1 ? '%A' : '%a', get(a:000, 1, ''))
endfunction

" Returns am/pm names according to the current or specified locale.
" @param lowercase = false
" @param locale = ''
function! s:am_pm_names(...)
  return s:_names(s:AM_PM_TIMES, a:0 && a:1 ? '%P' : '%p', get(a:000, 1, ''))
endfunction

" Returns 1 if the year is a leap year.
function! s:is_leap_year(year)
  return a:year % 4 == 0 && a:year % 100 != 0 || a:year % 400 == 0
endfunction


" ----------------------------------------------------------------------------
let s:Class = {}
function! s:Class._clone()
  return copy(self)
endfunction
function! s:_new_class(class)
  return extend({'class': a:class}, s:Class)
endfunction
function! s:_is_class(obj, class)
  return type(a:obj) == type({}) && get(a:obj, 'class', '') ==# a:class
endfunction

" ----------------------------------------------------------------------------
let s:DateTime = s:_new_class('DateTime')
function! s:DateTime.year()
  return self._year
endfunction
function! s:DateTime.month()
  return self._month
endfunction
function! s:DateTime.day()
  return self._day
endfunction
function! s:DateTime.hour()
  return self._hour
endfunction
function! s:DateTime.minute()
  return self._minute
endfunction
function! s:DateTime.second()
  return self._second
endfunction
function! s:DateTime.timezone(...)
  return a:0 ? self.to(call('s:timezone', a:000)) : self._timezone
endfunction
function! s:DateTime.day_of_week()
  if !has_key(self, '_day_of_week')
    let self._day_of_week = self.days_from_era() % 7
  endif
  return self._day_of_week
endfunction
function! s:DateTime.day_of_year()
  if !has_key(self, '_day_of_year')
    let self._day_of_year = self.julian_day() -
    \                       s:_g2jd(self._year, 1, 1) + 1
  endif
  return self._day_of_year
endfunction
function! s:DateTime.days_from_era()
  if !has_key(self, '_day_from_era')
    let self._day_from_era = self.julian_day() - s:ERA_TIME + 1
  endif
  return self._day_from_era
endfunction
function! s:DateTime.julian_day(...)
  let jd = s:_g2jd(self._year, self._month, self._day)
  if a:0 && a:1
    if has('float')
      let jd += (self.seconds_of_day() + 0.0) / s:SECONDS_OF_DAY - 0.5
    elseif self._hour < 12
      let jd -= 1
    endif
  endif
  return jd
endfunction
function! s:DateTime.seconds_of_day()
  return (self._hour * s:NUM_MINUTES + self._minute)
  \      * s:NUM_SECONDS + self._second
endfunction
function! s:DateTime.quarter()
  return (self._month - 1) / 3 + 1
endfunction
function! s:DateTime.unix_time()
  if !has_key(self, '_unix_time')
    if self._year < 1969 || 2038 < self._year
      let self._unix_time = -1
    else
      let self._unix_time = (self.julian_day() - s:EPOC_TIME) *
      \  s:SECONDS_OF_DAY + self._hour * 3600 + self._minute * 60 +
      \  self._second - self._timezone.offset()
      if self._unix_time < 0
        let self._unix_time = -1
      endif
    endif
  endif
  return self._unix_time
endfunction
function! s:DateTime.is_leap_year()
  return s:is_leap_year(self._year)
endfunction
function! s:DateTime.is(dt)
  return self.compareTo(a:dt) == 0
endfunction
function! s:DateTime.compareTo(dt)
  return self.delta(a:dt).sign()
endfunction
function! s:DateTime.delta(dt)
  return s:delta(self.days_from_era() - a:dt.days_from_era(),
  \              (self.seconds_of_day() + self.timezone().offset()) -
  \              (a:dt.seconds_of_day() + a:dt.timezone().offset()))
endfunction
function! s:DateTime.to(...)
  let dt = self._clone()
  if a:0 && s:_is_class(a:1, 'TimeZone')
    let dt._second += a:1.offset() - dt.timezone().offset()
    let dt._timezone = a:1
    return dt._normalize()
  endif
  let delta = call('s:delta', a:000)
  let dt._day += delta.days() * delta.sign()
  let dt._second += delta.seconds() * delta.sign()
  return dt._normalize()
endfunction
function! s:DateTime.format(format, ...)
  let locale = a:0 ? a:1 : ''
  let result = ''
  for f in s:_split_format(a:format)
    if s:V.is_string(f)
      let result .= f
    elseif s:V.is_list(f)
      let [d, flag, width] = f
      let info = s:format_info[d]
      let padding = ''
      if s:V.is_list(info[1])
        let [padding, w] = info[1]
        if width ==# ''
          let width = w
        endif
      endif
      if has_key(self, info[0])
        let value = self[info[0]]()
        if 2 < len(info)
          let l:['value'] = eval(info[2])
        endif
      elseif 2 < len(info)
        let value = info[2]
      endif
      if flag ==# '^'
        let value = toupper(value)
      elseif flag ==# '-'
        let padding = ''
      elseif flag ==# '_'
        let padding = ' '
      elseif flag ==# '0'
        let padding = '0'
      endif
      let result .= printf('%' . padding . width . 's', value)
      unlet value
    endif
    unlet f
  endfor
  return result
endfunction
function! s:DateTime.strftime(format)
  let expr = printf('strftime(%s, %d)', string(a:format), self.unix_time())
  return s:_with_locale(expr, a:0 ? a:1 : '')
endfunction
function! s:DateTime.to_string()
  return self.format('%c')
endfunction
function! s:DateTime._normalize()
  let next = 0
  for unit in ['second', 'minute', 'hour']
    let key = '_' . unit
    let self[key] += next
    let [next, self[key]] =
    \   s:_divmod(self[key], s:['NUM_' . toupper(unit . 's')])
  endfor
  let self._day += next
  let [self._year, self._month, self._day] =
  \   s:_jd2g(s:_g2jd(self._year, self._month, self._day))
  return self
endfunction

let s:DateTime['+'] = s:DateTime.to
let s:DateTime['-'] = s:DateTime.delta
let s:DateTime['=='] = s:DateTime.is


" ----------------------------------------------------------------------------
let s:TimeZone = s:_new_class('TimeZone')
function! s:TimeZone.offset()
  return self._offset
endfunction
function! s:TimeZone.minutes()
  return self._offset / s:NUM_SECONDS
endfunction
function! s:TimeZone.hours()
  return self._offset / s:SECONDS_OF_HOUR
endfunction
function! s:TimeZone.sign()
  return self._offset < 0 ? -1 : 0 < self._offset ? 1 : 0
endfunction
function! s:TimeZone.offset_string()
  return substitute(self.w3c(), ':', '', '')
endfunction
function! s:TimeZone.w3c()
  let sign = self._offset < 0 ? '-' : '+'
  let minutes = abs(self._offset) / s:NUM_SECONDS
  return printf('%s%02d:%02d', sign,
  \             minutes / s:NUM_MINUTES, minutes % s:NUM_MINUTES)
endfunction

" ----------------------------------------------------------------------------
let s:TimeDelta = s:_new_class('TimeDelta')
function! s:TimeDelta.seconds()
  return self._time
endfunction
function! s:TimeDelta.minutes()
  return self._time / s:NUM_SECONDS
endfunction
function! s:TimeDelta.hours()
  return self._time / s:SECONDS_OF_HOUR
endfunction
function! s:TimeDelta.days()
  return self._days
endfunction
function! s:TimeDelta.weeks()
  return self._days / s:NUM_DAYS_OF_WEEK
endfunction
function! s:TimeDelta.months()
  return self._days / 30
endfunction
function! s:TimeDelta.years()
  return self._days / 365
endfunction
function! s:TimeDelta.total_seconds()
  return self._days * s:SECONDS_OF_DAY + self._time
endfunction
function! s:TimeDelta.sign()
  return self._sign
endfunction
function! s:TimeDelta.negate()
  let td = self._clone()
  let td._sign = -self._sign
  return td
endfunction
function! s:TimeDelta.add(...)
  let n = self._clone()
  let other = call('s:delta', a:000)
  let n._days += other._days * other._sign
  let n._time += other._time * other._sign
  return n._normalize()
endfunction
function! s:TimeDelta.about()
  if self.sign() == 0
    return 'now'
  endif
  let dir = self.sign() < 0 ? 'ago' : 'later'
  if self._days == 0
    if self._time < s:NUM_SECONDS
      let val = self.seconds()
      let unit = val == 1 ? 'second' : 'seconds'
    elseif self._time < s:SECONDS_OF_HOUR
      let val = self.minutes()
      let unit = val == 1 ? 'minute' : 'minutes'
    else
      let val = self.hours()
      let unit = val == 1 ? 'hour' : 'hours'
    endif
  else
    if self._days < s:NUM_DAYS_OF_WEEK
      let val = self.days()
      let unit = val == 1 ? 'day' : 'days'
    elseif self._days < 30
      let val = self.weeks()
      let unit = val == 1 ? 'week' : 'weeks'
    elseif self._days < 365
      let val = self.months()
      let unit = val == 1 ? 'month' : 'months'
    else
      let val = self.years()
      let unit = val == 1 ? 'year' : 'years'
    endif
  endif
  return printf('%d %s %s', val, unit, dir)
endfunction
function! s:TimeDelta.to_string()
  let str = self.sign() < 0 ? '-' : ''
  if self._days != 0
    let str .= self._days . (self._days == 1 ? 'day' : 'days') . ', '
  endif
  let str .= printf('%02d:%02d:%02d',
  \                 self._time / (s:SECONDS_OF_HOUR),
  \                 (self._time / s:NUM_SECONDS) % s:NUM_MINUTES,
  \                 self._time % s:NUM_SECONDS)
  return str
endfunction
function! s:TimeDelta._normalize()
  if self._sign < 0
    let self._days = -self._days
    let self._time = -self._time
    let self._sign = -self._sign
  endif
  if self._days < 0 && 0 < self._time
    let self._days += 1
    let self._time -= s:SECONDS_OF_DAY
  elseif 0 < self._days && self._time < 0
    let self._days -= 1
    let self._time += s:SECONDS_OF_DAY
  endif
  let self._sign = self._time != 0 ? (0 <= self._time ? 1 : -1) :
  \                self._days != 0 ? (0 <= self._days ? 1 : -1) : 0
  if self._sign < 0
    let self._days = -self._days
    let self._time = -self._time
  endif
  return self
endfunction

" ----------------------------------------------------------------------------

" Converts Gregorian Calendar to Julian day
function! s:_g2jd(year, month, day)
  let [next, month] = s:_divmod(a:month - 1, s:NUM_MONTHS)
  let year = a:year + next + 4800 - (month <= 1)
  let month += month <= 1 ? 10 : -2
  return a:day + (153 * month + 2) / 5 + s:_div(1461 * year, 4) - 32045
  \      - s:_div(year, 100) + s:_div(year, 400)
endfunction

" Converts Julian day to Gregorian Calendar
function! s:_jd2g(jd)
  let t = a:jd + 68569
  let n = s:_div(4 * t, 146097)
  let t -= s:_div(146097 * n + 3, 4) - 1
  let i = (4000 * t) / 1461001
  let t += -(1461 * i) / 4 + 30
  let j = (80 * t) / 2447
  let x = j / 11
  let day = t - (2447 * j) / 80
  let month = j + 2 - (12 * x)
  let year = 100 * (n - 49) + i + x
  return [year, month, day]
endfunction

function! s:_names(dates, format, locale)
  return s:_with_locale('map(copy(a:1), "strftime(a:2, v:val)")',
  \                     a:locale, copy(a:dates), a:format)
endfunction

function! s:_with_locale(expr, locale, ...)
  if a:locale !=# ''
    let current_locale = v:lc_time
    execute 'language time' a:locale
  endif
  try
    return eval(a:expr)
  finally
    if a:locale !=# ''
      execute 'language time' current_locale
    endif
  endtry
endfunction

function! s:_div(n, d)
  return s:_divmod(a:n, a:d)[0]
endfunction
function! s:_mod(n, d)
  return s:_divmod(a:n, a:d)[1]
endfunction
function! s:_divmod(n, d)
  let [q, mod] = [a:n / a:d, a:n % a:d]
  return mod != 0 && (a:d < 0) != (mod < 0) ? [q - 1, mod + a:d] : [q, mod]
endfunction


" ----------------------------------------------------------------------------
function! s:_month_abbr(locale)
  return s:month_names(0, a:locale)
endfunction
function! s:_month_full(locale)
  return s:month_names(1, a:locale)
endfunction
function! s:_weekday_abbr(locale)
  return s:weekday_names(0, a:locale)
endfunction
function! s:_weekday_full(locale)
  return s:weekday_names(1, a:locale)
endfunction
function! s:_am_pm_lower(locale)
  return s:am_pm_names(0, a:locale)
endfunction
function! s:_am_pm_upper(locale)
  return s:am_pm_names(1, a:locale)
endfunction

" key = descriptor
" value = string (format alias)
" value = [field, captor, format_conv, parse_conv]
" at format:
"   field = function name of source.
"   captor = [flat, width] for number format.
"   format_conv = expr for convert. some variables are available.
"   parse_conv = unused.
" at parse:
"   field = param name (with "_")
"           if it doesn't exists, the descriptor can't use.
"   captor = pattern to match.
"   captor = [flat, width] for number format.
"   captor = a function to return a pattern or candidates.
"   format_conv = unused.
"   parse_conv = expr for convert. some variables are available.
let s:format_info = {
\   '%': ['', '%', '%'],
\   'a': ['day_of_week', function('s:_weekday_abbr'),
\         's:_weekday_abbr(locale)[value]'],
\   'A': ['day_of_week', function('s:_weekday_full'),
\         's:_weekday_full(locale)[value]'],
\   'b': ['month', function('s:_month_abbr'),
\         's:_month_abbr(locale)[value - 1]', 'value + 1'],
\   'B': ['month', function('s:_month_full'),
\         's:_month_full(locale)[value - 1]', 'value + 1'],
\   'c': '%F %T %z',
\   'C': ['year', ['0', 2], 'value / 100', 'o[key] % 100 + value * 100'],
\   'd': ['day', ['0', 2]],
\   'D': '%m/%d/%y',
\   'e': '%_m/%_d/%_y',
\   'F': '%Y-%m-%d',
\   'H': ['hour', ['0', 2]],
\   'I': ['hour', ['0', 2], 's:_mod(value - 1, 12) + 1', 'value % 12'],
\   'j': ['day_of_year', ['0', 3]],
\   'k': '%_H',
\   'l': '%_I',
\   'm': ['month', ['0', 2]],
\   'M': ['minute', ['0', 2]],
\   'n': ['', '\_.*', "\n"],
\   'p': ['hour', function('s:_am_pm_upper'),
\         's:_am_pm_upper(locale)[value / 12]', 'o[key] + value * 12'],
\   'P': ['hour', function('s:_am_pm_lower'),
\         's:_am_pm_lower(locale)[value / 12]', 'o[key] + value * 12'],
\   'r': '%I:%M:%S %p',
\   'R': '%H:%M',
\   's': ['unix_time', ['', 20]],
\   'S': ['second', ['0', 2]],
\   't': ['', '\_.*', "\t"],
\   'u': ['day_of_week', ['0', 1], 'value == 0 ? 7 : value'],
\   'U': 'TODO',
\   'T': '%H:%M:%S',
\   'w': ['day_of_week', ['0', 1]],
\   'y': ['year', ['0', 2], 'value % 100',
\         '(o[key] != 0 ? o[key] : (value < 69 ? 2000 : 1900)) + value'],
\   'Y': ['year', ['0', 4]],
\   'z': ['timezone', '[+-]\d\{4}', 'value.offset_string()', 's:timezone(value)'],
\ }
let s:format_info.h = s:format_info.b
let s:DESCRIPTORS_PATTERN = join(keys(s:format_info), '\|')

" 'foo%Ybar%02m' => ['foo', ['Y', '', -1], 'bar', ['m', '0', 2], '']
function! s:_split_format(format)
  let res = []
  let pat = '\C%\([-_0^#]\?\)\(\d*\)\(' . s:DESCRIPTORS_PATTERN . '\)'
  let format = a:format
  while format != ''
    let i = match(format, pat)
    if i < 0
      let res += [format]
      break
    endif
    if i != 0
      let res += [format[: i - 1]]
      let format = format[i :]
    endif
    let [matched, flag, width, d] = matchlist(format, pat)[: 3]
    let format = format[len(matched) :]
    let info = s:format_info[d]
    if s:V.is_string(info)
      let format = info . format
    else
      let res += [[d, flag, width]]
    endif
    unlet info
  endwhile
  return res
endfunction

if has('win16') || has('win32') || has('win64')
  function! s:_default_tz()
    return s:win_tz
  endfunction
else
  function! s:_default_tz()
    return strftime('%z')
  endfunction
endif

" ----------------------------------------------------------------------------
let s:NUM_SECONDS = 60
let s:NUM_MINUTES = 60
let s:NUM_HOURS = 24
let s:NUM_DAYS_OF_WEEK = 7
let s:NUM_MONTHS = 12
let s:SECONDS_OF_HOUR = s:NUM_SECONDS * s:NUM_MINUTES
let s:SECONDS_OF_DAY = s:SECONDS_OF_HOUR * s:NUM_HOURS
let s:ERA_TIME = s:_g2jd(1, 1, 1)
let s:EPOC_TIME = s:_g2jd(1970, 1, 1)

let s:MONTHS = map(range(1, 12),
\   's:from_date(1970, v:val, 1, 0, 0, 0, 0).unix_time()')
let s:WEEKS = map(range(4, 10),
\   's:from_date(1970, 1, v:val, 0, 0, 0, 0).unix_time()')
let s:AM_PM_TIMES = map([0, 12],
\   's:from_date(1970, 1, 1, v:val, 0, 0, 0).unix_time()')

let &cpo = s:save_cpo
