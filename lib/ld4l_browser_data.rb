require "ld4l_browser_data/version"

module Kernel
  def bogus(message)
    # Monkey patch for debugging: write a message with a "BOGUS" label to the console.
    puts(">>>>>>>>>>>>>BOGUS #{message}")
  end
end

module Ld4lBrowserData
  # You screwed up the calling sequence in the code.
  class IllegalStateError < StandardError
  end

  # What did you ask for?
  class UserInputError < StandardError
  end

  # Something is configured incorrectly.
  class SettingsError < StandardError
  end
end
