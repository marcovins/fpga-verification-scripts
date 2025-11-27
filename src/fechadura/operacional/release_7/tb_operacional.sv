`timescale 1ns/1ns

module testbench_operacional;
    logic clk;
    logic rst;
    logic sensor_contato;
    logic botao_interno;
    logic botao_bloqueio;
    logic botao_config;
    setupPac_t data_setup_new;
    logic data_setup_ok;
    senhaPac_t digitos_value;
    logic digitos_valid;
    bcdPac_t bcd_pac;
    logic teclado_en;
    logic display_en;
    logic setup_on;
    logic tranca;
    logic bip;

    operacional dut (
        .clk(clk),
        .rst(rst),
        .sensor_contato(sensor_contato),
        .botao_interno(botao_interno),
        .botao_bloqueio(botao_bloqueio),
        .botao_config(botao_config),
        .data_setup_new(data_setup_new),
        .data_setup_ok(data_setup_ok),
        .digitos_value(digitos_value),
        .digitos_valid(digitos_valid),
        .bcd_pac(bcd_pac),
        .teclado_en(teclado_en),
        .display_en(display_en),
        .setup_on(setup_on),
        .tranca(tranca),
        .bip(bip)
    );
    
    always #1 clk = ~clk;

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
