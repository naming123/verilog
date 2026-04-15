library verilog;
use verilog.vl_types.all;
entity FA_6bit is
    port(
        sum             : out    vl_logic_vector(5 downto 0);
        c_out           : out    vl_logic;
        a               : in     vl_logic_vector(5 downto 0);
        b               : in     vl_logic_vector(5 downto 0);
        c_in            : in     vl_logic
    );
end FA_6bit;
