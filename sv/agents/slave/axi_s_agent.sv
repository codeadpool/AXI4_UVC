`ifndef AXI_S_AGENT_SV
`define AXI_S_AGENT_SV

//=============================================================================
// Class: AXI SLVAE AGENT
//=============================================================================
class axi_s_agent extends uvm_agent;
  `uvm_component_utils(axi_s_agent)

  // Agent configuration object
  axi_s_agent_cfg m_cfg;
  virtual axi_if vif;

  axi_s_driver    m_drv;
  axi_s_monitor   m_mon;
  axi_s_sequencer m_seqr;

  function new(string name = "axi_s_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Retrieve the agent configuration from the UVM configuration database.
    // If it doesn't exist, create a new configuration object.
    if (!uvm_config_db#(axi_s_agent_cfg)::get(this, "", "agent_cfg", m_cfg))
      m_cfg = new("m_cfg");

    m_mon = axi_s_monitor::type_id::create("m_mon", this);
    uvm_config_db#(virtual axi_if)::set(m_mon, "", "vif", vif);

    if (m_cfg.is_active == UVM_ACTIVE) begin
      m_drv  = axi_s_driver::type_id::create("m_drv", this);
      m_seqr = axi_s_sequencer::type_id::create("m_seqr", this);

      uvm_config_db#(virtual axi_if)::set(m_drv, "", "vif", vif);
      
      // Pass the configuration object to the driver and sequencer.
      uvm_config_db#(axi_s_agent_cfg)::set(m_drv, "", "agent_cfg", m_cfg);
      uvm_config_db#(axi_s_agent_cfg)::set(m_seqr, "", "agent_cfg", m_cfg);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // If the agent is active, connect the driver's sequence item port 
    // to the sequencer's sequence item export.
    if (m_cfg.is_active == UVM_ACTIVE)
      m_drv.seq_item_port.connect(m_seqr.seq_item_export);
  endfunction : connect_phase
endclass

`endif
