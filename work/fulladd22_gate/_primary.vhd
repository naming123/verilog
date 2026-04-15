library verilog;
use verilog.vl_types.all;
entity fulladd22_gate is
    port(
        sum             : out    vl_logic_vector(22 downto 0);
        a               : in     vl_logic_vector(21 downto 0);
        b               : in     vl_logic_vector(21 downto 0);
        c_in            : in     vl_logic
    );
end fulladd22_gate;
