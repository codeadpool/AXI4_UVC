`ifndef AXI_ENV_CFG_SV
`define AXI_ENV_CFG_SV

//=====================================================================
// ENVIRONMENT CONFIG FOR BOTH MASTER/ SLAVE
//=====================================================================
class axi_env_cfg extends uvm_object;
  `uvm_object_utils(axi_env_cfg)

  //===========================================
  // #of agents and realted config
  //===========================================
  int num_master_agents, num_slave_agents;

  bit has_master = 1;
  bit has_slave = 1;
  bit has_scb = 1;
  bit has_virtual_sequencer = 1;
  int scb_verbosity = UVM_LOW;

  axi_m_agent_cfg m_master_agent_cfg[];
  axi_s_agent_cfg m_slave_agent_cfg[];

  
  function new(string name = "axi_env_cfg");
    super.new(name);
    m_master_agent_cfg = axi_m_agent_cfg::type_id::create("m_master_agent_cfg");
    m_slave_agent_cfg  = axi_s_agent_cfg::type_id::create("m_slave_agent_cfg");
  endfunction
endclass

`endif
