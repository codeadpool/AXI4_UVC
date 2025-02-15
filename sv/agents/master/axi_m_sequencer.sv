//===========================================
// class: AXI stock Sequencer 
//===========================================
`ifndef AXI_M_SEQUENCER_SV
`define AXI_M_SEQUENCER_SV

class axi_m_sequencer extends uvm_sequencer #(axi_txn);
  
  `uvm_component_utils(axi_m_sequencer)

  function new(string name = "axi_m_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

`endif
