# Declarative Approach

Vagrant requires some ruby knowledge, because the Vagrantfile itself is based on ruby, and this fact sometimes is and obstacle for people with limited programming background.

This cannot be avoided, but by using the declarative approach also people with limited programming background can use vagrant-compose to easily define a cluster composed by many VMs.

With declarative approach,  the definition of the cluster is done in yaml, and the ruby programming part within the Vagrantfile is reduced to the minimum.

## Quick start

Create a yaml file containing the definition of a cluster named `kubernates` with one `master` node and three `minions`  nodes.

```yaml
kubernetes:
  master:
    instances: 1
  minions:
    instances: 3
```

Then create the following `Vagrantfile` for parsing the above yaml file 

```ruby
Vagrant.configure(2) do |config|
  #load cluster definition
  config.cluster.from("mycluster.yaml")

  #cluster creation
  config.cluster.nodes.each do |node, index|
    config.vm.define "#{node.boxname}" do |node_vm|
      node_vm.vm.box = "#{node.box}"
    end
  end
end
```

The first part of the `Vagrantfile` contains the command for parsing the cluster definition:  

```ruby
config.cluster.from("mycluster.yaml")
```

The second part of the `Vagrantfile` creates the cluster by defining a vm in VirtualBox for each node in the cluster:

```ruby
config.cluster.nodes.each do |node, index|
  config.vm.define "#{node.boxname}" do |node_vm|
    node_vm.vm.box = "#{node.box}"
  end
end
```

If you run `vagrant up` you will get a 4 node cluster with following machines, based on `ubuntu/trusty64` base box (default).

- `master1`
- `minion1`
- `minion2`
- `minion3`

Done !

Of course, real-word scenarios are more complex; it is necessary to get more control in configuring the cluster topology and machine attributes, and finally you need also to implement automatic provisioning of software stack installed in the machines.

See following chapters for more details.

## Configuring the cluster

For instance, if you are setting up an environment for testing [Kubernetes](http://kubernetes.io/), your cluster will be composed by:

- a group of nodes for kubernetes master roles (masters)
- a group of nodes for deploying pods (minions)

Using the declarative approach, the above cluster can be defined using a yaml file, and using vagrant-compose plugin, it very easy to instruct Vagrant create a separate VM for each of the above node.

### Defining cluster and cluster attributes

The outer element of the yaml file should be an object with the cluster name:

````yaml
kubernetes:
  ...
````

Inside the cluster element, cluster attributes ca be defined:

```yaml
kubernetes:
  box: ubuntu/trusty64
  domain: test
  ...
```

Valid cluster attributes are defined in the following list; if an attribute is not provided, the default value apply.
- **`box`**
  The value/value generator to be used for assigning a base box to nodes in the cluster; it defaults to ubuntu/trusty64.
  NB. this attribute acts as defaults for all node groups, but each node group can override it. 
- **`node_prefix`**
  A prefix to be added before each node name / box name; it defaults to empty string (no prefix)
- **`domain`**
  The network domain to wich the cluster belongs. It will be used for computing nodes fqdn; it defaults to vagrant

### Defining set of nodes

A cluster can be composed by one or more set of nodes; each set of nodes represent a group of one or more nodes with similar characteristics.

Node groups are defined as elements within the cluster element:

```yaml
kubernetes:
  ...
  masters:
    ...
  minions:
    ...
  ...
```

Each node group element can contain a list of attributes; attributes defined at node group level will act as templete/value generator for the same attribute for each node within the group.

Available node group attributes are defined in the following list; if an attribute is not provided, the default value apply.

- **`instances`**
  The number of nodes in the node group; default value equals to 1.

- **`box`**
  The value/value generator to be used for assigning a base box to nodes in the node group; default value equals to**`cluster.box`** attribute.

- **`boxname`**
  The value/value generator to be used for assigning a boxname to nodes in the node group; default value is the following expression:

  **`"{% if cluster_node_prefix %}{{cluster_node_prefix}}-{% endif %}{{group_name}}{{node_index + 1}}"`**

- **`hostname`**
  The value/value generator to be used for assigning a hostname to nodes in the node group; default value is the following expression:

  **`"{{boxname}}"`**

- **`fqdn`**

  The value/value generator to be used for assigning a fqdn to nodes in the node group; default value is the following expression:

  **`"{{hostname}}{% if cluster_domain %}.{{cluster_domain}}{% endif %}"`**

- **`aliases`**
  The value/value generator to be used for assigning an alias/a list of aliases to nodes in the node group; default value is an empty list.

- **`ip`**
  The value/value generator to be used for assigning an ip address to nodes in the node group; default value is the following expression:

  **`"172.31.{{group_index}}.{{100 + node_index + 1}}"`**

- **`cpus`**
  The value/value generator to be used for defining the number of vCPU for nodes in the node group; default value is 1.

- **`memory`**
  The value/value generator to be used for defining the quantity of memory assigned to nodes in the node group; default value is 256.

- **`attributes`**

  The value/value generator to be used for defining additional attributes for nodes in the node group; default value is an empty dictionary.

Please note that each attributes can be set to:

- A literal value, like for instance `"ubuntu/trusty64" or 256. Such value will be inherited - without changes - by all nodes in the node group.
- A [Jinja2](http://jinja.pocoo.org/docs/dev/) expressions, afterwards value_generator, that will be executed when building the nodes in the node group.
  ​
  Jinja2 expressions are described in http://jinja.pocoo.org/docs/dev/templates/ ; on top of out of the box functions/filters defined in Jinja2, it is allowed usage of functions/filters defined in Ansible, as documented in http://docs.ansible.com/ansible/playbooks_filters.html. 
  ​
  Each expression will be executed within an execution context where a set of varibles is made available by the vagrant-playbook processors:
  - cluster_name
  - cluster_node_prefix
  - cluster_domain
  - group_index (the index of the nodegroup within the cluster, zero based)
  - group_name
  - node_index (the index of the node within the nodegroup, zero based)
  - additionally, all attributes already computed for this node group will be presented as variable (attributes are computed in following order: box, boxname, hostname, aliases, fqdn, ip, cpus, memory, ansible_groups, attributes; for instance, when execution the expression for computing the hostname attribute

## Composing nodes

The yaml file containing the cluster definition can be used within a Vagrant file as a recipe for building a cluster with a VM for each node.

``` ruby
Vagrant.configure(2) do |config|
  ...
  config.cluster.from("mycluster.yaml")
  ...
end
```
The above command will compose the cluster, transforming node groups in node, and store them in the `config.cluster.nodes` variable; each node has following attributes assigned according to value/value generators defined at node group level in the yaml file:

- **box**
- **boxname**
- **hostname**
- **fqdn**
- **aliases**
- **ip**
- **cpus**
- **memory**
- **attributes**

Two additional attributes will be automatically set for each node:

- **index**, [integer (zero based)], uniquely assigned to each node in the cluster
- **group_index**, [integer (zero based)], uniquely assigned to each node in a set of nodes

## Creating nodes

Given the list of nodes stored in the `config.cluster.nodes` variable, it is possible to create a multi-machine environment by iterating over the list:

``` ruby
config.cluster.nodes.each do |node|
  ...
end
```

Within the cycle you can instruct vagrant to create machines based on attributes of the current node; for instance, you can define a VM in VirtualBox (default Vagrant provider) and use the [vagrant-hostmanager](https://github.com/smdahlen/vagrant-hostmanager) plugin to set the hostname into the guest machine:

``` ruby
config.cluster.nodes.each do |node|
  config.vm.define "#{node.boxname}" do |node_vm|
    node_vm.vm.box = "#{node.box}"
    node_vm.vm.network :private_network, ip: "#{node.ip}"
    node_vm.vm.hostname = "#{node.fqdn}"
    node_vm.hostmanager.aliases = node.aliases unless node.aliases.empty?
    node_vm.vm.provision :hostmanager

    node_vm.vm.provider "virtualbox" do |vb|
      vb.name = "#{node.boxname}"  
      vb.memory = node.memory
      vb.cpus = node.cpus
    end            
  end
end
```

> In order to increase performance of node creation, you can leverage on support for linked clones introduced by Vagrant 1.8.1. Add the following line to the above script:
>
> vb.linked_clone = true if Vagrant::VERSION =~ /^1.8/

 [vagrant-hostmanager](https://github.com/smdahlen/vagrant-hostmanager) requires following additional settings before the `config.cluster.nodes.each` command:

``` ruby
config.hostmanager.enabled = false          
config.hostmanager.manage_host = true       
config.hostmanager.include_offline = true  
```

## Configuring ansible provisioning

The vagrant-compose plugin provides support for a straight forward provisioning of nodes in the cluster implemented with Ansible.

### Defining ansible_groups

Each set of nodes, and therefore all the nodes within the set, can be assigned to one or more ansible_groups.

In the following example, `masters` nodes will be part of `etcd` and `docker` ansible_groups.

```yaml
kubernetes:
  ...
  masters:
  ... 
    ansible_groups:
      - etcd
      - docker
     ...
  minions:
    ...
  ...
```

This configuration is used by the  `config.cluster.from(…)` method in order to define an **inventory file** with all nodes; the resulting list of ansible_groups, each with its own list of host  is stored in the `config.cluster.ansible_groups` variable.

Please note that the possibility to assign a node to one or more groups introduces an high degree of flexibility, as well as the capability to add nodes in different node groups to the same ansible_groups.

Ansible can leverage on ansible_groups for providing machines with the required software stacks.
NB. you can see resulting ansible_groups by using `debug` command with `verbose` equal to `true`.

### Defining group vars

In Ansible, the inventory file is usually integrated with a set of variables containing settings that will influence playbooks behaviour for all the host in a group.

The vagrant-compose plugin allows you to define one or more group_vars generator for each ansible_groups; 

```yaml
kubernetes:
  ansible_playbook_path: ...  
  ...
  masters:
    ansible_groups:
      - etcd
      - docker
  ...
  minions:
    ...
  ...
  ansible_group_vars:
    etcd :
      var1: ...
    docker :
      var2: ...
      var3: ...
  ...
```

Group vars can be set to literal value or to Jinja2 value generators, that will be executed during the parse of the yaml file; each Jinja2 expression will be executed within an execution context where a set of varibles is made available by the vagrant-playbook processors:

- **context_vars** see below
- **nodes**, list of nodes in the ansible_group to which the group_vars belong

Ansible group vars will be stored into yaml files saved into `{cluster.ansible_playbook_path}\group_vars` folder.

The variable  `cluster.ansible_playbook_path` defaults to the current directory  (the directory of the Vagrantfile)  +  `/provisioning`; this value can be changed like any other cluster attributes (see Defining cluster & cluster attributes).

### Defining host vars

While group vars will influence playbooks behaviour for all hosts in a group, in Ansible host vars will influence playbooks behaviour for a specific host.

The vagrant-compose plugin allows to define one or more host_vars generator for each ansible_groups;  

```yaml
kubernetes:
  ansible_playbook_path: ...  
  ...
  masters:
    ansible_groups:
      - etcd
      - docker
  ...
  minions:
    ...
  ...
  ansible_group_vars:
    ...
  ansible_host_vars:
    etcd :
      var5: ...
    docker :
      var6: ...
      var7: ...
  ...
```

Host vars can be set to literal value or to Jinja2 value generators, that will be executed during the parse of the yaml file; each Jinja2 expression will be executed within an execution context where a set of varibles is made available by the vagrant-playbook processors:

- **context_vars** see below
- **node**, the node in the ansible_group to which host_vars belongs

Ansible host vars will be stored into yaml files saved into `{cluster.ansible_playbook_path}\host_vars` folder.

### Context vars

Group vars and host var generation by design can operate only with the set of information that comes with a groups of nodes or a single node.

However, sometimes, it is necessary to share some information across group of nodes.
This can be achieved by setting one or more context_vars generator for each ansible_groups.

```yaml
kubernetes:
  ansible_playbook_path: ...  
  ...
  masters:
    ansible_groups:
      - etcd
      - docker
  ...
  minions:
    ...
  ...
  context_vars:
    etcd :
      var8: ...
    docker :
      var9: ...
      var10: ...
  ansible_group_vars:
    ...
  ansible_host_vars:
    ...
  ...
```

Context vars can be set to literal value or to Jinja2 value generators, that will be executed during the parse of the yaml file; each Jinja2 expression will be executed within an execution context where a set of varibles is made available by the vagrant-playbook processors:

- nodes, list of nodes in the ansible_group to which the group_vars belong


> Context_vars generator are always executed before group_vars and host_vars generators; the resulting context, is given in input to group_vars and host_vars generators.

Then, you can use the above context var when generating group_vars for host vars.

### Group of groups

A useful ansible inventory feature is [group of groups](http://docs.ansible.com/ansible/intro_inventory.html#hosts-and-groups).

By default vagrant-compose will generate a group named `[all_groups:children]` with all the ansible_groups defined in cluster configuration; however:
- you cannot rename all_groups
- you cannot exclude any ansible group from all_groups.

If you need higher control on groups of groups you can simply add a new item to the variable `config.cluster.ansible_groups` before creating nodes.

For instance:
```ruby
config.cluster.ansible_groups['k8s-cluster:children'] = ['kube-master', 'kube-nodes']
```

Please note that you can use this approach also for setting group variables directly into the inventory file using :vars (see ansible documentation).

## Creating nodes (with provisioning)

Given `config.cluster.ansible_groups` variable, generated group_vars and host_vars files, and of course an ansible playbook, it is possible to integrate provisioning into the node creation sequence.

NB. The example uses ansible parallel execution (all nodes are provisioned together in parallel after completing node creation).

``` ruby
config.cluster.from("mycluster.yaml")
...
config.cluster.nodes.each do |node|
  config.vm.define "#{node.boxname}" do |node_vm|
    ...
    if node.index == config.cluster.nodes.size - 1
      node_vm.vm.provision "ansible" do |ansible|
        ansible.limit = 'all' # enable parallel provisioning
        ansible.playbook = "provisioning/playbook.yml"
        ansible.groups = config.cluster.ansible_groups
      end
    end
  end
end
```

