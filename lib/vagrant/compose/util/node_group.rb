require_relative "node"

module VagrantPlugins
  module Compose

    # Definisce un node group, ovvero un insieme di nodi con caratteristiche omogenee.
    # i singoli nodi del gruppo, sono generati in fase di compose tramite delle espressioni 
    # che generano i valori degli attributi che caratterizzano ogni nodo 
    class NodeGroup 
      attr_reader :uid
      attr_reader :name
      attr_reader :instances
      attr_accessor :box
      attr_accessor :boxname
      attr_accessor :hostname
      attr_accessor :aliases
      attr_accessor :ip
      attr_accessor :cpus
      attr_accessor :memory
      attr_accessor :ansible_groups
      attr_accessor :attributes

      def initialize(index, instances, name)  
        @index  = index
        @name = name
        @instances = instances
      end  

      # compone il gruppo, generando le istanze dei vari nodi
      def compose(cluster_name, cluster_domain, cluster_offset)
        node_index = 0
        while node_index < @instances
          box            = generate(:box, @box, node_index) 
          boxname        = "#{cluster_name}-#{generate(:boxname, @boxname, node_index)}" 
          hostname       = "#{cluster_name}-#{generate(:hostname, @hostname, node_index)}" 
          aliases        = generate(:aliases, @aliases, node_index).join(',')
          fqdn           = cluster_domain.empty? "#{hostname}" : "#{hostname}.#{cluster_domain}"
          ip             = generate(:ip, @ip, node_index)
          cpus           = generate(:cpus, @cpus, node_index)
          memory         = generate(:memory, @memory, node_index) 
          ansible_groups = generate(:ansible_groups, @ansible_groups, node_index)
          attributes     = generate(:attributes, @attributes, node_index)
          yield Node.new(box, boxname, hostname, fqdn, aliases, ip, cpus, memory, ansible_groups, attributes, cluster_offset + node_index, node_index)

          node_index += 1
        end
      end

      # funzione di utilità per l'esecuzione delle espressioni che generano 
      # i valori degli attributi
      def generate(var, generator, node_index)
        unless generator.respond_to? :call
          return generator
        else
          begin
            return generator.call(@index, @name, node_index) 
          rescue Exception => e
            raise VagrantPlugins::Compose::Errors::AttributeExpressionError, :message => e.message, :attribute => var, :node_index => node_index, :node_group_name => name
          end
        end
      end
    end 
  
  end
end 