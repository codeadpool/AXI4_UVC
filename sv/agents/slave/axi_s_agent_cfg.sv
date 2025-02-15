`ifndef AXI_S_AGENT_CFG_SV
`define AXI_S_AGENT_CFG_SV

//=====================================================================
// Class: AXI SLKAVE AGENT CONFIG
//=====================================================================
class axi_s_agent_cfg extends uvm_object;
  `uvm_component_utils(axi_s_agent_cfg)

  //===========================================
  // Agent mode control
  //===========================================
  uvm_active_passive_enum is_active = UMV_ACTIVE;
  bit en_coverage;

  int driver_delay;
  int seqr_delay;

  int random_seed;
  int verbosity_level;

  function new(string name = "axi_s_agent_cfg");
    super.new(name);

    active          = 'b1;
    en_coverage     = 'b0;
    driver_delay    = 0;
    seqr_delay      = 0;
    random_seed     = 12345;
    verbosity_level = UVM_MEDIUM;
  endfunction

  //===========================================
  // Copy Method: to cpy config from another inst
  //===========================================
  function void copy(const axi_s_agent_cfg rhs);
    this.active                 = rhs.active;
    this.driver_delay           = rhs.driver_delay;
    this.seqr_delay             = rhs.seqr_delay;
    this.random_seed            = rhs.random_seed;
    this.verbosity_level        = rhs.verbosity_level;
    this.en_coverage            = rhs.en_coverage;
  endfunction

  //===========================================
  // cvrt to string Method
  //===========================================
  function string convert2string();
    return $sformatf(
      "Active: %0d, Driver Delay: %0d, Sequencer Delay: %0d, Seed: %0d, Verbosity: %0d, "  \
      "Coverage: %0d",
      active, driver_delay, seqr_delay, random_seed, verbosity_level,
      en_coverage);
  endfunction
  
endclass
`endif
