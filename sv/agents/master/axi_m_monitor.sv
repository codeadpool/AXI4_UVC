`ifndef AXI_M_MONITOR_SV
`define AXI_M_MONITOR_SV

class axi_m_monitor extends uvm_monitor;
  `uvm_component_utils(axi_m_monitor)

  virtual axi_if vif;
  uvm_analysis_port#(axi_txn) mon_analysis_port;
  
  // Queues to track pending transactions
  axi_txn write_txn_q[$];
  axi_txn read_txn_q[$];

  function new(string name = "axi_m_monitor", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "Virtual interface isn't set")
    mon_analysis_port = new("mon_analysis_port", this);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      fork
        monitor_write();
        monitor_read();
      join_none;
    end
  endtask

  task monitor_write();
    axi_txn txn;
    
    forever begin
      txn = axi_txn::type_id::create("txn");
      
      wait(vif.m_mon.AWVALID && vif.m_mon.AWREADY);
      txn.AWADDR  = vif.m_mon.AWADDR;
      txn.AWBURST = vif.m_mon.AWBURST;
      txn.AWSIZE  = vif.m_mon.AWSIZE;
      txn.AWLEN   = vif.m_mon.AWLEN;
      txn.AWID    = vif.m_mon.AWID;

      `uvm_info(get_type_name(), $sformatf("Write Addr Captured: AWADDR=0x%0h, AWID=%0d", txn.AWADDR, txn.AWID), UVM_MEDIUM)

      for (int i = 0; i <= txn.AWLEN; i++) begin
        wait(vif.m_mon.WVALID && vif.m_mon.WREADY);
        txn.data.push_back(vif.m_mon.WDATA);
        txn.strb = vif.m_mon.WSTRB;
        
        if (vif.m_mon.WLAST)
          break;
      end

      `uvm_info(get_type_name(), $sformatf("Write Data Captured: Data=%p", txn.data), UVM_MEDIUM)

      write_txn_q.push_back(txn);
      wait(vif.m_mon.BVALID && vif.m_mon.BREADY);
      
      foreach (write_txn_q[i]) begin
        if (write_txn_q[i].AWID == vif.m_mon.BID) begin
          txn = write_txn_q[i];
          write_txn_q.delete(i);
          break;
        end
      end
      
      txn.BRESP = vif.m_mon.BRESP;
      txn.BID   = vif.m_mon.BID;

      `uvm_info(get_type_name(), $sformatf("Write Response Captured: BRESP=0x%0h, BID=%0d", txn.BRESP, txn.BID), UVM_MEDIUM)

      mon_analysis_port.write(txn);
    end
  endtask

  task monitor_read();
    axi_txn txn;
    
    forever begin
      txn = axi_txn::type_id::create("txn");

      wait(vif.m_mon.ARVALID && vif.m_mon.ARREADY);
      txn.ARADDR  = vif.m_mon.ARADDR;
      txn.ARBURST = vif.m_mon.ARBURST;
      txn.ARSIZE  = vif.m_mon.ARSIZE;
      txn.ARLEN   = vif.m_mon.ARLEN;
      txn.ARID    = vif.m_mon.ARID;

      `uvm_info(get_type_name(), $sformatf("Read Addr Captured: ARADDR=0x%0h, ARID=%0d", txn.ARADDR, txn.ARID), UVM_MEDIUM)

      read_txn_q.push_back(txn);
      for (int i = 0; i <= txn.ARLEN; i++) begin
        wait(vif.m_mon.RVALID && vif.m_mon.RREADY);
        
        // Match response with request
        foreach (read_txn_q[j]) begin
          if (read_txn_q[j].ARID == vif.m_mon.RID) begin
            txn = read_txn_q[j];
            read_txn_q.delete(j);
            break;
          end
        end
        
        txn.data.push_back(vif.m_mon.RDATA);
        txn.RRESP = vif.m_mon.RRESP;
        txn.RID   = vif.m_mon.RID;
        
        `uvm_info(get_type_name(), $sformatf("Read Data Captured: Data=%0h, RRESP=0x%0h, RID=%0d", vif.m_mon.RDATA, vif.m_mon.RRESP, vif.m_mon.RID), UVM_MEDIUM)

        if (vif.m_mon.RLAST)
          break;
      end

      mon_analysis_port.write(txn);
    end
  endtask
endclass

`endif
