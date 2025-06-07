defmodule Midi do
  defstruct(content: <<>>)

  defmodule Frame do
    defstruct(
        type: "xxxx",
        length: 0,
        data: <<>>
    )

    def to_binary(%Midi.Frame{type: type, length: length, data: data}) do
      <<
        type::binary-4,
        length::integer-32,
        data::binary
      >>
    end

    def from_file(name) do
      %Midi{content: File.read!(name)}
    end
  end
end
