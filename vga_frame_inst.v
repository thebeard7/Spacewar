module frame_buffer_wrapper (
input [14:0] address_sig,
input clock_sig,
input [23:0] data_sig,
input wren_sig,
output [23:0] q_sig
);

vga_frame frame_buffer_inst (
.address(address_sig),
.clock(clock_sig),
.data(data_sig),
.wren(wren_sig),
.q(q_sig)
);

endmodule