`ifndef AXI_ENV_SV
`define AXI_ENV_SV

class axi_env extends uvm_env;
  `uvm_component_utils(axi_env)

  axi_m_agent_top    m_master_agent;
  axi_s_agent_top    m_slave_agent;
  axi_scoreboard     m_scb;

  axi_virtual_sequencer  v_sqr;
  axi_env_cfg       m_cfg;

  function new(string name = "axi_env", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if(!uvm_config_db#(axi_env_cfg)::get(this, "", "axi_env_cfg", m_cfg))
      `uvm_fatal("CFG", "Failed to get environment configuration")

    if(m_cfg.has_master) begin
      m_master_agent = axi_m_agent_top::type_id::create("m_master_agent", this);
      uvm_config_db#(axi_m_agent_cfg)::set(this, "m_master_agent*", "cfg", m_cfg.master_cfg);
    end

    if(m_cfg.has_slave) begin
      m_slave_agent = axi_s_agent_top::type_id::create("m_slave_agent", this);
      uvm_config_db#(axi_s_agent_cfg)::set(this, "m_slave_agent*", "cfg", m_cfg.slave_cfg);
    end

    if(m_cfg.has_scb)
      m_scb = axi_scoreboard::type_id::create("m_scb", this);

    if(m_cfg.has_virtual_sequencer)
      v_sqr = axi_virtual_sequencer::type_id::create("v_sqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    if(m_cfg.has_scb) begin

      if(m_cfg.has_master) begin
        m_master_agent.m_monitor.addr_ap.connect(m_scb.axi_write_addr_fifo.analysis_export);
        m_master_agent.m_monitor.wr_data_ap.connect(m_scb.axi_write_data_fifo.analysis_export);
        m_master_agent.m_monitor.rd_addr_ap.connect(m_scb.axi_read_addr_fifo.analysis_export);
      end

      if(m_cfg.has_slave) begin
        m_slave_agent.m_monitor.wr_resp_ap.connect(m_scb.axi_write_resp_fifo.analysis_export);
        m_slave_agent.m_monitor.rd_data_ap.connect(m_scb.axi_read_data_fifo.analysis_export);
      end
    end

    if(m_cfg.has_virtual_sequencer && m_cfg.has_master) begin
      v_sqr.m_master_sqr = m_master_agent.m_sequencer;
    end
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    if(m_cfg.has_scb) begin
      m_scb.set_report_verbosity_level(m_cfg.scb_verbosity);
    end
  endfunction
endclass

`endif
