# TODO
# * Ideally this would use the sandboxed version, but that's for later.
# * Use newer versions that the user might have installed through RubyGems?

require File.join(ENV['COCOAPODS_BUNDLE_ROOT'], 'bundler/setup')
require 'cocoapods'

Pod::Command.run(ARGV)
