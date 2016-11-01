module VagrantPlugins
  module Compose

    # This class define a node throught a set of setting to be used when creating vagrant machines in the cluster.
    # Settings will be assigned value by cluster.compose method, according with the connfiguration 
    # of the group of nodes to which the node belongs.
    class Node

      # The vagrant base box to be used for creating the vagrant machine that implements the node. 
      attr_reader :box

      # The box name for this node a.k.a. the name for the machine in VirtualBox/VMware console.
      attr_reader :boxname

      # The hostname for the node.
      attr_reader :hostname

      # The fully qualified name for the node.
      attr_reader :fqdn

      # The list of aliases a.k.a. alternative host names for the node.
      attr_reader :aliases

      # The ip for the node.      
      attr_reader :ip

      # The cpu for the node.
      attr_reader :cpus

      # The memory for the node.
      attr_reader :memory

      # The list of ansible_groups for the node.
      attr_reader :ansible_groups
      
      # A set of custom attributes for the node.
      attr_reader :attributes
      
      # A number identifying the node within the group of nodes to which the node belongs.
      attr_reader :index
      
      # A number identifying the group of nodes to which the node belongs.
      attr_reader :group_index

      def initialize(box, boxname, hostname, fqdn, aliases, ip, cpus, memory, ansible_groups, attributes, index, group_index) 
        @box            = box
        @boxname        = boxname
        @hostname       = hostname
        @fqdn           = fqdn
        @aliases        = aliases
        @ip             = ip
        @cpus           = cpus
        @memory         = memory
        @ansible_groups = ansible_groups
        @attributes     = attributes
        @index          = index
        @group_index    = group_index
      end 
    end
  
  end 
end