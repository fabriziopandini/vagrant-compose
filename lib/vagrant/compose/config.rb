require "vagrant"

require_relative "util/cluster"

module VagrantPlugins
  module Compose
    class Config < Vagrant.plugin("2", :config)

      attr_reader :nodes, :ansible_groups

	  def initialize
		@nodes = {}
		@ansible_groups = {}
	  end
	  
	  def compose (name, &block)
	    # implementa la creazione di un cluster, l'esecuzione di un blocco di codice
  		# per la configurazione del cluster stesso, e l'esecuzione della sequenza di compose.
		@cluster = Cluster.new(name)
		begin
        	block.call(@cluster)
		rescue Exception => e
	      raise VagrantPlugins::Compose::Errors::ClusterInitializeError, :message => e.message, :cluster_name => name
	    end
		@nodes, @ansible_groups = @cluster.compose
 	  end

 	  def debug
 	  	puts "==> cluster #{@cluster.name} with #{nodes.size} nodes" 
 	  	@nodes.each do |node|
		   puts "        #{node.boxname} accessible as #{node.fqdn} #{node.aliases} #{node.ip} => [#{node.box}, #{node.cpus} cpus, #{node.memory} memory]"       

 	  	end
    	puts "    ansible_groups filtered by #{@cluster.multimachine_filter}" if not @cluster.multimachine_filter.empty?
 	  end
    end
  end
end