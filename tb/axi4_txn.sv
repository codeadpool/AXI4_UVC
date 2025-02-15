import AXI4_pkg::*;
class axi_txn extends uvm_sequence_item;
  //
 // Write Address Channel
  rand addr_t  AWADDR;  // Address
  rand id_t    AWID;    // ID
  rand logic   AWVALID; // Valid signal
  logic        AWREADY; // Ready signal
  rand len_t   AWLEN;   // Burst length
  rand size_t  AWSIZE;  // Burst size
  rand burst_t AWBURST; // Burst type

  // Write Data Channel
  rand data_t  WDATA;   // Data
  rand id_t    WID;     // ID
  rand strb_t  WSTRB;   // Write strobe
  rand logic   WVALID;  // Valid signal
  logic        WREADY;  // Ready signal
  rand logic   WLAST;   // Last transfer in burst

  // Write Response Channel
  rand resp_t  BRESP;   // Response
  rand id_t    BID;     // ID
  rand logic   BVALID;  // Valid signal
  logic        BREADY;  // Ready signal

  // Read Address Channel
  rand addr_t  ARADDR;  // Address
  rand id_t    ARID;    // ID
  rand logic   ARVALID; // Valid signal
  logic        ARREADY; // Ready signal
  rand len_t   ARLEN;   // Burst length
  rand size_t  ARSIZE;  // Burst size
  rand burst_t ARBURST; // Burst type

  // Read Data Channel
  rand data_t  RDATA;   // Data
  rand id_t    RID;     // ID
  rand resp_t  RRESP;   // Response
  rand logic   RVALID;  // Valid signal
  logic        RREADY;  // Ready signal
  rand logic   RLAST;   // Last transfer in burst

  // Constructor
  function new(string name = "axi4_txn");
    super.new(name);
  endfunction

  // UVM automation macros for field operations
  `uvm_object_utils_begin(axi4_txn)
    `uvm_field_int(AWADDR, UVM_ALL_ON)
    `uvm_field_int(AWID, UVM_ALL_ON)
    `uvm_field_int(AWVALID, UVM_ALL_ON)
    `uvm_field_int(AWREADY, UVM_ALL_ON)
    `uvm_field_int(AWLEN, UVM_ALL_ON)
    `uvm_field_int(AWSIZE, UVM_ALL_ON)
    `uvm_field_int(AWBURST, UVM_ALL_ON)
    `uvm_field_int(WDATA, UVM_ALL_ON)
    `uvm_field_int(WID, UVM_ALL_ON)
    `uvm_field_int(WSTRB, UVM_ALL_ON)
    `uvm_field_int(WVALID, UVM_ALL_ON)
    `uvm_field_int(WREADY, UVM_ALL_ON)
    `uvm_field_int(WLAST, UVM_ALL_ON)
    `uvm_field_int(BRESP, UVM_ALL_ON)
    `uvm_field_int(BID, UVM_ALL_ON)
    `uvm_field_int(BVALID, UVM_ALL_ON)
    `uvm_field_int(BREADY, UVM_ALL_ON)
    `uvm_field_int(ARADDR, UVM_ALL_ON)
    `uvm_field_int(ARID, UVM_ALL_ON)
    `uvm_field_int(ARVALID, UVM_ALL_ON)
    `uvm_field_int(ARREADY, UVM_ALL_ON)
    `uvm_field_int(ARLEN, UVM_ALL_ON)
    `uvm_field_int(ARSIZE, UVM_ALL_ON)
    `uvm_field_int(ARBURST, UVM_ALL_ON)
    `uvm_field_int(RDATA, UVM_ALL_ON)
    `uvm_field_int(RID, UVM_ALL_ON)
    `uvm_field_int(RRESP, UVM_ALL_ON)
    `uvm_field_int(RVALID, UVM_ALL_ON)
    `uvm_field_int(RREADY, UVM_ALL_ON)
    `uvm_field_int(RLAST, UVM_ALL_ON)
  `uvm_object_utils_end

  // Optional: Add constraints for randomization
  constraint c_valid_signals {
    AWVALID dist {0 := 20, 1 := 80}; // AWVALID is high 80% of the time
    WVALID  dist {0 := 20, 1 := 80}; // WVALID is high 80% of the time
    BVALID  dist {0 := 20, 1 := 80}; // BVALID is high 80% of the time
    ARVALID dist {0 := 20, 1 := 80}; // ARVALID is high 80% of the time
    RVALID  dist {0 := 20, 1 := 80}; // RVALID is high 80% of the time
  } 

   // Constraints for AXI4 signals
  constraint c_AWVALID { AWVALID inside {0, 1}; }
  constraint c_AWREADY { AWREADY inside {0, 1}; }
  constraint c_AWLEN   { AWLEN inside {[0:255]}; } // Burst length (0 to 255)
  constraint c_AWSIZE  { AWSIZE inside {0, 1, 2, 3, 4, 5, 6}; } // Burst size (1, 2, 4, 8, 16, 32, 64 bytes)
  constraint c_AWBURST { AWBURST inside {0, 1, 2}; } // Burst type (FIXED, INCR, WRAP)

  constraint c_WVALID  { WVALID inside {0, 1}; }
  constraint c_WREADY  { WREADY inside {0, 1}; }
  constraint c_WLAST   { WLAST inside {0, 1}; }

  constraint c_BVALID  { BVALID inside {0, 1}; }
  constraint c_BREADY  { BREADY inside {0, 1}; }
  constraint c_BRESP   { BRESP inside {0, 1, 2, 3}; } // Response (OKAY, EXOKAY, SLVERR, DECERR)

  constraint c_ARVALID { ARVALID inside {0, 1}; }
  constraint c_ARREADY { ARREADY inside {0, 1}; }
  constraint c_ARLEN   { ARLEN inside {[0:255]}; } // Burst length (0 to 255)
  constraint c_ARSIZE  { ARSIZE inside {0, 1, 2, 3, 4, 5, 6}; } // Burst size (1, 2, 4, 8, 16, 32, 64 bytes)
  constraint c_ARBURST { ARBURST inside {0, 1, 2}; } // Burst type (FIXED, INCR, WRAP)

  constraint c_RVALID  { RVALID inside {0, 1}; }
  constraint c_RREADY  { RREADY inside {0, 1}; }
  constraint c_RLAST   { RLAST inside {0, 1}; }
  constraint c_RRESP   { RRESP inside {0, 1, 2, 3}; } // Response (OKAY, EXOKAY, SLVERR, DECERR)

  virtual function string convert2string();
    string s;
    s = $sformatf("AWADDR=%h, AWID=%h, AWVALID=%b, AWREADY=%b, AWLEN=%h, AWSIZE=%h, AWBURST=%h\n",
                  AWADDR, AWID, AWVALID, AWREADY, AWLEN, AWSIZE, AWBURST);
    s = $sformatf("%sWDATA=%h, WID=%h, WSTRB=%h, WVALID=%b, WREADY=%b, WLAST=%b\n",
                  s, WDATA, WID, WSTRB, WVALID, WREADY, WLAST);
    s = $sformatf("%sBRESP=%h, BID=%h, BVALID=%b, BREADY=%b\n",
                  s, BRESP, BID, BVALID, BREADY);
    s = $sformatf("%sARADDR=%h, ARID=%h, ARVALID=%b, ARREADY=%b, ARLEN=%h, ARSIZE=%h, ARBURST=%h\n",
                  s, ARADDR, ARID, ARVALID, ARREADY, ARLEN, ARSIZE, ARBURST);
    s = $sformatf("%sRDATA=%h, RID=%h, RRESP=%h, RVALID=%b, RREADY=%b, RLAST=%b",
                  s, RDATA, RID, RRESP, RVALID, RREADY, RLAST);
    return s;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    AXI4_txn rhs_;
    if (!$cast(rhs_, rhs)) begin
      `uvm_fatal("DO_COMPARE", "Cast failed")
      return 0;
    end
    return (AWADDR  == rhs_.AWADDR  &&
            AWID    == rhs_.AWID    &&
            AWVALID == rhs_.AWVALID &&
            AWREADY == rhs_.AWREADY &&
            AWLEN   == rhs_.AWLEN   &&
            AWSIZE  == rhs_.AWSIZE  &&
            AWBURST == rhs_.AWBURST &&
            WDATA   == rhs_.WDATA   &&
            WID     == rhs_.WID     &&
            WSTRB   == rhs_.WSTRB   &&
            WVALID  == rhs_.WVALID  &&
            WREADY  == rhs_.WREADY  &&
            WLAST   == rhs_.WLAST   &&
            BRESP   == rhs_.BRESP   &&
            BID     == rhs_.BID     &&
            BVALID  == rhs_.BVALID  &&
            BREADY  == rhs_.BREADY  &&
            ARADDR  == rhs_.ARADDR  &&
            ARID    == rhs_.ARID    &&
            ARVALID == rhs_.ARVALID &&
            ARREADY == rhs_.ARREADY &&
            ARLEN   == rhs_.ARLEN   &&
            ARSIZE  == rhs_.ARSIZE  &&
            ARBURST == rhs_.ARBURST &&
            RDATA   == rhs_.RDATA   &&
            RID     == rhs_.RID     &&
            RRESP   == rhs_.RRESP   &&
            RVALID  == rhs_.RVALID  &&
            RREADY  == rhs_.RREADY  &&
            RLAST   == rhs_.RLAST);
  endfunction

  virtual function void post_randomization();
    WRADDR_calc();
    RADDR_calc ();
    STRB_calc  ();
  endfunction

endclass
