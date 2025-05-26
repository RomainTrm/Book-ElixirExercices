defmodule Dictionary do
  @name {:global, __MODULE__}

  # API
  def start_link,
  do: Agent.start_link(fn -> %{} end, name: @name)

  def add_words(words),
  do: Agent.update(@name, &do_add_words(&1, words))

  def anagrams_of(word),
  do: Agent.get(@name, &Map.get(&1, signature_of(word)))

  # Internal methods
  defp do_add_words(dictionary, words) do
    words |> Enum.reduce(dictionary, &add_one_word(&1, &2))
  end

  defp add_one_word(word, dictionary) do
    Map.update(dictionary, signature_of(word), [word], &[word|&1])
  end

  defp signature_of(word) do
    word |> to_charlist |> Enum.sort |> to_string
  end
end

defmodule WordListLoader do
  def load_from_files(files) do
    files
    |> Stream.map(fn name -> Task.async(fn -> load(name) end) end)
    |> Enum.map(&Task.await/1)
  end

  defp load(file) do
    File.stream!(file, [], :line)
    |> Stream.map(&String.trim/1)
    |> Dictionary.add_words
  end
end
