`ifndef AXI_M_AGENT_SV
`define AXI_M_AGENT_SV

//=====================================================================
// Class: AXI MASTER AGENT
//=====================================================================
class axi_m_agent extends uvm_agent;
  `uvm_component_utils(axi_m_agent)

  // agent config
  axi_m_agent_cfg m_cfg;
  virtual axi_if vif;

  axi_m_driver    m_drv;
  axi_m_monitor   m_mon;
  axi_m_sequencer m_seqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Retrieve the agent config from the uvm_config_db
    // if it doesn't exist, create a new config object
    if(!uvm_config_db#(axi_m_agent_cfg)::get(this, "", "agent_cfg", m_cfg))
      m_cfg = new("m_cfg");

    m_mon = axi_m_monitor::type_id::create("m_mon", this);
    uvm_config_db#(virtual axi_if)::set(m_mon, "", "vif", vif);
    
    if(m_cfg.is_active == UMV_ACTIVE) begin
      m_drv  = axi_m_driver::type_id::create("m_drv", this);
      m_seqr = axi_m_sequencer::type_id::create("m_seqr", this);

      uvm_config_db#(virtual axi_if)::set(m_drv, "", "vif", vif);
      
      // Passing the config object to the driver &sequencer
      uvm_config_db#(axi_agent_cfg)::set(m_drv, "", "agent_cfg", m_cfg);
      uvm_config_db#(axi_agent_cfg)::set(m_seqr, "", "agent_cfg", m_cfg);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // if agent is active, connect the driver's sequence item port 
    // to the sequencer's sequence item export.
    if(m_cfg.is_active == UVM_ACITVE)
      m_drv.seq_item_port.connect(m_seqr.seq_item_export);
  endfunction : connect_phase
endclass

`endif
