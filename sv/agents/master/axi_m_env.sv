`ifndef AXI_M_AGENT_TOP_SV
`define AXI_M_AGENT_TOP_SV

//=====================================================================
// Class: AXI MASTER ENVIRONMENT
//=====================================================================
class axi_m_agent_top extends uvm_env;
  `uvm_component_utils(axi_m_agent_top)

  axi_m_agent     m_master_agent[];
  axi_env_cfg     m_master_env_cfg;

  function new(string name = "axi_m_agent_top", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    //===========================================
    // ENV Config Retrieval
    //===========================================
    if (!uvm_config_db#(axi_env_cfg)::get(this, "", "axi_env_cfg", m_master_env_cfg))
      `uvm_fatal(get_type_name(), "Failed to get axi_env_cfg from config DB")

    if (m_master_env_cfg.num_master_agent <= 0) begin
      `uvm_fatal(get_type_name(), 
        $sformatf("No master agents specified! (m_master_env_cfg.num_master_agent = %0d)",
                  m_master_env_cfg.num_master_agent));
    end

    m_master_agent = new[m_master_env_cfg.num_master_agents];

    foreach (m_master_agent[i])begin
      m_master_agent[i] = axi_m_agent::type_id::create($sformatf("m_master_agent[%0d]", i), this);

      uvm_config_db#(axi_m_agent_cfg)::set(this, $sformatf("m_master_agent[%0d]*", i), "m_master_agent_cfg",
        m_master_env_cfg.m_agent_cfg[i]);  
    end
  endfunction : build_phase
endclass

`endif
