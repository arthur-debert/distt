class Nanodoc < Formula
  desc "A minimalist document bundler designed for stitching hints, reminders and short docs."
  homepage "https://pypi.org/project/nanodoc"
  url "https://files.pythonhosted.org/packages/source/n/nanodoc/nanodoc-0.8.11.tar.gz"
  sha256 "6b2999845b23b744597498055746518747458daf9eecdc423de4a9ec6d46cba7"
  license "MIT"

  depends_on "python@3"

  def install
    # Get the path to the Homebrew Python
    python = Formula["python@3"].opt_bin/"python3"
    
    # Install using pip from Homebrew Python
    system python, "-m", "pip", "install", "--prefix=#{prefix}", "nanodoc==#{version}"

    # Create wrapper script that uses python -m nanodoc
    (bin/"nanodoc").write <<~EOS
      #!/bin/bash
      exec "#{python}" -m nanodoc "$@"
    EOS
    chmod 0755, bin/"nanodoc"
  end

  test do
    # Test using the wrapper script
    system bin/"nanodoc", "--help"

    # Also test using python -m directly
    python = Formula["python@3"].opt_bin/"python3"
    system python, "-m", "nanodoc", "--help"
  end
end