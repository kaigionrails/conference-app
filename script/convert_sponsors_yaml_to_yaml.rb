#!/usr/bin/env ruby
# frozen_string_literal: true

# プロジェクトルートの sponsors.yml を data/sponsors/{year}.yaml に変換します。
# tiers の各要素に slug と sponsors を持つ YAML を入力として使用します。
# key は logo の S{番号}_{key}_{plan} から、plan は tier の slug から取得し、
# name / logo / labels を出力します。
# 2026 では sponsor-app ではなく、公式サイトで利用している YAML をベースとしています。
#
# $ ruby script/convert_sponsors_yaml_to_yaml.rb 2026

require "fileutils"
require "yaml"

def abort_with(message)
  warn "Error: #{message}"
  exit 1
end

unless ARGV.length == 1 && ARGV.first.match?(/\A\d{4}\z/)
  abort_with "Usage: ruby script/convert_sponsors_yaml_to_yaml.rb YEAR"
end
year = ARGV.first.to_i

project_root = File.expand_path("..", __dir__)
sponsors_yaml_path = File.join(project_root, "sponsors.yml")
output_path = File.join(project_root, "data", "sponsors", "#{year}.yaml")

abort_with "sponsors.yml not found at #{sponsors_yaml_path}" unless File.exist?(sponsors_yaml_path)

sponsors_data = YAML.safe_load_file(sponsors_yaml_path, symbolize_names: true)
sponsors = sponsors_data.fetch(:tiers).flat_map do |tier|
  plan = tier.fetch(:slug)
  tier.fetch(:sponsors).map do |sponsor|
    logo = sponsor.fetch(:logo)
    matched = logo.match(/\AS\d+_(.+)_#{Regexp.escape(plan)}\z/)
    abort_with "Invalid sponsor logo (expected S{number}_{key}_#{plan}): #{logo}" if matched.nil?

    entry = {
      key: matched[1],
      name: sponsor.fetch(:name).strip,
      plan: plan,
      logo: logo
    }
    entry[:labels] = sponsor[:labels] if sponsor.key?(:labels)
    entry
  end
end

duplicate_keys = sponsors.group_by { |sponsor| sponsor[:key] }.select { |_key, entries| entries.length > 1 }.keys
abort_with "Duplicate sponsor keys: #{duplicate_keys.join(", ")}" unless duplicate_keys.empty?

output_data = {sponsors: sponsors}

FileUtils.mkdir_p(File.dirname(output_path))
File.write(output_path, YAML.dump(output_data))

puts "Successfully converted sponsors.yml to #{output_path}"
puts "Total sponsors converted: #{sponsors.length}"
