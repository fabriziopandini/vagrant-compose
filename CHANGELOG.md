# 0.7.4 (May 20, 2017)

* fix multimachine_filter error with commands without vmname

# 0.7.3 (May 20, 2017)

* PR Fix issue calling provision without filter #13 (now mutlimachine filter works properly even if mixed with other POSIX options)
* breaking change: removed cluster.multimachine_filter property (use instead config.multimachine_filter)

# 0.7.2 (November 16, 2016)

* issues #11 Allow management of Ansible vars for all hosts
* issues #9 Create group_vars and host_vars directory only if necessary

* breaking change: custom group of groups all_groups:children removed. Insteal use all (automatically created by ansible)

# 0.7.1 (November 04, 2016)

* Minor fix

# 0.7.0 (November 02, 2016)

* introduced support for declarative cluster definition

# 0.2.4 (June 26, 2016)

* issues #3 Now vagrant up and vagrant provision support also a list of machine name / regular expressions.
* pr #3 Support changing ansible_playbook_path & clean up   path management

NB. breaking change
ansible_group_vars_path and ansible_host_vars_path are not supported anymore

# 0.2.3 (April 2, 2016)

* Now custer name can be omitted (thanks to jaydoane)

other changes:
* Documented cluster.debug feature
* Improved code inline documentation

# 0.2.2 (December 31, 2015)

breaking changes!
* nodes instances number defined into node method (instances attributes removed)
* cluster.nodes return only nodes (before nodes with index were returned)

other changes:
* Improved documentation.
* cluster domain now is optional
* nodes code block now is optional
* improved detection of multimachine_filter
* minor fixes

# 0.1.0 (December 27, 2015)

* Initial release.


