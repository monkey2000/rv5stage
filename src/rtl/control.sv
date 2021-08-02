`ifndef RV5STAGE_CONTROL
`define RV5STAGE_CONTROL

`include "src/rtl/common.sv"

module control(
  input PipeRequest if_req,
  input PipeRequest id_req,
  input PipeRequest ex_req,
  input PipeRequest ma_req,
  output PipeControl pc_ctrl,
  output PipeControl if_id_ctrl,
  output PipeControl id_ex_ctrl,
  output PipeControl ex_ma_ctrl
);

always_comb begin
  pc_ctrl.stall = if_req.stall_req || id_req.stall_req || ex_req.stall_req || ma_req.stall_req;
  pc_ctrl.flush = if_req.flush_req[`PC] || id_req.flush_req[`PC] || ex_req.flush_req[`PC] || ma_req.flush_req[`PC];
end

always_comb begin
  if_id_ctrl.stall = id_req.stall_req || ex_req.stall_req || ma_req.stall_req;
  if_id_ctrl.flush = if_req.flush_req[`IF_ID] || id_req.flush_req[`IF_ID] || ex_req.flush_req[`IF_ID] || ma_req.flush_req[`IF_ID];
end

always_comb begin
  id_ex_ctrl.stall = ex_req.stall_req || ma_req.stall_req;
  id_ex_ctrl.flush = if_req.flush_req[`ID_EX] || id_req.flush_req[`ID_EX] || ex_req.flush_req[`ID_EX] || ma_req.flush_req[`ID_EX];
end

always_comb begin
  ex_ma_ctrl.stall = ma_req.stall_req;
  ex_ma_ctrl.flush = if_req.flush_req[`EX_MA] || id_req.flush_req[`EX_MA] || ex_req.flush_req[`EX_MA] || ma_req.flush_req[`EX_MA];
end

endmodule

`endif
