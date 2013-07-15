# Manage services using Supervisor.  Start/stop uses /sbin/service and enable/disable uses chkconfig

Puppet::Type.type(:service).provide :supervisor, :parent => :base do

  desc "Supervisor: A daemontools-like service monitor written in python
  "

  commands :supervisord   => "/usr/bin/supervisord",
           :supervisorctl => "/usr/bin/supervisorctl"

  def self.instances
    # this exclude list is all from /sbin/service (5.x), but I did not exclude kudzu
    []
  end

  def _name
    self.name.split(':')[0]
  end

  def process_name
    self.name
  end

  def enable
      output = supervisorctl(:add, @resource[:name])
  rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not enable #{self.name}: #{detail}"
  end

  def disable
    self.stopcmd
    output = supervisorctl(:remove, @resource[:name])
  rescue Puppet::ExecutionFailure
    raise Puppet::Error, "Could not disable #{self.name}: #{output}"
  end

  def status
    begin
      output = supervisorctl(:status)
    rescue Puppet::ExecutionFailure
      return :false
    end

    filtered_output = output.lines.grep /#{@resource[:name]}[ :_]/
    if filtered_output.empty?
      return :false
    end

    status_not_running = filtered_output.reject {|item| item =~ /RUNNING/}

    if status_not_running.empty?
      return :true
    end

    :false
  end

  def restart
    output = supervisorctl(:start, @resource[:name])
    started = output.lines.grep(/started$/).count
    stopped = output.lines.grep(/stopped$/).count
    if started == stopped and started > 0
      return
    end
  end

  def start
    output = supervisorctl(:start, @resource[:name])
    #if output.empty? and '*' in self.name
    #  return
    #end

    if output.include? 'ERROR (no such process)'
      raise Puppet::Error, "Could not start #{self.name}: #{output}"
    end

    filtered_output = output.lines.reject {|item| item =~ /ERROR (already started)/}
    filtered_output = filtered_output.reject {|item| item =~ /started/}
    raise Puppet::Error, "Could not start #{self.name}: #{output}" unless filtered_output.empty?
  end

  def stop
    supervisorctl(:stop, @resource[:name])
  end

end
