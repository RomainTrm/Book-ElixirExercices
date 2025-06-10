defmodule KinectProtocolError do
  defexception message: "Kinect protocol error",
               can_retry: false

  def full_message(me) do
    "Kinect failed: #{me.message}, retriable: #{me.can_retry}"
  end
end

defmodule Test do
  def run do
    try do
      raise KinectProtocolError
    rescue
      error in [KinectProtocolError] ->
        IO.puts KinectProtocolError.full_message(error)
        if error.can_retry, do: IO.puts "Schedule retry"
    end
  end
end
