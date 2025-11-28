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
    setupPac_t old_configs;
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

    task automatic enter_setup();
        setup_on = 1'b1;
        repeat(2) @(posedge clk);
        setup_on = 1'b0;
        repeat(2) @(posedge clk);
        send_digit(4'hA);
        @(posedge clk);
        send_digit(4'hA);
        @(posedge clk);
    endtask

    task send_digit(input logic [3:0] digit);
        digitos_value = digit;
        digitos_valid = 1'b1;
        @(posedge clk);
        digitos_valid = 1'b0;
        @(posedge clk);
    endtask

    task automatic verificar_deslocamento(logic [3:0] expected_BCD1, logic [3:0] expected_BCD0);
        if(bcd_pac.BCD1 == expected_BCD1 && bcd_pac.BCD0 == expected_BCD0) begin
            $display("[%0t] PASSOU! Valor Salvo: %0d | tecla_valid: %0d | BCD1: %0d | BCD0 : %0d", $time, data_setup_new.bip_status, digitos_valid, bcd_pac.BCD1, bcd_pac.BCD0);
        end else begin
            $display("[%0t] FALHOU! Valor Salvo: %0d | tecla_valid: %0d | BCD1: %0d | BCD0 : %0d", $time, data_setup_new.bip_status, digitos_valid, bcd_pac.BCD1, bcd_pac.BCD0);
        end
    endtask

    task automatic verificar_bcd(logic [4:0] expected_BCD5);
        if(bcd_pac.BCD5 == expected_BCD5) begin
            $display("[%0t] PASSOU! alternância de configuração funcionando corretamente. BCD5: %0d", $time, bcd_pac.BCD5);
        end else begin
            $display("[%0t] FALHOU! alternância de configuração nao funcionando corretamente. BCD5: %0d", $time, bcd_pac.BCD5);
        end
    endtask

    function automatic bit compare_configs(setupPac_t a, setupPac_t b);
    return
        (a.bip_status === b.bip_status) &&
        (a.bip_time === b.bip_time) &&
        (a.senha_master.digits === b.senha_master.digits) &&
        (a.senha_1.digits === b.senha_1.digits) &&
        (a.senha_2.digits === b.senha_2.digits) &&
        (a.senha_3.digits === b.senha_3.digits) &&
        (a.senha_4.digits === b.senha_4.digits);
    endfunction

    task automatic return_to_operational(logic [4:0] expected_tranca_aut_time);
        send_digit(4'hB);
        fork
            begin
                wait(data_setup_ok == 1'b1);
                $display("[%0t] PASSOU! retornou ao operacional com sucesso.", $time);
            end
            begin
                #1000;
                $display("[%0t] FALHOU! nao retornou ao operacional em tempo.", $time);
            end
        join_any
        disable fork;

        if(data_setup_new.tranca_aut_time === expected_tranca_aut_time && compare_configs(data_setup_new, old_configs)) begin
            $display("[%0t] PASSOU! Configuracao salva corretamente.", $time);
        end else begin
            $display("[%0t] FALHOU! Configuracao nao salva corretamente.", $time);
        end
    endtask

    task automatic test_limits(logic [4:0] input_value, logic [4:0] expected_value);
        send_digit(input_value[3:0]);
        send_digit({1'b0, input_value[4]});
        send_digit(4'hA);
        @(posedge clk);

        if(data_setup_new.tranca_aut_time === expected_value) begin
            $display("[%0t] PASSOU! Limite testado corretamente para valor de entrada: %0d | Valor salvo: %0d", $time, input_value, data_setup_new.bip_time);
        end else begin
            $display("[%0t] FALHOU! Limite nao testado corretamente para valor de entrada: %0d | Valor salvo: %0d", $time, input_value, data_setup_new.bip_time);
        end
    endtask

    task automatic execute_tests_release_6();
        old_configs = data_setup_new;
        //1
        enter_setup();

        //2
        send_digit(4'd1);
        send_digit(4'd2);
        send_digit(4'd3);
        verificar_deslocamento(4'd0, 4'd3);

        //3
        send_digit(4'hA);
        verificar_bcd(4'd4);

        //4
        return_to_operational(5'd23);

        //5
        enter_setup();
        send_digit(4'd0);
        send_digit(4'd3);
        send_digit(4'hA);
        test_limits(5'd3, 5'd5);

        //6
        send_digit(4'hA);
        verificar_bcd(4'd5);

        //7
        return_to_operational(5'd5);

        //8
        enter_setup();
        send_digit(4'd9);
        send_digit(4'd7);
        send_digit(4'hA);
        test_limits(5'd97, 5'd60);

        //9
        send_digit(4'hA);
        verificar_bcd(4'd5);

        //10
        return_to_operational(5'd60);

    endtask

    initial begin
        clk = 0;
        rst = 0;
        setup_on = 0;
        digitos_value = '0;
        digitos_valid = 0;
        execute_tests_release_6();
        #100 $finish;
    end

endmodule
