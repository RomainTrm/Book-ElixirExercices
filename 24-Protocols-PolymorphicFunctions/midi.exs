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
  end

  def from_file(name) do
    %Midi{content: File.read!(name)}
  end
end

defimpl Enumerable, for: Midi do
  ## Reduce
  # Housekeeping function for laizy handling
  def _reduce(_content, {:halt, acc}, _fun) do
    {:halted, acc}
  end

  # Housekeeping function for laizy handling
  def _reduce(content, {:suspend, acc}, fun) do
    {:suspended, acc, &_reduce(content, &1, fun)}
  end

  def _reduce(_content = "", {:cont, acc}, _fun) do
    {:done, acc}
  end

  def _reduce(<<
        type::binary-4,
        length::integer-32,
        data::binary-size(length),
        rest::binary
      >>,
      {:cont, acc},
      fun) do
    frame = %Midi.Frame{type: type, length: length, data: data}
    _reduce(rest, fun.(frame, acc), fun)
  end

  def reduce(%Midi{content: content}, state, fun) do
    _reduce(content, state, fun)
  end

  ## Count
  def count(midi = %Midi{}) do
    frame_count = Enum.reduce(midi, 0, fn (_, count) -> count + 1 end)
    {:ok, frame_count}
  end

  ## No implementations
  def member?(%Midi{}, %Midi.Frame{}) do
    {:error, __MODULE__}
  end

  def slice(%Midi{}) do
    {:error, __MODULE__}
  end
end

defimpl Collectable, for: Midi do
  def into(%Midi{content: content}) do
    {
      content,
      fn
        acc, {:cont, frame = %Midi.Frame{}} -> acc <> Midi.Frame.to_binary(frame)
        acc, :done -> %Midi{content: acc}
        _, :halt -> :ok
      end
    }
  end
end

defimpl Inspect, for: Midi do
  import Inspect.Algebra

  def inspect(%Midi{content: <<>>}, _opts) do
    "#Midi[<<empty>>]"
  end

  # Without Algebra
  # def inspect(midi = %Midi{}, _opts) do
  #   content =
  #     Enum.map(midi, fn frame -> Kernel.inspect(frame) end)
  #     |> Enum.join("\n")
  #   "#Midi[\n#{content}\n]"
  # end

  # With Algebra
  def inspect(midi = %Midi{}, opts) do
    open = color("#Midi[", :map, opts)
    close = color("]", :map, opts)
    separator = color(",", :map, opts)

    container_doc(
      open,
      Enum.to_list(midi),
      close,
      %Inspect.Opts{limit: 4},
      fn frame, _opts -> Inspect.Midi.Frame.inspect(frame, opts) end,
      separator: separator,
      break: :strict
    )
  end
end

defimpl Inspect, for: Midi.Frame do
  import Inspect.Algebra

  # Without Algebra
  # def inspect(%Midi.Frame{type: "MThd",
  #                         length: 6,
  #                         data: <<
  #                           format::integer-16,
  #                           tracks::integer-16,
  #                           division::bits-16
  #                         >>},
  #             _opts) do
  #   beats = decode(division)
  #   "#Midi.Header{Midi format: #{format}, tracks: #{tracks}, timing: #{beats}}"
  # end

  # def inspect(%Midi.Frame{type: "MTrk", length: length, data: data}, _opts) do
  #   "#Midi.Track{length: #{length}, data: #{Kernel.inspect(data)}}"
  # end

  # With Algebra
  def inspect(%Midi.Frame{type: "MThd",
                          length: 6,
                          data: <<
                            format::integer-16,
                            tracks::integer-16,
                            division::bits-16
                          >>
              },
              opts) do
    concat(
      [
        nest(
          concat(
            [
              color("#Midi.Header{", :map, opts),
              break(""),
              "Midi format: #{format}",
              break(" "),
              "tracks: #{tracks}",
              break(" "),
              "timing: #{decode(division)}"
            ]
          ),
          2
        ),
        break(""),
        color("}", :map, opts)
      ]
    )
  end

  def inspect(%Midi.Frame{type: "MTrk", length: length, data: data}, opts) do
    open = color("#Midi.Track[", :map, opts)
    close = color("]", :map, opts)
    separator = color(",", :map, opts)
    content = [
      length: length,
      data: data
    ]

    container_doc(
      open,
      content,
      close,
      %Inspect.Opts{limit: 15},
      fn {key, value}, opts ->
        key = color("#{key}:", :atom, opts)
        concat(key, concat(" ", to_doc(value, opts)))
      end,
      separator: separator,
      break: :strick
    )
  end

  defp decode(<<0::1, beats::15>>) do
    "#{beats} bpm"
  end

  defp decode(<<1::1, fps::7, beats::8>>) do
    "#{-fps} fps, #{beats}/frame"
  end

  defp decode(x) do
    raise inspect x
  end
end
