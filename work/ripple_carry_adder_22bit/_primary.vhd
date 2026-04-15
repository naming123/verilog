library verilog;
use verilog.vl_types.all;
entity ripple_carry_adder_22bit is
    port(
        sum             : out    vl_logic_vector(22 downto 0);
        a               : in     vl_logic_vector(21 downto 0);
        b               : in     vl_logic_vector(21 downto 0);
        c_in            : in     vl_logic;
        clk             : in     vl_logic;
        rstn            : in     vl_logic
    );
end ripple_carry_adder_22bit;
