`ifndef AXI_S_SEQUENCER_SV
`define AXI_S_SEQUENCER_SV

class axi_s_sequencer extends uvm_sequencer #(transactionType);
  
  `uvm_component_utils(axi_s_sequencer)

  function new(string name = "axi_s_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

`endif
