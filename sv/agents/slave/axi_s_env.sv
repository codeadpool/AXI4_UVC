`ifndef AXI_S_AGENT_TOP_SV
`define AXI_S_AGENT_TOP_SV

//=====================================================================
// Class: AXI SLAVE ENVIRONMENT
//=====================================================================
class axi_s_agent_top extends uvm_env;
  `uvm_component_utils(axi_s_agent_top)

  axi_s_agent     m_slave_agent[];
  axi_env_cfg     m_slave_env_cfg; 

  function new(string name = "axi_s_agent_top", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    //=====================================================================
    // ENV Config Retrieval
    //=====================================================================
    if(!uvm_config_db#(axi_env_cfg)::get(this, "", "axi_env_cfg", m_slave_env_cfg))
      `uvm_fatal(get_type_name(), "Failed to get axi_env_cfg from config DB")

    if(m_slave_env_cfg.num_slave_agent <= 0) begin
      `uvm_fatal(get_type_name(),
        $sformatf("No slave agents specified! (m_slave_env_cfg.num_slave_agent = %0d)", 
                  m_slave_env_cfg.num_slave_agent));
    end

    m_slave_agent = new[m_slave_env_cfg.num_slave_agents];

    foreach (m_slave_agent[i]) begin
      m_slave_agent[i] = axi_s_agent::type_id::create($sformatf("m_slave_agent[%0d]", i), this); 

      uvm_config_db#(axi_s_agent_cfg)::set(this, $sformatf("m_slave_agent[%0d]*", i), "m_slave_agent_cfg", 
      m_slave_env_cfg.m_slave_cfg[i]);
    end
  endfunction : build_phase
endclass

`endif
