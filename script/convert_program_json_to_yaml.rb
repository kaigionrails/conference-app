#!/usr/bin/env ruby
# frozen_string_literal: true

# ========================================================================
# Kaigi on Rails プログラムデータ変換スクリプト
# ========================================================================
#
# 【概要】
# このスクリプトは、Kaigi on Rails のプログラム情報を
# program.jsonから読み込み、
# Railsアプリケーションで使用するシードデータ形式（db/seeds/{year}.yaml）に
# 変換します。
#
# 【使い方】
# $ ruby script/convert_program_json_to_yaml.rb [年]
# または
# $ ./script/convert_program_json_to_yaml.rb [年]
#
# 例:
# $ ruby script/convert_program_json_to_yaml.rb 2025
# $ ruby script/convert_program_json_to_yaml.rb  # 現在年をデフォルトで使用
#
# 【前提条件】
# 1. program.json がプロジェクトルートに存在すること
#   - トークのタイトル、概要、スピーカー情報などを含むJSONファイル
#   - cfp-appからエクスポートしたもの
#     - https://cfp.kaigionrails.org/events/:slug/staff/program/sessions
#
# 【出力】
# db/seeds/{year}.yaml
# - Railsのシードデータとして使用可能な形式のYAMLファイル
# - タイムスタンプは自動生成されますが、プレースホルダーなので
#   実際のカンファレンススケジュールに合わせて手動で調整が必要です
#
# 【処理の流れ】
# 1. program.jsonを読み込み
# 2. 各トークについて以下を処理：
#    - タイトル、概要、トラック情報を設定
#    - 発表時間を抽出（15分または30分）
#    - 固定のプレースホルダータイムスタンプを生成
#    - スピーカー情報をprogram.jsonから取得
# 3. YAML形式で出力（特殊なタイムスタンプ形式を保持）
#
# 【注意事項】
# - タイムスタンプは全て指定年の1月1日10:00の固定値として生成されます
# - 実際のカンファレンススケジュールに合わせて手動調整してください
# ========================================================================

require "json"
require "yaml"
require "time"
require "fileutils"
require "date"
require_relative "../config/environment"

# Parse command line arguments
year =
  if ARGV[0]
    ARGV[0].to_i
  else
    Time.zone.today.year
  end

puts "Processing for year: #{year}"

# Load program.json
program_json_path = File.join(__dir__, "..", "program.json")
unless File.exist?(program_json_path)
  puts "Error: program.json not found at #{program_json_path}"
  exit 1
end

# Parse file
program_data = JSON.parse(File.read(program_json_path))

# Helper function to extract GitHub username from URL or username
def extract_github_username(github_field)
  return nil if github_field.nil?

  # If it's a URL, extract the username
  if github_field.start_with?("http")
    github_field.split("/").last
  else
    github_field
  end
end

# Function to extract duration from format string
def extract_duration(format_str)
  return 30 if format_str.nil?

  case format_str
  when /Long session \(30 min\)/i
    30
  when /Short session \(15 min\)/i
    15
  else
    30 # default
  end
end

# Function to create a fixed placeholder timestamp
def create_timestamp(year)
  # Create a fixed timestamp for all talks: Jan 1 of the specified year, 10:00 AM JST
  base_time = Time.parse("#{year}-01-01 10:00:00 +0900")

  # Format as YAML timestamp
  # Using the special YAML timestamp format
  "!!timestamp #{base_time.strftime("%Y-%m-%dT%H:%M:%S%:z")}"
end

# Convert program data to the seed data format
converted_talks = []

program_data.each do |talk|
  converted_talk = {
    title: talk["title"],
    abstract: talk["abstract"]
  }

  # Add fixed placeholder timestamp (same for all talks)
  converted_talk[:start_at] = create_timestamp(year)

  # Extract duration from format
  converted_talk[:duration_minutes] = extract_duration(talk["format"])

  # Handle track (convert null to empty string)
  converted_talk[:track] = talk["track"] || ""

  # Process speakers
  if talk["speakers"] && !talk["speakers"].empty?
    speakers_array = []

    talk["speakers"].each do |speaker|
      speaker_name = speaker["name"]

      # Use data from program.json
      speaker_entry = {
        name: speaker_name,
        slug: extract_github_username(speaker["github_account"]),
        github_username: extract_github_username(speaker["github_account"]),
        gravatar_hash: speaker["gravatar_hash"],
        bio: speaker["bio"] || ""
      }

      speakers_array << speaker_entry
    end

    converted_talk[:speakers] = speakers_array
  end

  converted_talks << converted_talk
end

# Create the final structure
output_data = {
  talks: converted_talks
}

# Custom YAML generation to handle timestamp format
yaml_content = YAML.dump(output_data)

# Replace quoted timestamps with unquoted YAML timestamp format
yaml_content.gsub!(/'!!timestamp ([\d\-T:+]+)'/, '!!timestamp \1')
yaml_content.gsub!(/"!!timestamp ([\d\-T:+]+)"/, '!!timestamp \1')

# Output file path
output_path = File.join(__dir__, "..", "db", "seeds", "#{year}.yaml")

# Ensure the directory exists
FileUtils.mkdir_p(File.dirname(output_path))

# Write to file
File.write(output_path, yaml_content)

puts "Successfully converted program.json to #{output_path}"
puts "Total talks converted: #{converted_talks.length}"
puts "\nNote: All start_at timestamps are set to the same placeholder value (#{year}-01-01 10:00 JST) and must be manually adjusted to match the actual conference schedule."
