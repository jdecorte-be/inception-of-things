# Virtualization, Debian, and Vagrant Setup Guide

This guide explains how to install a Debian VM, enable virtualization, set up SSH, and use Vagrant for managing and provisioning virtual machines.

---

## Install Debian VM

1. Download ISO  
   [Debian Bullseye Installer](https://www.debian.org/releases/bullseye/debian-installer/)

2. VM Configuration (in VirtualBox, VMware, etc.)  
   - CPUs: 3  
   - RAM: 4096 MB  
   - Disk: 14 GB  
   - Graphics: Headless / no GUI

3. Hostname  
   ```
   login-nameS
   ```
   (where `S` stands for server).

4. Install SSH  
   - During setup, select the option to install `SSH server`.

---

## Enable Virtualization

### 1. Check if virtualization is enabled in Debian VM
```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```
- Output > 0 → virtualization enabled  
- Output = 0 → not enabled

### 2. On your Mac host machine
Check if CPU supports VMX:
```bash
sysctl -a | grep machdep.cpu.features
```
Look for `VMX`.

### 3. Enable Nested VT-x/AMD-V in VirtualBox
1. Power off VM completely.
2. In VirtualBox Settings → System → Processor:
   - Enable Nested VT-x/AMD-V
3. In System → Acceleration:
   - Enable VT-x/AMD-V

Alternatively, enable via CLI:
```bash
VBoxManage modifyvm "Your_VM_Name" --nested-hw-virt on
VBoxManage modifyvm "Your_VM_Name" --hwvirtex on
VBoxManage modifyvm "Your_VM_Name" --vtxvpid on
```

Replace `"Your_VM_Name"` with your VM’s name.

### 4. Verify Nested Virtualization
```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```
Result should be greater than 0.

---

## Install Virtualization Packages (inside Debian)

```bash
sudo apt-get update
sudo apt-get install -y qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager
```

---

## SSH Setup

- Install SSH:
  ```bash
  sudo apt-get install -y openssh-server
  ```
- Configure SSH key-based authentication:  
  [Video tutorial](https://www.youtube.com/watch?v=GW6_xA_WxsM)

---

## Vagrant Basics

### What is Vagrant?
Vagrant automates the creation and management of VMs.  
- Configurations are written in a `Vagrantfile`.
- Provisioning can be done with scripts or tools (Ansible, Puppet, Chef, Salt).

### Three key settings in `Vagrantfile`
1. Provider (VirtualBox, VMware, AWS, GCP, Azure, OpenStack)  
2. Base Image (example: `ubuntu/focal64`)  
3. Provisioner (Script, Ansible, Puppet, Chef, etc.)

---

## Vagrant Box Management

- `vagrant box add` → Add a box  
  ```bash
  vagrant box add ubuntu/focal64
  ```
- `vagrant box list` → List installed boxes  
- `vagrant box outdated` → Check for updates  
- `vagrant box update` → Update a box  
- `vagrant box repackage` → Repackage with new name  
- `vagrant box prune` → Remove old versions  
- `vagrant box remove` → Remove box  

Boxes are stored at:
- Mac/Linux: `~/.vagrant.d/boxes`  
- Windows: `C:/Users/USERNAME/.vagrant.d/boxes`

---

## Vagrant Core Commands

| Command | Description |
|---------|-------------|
| `vagrant init <box>` | Initialize Vagrantfile |
| `vagrant up` | Create and configure VM |
| `vagrant ssh` | SSH into VM |
| `vagrant ssh-config` | Show SSH config |
| `vagrant halt` | Stop VM |
| `vagrant suspend` | Suspend VM |
| `vagrant resume` | Resume VM |
| `vagrant reload` | Restart VM |
| `vagrant destroy` | Delete VM |
| `vagrant status` | VM status |
| `vagrant package` | Package VM into `.box` |
| `vagrant provision` | Run provisioners |
| `vagrant plugin install` | Install plugin |
| `vagrant plugin list` | List plugins |
| `vagrant plugin uninstall` | Remove plugin |

Extra VirtualBox commands:
```bash
vboxmanage list vms
vboxmanage list runningvms
```

---

## Provisioning with Vagrant

Provisioning = setting up a VM with required software automatically.  
Can be done via:

- Inline script in Vagrantfile:
  ```ruby
  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    sudo apt-get install apache2 -y
  SHELL
  ```

- External script:
  ```ruby
  config.vm.provision "shell", path: "provision.sh"
  ```

Run provisioning manually:
```bash
vagrant provision
```

---

## Networking in Vagrant

1. Port Forwarding
   ```ruby
   config.vm.network "forwarded_port", guest: 80, host: 8080
   ```
   Access via `http://localhost:8080`

2. Private Network (Host-only)
   ```ruby
   config.vm.network "private_network", ip: "192.168.56.10"
   ```

3. Public Network (Bridged)
   ```ruby
   config.vm.network "public_network"
   ```

---

## Shared Folders

```ruby
config.vm.synced_folder "./data", "/vagrant_data"
```

---

## Snapshots

```bash
vagrant snapshot save my_snapshot
vagrant snapshot restore my_snapshot
```

---

## Plugins

```bash
vagrant plugin install <name>
vagrant plugin list
vagrant plugin uninstall <name>
```

---

## Useful Resources

- [Fix dbus error](https://unix.stackexchange.com/questions/467618/how-do-i-fix-my-problem-with-hostnamectl-command-it-cannot-connect-to-dbus)  
- [Change hostname on Debian](https://www.cyberciti.biz/faq/how-to-change-hostname-on-debian-10-linux/)  
- [Install SSH on Debian](https://aymeric-cucherousset.fr/en/connecting-via-ssh-on-debian-11/)  
- [Install Vagrant](https://developer.hashicorp.com/vagrant/install#linux)  
- [Vagrant tutorial playlist](https://www.youtube.com/playlist?list=PLhW3qG5bs-L9S272lwi9encQOL9nMOnRa)  
- [Russian guide with all packages](https://github.com/codesshaman/inception/blob/main/01_INSTALL_SOFT.md)  
Vagrantfile generator: https://vagrantfile-generator.vercel.app/


Good Kubernetes tutorial : https://www.youtube.com/watch?v=7bA0gTroJjw
