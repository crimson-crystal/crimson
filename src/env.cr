module Crimson::ENV
  CRIMSON_LIBRARY = begin
    {% if flag?(:win32) %}
      Path[::ENV["APPDATA"]] / "crimson"
    {% else %}
      if data = ::ENV["XDG_DATA_HOME"]?
        Path[data] / "crimson"
      else
        Path.home / ".local" / "share" / "crimson"
      end
    {% end %}
  end

  CRYSTAL_CACHE = begin
    {% if flag?(:win32) %}
      Path[::ENV["LOCALAPPDATA"]] / "crystal"
    {% else %}
      Path.home / ".cache" / "crystal"
    {% end %}
  end

  CRYSTAL_LIBRARY = begin
    {% if flag?(:win32) %}
      Path[::ENV["LOCALAPPDATA"]] / "Programs" / "Crystal"
    {% else %}
      Path["usr"] / "lib" / "crystal"
    {% end %}
  end
end
