library verilog;
use verilog.vl_types.all;
entity DFF_output is
    port(
        sum             : out    vl_logic_vector(22 downto 0);
        sum_d           : in     vl_logic_vector(22 downto 0);
        clk             : in     vl_logic;
        rstn            : in     vl_logic
    );
end DFF_output;
