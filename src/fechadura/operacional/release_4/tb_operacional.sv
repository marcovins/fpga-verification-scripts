`timescale 1ns/1ns

module testbench_operacional;
    parameter int UM_SEGUNDO = 1000;

    logic clk = 0;
    logic rst;
    logic sensor_contato = 0;
    logic botao_interno = 0;
    logic botao_bloqueio = 0;
    logic botao_config = 0;
    setupPac_t data_setup_new = '0;
    logic display_en_setup = 0;
    bcdPac_t bcd_pac_setup = '0;
    logic data_setup_ok = 0;
    bcdPac_t bcd_pac_operacional;
    logic display_en_operacional;
    logic enable_o, enable_s;
 	logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    int total_testes = 0;
    int testes_passaram = 0;
    int testes_falharam = 0;

    senhaPac_t digitos_value = '1;
    logic digitos_valid = 0;
    logic teclado_en;
    logic setup_on;
    logic tranca;
    logic bip;
    logic [6:0] HIFEN = 7'b1000000;
  	int	num_teste;

    // sinais para testes
    logic teclado_desabilitado;

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
    
    always #1 clk = ~clk;

    task automatic reset();
        rst = 1;
        repeat(3) @(posedge clk);
        rst = 0;
    endtask

    task send_digit(input logic [3:0] digit);
        digitos_value.digits = {digitos_value.digits[18:0], digit};
        
        digitos_valid = 1'b1;
        @(posedge clk);
        digitos_valid = 1'b0;
        @(posedge clk);

        // Limpa o buffer após '*' ou '#'
        if (digit == 4'hA || digit == 4'hB) begin
             digitos_value = '1; // Preenche tudo com 1s (equivale a 0xF repetido)
        end
    endtask

    task automatic print_teste(input bit condicao, input string msg_erro);
        total_testes++;
        if (condicao) begin
            $display("Teste %0d: PASSOU!", num_teste);
            testes_passaram++;
        end else begin
            testes_falharam++;
            if (msg_erro == "")
                $display("Teste %0d: FALHOU! (sem mensagem)", num_teste);
            else
                $display("Teste %0d: FALHOU! %s", num_teste, msg_erro);
        end
    endtask

    function automatic logic [6:0] retorna_hex_por_idx(input int idx);
        case(idx)
            0: return HEX0;
            1: return HEX1;
            2: return HEX2;
            3: return HEX3;
            4: return HEX4;
            5: return HEX5;
            default: return '0;
        endcase
    endfunction

    function automatic logic verifica_valor_hex(input int idx);
        // Verifica se os displays de 0 até idx mostram hífen
        for(int i = 0; i <= idx; i++)begin
            logic [6:0] hex = retorna_hex_por_idx(i);
            if(hex !== HIFEN)
                return 1'b0;
        end
        return 1'b1;
    endfunction

    function automatic logic verifica_todos_hex_hifen();
        // Verifica se todos os displays (HEX0 a HEX5) mostram hífen
        for(int i = 0; i < 6; i++)begin
            logic [6:0] hex = retorna_hex_por_idx(i);
            if(hex !== HIFEN)
                return 1'b0;
        end
        return 1'b1;
    endfunction

    task automatic envia_senha_errada();
        // Envia 3 dígitos aleatórios + '*' para confirmar senha incorreta
        for (int j = 0; j < 3; j++) begin
            send_digit($urandom_range(0, 9));
        end
        send_digit(4'hA); // '*' para confirmar
        @(posedge clk);
    endtask

    task automatic aguarda_tempo(input int pulsos);
        repeat(pulsos) @(posedge clk);
    endtask

    task automatic execute_testes_release4;
        num_teste = 1;
        
        // Teste 1 a 4: Erros de 1 a 4 - Verificar sistema inoperante por 1s e displays
        for (int i = 0; i < 4; i++) begin            
            // Envia senha errada
            envia_senha_errada();
            
            // Aguarda 1 segundo (sistema inoperante)
            aguarda_tempo(UM_SEGUNDO); // 1 segundo
            
            // Verifica se o display correspondente está com hífen
            print_teste(verifica_valor_hex(i), $sformatf("HEX%0d deveria mostrar hífen após erro %0d", i, i+1));
            num_teste++;
        end
        
        // Teste 5: 5º erro - Bloqueio de 30s e todos displays com hífen
        envia_senha_errada();
        
        // Verifica se todos os displays mostram hífen
        @(posedge clk);
        print_teste(verifica_todos_hex_hifen(), "Todos os displays deveriam mostrar hífen após 5 erros");
        num_teste++;
        
        // Teste 6: Durante bloqueio - Verificar se teclado é ignorado
        teclado_desabilitado = 1'b1;
        
        // Tenta enviar dígitos durante o bloqueio e verifica se teclado_en permanece desabilitado
        for (int tentativa = 0; tentativa < 10; tentativa++) begin
            aguarda_tempo(2 * UM_SEGUNDO);
            
            // Tenta enviar um dígito
            send_digit($urandom_range(0, 9));
            @(posedge clk);
            
            // Verifica se o teclado continua desabilitado
            if (teclado_en == 1'b1) begin
                teclado_desabilitado = 1'b0;
                break;
            end
        end
        
        print_teste(teclado_desabilitado, "Teclado deveria estar desabilitado durante bloqueio");
        num_teste++;
        
        // Aguarda o restante do tempo de bloqueio (30s total)
        aguarda_tempo(10 * UM_SEGUNDO); // Aguarda mais 10s para completar 30s
        
        // Teste 7: Após 30s - Sistema normaliza
        @(posedge clk);
        
        print_teste(teclado_en == 1'b1, "Sistema deveria normalizar após 30s (teclado_en ativo)");
        num_teste++;
    endtask

    initial begin
        reset();
        execute_testes_release4();
        
        $display("\n========================================");
        $display("RESUMO DOS TESTES");
        $display("========================================");
        $display("Total de testes: %0d", total_testes);
        $display("Testes passaram: %0d", testes_passaram);
        $display("Testes falharam: %0d", testes_falharam);
        $display("========================================\n");
        
        #100 $finish;
    end

endmodule
