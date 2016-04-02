require "pathname"

require "vagrant/compose/plugin"

module VagrantPlugins
  module Compose
    lib_path = Pathname.new(File.expand_path("../compose", __FILE__))
    autoload :Errors, lib_path.join("errors")

    # This returns the path to the source of this plugin.
    #
    # @return [Pathname]
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
    end
  end
end
