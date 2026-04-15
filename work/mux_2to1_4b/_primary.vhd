library verilog;
use verilog.vl_types.all;
entity mux_2to1_4b is
    port(
        \out\           : out    vl_logic_vector(3 downto 0);
        i0              : in     vl_logic_vector(3 downto 0);
        i1              : in     vl_logic_vector(3 downto 0);
        sel             : in     vl_logic
    );
end mux_2to1_4b;
