require 'bundler/setup'
require 'net/ssh'

class SmartOS < Thor
  argument :host, :desc => "The host of the SmartOS global zone", :type => :string, :required => true

  no_tasks do
    def with_ssh
      config = Net::SSH::Config.for(host)
      Net::SSH.start(config[:host] || host, config[:user], config) do |ssh|
        yield ssh
      end
    end
  end

  class VM < SmartOS
    namespace "smartos:vm"

    desc "list", "Lists available virtual machines on the SmartOS global zone"
    def list
      with_ssh do |ssh|
        result = ssh.exec!("vmadm list")
        puts result
      end
    end

    desc "start [UUID]", "Starts a virtual machine or machines"
    method_option :alias, :desc => "Start the VM(s) by an alias", :type => :string, :required => false
    method_option :all, :required => false, :desc => "Start all VMs", :type => :boolean, :default => false
    def start(uuid = nil)
      with_ssh do |ssh|
        vms = case
              when uuid
                [uuid]
              when options['all']
                ssh.exec!("vmadm lookup").split(/\s+/)
              when options['alias']
                ssh.exec!("vmadm lookup alias=#{options['alias']}").split(/\s+/)
              else
                raise Thor::RequiredArgumentMissingError, "You must specify a VM UUID, --alias or --all!"
              end
        result = ssh.exec!("for v in #{vms.join(' ')}; do vmadm start $v; done")
        puts result
      end
    end
  end

  class Dataset < SmartOS
    namespace "smartos:dataset"
    desc "list", "Lists available datasets on the SmartOS global zone"
    def list
      with_ssh do |ssh|
        result = ssh.exec!("dsadm list")
        puts result
      end
    end
  end
end
