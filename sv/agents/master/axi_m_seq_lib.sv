//===========================================
// File: AXI Master Sequence library
//===========================================

//===========================================
// AXI Master Base Sequence
//===========================================
class axi_m_wbase_seq extends uvm_sequence #(axi_txn);
  `uvm_object_utils(axi_m_wbase_seq)
  
  function new(string name = "axi_m_wbase_seq");
    super.new(name);
  endfunction
endclass

//===========================================
// AXI Master Base WRITE sequence
//===========================================
class axi_m_wr_seq extends axi_m_wbase_seq;
  `uvm_object_utils(axi_m_wr_seq)
  
  function new(string name = "axi_m_wr_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    axi_txn txn;
    txn = axi_txn::type_id::create("txn");
    
    if (!txn.randomize() with { AWVALID == 1; WVALID == 1; BREADY == 1; }) begin
      `uvm_error("WRITE_SEQ", "Randomization failed")
    end
    
    send_request(txn);
  endtask
endclass

//===========================================
// AXI Master Base READ Sequence
//===========================================
class axi_m_rd_seq extends axi_m_wbase_seq;
  `uvm_object_utils(axi_m_rd_seq)
  
  function new(string name = "axi_m_rd_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    axi_txn txn;
    txn = axi_txn::type_id::create("txn");
    
    if (!txn.randomize() with { ARVALID == 1; RREADY == 1; }) begin
      `uvm_error("READ_SEQ", "Randomization failed")
    end
    
    send_request(txn);
  endtask
endclass

//===========================================
// AXI Master BURST WRITE Sequence
//===========================================
class axi_m_wr_burst_seq extends axi_m_wbase_seq;
  `uvm_object_utils(axi_m_wr_burst_seq)
  
  function new(string name = "axi_m_wr_burst_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    axi_txn txn;
    txn = axi_txn::type_id::create("txn");
    
    if (!txn.randomize() with { AWVALID == 1; WVALID == 1; BREADY == 1; AWLEN inside {[1:15]}; }) begin
      `uvm_error("BURST_WRITE_SEQ", "Randomization failed")
    end
    
    send_request(txn);
  endtask
endclass

//===========================================
// AXI Master BURST READ Sequence
//===========================================
class axi_m_rd_burst_seq extends axi_m_wbase_seq;
  `uvm_object_utils(axi_m_rd_burst_seq)
  
  function new(string name = "axi_m_rd_burst_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    axi_txn txn;
    txn = axi_txn::type_id::create("txn");
    
    if (!txn.randomize() with { ARVALID == 1; RREADY == 1; ARLEN inside {[1:15]}; }) begin
      `uvm_error("BURST_READ_SEQ", "Randomization failed")
    end
    
    send_request(txn);
  endtask
endclass
