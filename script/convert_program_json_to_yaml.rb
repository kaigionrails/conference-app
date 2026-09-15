#!/usr/bin/env ruby
# frozen_string_literal: true

# ========================================================================
# Kaigi on Rails プログラムデータ変換スクリプト
# ========================================================================
#
# 【概要】
# cfp-app からエクスポートした program.json と、タイムテーブルツールから
# エクスポートした time_slots.csv を突き合わせて、Rails アプリケーションの
# シードデータ (db/seeds/{year}.yaml) を生成します。
#
# - トーク情報 (タイトル / 概要 / 登壇者) は program.json から
# - 登壇開始時刻 (start_at) / 登壇時間 (duration_minutes) / 部屋 (track) は
#   time_slots.csv から
# を取得し、両者はタイトルの完全一致で紐付けます。
#
# 【使い方】
# $ ruby script/convert_program_json_to_yaml.rb 2026 --day1 2026-09-25
#
# --day1 には Day 1 の開催日 (YYYY-MM-DD) を渡します。time_slots.csv の
# Conference Day は 1 / 2 という相対値なので、実日付への変換に必要です。
#
# 【前提条件】
# 以下の 2 ファイルがプロジェクトルートに存在すること。
#
# - program.json
#   - トークのタイトル、概要、スピーカー情報などを含む JSON ファイル
#   - cfp-app からエクスポートしたもの
#     - https://cfp.kaigionrails.org/events/:slug/staff/program/sessions
# - time_slots.csv
#   - タイムテーブルの各枠の日付、時刻、部屋を含む CSV ファイル
#   - Conference Day, Start Time, End Time, Room Name, Title, Track Name,
#     Session Format, Description, Presenter のヘッダを持つ
#
# 【出力】
# db/seeds/{year}.yaml
#
# 【注意事項】
# - Keynote は program.json に含まれないため、CSV の行からタイトルと時刻のみを
#   取り込みます。概要と登壇者は空なので、生成後に手動で補完してください。
# - GitHub アカウントが登録されていない登壇者は github_username / slug が
#   空文字になります。slug には unique 制約があるため、生成後に手動で
#   埋める必要があります。対象の登壇者はスクリプトの最後に一覧表示されます。
# - GitHub アカウントの書式が不正な登壇者も同様に一覧表示されます。
#   cfp-app 側の入力ミスなので、生成後に手動で修正してください。
# ========================================================================

require "csv"
require "date"
require "fileutils"
require "json"
require "yaml"

TIME_ZONE_OFFSET = "+09:00"
GITHUB_USERNAME_PATTERN = /\A[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}\z/i

def abort_with(message)
  warn "Error: #{message}"
  exit 1
end

# Parse command line arguments
year = nil
day1 = nil

args = ARGV.dup
until args.empty?
  arg = args.shift
  name, _, inline_value = arg.partition("=")

  case name
  when "--day1"
    day1 = inline_value.empty? ? args.shift : inline_value
  when /\A\d{4}\z/
    year = name.to_i
  else
    abort_with "Unknown argument: #{arg}"
  end
end

abort_with "Year is required, e.g. ruby script/convert_program_json_to_yaml.rb 2026 --day1 2026-09-25" if year.nil?
abort_with "--day1 is required, e.g. --day1 #{year}-09-25" if day1.nil?

day1_date =
  begin
    Date.strptime(day1, "%Y-%m-%d")
  rescue Date::Error
    abort_with "--day1 must be in YYYY-MM-DD format: #{day1}"
  end

project_root = File.expand_path("..", __dir__)
program_json_path = File.join(project_root, "program.json")
time_slots_csv_path = File.join(project_root, "time_slots.csv")
output_path = File.join(project_root, "db", "seeds", "#{year}.yaml")

abort_with "program.json not found at #{program_json_path}" unless File.exist?(program_json_path)
abort_with "time_slots.csv not found at #{time_slots_csv_path}" unless File.exist?(time_slots_csv_path)

puts "Processing for year: #{year} (Day 1: #{day1_date})"
puts "  program.json:   #{program_json_path}"
puts "  time_slots.csv: #{time_slots_csv_path}"

# "10:00 am" / " 1:30 pm" のような表記を [hour, minute] に変換する
def parse_time_of_day(value)
  matched = value.to_s.strip.match(/\A(\d{1,2}):(\d{2})\s*(am|pm)\z/i)
  raise ArgumentError, "Unparsable time: #{value.inspect}" if matched.nil?

  hour = matched[1].to_i % 12
  hour += 12 if matched[3].casecmp?("pm")
  [hour, matched[2].to_i]
end

def build_time(date, value)
  hour, minute = parse_time_of_day(value)
  Time.new(date.year, date.month, date.day, hour, minute, 0, TIME_ZONE_OFFSET)
end

# GitHub アカウントは URL 形式で登録されている場合がある
def extract_github_username(github_account)
  value = github_account.to_s.strip
  return "" if value.empty?

  value.start_with?("http") ? value.split("/").last : value
end

# 部屋名 (Magenta) を track 名 (Magenta Hall) に変換する
def build_track(room_name)
  "#{room_name.to_s.strip} Hall"
end

# YAML の timestamp 型として出力するためのプレースホルダー
def timestamp_placeholder(time)
  "!!timestamp #{time.strftime("%Y-%m-%dT%H:%M:%S%:z")}"
end

# time_slots.csv からセッション行と Keynote 行を集める
sessions_by_title = {}
keynote_slots = []

CSV.foreach(time_slots_csv_path, headers: true).with_index(1) do |row, row_number|
  title = row["Title"].to_s.strip
  next if title.empty?

  start_at = build_time(day1_date + (row["Conference Day"].to_i - 1), row["Start Time"])
  end_at = build_time(day1_date + (row["Conference Day"].to_i - 1), row["End Time"])
  slot = {
    title: title,
    start_at: start_at,
    duration_minutes: ((end_at - start_at) / 60).to_i,
    track: build_track(row["Room Name"])
  }

  if row["Session Format"].to_s.strip.empty?
    keynote_slots << slot if title.match?(/keynote/i)
  else
    abort_with "Duplicated session title in time_slots.csv at row #{row_number}: #{title}" if sessions_by_title.key?(title)
    sessions_by_title[title] = slot
  end
end

program_data = JSON.parse(File.read(program_json_path))

missing_slots = program_data.map { |talk| talk["title"] }.reject { |title| sessions_by_title.key?(title) }
unless missing_slots.empty?
  abort_with "No matching row in time_slots.csv for:\n" + missing_slots.map { |title| "  - #{title}" }.join("\n")
end

speakers_without_github = []
speakers_with_invalid_github = []

talks = program_data.map do |talk|
  slot = sessions_by_title.fetch(talk["title"])

  speakers = (talk["speakers"] || []).map do |speaker|
    name = speaker["name"].to_s.strip
    github_username = extract_github_username(speaker["github_account"])
    if github_username.empty?
      speakers_without_github << name
    elsif !github_username.match?(GITHUB_USERNAME_PATTERN)
      speakers_with_invalid_github << [name, github_username]
    end

    {
      name: name,
      slug: github_username,
      github_username: github_username,
      gravatar_hash: speaker["gravatar_hash"],
      bio: speaker["bio"].to_s
    }
  end

  {
    title: talk["title"],
    abstract: talk["abstract"].to_s,
    start_at: slot[:start_at],
    duration_minutes: slot[:duration_minutes],
    track: slot[:track],
    speakers: speakers
  }
end

# Keynote は program.json に含まれないため、CSV の情報のみで枠を作る
keynotes = keynote_slots.map do |slot|
  {
    title: slot[:title],
    abstract: "",
    start_at: slot[:start_at],
    duration_minutes: slot[:duration_minutes],
    track: slot[:track],
    speakers: []
  }
end

sorted_talks = (keynotes + talks).sort_by { |talk| [talk[:start_at], talk[:track]] }
output_data = {
  talks: sorted_talks.map { |talk| talk.merge(start_at: timestamp_placeholder(talk[:start_at])) }
}

yaml_content = YAML.dump(output_data)
# プレースホルダーを YAML の timestamp 型に戻す
yaml_content.gsub!(/'!!timestamp ([\d\-T:+]+)'/, '!!timestamp \1')
yaml_content.gsub!(/"!!timestamp ([\d\-T:+]+)"/, '!!timestamp \1')

FileUtils.mkdir_p(File.dirname(output_path))
File.write(output_path, yaml_content)

puts "Successfully converted program.json and time_slots.csv to #{output_path}"
puts "Total talks converted: #{sorted_talks.length} (including #{keynotes.length} keynote(s))"

unless keynotes.empty?
  puts "\nNote: The following keynotes have no abstract and no speakers. Fill them in manually:"
  keynotes.each { |keynote| puts "  - #{keynote[:title]}" }
end

unless speakers_without_github.empty?
  puts "\nWarning: The following speakers have no GitHub account, so github_username and slug are empty."
  puts "         slug has a unique constraint, so you must fill them in manually:"
  speakers_without_github.uniq.each { |name| puts "  - #{name}" }
end

unless speakers_with_invalid_github.empty?
  puts "\nWarning: The following speakers have a malformed GitHub account. Fix them manually:"
  speakers_with_invalid_github.uniq.each { |name, github_username| puts "  - #{name}: #{github_username.inspect}" }
end
