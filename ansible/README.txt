############
using inventories

ansible-playbook -i inventories/common playbooks/common.yml --extra-vars="lastname=dodson today=20161018" --tags="install_homebrew" -v
############

variable precedence
if we have the same variable name, then precedence is

local file, - set_fact: cat="kitty"
host_vars/all
host_vars/{{ host }}
group_vars/{{ host }}
group_vars/all

############

to get around the with_items on multiple hosts.. see
C:\GIT\auto-client-setup\roles\common\tasks\with_items_on_multiple_hosts.yml

############

## TODO running playbooks & TAGS needs looking into

############

Ansible provides a so called check mode, also called dry run mode (in Tower for example).
Invoked via --check the check mode does not alter the target nodes,
but tries to output what would change and what not.
Note however that this needs to be supported by the used modules, and not all modules support this.

ansible-playbook --check -i hosts site.yml --tags="install_homebrew" -v

############
to enable testing of 'sudo' to root for permissions

key for pair

create key on source box
ssh-keygen

cat ~/.ssh/id_rsa.pub | ssh adodson@XXXX 'umask 0077; mkdir -p .ssh; cat >> .ssh/authorized_keys && echo "Key copied"'

###########
NOTE ON SUDO WITH KEY/PAIR

once there is a key/pair setup on host mc, then cannot use "host / user / password"

instead we use the key/pair host name
server-shani, and in the task specify the user

  become: yes
  become_user: shani

###########

---
- name: Fetch configuration from all webservers
hosts: webservers
tasks:
- name: Get config
get_url:
dest: "configs/{{ ansible_hostname }}"
force: yes
url: "http://{{ ansible_hostname }}/diagnostic/config"
delegate_to: localhost

If you are delegating to the localhost, you can use a shortcut when defining the
action that automatically uses the local machine. If you define the key of the action
line as local_action, then the delegation to localhost is implied. If we were to
have used this in the previous example, it would be slightly shorter and will look
like this:
---
- name: Fetch configuration from all webservers #2
hosts: webservers
tasks:
- name: Get config
local_action: get_url dest=configs/{{ ansible_hostname
}}.cfg url=http://{{ ansible_hostname

###########

https://galaxy.ansible.com/rvm/ruby

What is rvm1-ansible?
It is an Ansible role to install and manage ruby versions using rvm.

Why should you use rvm?
In production it's useful because compiling a new version of ruby can easily
take upwards of 10 minutes. That's 10 minutes of your CPU being pegged at 100%.

rvm has pre-compiled binaries for a lot of operating systems. That means you can
install ruby in about 1 minute, even on a slow micro instance.

This role even adds the ruby binaries to your system path when doing a system
wide install. This allows you to access them as if they were installed without
using a version manager while still benefiting from what rvm has to offer.

Installation
$ ansible-galaxy install rvm.ruby