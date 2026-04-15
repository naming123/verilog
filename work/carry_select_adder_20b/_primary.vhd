library verilog;
use verilog.vl_types.all;
entity carry_select_adder_20b is
    port(
        sum             : out    vl_logic_vector(20 downto 0);
        a               : in     vl_logic_vector(19 downto 0);
        b               : in     vl_logic_vector(19 downto 0);
        c_in            : in     vl_logic;
        clk             : in     vl_logic;
        rstn            : in     vl_logic
    );
end carry_select_adder_20b;
