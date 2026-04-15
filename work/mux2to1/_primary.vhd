library verilog;
use verilog.vl_types.all;
entity mux2to1 is
    port(
        \out\           : out    vl_logic;
        i0              : in     vl_logic;
        i1              : in     vl_logic;
        s               : in     vl_logic
    );
end mux2to1;
