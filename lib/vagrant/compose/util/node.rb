module VagrantPlugins
  module Compose

    # Definisce un nodo, ovvero uno delle istanze di nodi che compongono il cluster
    class Node
      attr_reader :box
      attr_reader :boxname
      attr_reader :hostname
      attr_reader :fqdn
      attr_reader :aliases
      attr_reader :ip
      attr_reader :cpus
      attr_reader :memory
      attr_reader :ansible_groups
      attr_reader :attributes
      attr_reader :index
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