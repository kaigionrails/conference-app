D = Steep::Diagnostic

target :lib do
  signature "sig"

  check "app"

  configure_code_diagnostics do |hash|
    hash[D::Ruby::UnknownInstanceVariable] = :hint
  end
end

# target :test do
#   signature "sig", "sig-private"
#
#   check "test"
#
#   # library "pathname", "set"       # Standard libraries
# end
