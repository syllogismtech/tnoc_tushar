class multi_agent_env extends uvm_env;
  `uvm_component_utils(multi_agent_env)

  // Config Object
  env_config env_cfg;

  // Agent Handles
  axi_master_agent master_agents[];
  axi_slave_agent  slave_agents[];

  // Virtual Sequencer
  virtual_sequencer vseqr;

  // Scoreboard and Decoder
  address_decoder addr_dec;
  axi_scoreboard  sb;

  // Constructor
  extern function new(string name = "multi_agent_env", uvm_component parent = null);

  // UVM Phases
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);

endclass : multi_agent_env


function multi_agent_env::new(string name = "multi_agent_env", uvm_component parent = null);
  super.new(name, parent);
endfunction : new


function void multi_agent_env::build_phase(uvm_phase phase);
  super.build_phase(phase);

  // Get full config object
  if (!uvm_config_db#(env_config)::get(this, "", "env_cfg", env_cfg))
    `uvm_fatal("CFG_ERR", "env_cfg not found in config_db")

  // Create master agents
  master_agents = new[env_cfg.num_masters];
  foreach (master_agents[i]) begin
    if (env_cfg.enabled_masters[i]) begin
      uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("master_agents[%0d]", i),
        "is_active", env_cfg.is_master_active[i] ? UVM_ACTIVE : UVM_PASSIVE);
      master_agents[i] = axi_master_agent::type_id::create($sformatf("master_agents[%0d]", i), this);
    end
  end

  // Create slave agents
  slave_agents = new[env_cfg.num_slaves];
  foreach (slave_agents[j]) begin
    if (env_cfg.enabled_slaves[j]) begin
      uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("slave_agents[%0d]", j),
        "is_active", env_cfg.is_slave_active[j] ? UVM_ACTIVE : UVM_PASSIVE);
      slave_agents[j] = axi_slave_agent::type_id::create($sformatf("slave_agents[%0d]", j), this);
    end
  end

  // Virtual Sequencer
  vseqr = virtual_sequencer::type_id::create("vseqr", this);

  // Scoreboard and Address Decoder
  sb       = axi_scoreboard::type_id::create("sb", this);
  addr_dec = address_decoder::type_id::create("addr_dec", this);
endfunction : build_phase


function void multi_agent_env::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  // Connect master sequencers to virtual sequencer
  foreach (master_agents[i]) begin
    if (master_agents[i] != null)
      vseqr.master_seqr[i] = master_agents[i].sequencer;
  end

  // Connect slave sequencers to virtual sequencer
  foreach (slave_agents[j]) begin
    if (slave_agents[j] != null)
      vseqr.slave_seqr[j] = slave_agents[j].sequencer;
  end

  // Connect analysis ports to scoreboard
  foreach (master_agents[i]) begin
    if (master_agents[i] != null)
      master_agents[i].monitor.ap.connect(sb.master_export[i]);
  end

  foreach (slave_agents[j]) begin
    if (slave_agents[j] != null)
      slave_agents[j].monitor.ap.connect(sb.slave_export[j]);
  end

  // Connect decoder output to scoreboard input
  addr_dec.decoded_ap.connect(sb.decoded_input);
endfunction : connect_phase
