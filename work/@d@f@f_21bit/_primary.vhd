library verilog;
use verilog.vl_types.all;
entity DFF_21bit is
    port(
        q               : out    vl_logic_vector(20 downto 0);
        d               : in     vl_logic_vector(20 downto 0);
        clk             : in     vl_logic;
        rstn            : in     vl_logic
    );
end DFF_21bit;
