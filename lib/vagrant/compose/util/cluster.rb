require_relative "node_group"

# Definisce un cluster, ovvero l'insieme di 1..n gruppi di nodi con caratteristiche simili.
class Cluster

  attr_reader   :name
  attr_reader   :multimachine_filter
  attr_accessor :box
  attr_accessor :domain
  attr_accessor :ansible_playbook_path
  attr_accessor :ansible_context_vars
  attr_accessor :ansible_group_vars
  attr_accessor :ansible_host_vars

  # Costruttore di una istanza di cluster.
  def initialize(name)
    @group_index             = 0
    @node_groups           = {}
    @ansible_context_vars  = {}
    @ansible_group_vars    = {}
    @ansible_host_vars     = {}
    @multimachine_filter   = ""
    @ansible_playbook_path = File.join(Dir.pwd, 'provisioning')

    @name        = name 
    @box         = 'ubuntu/trusty64'
    @domain      = 'vagrant'
  end   

  # Metodo per la creazione di un gruppo di nodi; in fase di creazione, il blocco inizializza
  # i valori/le expressioni da utilizzarsi nella valorizzazione degli attributi dei nodi in fase di compose.
  #
  # Oltre alla creazione dei nodi, il metodo prevede anche l'esecuzione di un blocco di codice per
  # la configurazione del gruppo di nodi stesso.
  def nodes(instances, name, &block)
    raise RuntimeError, "Nodes #{name} already exists in this cluster." unless not @node_groups.has_key?(name)

    @node_groups[name] = NodeGroup.new(@group_index, instances, name)
    @node_groups[name].box        = @box 
    @node_groups[name].boxname    = lambda { |group_index, group_name, node_index| return "#{group_name}#{node_index + 1}" }
    @node_groups[name].hostname   = lambda { |group_index, group_name, node_index| return "#{group_name}#{node_index + 1}" }
    @node_groups[name].aliases    = []
    @node_groups[name].ip         = lambda { |group_index, group_name, node_index| return "172.31.#{group_index}.#{100 + node_index + 1}" }
    @node_groups[name].cpus       = 1
    @node_groups[name].memory     = 256
    @node_groups[name].ansible_groups = []
    @node_groups[name].attributes = {}

    @group_index += 1 

    block.call(@node_groups[name]) if block_given?
  end 

  # Prepara il provisioning del cluster
  def compose 

    @multimachine_filter =  ARGV.length > 1 ? ARGV[1] : "" # detect if running vagrant up/provision MACHINE

    ## Fase1: Creazione dei nodi

    # sviluppa i vari gruppi di nodi, creando i singoli nodi
    nodes = []

    @node_groups.each do |key, group| 
      group.compose(@name, @domain, nodes.size) do |node|
        nodes << node
      end
    end

    # sviluppa i gruppi abbinando a ciascono i nodi creati
    # NB. tiene in considerazione anche l'eventualità che un gruppo possa essere composto da nodi appartenenti a diversi node_groups
    ansible_groups= {}
    nodes.each do |node|
      node.ansible_groups.each do |ansible_group|
        ansible_groups[ansible_group] = [] unless ansible_groups.has_key? (ansible_group)
        ansible_groups[ansible_group] << node
      end  
    end

    ## Fase2: Configurazione provisioning del cluster via Ansible
    # Ogni nodo diventerà una vm su cui sarà fatto il provisioning, ovvero un host nell'inventory di ansible 
    # Ad ogni gruppo corrispondono nodi con caratteristiche simili

    # genearazione inventory file per ansible, aka ansible_groups in Vagrant (NB. 1 group = 1 gruppo ansible)
    ansible_groups_provision = {}
    ansible_groups.each do |ansible_group, ansible_group_nodes|
      ansible_groups_provision[ansible_group] = []
      ansible_group_nodes.each do |node|
        ansible_groups_provision[ansible_group] << node.hostname if @multimachine_filter.empty? or @multimachine_filter == node.boxname #filter ansible groups if vagrant command on one node
      end  
    end
    ansible_groups_provision['all_groups:children'] = ansible_groups.keys

    # Oltre alla creazione del file di inventory per ansible, contenente gruppi e host, è supportata:
    # - la creazione di file ansible_group_vars, ovvero di file preposti a contenere una serie di variabili - specifico di ogni gruppo di host  -
    #   per condizionare il provisioning ansible sulla base delle caratteristiche del cluster specifico
    # - la creazione di file ansible_host_vars, ovvero di file preposti a contenere una serie di variabili - specifico di ogni host -
    #   per condizionare il provisioning ansible sulla base delle caratteristiche del cluster specifico

    # La generazione delle variabili utilizza una serie di VariableProvisioner, uno o più d'uno per ogni gruppo di hosts, configurati durante la
    # definizione del cluster.

    context = {}

    #genearazione context (NB. 1 group = 1 gruppo host ansible)
    ansible_groups.each do |ansible_group, ansible_group_nodes|
      
      # genero le variabili per il group
      provisioners = @ansible_context_vars[ansible_group]
      unless provisioners.nil?
        # se necessario, normalizzo provisioner in array provisioners
        provisioners = [ provisioners ] if not provisioners.respond_to?('each') 
        # per tutti i provisioners abbinati al ruolo        
        provisioners.each do |provisioner|
          begin
            vars = provisioner.call(context, ansible_group_nodes)

            #TODO: gestire conflitto (n>=2 gruppi che generano la stessa variabile - con valori diversi)
            context = context.merge(vars)
          rescue Exception => e
            raise VagrantPlugins::Compose::Errors::ContextVarExpressionError, :message => e.message, :ansible_group => ansible_group
          end
        end  
      end
    end

    # cleanup ansible_group_vars files
    # TODO: make variable public
    @ansible_group_vars_path = File.join(@ansible_playbook_path, 'group_vars')
    # TODO: make safe
    FileUtils.mkdir_p(@ansible_group_vars_path) unless File.exists?(@ansible_group_vars_path)
    Dir.foreach(@ansible_group_vars_path) {|f| fn = File.join(@ansible_group_vars_path, f); File.delete(fn) if f.end_with?(".yml")}

    #generazione ansible_group_vars file (NB. 1 group = 1 gruppo host ansible)
    ansible_groups.each do |ansible_group, ansible_group_nodes|
      ansible_group_vars = {}
      # genero le variabili per il group
      provisioners = @ansible_group_vars[ansible_group]
      unless provisioners.nil?
        # se necessario, normalizzo provisioner in array provisioners
        provisioners = [ provisioners ] if not provisioners.respond_to?('each') 
        # per tutti i provisioners abbinati al ruolo        
        provisioners.each do |provisioner|
          begin
            vars = provisioner.call(context, ansible_group_nodes)

            #TODO: gestire conflitto (n>=2 gruppi che generano la stessa variabile - con valori diversi)
            ansible_group_vars = ansible_group_vars.merge(vars)
          rescue Exception => e
            raise VagrantPlugins::Compose::Errors::GroupVarExpressionError, :message => e.message, :ansible_group => ansible_group
          end
        end  
      end

      # crea il file (se sono state generate delle variabili)
      unless ansible_group_vars.empty?
        # TODO: make safe  
        File.open(File.join(@ansible_group_vars_path,"#{ansible_group}.yml") , 'w+') do |file|
          file.puts YAML::dump(ansible_group_vars)
        end 
      end
    end

    # cleanup ansible_host_vars files (NB. 1 nodo = 1 host)
    # TODO: make variable public
    @ansible_host_vars_path = File.join(@ansible_playbook_path, 'host_vars')
    # TODO: make safe
    FileUtils.mkdir_p(@ansible_host_vars_path) unless File.exists?(@ansible_host_vars_path)
    Dir.foreach(@ansible_host_vars_path) {|f| fn = File.join(@ansible_host_vars_path, f); File.delete(fn) if f.end_with?(".yml")}

    #generazione ansible_host_vars file
    nodes.each do |node|
      # genero le variabili per il nodo; il nodo, può essere abbinato a diversi gruppi
      ansible_host_vars = {}
      node.ansible_groups.each do |ansible_group|
        # genero le variabili per il gruppo
        provisioners = @ansible_host_vars[ansible_group]
        unless provisioners.nil?
          # se necessario, normalizzo provisioner in array provisioners
          provisioners = [ provisioners ] if not provisioners.respond_to?('each') 
          # per tutti i provisioners abbinati al gruppo
          provisioners.each do |provisioner|
            begin
              vars = provisioner.call(context, node)

              #TODO: gestire conflitto (n>=2 gruppi che generano la stessa variabile - con valori diversi)
              ansible_host_vars = ansible_host_vars.merge(vars)
            rescue Exception => e
              raise VagrantPlugins::Compose::Errors::HostVarExpressionError, :message => e.message, :host => node.hostname, :ansible_group => ansible_group
            end
          end  
        end
      end

      # crea il file (se sono state generate delle variabili)
      unless ansible_host_vars.empty?
        # TODO: make safe  
        File.open(File.join(@ansible_host_vars_path,"#{node.hostname}.yml") , 'w+') do |file|
          file.puts YAML::dump(ansible_host_vars)
        end 
      end
    end

    return nodes, ansible_groups_provision
  end

end 