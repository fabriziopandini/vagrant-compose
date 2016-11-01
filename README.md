# vagrant-compose

A Vagrant plugin that helps building complex scenarios with many VMs.

Each VM is a node in the cluster.
Typically, in a cluster nodes are grouped by type, and each group of nodes has different characteristic, software stacks and configuration.

For instance, if you are setting up an environment for testing [Consul](https://consul.io/), your cluster will be composed by:

- consul server nodes
- consul agent nodes

Vagrant-compose streamline the definition of complex multi-VMs scenarios, providing also support for a straight forward provisioning of nodes with Ansible.

## Installation

Install the plugin following the typical Vagrant procedure:

```
$ vagrant plugin install vagrant-compose
```

The declarative approach (see below) additionally requires the vagrant-playbook python package, that can be installed with

```
$ pip install vagrant-playbook
```

# Composing a cluster
Vagrant-compose supports two appraches for definining a cluster of VMs.

- Programmatic Approach

  Cluster are defined by using the some ruby knowledge that is required for writing Vagrantfiles.

  see [Programmatic Approach](https://github.com/fabriziopandini/vagrant-compose/blob/master/doc/programmatic.md) for more details.

- Declarative Approach

  By using the declarative approach also people with limited programming background can use vagrant-compose to easily define a cluster composed by many VMs; with declarative approach,  the definition of the cluster is done in yaml, and the ruby programming part within the Vagrantfile is reduced to the minimum.

  see [Declarative Approach](https://github.com/fabriziopandini/vagrant-compose/blob/master/doc/declarative.md) for more details.

# Additional notes
Vagrant compose will play nicely with all vagrant commands.

For instance, When using vagrant tageting a single machine, like f.i. `vagrant up mesos-master1`, the `cluster.ansible_groups` variable will include only the given machine.

Happy vagrant-compose!
