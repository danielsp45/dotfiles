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

      try do
        File.rename!(source, destination)
      rescue
        e in File.RenameError -> IO.puts("Error moving file #{source} to #{destination}")
      end
    end)
  end

  defp get_config(config_name) do
    file = File.read!(@config)
    config = JSON.decode!(file)

    result = Map.get(config, config_name)

    if is_nil(result) do
      raise "param not found in config file"
    else
      result
    end
  end
end

DownloadsCleaner.run()
