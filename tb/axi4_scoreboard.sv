`ifndef AXI_SCOREBOARD_SV
`define AXI_SCOREBOARD_SV

class axi_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(axi_scoreboard)

  uvm_tlm_analysis_fifo #(axi_txn) axi_wr_addr_fifo;
  uvm_tlm_analysis_fifo #(axi_txn) axi_wr_data_fifo;
  uvm_tlm_analysis_fifo #(axi_txn) axi_wr_resp_fifo;
  uvm_tlm_analysis_fifo #(axi_txn) axi_rd_addr_fifo;
  uvm_tlm_analysis_fifo #(axi_txn) axi_rd_data_fifo;

  // Memory model (byte addressable)
  bit [7:0] shadow_mem[*];
  
  // Expected txn
  axi_txn wr_addr_queue[$];
  axi_txn wr_data_queue[$];
  axi_txn rd_addr_queue[$];

  // Coverage collectors
  covergroup axi_wr_cg;
    AWLEN: coverpoint item.AWLEN {
      bins len[] = {[0:15]};
    }
    AWSIZE: coverpoint item.AWSIZE {
      bins size_1   = {0};
      bins size_2   = {1};
      bins size_4   = {2};
      bins size_8   = {3};
      bins size_16  = {4};
      bins size_32  = {5};
      bins size_64  = {6};
      bins size_128 = {7};
    }
    AWBURST: coverpoint item.AWBURST {
      bins fixed = {0};
      bins incr  = {1};
      bins wrap  = {2};
    }
    AWVALID_AWrdY: cross AWLEN, AWSIZE, AWBURST;
  endgroup

  covergroup axi_rd_cg;
    ARLEN: coverpoint item.ARLEN {
      bins len[] = {[0:15]};
    }
    ARSIZE: coverpoint item.ARSIZE {
      bins size_1   = {0};
      bins size_2   = {1};
      bins size_4   = {2};
      bins size_8   = {3};
      bins size_16  = {4};
      bins size_32  = {5};
      bins size_64  = {6};
      bins size_128 = {7};
    }
    ARBURST: coverpoint item.ARBURST {
      bins fixed = {0};
      bins incr  = {1};
      bins wrap  = {2};
    }
    ARVALID_ARrdY: cross ARLEN, ARSIZE, ARBURST;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    axi_wr_cg = new();
    axi_rd_cg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi_wr_addr_fifo = new("axi_wr_addr_fifo", this);
    axi_wr_data_fifo = new("axi_wr_data_fifo", this);
    axi_wr_resp_fifo = new("axi_wr_resp_fifo", this);
    axi_rd_addr_fifo = new("axi_rd_addr_fifo", this);
    axi_rd_data_fifo = new("axi_rd_data_fifo", this);
  endfunction

  task run_phase(uvm_phase phase);
    fork
      process_wr_txn();
      process_rd_txn();
      process_resp_checking();
    join
  endtask

  task process_wr_txn();
    forever begin
      axi_txn addr_txn, data_txn;
      
      // Get wr address and data
      axi_wr_addr_fifo.get(addr_txn);
      axi_wr_data_fifo.get(data_txn);
      
      // Check address/data alignment
      check_alignment(addr_txn);
      
      // Store expected transaction
      wr_addr_queue.push_back(addr_txn);
      wr_data_queue.push_back(data_txn);
      
      // Update shadow memory
      update_shadow_memory(addr_txn, data_txn);
      
      // Coverage sampling
      axi_wr_cg.sample(addr_txn);
    end
  endtask

  task process_rd_txn();
    forever begin
      axi_txn addr_txn, data_txn;
      
      // Get rd address
      axi_rd_addr_fifo.get(addr_txn);
      
      // Check address alignment
      check_alignment(addr_txn);
      
      // Predict expected data
      data_txn = predict_rd_data(addr_txn);
      rd_addr_queue.push_back(data_txn);
      
      // Coverage sampling
      axi_rd_cg.sample(addr_txn);
    end
  endtask

  task process_resp_checking();
    forever begin
      axi_txn resp_txn, exp_txn;
      
      // Check wr resps
      axi_wr_resp_fifo.get(resp_txn);
      if(wr_addr_queue.size() > 0) begin
        exp_txn = wr_addr_queue.pop_front();
        check_wr_resp(exp_txn, resp_txn);
      end
      
      // Check rd data
      axi_rd_data_fifo.get(resp_txn);
      if(rd_addr_queue.size() > 0) begin
        exp_txn = rd_addr_queue.pop_front();
        check_rd_data(exp_txn, resp_txn);
      end
    end
  endtask

  function void check_alignment(axi_txn txn);
    // Check address alignment for burst size
    int aligned_addr = txn.addr & ((1 << txn.size) - 1);
    if(aligned_addr != 0) begin
      `uvm_error("SCBD", $sformatf("Unaligned address 0x%0h for size %0d", 
                 txn.addr, (1 << txn.size)))
    end
  endfunction

  function void update_shadow_memory(axi_txn addr_txn, axi_txn data_txn);
    bit [31:0] current_addr;
    int beat_size = 1 << addr_txn.size;
    
    foreach(data_txn.data[i]) begin
      current_addr = calculate_address(addr_txn.addr, i, 
                                      addr_txn.size, addr_txn.burst);
      
      // Check address range
      if(current_addr < addr_txn.addr_start || current_addr > addr_txn.addr_end) begin
        `uvm_error("SCBD", $sformatf("Address 0x%0h out of range", current_addr))
      end
      
      // Update memory byte by byte
      for(int j = 0; j < beat_size; j++) begin
        shadow_mem[current_addr + j] = data_txn.data[i][j*8 +: 8];
      end
    end
  endfunction

  function axi_txn predict_rd_data(axi_txn addr_txn);
    axi_txn predicted = new();
    bit [31:0] current_addr;
    int beat_size = 1 << addr_txn.size;
    
    predicted.data = new[addr_txn.len + 1];
    
    foreach(predicted.data[i]) begin
      current_addr = calculate_address(addr_txn.addr, i, 
                                      addr_txn.size, addr_txn.burst);
      predicted.data[i] = 0;
      
      // rd from shadow memory
      for(int j = 0; j < beat_size; j++) begin
        if(shadow_mem.exists(current_addr + j)) begin
          predicted.data[i][j*8 +: 8] = shadow_mem[current_addr + j];
        end
        else begin
          predicted.data[i][j*8 +: 8] = 8'hxx;
          `uvm_warning("SCBD", $sformatf("rd uninitialized address 0x%0h", 
                     current_addr + j))
        end
      end
    end
    return predicted;
  endfunction

  function void check_wr_resp(axi_txn exp_txn, axi_txn act_txn);
    // Check resp code
    if(act_txn.bresp !== exp_txn.expected_resp) begin
      `uvm_error("SCBD", $sformatf("Bad wr resp: Exp %0s, Got %0s",
                 resp2str(exp_txn.expected_resp), resp2str(act_txn.bresp)))
    end
    
    // Check transaction ID matching
    if(act_txn.id !== exp_txn.id) begin
      `uvm_error("SCBD", $sformatf("ID mismatch: Exp %0d, Got %0d",
                 exp_txn.id, act_txn.id))
    end
  endfunction

  function void check_rd_data(axi_txn exp_txn, axi_txn act_txn);
    // Check data beats count
    if(act_txn.data.size() !== exp_txn.data.size()) begin
      `uvm_error("SCBD", $sformatf("Data beat count mismatch: Exp %0d, Got %0d",
                 exp_txn.data.size(), act_txn.data.size()))
    end
    
    // Check each data beat
    foreach(exp_txn.data[i]) begin
      if(act_txn.data[i] !== exp_txn.data[i]) begin
        `uvm_error("SCBD", $sformatf("Data mismatch @beat %0d: Exp 0x%0h, Got 0x%0h",
                   i, exp_txn.data[i], act_txn.data[i]))
      end
    end
    
    // Check resp code
    if(act_txn.rresp !== exp_txn.expected_resp) begin
      `uvm_error("SCBD", $sformatf("Bad rd resp: Exp %0s, Got %0s",
                 resp2str(exp_txn.expected_resp), resp2str(act_txn.rresp)))
    end
  endfunction

  function string resp2str(logic [1:0] resp);
    case(resp)
      2'b00: return "OKAY";
      2'b01: return "EXOKAY";
      2'b10: return "SLVERR";
      2'b11: return "DECERR";
    endcase
  endfunction

  function logic [31:0] calculate_address(
    input logic [31:0] base_addr,
    input int beat,
    input logic [2:0] size,
    input logic [1:0] burst
  );
    int offset = beat * (1 << size);
    case(burst)
      2'b00: return base_addr; // FIXED
      2'b01: return base_addr + offset; // INCR
      2'b10: begin // WRAP
        int wrap_boundary = (1 << (size + $clog2(beat+1)));
        return (base_addr & ~(wrap_boundary-1)) | 
               ((base_addr + offset) & (wrap_boundary-1));
      end
      default: return base_addr + offset;
    endcase
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    if(wr_addr_queue.size() > 0)
      `uvm_error("SCBD", $sformatf("%0d unmatched wr addresses", wr_addr_queue.size()))
    if(rd_addr_queue.size() > 0)
      `uvm_error("SCBD", $sformatf("%0d unmatched rd addresses", rd_addr_queue.size()))
  endfunction

endclass

`endif
