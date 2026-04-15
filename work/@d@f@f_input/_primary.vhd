library verilog;
use verilog.vl_types.all;
entity DFF_input is
    port(
        a_q             : out    vl_logic_vector(21 downto 0);
        b_q             : out    vl_logic_vector(21 downto 0);
        c_in_q          : out    vl_logic;
        a               : in     vl_logic_vector(21 downto 0);
        b               : in     vl_logic_vector(21 downto 0);
        c_in            : in     vl_logic;
        clk             : in     vl_logic;
        rstn            : in     vl_logic
    );
end DFF_input;
