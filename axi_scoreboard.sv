class axi_scoreboard extends uvm_component;

  `uvm_component_utils(axi_scoreboard)

  // Analysis exports for master/slave monitors
  uvm_analysis_export #(axi_transaction) master_export[$];
  uvm_analysis_export #(axi_transaction) slave_export[$];

  // Internal analysis FIFOs
  uvm_tlm_analysis_fifo #(axi_transaction) master_fifo[$];
  uvm_tlm_analysis_fifo #(axi_transaction) slave_fifo[$];

  // Scoreboard storage: request and response DB
  typedef struct {
    axi_transaction txn;
    time timestamp;
  } txn_info_t;

  typedef int master_id_t;
  typedef int txn_id_t;

  // Mapping from master_id & txn_id to txn_info
  typedef txn_info_t txn_db_t[int][int]; // [master_id][txn_id]
  txn_db_t request_db;
  txn_db_t response_db;

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Dynamically create analysis exports/fifos for each master/slave
    int num_masters;
    int num_slaves;

    if (!uvm_config_db#(int)::get(this, "", "num_masters", num_masters))
      `uvm_fatal("SB_CFG", "num_masters not found")

    if (!uvm_config_db#(int)::get(this, "", "num_slaves", num_slaves))
      `uvm_fatal("SB_CFG", "num_slaves not found")

    foreach (int i [num_masters]) begin
      master_export.push_back(new($sformatf("master_export[%0d]", i), this));
      master_fifo.push_back(new($sformatf("master_fifo[%0d]", i), this));
    end

    foreach (int j [num_slaves]) begin
      slave_export.push_back(new($sformatf("slave_export[%0d]", j), this));
      slave_fifo.push_back(new($sformatf("slave_fifo[%0d]", j), this));
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    foreach (master_export[i])
      master_export[i].connect(master_fifo[i].analysis_export);

    foreach (slave_export[j])
      slave_export[j].connect(slave_fifo[j].analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    fork
      foreach (master_fifo[i]) monitor_master(i);
      foreach (slave_fifo[j]) monitor_slave(j);
    join
  endtask

  // MASTER TRANSACTION HANDLER
  task monitor_master(int master_id);
    axi_transaction txn;
    forever begin
      master_fifo[master_id].get(txn);
      int id = txn.txn_id;
      request_db[master_id][id] = '{txn, $time};
      `uvm_info("SB_MASTER", $sformatf("Received request: MID=%0d ID=%0d Addr=%h", master_id, id, txn.address), UVM_LOW)
    end
  endtask

  // SLAVE TRANSACTION HANDLER
  task monitor_slave(int slave_id);
    axi_transaction txn;
    forever begin
      slave_fifo[slave_id].get(txn);
      int mid = txn.master_id;
      int id  = txn.txn_id;

      if (!request_db.exists(mid) || !request_db[mid].exists(id)) begin
        `uvm_error("SB_MATCH", $sformatf("Orphaned response: No matching request for MID=%0d ID=%0d", mid, id))
        continue;
      end

      txn_info_t req = request_db[mid][id];

      // Match fields
      bit match = (txn.address == req.txn.address) &&
                  (txn.data    == req.txn.data) &&
                  (txn.resp    == req.txn.resp);

      if (!match) begin
        `uvm_error("SB_MISMATCH", $sformatf("Mismatch: Req Addr=%h, Resp Addr=%h", req.txn.address, txn.address))
      end else begin
        `uvm_info("SB_PASS", $sformatf("Matched transaction for MID=%0d ID=%0d", mid, id), UVM_LOW)
      end

      // Remove matched request
      request_db[mid].delete(id);
    end
  endtask

endclass
