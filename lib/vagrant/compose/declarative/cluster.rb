require 'open4'
require_relative "../node"

module VagrantPlugins
  module Compose
    module Declarative

      class Cluster

        # The name of the cluster
        attr_reader   :name

        # The default vagrant base box to be used for creating vagrant machines in this cluster.
        # This setting can be changed at group/node level
        attr_accessor :box

        # The network domain to wich the cluster belongs (used for computing nodes fqdn)
        attr_accessor :domain

        # The root path for ansible playbook; it is used as a base path for computing ansible_group_vars and ansible_host_vars
        # It defaults to current directory/provisioning
        attr_accessor :ansible_playbook_path

        # Implements cluster creation from a playbook file
        def from (file)
          # calls vagrant-playbook utility for executing the playbook file.
          playbook = YAML.load(pycompose (file))

          # extract cluster attributes
          @name                   = playbook.keys[0]
          @box                    = playbook[@name]['box']
          @domain                 = playbook[@name]['domain']
          @ansible_playbook_path  = playbook[@name]['ansible_playbook_path']

          # extract nodes
          nodes = []
          playbook[@name]['nodes'].each do |node|

            boxname = node.keys[0]

            box             = node[boxname]['box']
            hostname        = node[boxname]['hostname']
            aliases         = node[boxname]['hostname']
            fqdn            = node[boxname]['fqdn']
            ip              = node[boxname]['ip']
            cpus            = node[boxname]['cpus']
            memory          = node[boxname]['memory']
            ansible_groups  = node[boxname]['ansible_groups']
            attributes      = node[boxname]['attributes']
            index           = node[boxname]['index']
            group_index     = node[boxname]['group_index']

            nodes << VagrantPlugins::Compose::Node.new(box, boxname, hostname, fqdn, aliases, ip, cpus, memory, ansible_groups, attributes, index, group_index)
          end

          # extract ansible inventory, ansible_group_vars, ansible_host_vars
          ansible_groups = {}
          if playbook[@name].key?("ansible")

            ansible = playbook[@name]['ansible']

            # extract ansible inventory
            ansible_groups = ansible['inventory']

            # cleanup ansible_group_vars files
            # TODO: make safe
            ansible_group_vars_path = File.join(@ansible_playbook_path, 'group_vars')

            if File.exists?(ansible_group_vars_path)
              Dir.foreach(ansible_group_vars_path) {|f| fn = File.join(ansible_group_vars_path, f); File.delete(fn) if f.end_with?(".yml")}
            end

            #generazione ansible_group_vars file (NB. 1 group = 1 gruppo host ansible)
            if ansible.key?("group_vars")
              ansible['group_vars'].each do |group, vars|
                # crea il file (se sono state generate delle variabili)
                unless vars.empty?
                  FileUtils.mkdir_p(ansible_group_vars_path) unless File.exists?(ansible_group_vars_path)
                  # TODO: make safe
                  fileName = group.gsub(':', '_')
                  File.open(File.join(ansible_group_vars_path,"#{fileName}.yml") , 'w+') do |file|
                    file.puts YAML::dump(vars)
                  end
                end
              end
            end

            # cleanup ansible_host_vars files (NB. 1 nodo = 1 host)
            # TODO: make safe
            ansible_host_vars_path = File.join(@ansible_playbook_path, 'host_vars')

            if File.exists?(ansible_host_vars_path)
              Dir.foreach(ansible_host_vars_path) {|f| fn = File.join(ansible_host_vars_path, f); File.delete(fn) if f.end_with?(".yml")}
            end

            #generazione ansible_host_vars file 
            if ansible.key?("host_vars")
              ansible['host_vars'].each do |host, vars|
                # crea il file (se sono state generate delle variabili)
                unless vars.empty?
                  FileUtils.mkdir_p(ansible_host_vars_path) unless File.exists?(ansible_host_vars_path)
                  
                  # TODO: make safe
                  File.open(File.join(ansible_host_vars_path,"#{host}.yml") , 'w+') do |file|
                    file.puts YAML::dump(vars)
                  end
                end
              end
            end
          end

          return nodes, ansible_groups 
        end


        # Executes pycompose command
        def pycompose (file)
          p_err = ""
          p_out = ""

          begin
            p_status = Open4::popen4("vagrant-playbook -f #{file}") do |pid, stdin, stdout, stderr|
                p_err = stderr.read.strip
                p_out = stdout.read.strip
            end
          rescue Errno::ENOENT
            raise VagrantPlugins::Compose::Errors::PyComposeMissing
          rescue Exception => e
            raise VagrantPlugins::Compose::Errors::PyComposeError, :message => e.message
          end

          if p_status.exitstatus != 0
            raise VagrantPlugins::Compose::Errors::PyComposeError, :message => p_err
          end

          return p_out
        end

      end
    end
  end
end
