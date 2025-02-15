`ifndef AXI_S_MONITOR_SV
`define AXI_S_MONITOR_SV

class axi_s_monitor extends uvm_monitor;
  `uvm_component_utils(axi_s_monitor)

  virtual axi_if vif;
  uvm_analysis_port #(axi_txn) ap;

  function new(string name = "axi_s_monitor", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set for axi_s_monitor");

    ap = new("ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    fork
      collect_wr_addr_task();
      collect_wr_data_task();
      collect_wr_resp_task();
      collect_rd_addr_task();
      collect_rd_data_task();
    join
  endtask

  task collect_wr_addr_task();
    axi_txn txn_addr;
    forever begin
      @(posedge vif.CLK);
      if (vif.AWVALID && vif.AWREADY) begin
        txn_addr = axi_txn::type_id::create("txn_addr");
        txn_addr.ADDR = vif.AWADDR;
        txn_addr.PROT = vif.AWPROT;
        txn_addr.WR   = 1;
        // Optionally forward or store the write-address transaction.
        // For example: ap.write(txn_addr);
      end
    end
  endtask

  task collect_wr_data_task();
    axi_txn txn_data;
    forever begin
      @(posedge vif.CLK);
      if (vif.WVALID && vif.WREADY) begin
        txn_data = axi_txn::type_id::create("txn_data");
        txn_data.DATA = vif.WDATA;
        txn_data.STRB = vif.WSTRB;
        txn_data.LAST = vif.WLAST;
        if (vif.WLAST) begin
          ap.write(txn_data);
        end
      end
    end
  endtask

  task collect_wr_resp_task();
    axi_txn txn_resp;
    forever begin
      @(posedge vif.CLK);
      if (vif.BVALID && vif.BREADY) begin
        txn_resp = axi_txn::type_id::create("txn_resp");
        txn_resp.RESP = vif.BRESP;
        txn_resp.ID   = vif.BID;
        ap.write(txn_resp);
      end
    end
  endtask

  task collect_rd_addr_task();
    axi_txn txn_addr;
    forever begin
      @(posedge vif.CLK);
      if (vif.ARVALID && vif.ARREADY) begin
        txn_addr = axi_txn::type_id::create("txn_addr");
        txn_addr.ADDR = vif.ARADDR;
        txn_addr.PROT = vif.ARPROT;
        txn_addr.WR   = 0;
        // Optionally forward or store the read-address transaction.
        // For example: ap.write(txn_addr);
      end
    end
  endtask

  task collect_rd_data_task();
    axi_txn txn_data;
    forever begin
      @(posedge vif.CLK);
      if (vif.RVALID && vif.RREADY) begin
        txn_data = axi_txn::type_id::create("txn_data");
        txn_data.DATA = vif.RDATA;
        txn_data.RESP = vif.RRESP;
        txn_data.LAST = vif.RLAST;
        txn_data.ID   = vif.RID;
        ap.write(txn_data);
      end
    end
  endtask

endclass

`endif
