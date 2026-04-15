library verilog;
use verilog.vl_types.all;
entity mux2to1_7bit is
    port(
        \out\           : out    vl_logic_vector(6 downto 0);
        i0              : in     vl_logic_vector(6 downto 0);
        i1              : in     vl_logic_vector(6 downto 0);
        s               : in     vl_logic
    );
end mux2to1_7bit;
