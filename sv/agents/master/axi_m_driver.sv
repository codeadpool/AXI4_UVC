//=========================================================================
// File: AXI Master Driver Class
// AXI master that can process both wr &rd txns
// The driver uses pipelined transaction queues (FIFOs)
// for each AXI channel to decouple the handshake processes and support
// concurrent transactions.
//=========================================================================

`ifndef AXI_M_DRIVER_SV
`define AXI_M_DRIVER_SV

class axi_m_driver extends uvm_driver #(axi_txn);

  `uvm_component_utils(axi_m_driver)
  virtual axi_if vif;
  axi_txn req;
  
  // Transaction queues (FIFOs) for pipelining.
  uvm_tlm_analysis_fifo #(axi_txn) wr_addr_q;
  uvm_tlm_analysis_fifo #(axi_txn) wr_data_q;
  uvm_tlm_analysis_fifo #(axi_txn) wr_resp_q;
  uvm_tlm_analysis_fifo #(axi_txn) rd_addr_q;
  uvm_tlm_analysis_fifo #(axi_txn) rd_data_q;

  function new(string name = "axi_m_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set")
    
    // Instantiate the TLM FIFOs for each AXI channel.
    wr_addr_q = new("wr_addr_q", this);
    wr_data_q = new("wr_data_q", this);
    wr_resp_q = new("wr_resp_q", this);
    rd_addr_q = new("rd_addr_q", this);
    rd_data_q = new("rd_data_q", this);
  endfunction

  task run_phase(uvm_phase phase);
    fork
      process_seq_items();            
      handle_wr_addr_task();      
      handle_wr_data_task();         
      handle_wr_resp_task();     
      handle_rd_addr_task();       
      handle_rd_data_task();         
    join
  endtask

  //-------------------------------------------------------------------------
  // process_seq_items: Receives transactions from the sequencer and
  // distributes them to the appropriate channel queues based on type.
  //-------------------------------------------------------------------------
  task process_seq_items();
    forever begin
      axi_txn txn;
      // Block until a new transaction is received.
      seq_item_port.get_next_item(txn);
      if(txn.txn_type == WRITE) begin
        if(!wr_addr_q.try_put(txn))
          `uvm_error("DRIVER", "Write address queue full")
      end
      else begin
        if(!rd_addr_q.try_put(txn))
          `uvm_error("DRIVER", "Read address queue full")
      end
      // Signal that the sequence item has been accepted.
      seq_item_port.item_done();
    end
  endtask

  //-------------------------------------------------------------------------
  // handle_wr_addr_task: Drives the write address and control
  // signals on the AXI interface. After the handshake, it enqueues the txn
  // into the write data queue.
  //-------------------------------------------------------------------------
  task handle_wr_addr_task();
    forever begin
      axi_txn txn;
      // Get a transaction from the write address queue.
      wr_addr_q.get(txn);
      fork
        begin

          vif.m_drv.AWADDR  <= txn.AWADDR;
          vif.m_drv.AWBURST <= txn.AWBURST;
          vif.m_drv.AWSIZE  <= txn.AWSIZE;
          vif.m_drv.AWLEN   <= txn.AWLEN;

          // Assert AWVALID to indicate valid address/control signals.
          vif.m_drv.AWVALID <= 1'b1;
          // Wait for the slave to assert AWREADY.
          wait(vif.m_drv.AWREADY);
          // Deassert AWVALID after handshake is complete.
          vif.m_drv.AWVALID <= 1'b0;
          // Enqueue the transaction into the write data queue for the next phase.
          if(!wr_data_q.try_put(txn))
            `uvm_error("DRIVER", "Write data queue full")
        end
      join_none 
    end
  endtask

  //-------------------------------------------------------------------------
  // handle_wr_data_task: Drives the write data and strobe signals.
  // It sends all data beats of the transaction, asserting WLAST on the final beat.
  // Once completed, the transaction is enqueued in the write response queue.
  //-------------------------------------------------------------------------
  task handle_wr_data_task();
    forever begin
      axi_txn txn;
      wr_data_q.get(txn);
      fork
        begin
          // Loop through each beat in the data array.
          foreach(txn.data[i]) begin
            vif.m_drv.WDATA  <= txn.data[i];      
            vif.m_drv.WSTRB  <= txn.strb;           
            vif.m_drv.WVALID <= 1'b1;           

            // Assert WLAST for the final data beat.
            vif.m_drv.WLAST  <= (i == txn.data.size()-1);
            // Wait for the slave to assert WREADY.
            wait(vif.m_drv.WREADY);
          end
          // After sending all beats, deassert WVALID.
          vif.m_drv.WVALID <= 1'b0;
          // Enqueue the transaction into the write response queue.
          if(!wr_resp_q.try_put(txn))
            `uvm_error("DRIVER", "Write response queue full")
        end
      join_none // Continue concurrently.
    end
  endtask

  //-------------------------------------------------------------------------
  // handle_wr_resp_task: Receives the write response from the slave.
  // The driver asserts BREADY and waits for BVALID, then optionally checks the
  // response status.
  //-------------------------------------------------------------------------
  task handle_wr_resp_task();
    forever begin
      axi_txn txn;
      wr_resp_q.get(txn);
      fork
        begin
          // Assert BREADY to indicate readiness to accept the response.
          vif.m_drv.BREADY <= 1'b1;
          // Wait for the slave to indicate a valid response.
          wait(vif.m_drv.BVALID);
          // Deassert BREADY once the response is received.
          vif.m_drv.BREADY <= 1'b0;
          // Optional check: Warn if the response indicates an error.
          if(vif.m_drv.BRESP != 2'b00)
            `uvm_warning("DRIVER", $sformatf("Bad write response: %0h", vif.m_drv.BRESP))
        end
      join_none
    end
  endtask

  //-------------------------------------------------------------------------
  // handle_rd_addr_task: Drives the read address and control signals.
  // After the handshake, it enqueues the transaction into the read data queue.
  //-------------------------------------------------------------------------
  task handle_rd_addr_task();
    forever begin
      axi_txn txn;
      rd_addr_q.get(txn);
      fork
        begin
          // Drive the read address signals.
          vif.m_drv.ARADDR  <= txn.ARADDR;
          vif.m_drv.ARBURST <= txn.ARBURST;
          vif.m_drv.ARSIZE  <= txn.ARSIZE;
          vif.m_drv.ARLEN   <= txn.ARLEN;
          // Assert ARVALID to indicate valid read address/control signals.
          vif.m_drv.ARVALID <= 1'b1;
          // Wait for the slave to assert ARREADY.
          wait(vif.m_drv.ARREADY);
          // Deassert ARVALID after the handshake.
          vif.m_drv.ARVALID <= 1'b0;
          // Enqueue the transaction into the read data queue.
          if(!rd_data_q.try_put(txn))
            `uvm_error("DRIVER", "Read data queue full")
        end
      join_none
    end
  endtask

  //-------------------------------------------------------------------------
  // handle_rd_data_task: Receives the read data beats from the slave.
  // The driver asserts RREADY and collects the data beats until the expected
  // number of beats (ARLEN+1) is received, while checking for early termination.
  //-------------------------------------------------------------------------
  task handle_rd_data_task();
    forever begin
      axi_txn txn;
      rd_data_q.get(txn);
      fork
        begin
          // Assert RREADY to indicate readiness for receiving data.
          vif.m_drv.RREADY <= 1'b1;
          // Clear any existing data in the transaction container.
          txn.data.delete();
          // Receive (ARLEN + 1) beats of data.
          repeat(txn.ARLEN + 1) begin
            // Wait for the slave to assert RVALID.
            wait(vif.m_drv.RVALID);
            // Append the received data beat to the transaction's data array.
            txn.data.push_back(vif.m_drv.RDATA);
            // Check for early assertion of RLAST (should only be on the final beat).
            if(vif.m_drv.RLAST && (txn.data.size() != txn.ARLEN + 1))
              `uvm_error("DRIVER", "Early RLAST detected")
          end
          // Deassert RREADY after completing the data reception.
          vif.m_drv.RREADY <= 1'b0;
          // Optional check: Warn if the read response indicates an error.
          if(vif.m_drv.RRESP != 2'b00)
            `uvm_warning("DRIVER", $sformatf("Bad read response: %0h", vif.m_drv.RRESP))
        end
      join_none
    end
  endtask

endclass

`endif
