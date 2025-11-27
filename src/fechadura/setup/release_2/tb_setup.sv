`timescale 1ns/1ns

module testbench_setup;
    logic clk;
    logic rst;
    logic setup_on;
    senhaPac_t digitos_value;
    logic digitos_valid;
    logic display_en;
    bcdPac_t bcd_pac;
    setupPac_t data_setup_new;
    logic data_setup_ok;

    always #1 clk = ~clk;

    setup dut (
        .clk(clk),
        .rst(rst),
        .setup_on(setup_on),
        .digitos_value(digitos_value),
        .digitos_valid(digitos_valid),
        .display_en(display_en),
        .bcd_pac(bcd_pac),
        .data_setup_new(data_setup_new),
        .data_setup_ok(data_setup_ok)
    );

    task automatic reset();
        rst = 1;
        repeat(3) @(posedge clk);
        rst = 0;
    endtask

    initial begin
        reset();

        #100 $finish;
    end

endmodule
