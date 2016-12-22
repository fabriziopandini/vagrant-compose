require "vagrant"

require_relative "programmatic/cluster"
require_relative "declarative/cluster"

module VagrantPlugins
  module Compose

  	# Vagrant compose plugin definition class.
  	# This plugins allows easy configuration of a data structure that can be used as a recipe
  	# for setting up and provisioning a vagrant cluster composed by several machines with different
  	# roles.
    class Config < Vagrant.plugin("2", :config)

      # After executing compose, it returns the list of nodes in the cluster.
      attr_reader :nodes

      # After executing compose, it returns the ansible_groups configuration for provisioning nodes in the cluster.
      attr_reader :ansible_groups

  	  def initialize
        @cluster = nil
    		@nodes = {}
        @ansible_groups ={}
        @multimachine_filter = ((['up', 'provision'].include? ARGV[0]) && ARGV.length > 1) ? ARGV.drop(1) : [] # detect if running vagrant up/provision MACHINE
  	  end

  	  # Implements cluster creation, through the execution of the give code.
  	  def compose (name, &block)
  	    # create the cluster (the data structure representing the cluster)
  		  @cluster = VagrantPlugins::Compose::Programmatic::Cluster.new(name)
    		begin
  			     # executes the cluster configuration code
          	block.call(@cluster)
  		  rescue Exception => e
  	      raise VagrantPlugins::Compose::Errors::ClusterInitializeError, :message => e.message, :cluster_name => name
  	    end
  	    # tranform cluster configuration into a list of nodes/ansible groups to be used for
  		  @nodes, inventory = @cluster.compose
        @ansible_groups = filterInventory(inventory)
   	  end

      # Implements cluster creation
      def from (playbook_file)
        # create the cluster (the data structure representing the cluster)
        @cluster = VagrantPlugins::Compose::Declarative::Cluster.new()

        # executes the vagrant playbook
        @nodes, inventory = @cluster.from(playbook_file)
        @ansible_groups = filterInventory(inventory)
      end

      #filter ansible groups if vagrant command specify filters and maps to a list of hostnames
      def filterInventory(inventory)
        ansible_groups = {}
        inventory.each do |group, hosts|
          ansible_groups[group] = []
          hosts.each do |host|
            if filterBoxname(host['boxname'])
              ansible_groups[group] << host['hostname']
            end
          end
        end

        return ansible_groups
      end

      def filterBoxname(boxname)
        if @multimachine_filter.length > 0
            @multimachine_filter.each do |name|
            if pattern = name[/^\/(.+?)\/$/, 1]
              # This is a regular expression filter, so we convert to a regular
              # expression check for matching.
              regex = Regexp.new(pattern)
              return boxname =~ regex
            else
              # filter name, just look for a specific VM
              return boxname == name
            end
          end
        else
          # No filter was given, so we return every VM in the order
          # configured.
          return true
        end
      end

   	  # Implements a utility method that allows to check the list of nodes generated by compose.
   	  def debug(verbose = false)
        puts "==> cluster #{@cluster.name} with #{nodes.size} nodes"

        if not verbose
          @nodes.each do |node|
           puts "        #{node.boxname} accessible as #{node.fqdn} #{node.aliases} #{node.ip} => [#{node.box}, #{node.cpus} cpus, #{node.memory} memory]"
          end
        else
          puts "- nodes"
          @nodes.each do |node|
            puts ""
            puts "   - #{node.boxname}"
            puts "     box            #{node.box}"
            puts "     boxname        #{node.boxname}"
            puts "     hostname       #{node.hostname}"
            puts "     fqdn           #{node.fqdn}"
            puts "     aliases        #{node.aliases}"
            puts "     ip             #{node.ip}"
            puts "     cpus           #{node.cpus}"
            puts "     memory         #{node.memory}"
            puts "     ansible_groups #{node.ansible_groups}"
            puts "     attributes     #{node.attributes}"
            puts "     index          #{node.index}"
            puts "     group_index    #{node.group_index}"
          end

          filter = " (NB. filtered by #{@cluster.multimachine_filter})" if not @multimachine_filter.empty?
          puts ""
          puts "- ansible_groups #{filter}"

          @ansible_groups.each do |group, hosts|
            puts ""
            puts "  - #{group}"
            hosts.each do |host|
              puts "    - #{host}"
            end
          end
        end
        puts ""
   	  end
    end
  end
end
