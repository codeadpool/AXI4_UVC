import AXI4_pkg::*;

interface axi_if(
  input bit ACLK
);

  // Write Address Channel
  addr_t  AWADDR;
  id_t    AWID;
  logic   AWVALID;
  logic   AWREADY;
  len_t   AWLEN;
  size_t  AWSIZE;
  burst_t AWBURST;

  // Write Data Channel
  data_t  WDATA;
  id_t    WID;
  strb_t  WSTRB;
  logic   WVALID;
  logic   WREADY;
  logic   WLAST;

  // Write Response Channel
  resp_t  BRESP;
  id_t    BID;
  logic   BVALID;
  logic   BREADY;

  // Read Address Channel
  addr_t  ARADDR;
  id_t    ARID;
  logic   ARVALID;
  logic   ARREADY;
  len_t   ARLEN;
  size_t  ARSIZE;
  burst_t ARBURST;

  // Read Data Channel
  data_t  RDATA;
  id_t    RID;
  resp_t  RRESP;
  logic   RVALID;
  logic   RREADY;
  logic   RLAST;

  clocking mtr_drv@(posedge ACLK);
    default input #1 output #0;

    // Write Address Channel Inputs/Outputs
    input  AWREADY;
    output AWADDR;
    output AWLEN;
    output AWSIZE;
    output AWBURST;
    output AWVALID;

    // Write Data Channel Inputs/Outputs
    input  WREADY;
    output WDATA;
    output WSTRB;
    output WLAST;
    output WVALID;

    // Write Response Channel Inputs/Outputs
    input  BID;
    input  BRESP;
    input  BVALID;
    output BREADY;

    // Read Address Channel Inputs/Outputs
    output ARADDR;
    output ARLEN;
    output ARSIZE;
    output ARBURST;
    output ARVALID;

    // Read Data Channel Inputs/Outputs
    input  RID;
    input  RDATA;
    input  RRESP;
    input  RLAST;
    input  RVALID;
    output RREADY;
  endclocking

  clocking mtr_mon@(posedge ACLK);
    default input #1 output #0;

    // Write Address Channel Inputs/Outputs
    input  AWADDR;
    input  AWLEN;
    input  AWSIZE;
    input  AWBURST;
    input  AWVALID;
    input  AWREADY;

    // Write Data Channel Inputs/Outputs
    input  WDATA;
    input  WSTRB;
    input  WLAST;
    input  WVALID;
    input  WREADY;

    // Write Response Channel Inputs/Outputs
    input  BID;
    input  BRESP;
    input  BVALID;
    input  BREADY;

    // Read Address Channel Inputs/Outputs
    input  ARADDR;
    input  ARLEN;
    input  ARSIZE;
    input  ARBURST;
    input  ARVALID;
    input  ARREADY;

    // Read Data Channel Inputs/Outputs
    input  RID;
    input  RDATA;
    input  RRESP;
    input  RLAST;
    input  RVALID;
    input  RREADY;
  endclocking

  clocking slv_drv@(posedge ACLK);
    default input #1 output #0;

    // Write Address Channel Inputs/Outputs
    output AWADDR;
    output AWLEN;
    output AWSIZE;
    output AWBURST;
    output AWVALID;

    // Write Data Channel Inputs/Outputs
    output WDATA;
    output WSTRB;
    output WLAST;
    output WVALID;
    input  WREADY;

    // Write Response Channel Inputs/Outputs
    output BID;
    input  BREADY;

    // Read Address Channel Inputs/Outputs
    input  ARADDR;
    input  ARLEN;
    input  ARSIZE;
    input  ARBURST;
    input  ARVALID;
    output ARREADY;

    // Read Data Channel Inputs/Outputs
    output RVALID;
    output RLAST;
    output RRESP;
    output RDATA;
    output RID;
    input  RREADY;
  endclocking

  clocking slv_mon@(posedge ACLK);
    default input #1 output #0;

    // Write Address Channel Inputs
    input  AWADDR;
    input  AWLEN;
    input  AWSIZE;
    input  AWBURST;
    input  AWVALID;
    input  AWREADY;

    // Write Data Channel Inputs
    input  WDATA;
    input  WSTRB;
    input  WLAST;
    input  WVALID;
    input  WREADY;

    // Write Response Channel Inputs
    input  BID;
    input  BRESP;
    input  BVALID;
    input  BREADY;

    // Read Address Channel Inputs
    input  ARADDR;
    input  ARLEN;
    input  ARSIZE;
    input  ARBURST;
    input  ARVALID;
    input  ARREADY;

    // Read Data Channel Inputs
    input  RID;
    input  RDATA;
    input  RRESP;
    input  RLAST;
    input  RVALID;
    input  RREADY;
  endclocking

  modport mtr_drv(
    clocking mtr_drv
      );

  modport mtr_mon(
    clocking mtr_mon
      );

  modport slv_drv(
    clocking slv_drv
      );

  modport slv_mon(
    clocking slv_mon
      );

endinterface

