class env_config extends uvm_object;

  `uvm_object_utils(env_config)

  // Number of masters and slaves
  int num_masters;
  int num_slaves;

  // Enabled/Disabled status
  bit enabled_masters[];       // [num_masters]
  bit enabled_slaves[];        // [num_slaves]

  // Active/Passive status
  bit is_master_active[];      // [num_masters]
  bit is_slave_active[];       // [num_slaves]

  // Constructor
  function new(string name = "env_config");
    super.new(name);
  endfunction

endclass
