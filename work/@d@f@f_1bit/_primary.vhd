library verilog;
use verilog.vl_types.all;
entity DFF_1bit is
    port(
        q               : out    vl_logic;
        d               : in     vl_logic;
        clk             : in     vl_logic;
        rstn            : in     vl_logic
    );
end DFF_1bit;
