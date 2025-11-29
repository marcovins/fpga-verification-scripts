`timescale 1ns/1ns

module testbench_setup;
    logic clk;
    logic rst;
    logic setup_on;
    senhaPac_t digitos_value;
    logic digitos_valid;
    logic display_en_setup;
    bcdPac_t bcd_pac_setup;
    setupPac_t data_setup_new;
    logic data_setup_ok;

    bcdPac_t bcd_pac_operacional;
    logic display_en_operacional;
    logic sensor_contato;
	logic botao_interno;
	logic botao_bloqueio;
	logic botao_config;
	logic teclado_en;
	logic tranca;
    logic bip;

	logic enable_o, enable_s;
	bcdPac_t bcd_packet_operacional, bcd_packet_setup;
 	logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    always #1 clk = ~clk;

    setup dut_setup (
        .clk(clk),
        .rst(rst),
        .setup_on(setup_on),
        .digitos_value(digitos_value),
        .digitos_valid(digitos_valid),
        .display_en(display_en_setup),
        .bcd_pac(bcd_pac_setup),
        .data_setup_new(data_setup_new),
        .data_setup_ok(data_setup_ok)
    );

    operacional dut_operacional (
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
        .bcd_pac(bcd_pac_operacional),
        .teclado_en(teclado_en),
        .display_en(display_en_operacional),
        .setup_on(setup_on),
        .tranca(tranca),
        .bip(bip)
    );

    display DUT (
        .clk(clk),
        .rst(rst),
        .enable_o(display_en_operacional),
        .enable_s(display_en_setup),
        .bcd_packet_operacional(bcd_pac_operacional),
        .bcd_packet_setup(bcd_pac_setup),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .HEX4(HEX4),
        .HEX5(HEX5)
    );

    task automatic reset();
        rst = 1;
        repeat(5000) @(posedge clk);
        rst = 0;
    endtask

    task send_digit(input logic [3:0] digit);
        // Shift Register
        digitos_value.digits = {digitos_value.digits[18:0], digit};
        
        // Pulso de Validação
        digitos_valid = 1'b1;
        @(posedge clk);
        digitos_valid = 1'b0;
        @(posedge clk);

        // Limpa o buffer após '*' ou '#'
        if (digit == 4'hA || digit == 4'hB) begin
             digitos_value = '1; // Preenche tudo com 1s (equivale a 0xF repetido)
        end
    endtask

    task automatic print_teste(input bit condicao, input int num_teste, input string msg_erro);
        if (condicao)
            $display("Teste %0i: PASSOU!", num_teste);
        else
            $display("Teste %0i: FALHOU! %s", num_teste, msg_erro);
    endtask

    task automatic execute_tests_release_1();
        reset();

        // Porta destravada e aberta
        botao_interno = 0;
        repeat(3) @(posedge clk);
        sensor_contato = 1;

        int num_teste = 1;

        // Passo 1 -> Pressionar botão CONFIG
        botao_config = 1;
        repeat(3) @(posedge clk);
        botao_config = 0;

        print_teste(bcd_pac_setup.BCD5 == 0, num_teste, "BCD5 = 1");

        // Passo 2 -> Enviar senha incorreta + '*'
        for (int i = 0; i < 4; i++) begin
            send_digit(4'h1);
        end

        // Pressionar '*'
        send_digit(4'hA);

        num_teste = num_teste + 1;

        print_teste(setup_on == 0 && HEX5 == 0, num_teste, "SETUP = 1 e/ou HEX5 = 1");

        // Passo 3 -> Enviar senha master correta + '*'
        logic [3:0] sen_master [4] = '{1, 2, 3, 4};
        
        foreach (sen_master[i]) begin
            send_digit(sen_master[i]);
        end

        // Pressionar '*'
        send_digit(4'hA);

        num_teste = num_teste + 1;

        print_teste(bcd_pac_setup.BCD5 == 1 && setup_on == 1, num_teste, "BDC5 = 0 e/ou SETUP = 0");

        // Passo 4 -> Enviar tecla “#” antes de confirmar
        send_digit(4'hB);

        num_teste = num_teste + 1;

        print_teste(setup_on == 0, num_teste, "SETUP = 1");
    endtask

    initial begin
        clk = 0;
        rst = 0;
        digitos_value.digits = '0;
        digitos_valid = 0;
        execute_tests_release_1();

        #100 $finish;
    end

endmodule
