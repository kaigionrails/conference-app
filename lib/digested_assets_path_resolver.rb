require "json"

class DigestedAssetsPathResolver
  def initialize
      manifest_path = File.join("public", "assets", ".manifest.json")
      @manifest = if File.exist?(manifest_path)
        JSON.parse(File.read(manifest_path))
      else
        {}
      end
  end

  def digested_asset_path(source)
    File.join("assets", @manifest.fetch(source, source)).to_s
  end
end
