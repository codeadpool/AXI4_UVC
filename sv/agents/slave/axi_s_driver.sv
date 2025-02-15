`ifndef AXI_S_DRIVER_SV
`define AXI_S_DRIVER_SV

//=========================================================================
// AXI Slave Driver Class
//=========================================================================
class axi_s_driver extends uvm_driver #(axi_txn);
  `uvm_component_utils(axi_s_driver)

  virtual axi_if              vif;
  axi_s_cfg                   cfg;
  
  uvm_tlm_analysis_fifo #(axi_txn) rd_addr_q;
  uvm_tlm_analysis_fifo #(axi_txn) wr_addr_q;
  uvm_tlm_analysis_fifo #(axi_txn) wr_data_q;
  
  bit [31:0]                  memory[*];
  int unsigned                outstanding_reads[$];
  int unsigned                outstanding_writes[$];

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(axi_s_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("NOCFG", "Configuration not set")

    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set")

    rd_addr_q = new("rd_addr_q", this);
    wr_addr_q = new("wr_addr_q", this);
    wr_data_q = new("wr_data_q", this);
  endfunction

  task run_phase(uvm_phase phase);
    fork
      handle_reset();      
      handle_rd_addr_task();  
      handle_rd_data_task();  
      handle_wr_addr_task();  
      handle_wr_data_task();  
      handle_wr_resp_task();  
    join_none 
  endtask

  task handle_reset();
    forever begin
      @(negedge vif.rstn);
      reset_signals();
      memory.delete();
      rd_addr_q.flush();
      wr_addr_q.flush();
      wr_data_q.flush();
    end
  endtask

  task reset_signals();
    vif.ARREADY <= 0;
    vif.AWREADY <= 0;
    vif.WREADY  <= 0;
    vif.RVALID  <= 0;
    vif.BVALID  <= 0;
    vif.RRESP   <= 0;
    vif.BRESP   <= 0;
  endtask

  task handle_rd_addr_task();
    forever begin
      axi_txn txn;
      int delay;
      delay = $urandom_range(0, cfg.max_arready_delay);
      repeat(delay) @(posedge vif.clk);
      vif.ARREADY <= 1;
      wait(vif.ARVALID && vif.ARREADY);
      txn = axi_txn::type_id::create("txn");
      txn.copy_cfg_fields(vif);
      if(!rd_addr_q.try_put(txn))
        `uvm_error("DRV", "Read address queue full")
      vif.ARREADY <= 0;
    end
  endtask

  task handle_rd_data_task();
    forever begin
      axi_txn txn;
      logic [31:0] addr;
      int beats_remaining;

      rd_addr_q.get(txn);
      fork
        begin
          automatic axi_txn local_txn = txn;
          automatic int beat_count = 0;
          repeat(local_txn.response_delay) @(posedge vif.clk);
          while(beat_count <= local_txn.LEN) begin
            addr = calculate_address(local_txn.ADDR, beat_count, 
                                     local_txn.SIZE, local_txn.BURST);
            vif.RVALID <= 1;
            vif.RID    <= local_txn.ID;
            vif.RLAST  <= (beat_count == local_txn.LEN);
            vif.RRESP  = check_read_status(addr);
            vif.RDATA  = memory.exists(addr) ? memory[addr] : 32'hdeadbeef;
            @(posedge vif.clk iff vif.RREADY);
            vif.RVALID <= 0;
            beat_count++;
          end
        end
      join_none 
    end
  endtask

  task handle_wr_addr_task();
    forever begin
      axi_txn txn;
      int delay;
      delay = $urandom_range(0, cfg.max_awready_delay);
      repeat(delay) @(posedge vif.clk);
      vif.AWREADY <= 1;
      wait(vif.AWVALID && vif.AWREADY);
      txn = axi_txn::type_id::create("txn");
      txn.copy_cfg_fields(vif);
      if(!wr_addr_q.try_put(txn))
        `uvm_error("DRV", "Write address queue full")
      vif.AWREADY <= 0;
    end
  endtask

  task handle_wr_data_task();
    forever begin
      axi_txn addr_txn, data_txn;
      int beat_count = 0;
      wr_addr_q.get(addr_txn);
      fork
        begin
          automatic axi_txn local_addr_txn = addr_txn;
          automatic logic [31:0] addr;
          automatic logic [31:0] data[$];
          while(beat_count <= local_addr_txn.LEN) begin
            repeat($urandom_range(0, cfg.max_wready_delay)) @(posedge vif.clk);
            vif.WREADY <= 1;
            @(posedge vif.clk iff vif.WVALID && vif.WREADY);
            data.push_back(vif.WDATA);
            addr = calculate_address(local_addr_txn.ADDR, beat_count,
                                     local_addr_txn.SIZE, local_addr_txn.BURST);
            if(vif.WLAST !== (beat_count == local_addr_txn.LEN))
              `uvm_error("DRV", "WLAST assertion mismatch")
            if(!local_addr_txn.inject_error && check_write_access(addr))
              memory[addr] = vif.WDATA;
            vif.WREADY <= 0;
            beat_count++;
          end
          data_txn = local_addr_txn;
          data_txn.data = data;
          if(!wr_data_q.try_put(data_txn))
            `uvm_error("DRV", "Write data queue full")
        end
      join_none 
    end
  endtask

  task handle_wr_resp_task();
    forever begin
      axi_txn txn;
      int delay;
      wr_data_q.get(txn);
      fork
        begin
          automatic axi_txn local_txn = txn;
          repeat(local_txn.response_delay) @(posedge vif.clk);
          vif.BVALID <= 1;
          vif.BID    <= local_txn.ID;
          vif.BRESP  <= check_write_status(local_txn.ADDR);
          @(posedge vif.clk iff vif.BREADY);
          vif.BVALID <= 0;
        end
      join_none
    end
  endtask
endclass

`endif
