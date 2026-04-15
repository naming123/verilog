library verilog;
use verilog.vl_types.all;
entity mux2to1_8bit is
    port(
        \out\           : out    vl_logic_vector(7 downto 0);
        i0              : in     vl_logic_vector(7 downto 0);
        i1              : in     vl_logic_vector(7 downto 0);
        s               : in     vl_logic
    );
end mux2to1_8bit;
