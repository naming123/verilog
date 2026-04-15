library verilog;
use verilog.vl_types.all;
entity FA_5bit is
    port(
        sum             : out    vl_logic_vector(4 downto 0);
        c_out           : out    vl_logic;
        a               : in     vl_logic_vector(4 downto 0);
        b               : in     vl_logic_vector(4 downto 0);
        c_in            : in     vl_logic
    );
end FA_5bit;
