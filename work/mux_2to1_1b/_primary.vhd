library verilog;
use verilog.vl_types.all;
entity mux_2to1_1b is
    port(
        \out\           : out    vl_logic;
        i0              : in     vl_logic;
        i1              : in     vl_logic;
        sel             : in     vl_logic
    );
end mux_2to1_1b;
