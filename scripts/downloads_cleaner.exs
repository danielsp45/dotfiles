Mix.install([
  {:json, "~> 1.4"}
])

defmodule DownloadsCleaner do
  @config "./config.json"

  def run() do
    downloads_path = get_config("downloads_path")
    bin_path = get_config("bin_path")

    files = File.ls!(downloads_path)

    Enum.each(files, fn file ->
      source = Path.join(downloads_path, file)
      destination = Path.join(bin_path, file)
      IO.puts("Moving file #{source} to #{destination}")
      File.rename!(source, destination)
    end)
  end

  defp get_config(config) do
    file = File.read!(@config)
    result = JSON.decode!(file)

    if result[config] do
      result[config]
    else
      raise "param not found in config file"
    end
  end
end

DownloadsCleaner.run()
