//------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------PACOTES--------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------


typedef struct packed {
    logic [19:0] [3:0] digits;
  } senhaPac_t;

  typedef struct packed {
	logic [3:0] BCD0;
	logic [3:0] BCD1;
	logic [3:0] BCD2;
	logic [3:0] BCD3;
	logic [3:0] BCD4;
    logic [3:0] BCD5;
    
  } bcdPac_t;

  typedef struct packed {
    logic bip_status;
    logic [5:0] bip_time;
    logic [5:0] tranca_aut_time;
    senhaPac_t senha_master;
    senhaPac_t senha_1;
    senhaPac_t senha_2;
    senhaPac_t senha_3;
    senhaPac_t senha_4;
  } setupPac_t;



//------------------------------------------------------------------------------------------------------------------------
//-----------------------------------------MÓDULO OPERACIONAL-------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------


module operacional#(
  parameter DEBOUNCE = 100,
  parameter DURACAO = 0,
  parameter SENHA_ERRADA = 1000,
  parameter BLOQUEADO = 30000
) (
  input		logic		    clk,
	input		logic		    rst,
	input		logic		    sensor_contato,
	input		logic		    botao_interno,
	input		logic		    botao_bloqueio,
	input		logic		    botao_config,
  input		setupPac_t 	data_setup_new,
	input		logic		    data_setup_ok,
	input		senhaPac_t	digitos_value,
	input		logic		    digitos_valid,
	output	bcdPac_t	  bcd_pac,
	output 	logic 		  teclado_en,
	output	logic		    display_en,
	output	logic		    setup_on,
  output	logic		    tranca,
	output	logic		    bip
);
  enum logic [4:0] {
    reset, //00
    porta_trancada,
    porta_encostada,
    porta_aberta,//03
    setup,
    bloqueado,
    nao_pertube,//06
    senha_errada,
    validar_mask,
    validar_senha,//09
    validar_senhadenovo,
    bipar_senha_incompleta,
    bipar_porta_aberta,//12
    debounce_nao_pertube,
    debounce_sair_nao_pertube,
    debounce_trancar,//15
    debounce_destrancar,
    leitura_senha_master,
    validar_senha_master//18
  } estado;
  logic [15:0] cont, contFechado, tent;
  logic [79:0] mask1, mask2, mask3, mask4, mask_master;
  logic senha_correta;
  logic [79:0] buffer_senha;
  logic senha_1, senha_2, senha_3, senha_4, confirmar, erro_teclado;
  reg exit_setup;

  //assign exit_setup = digitos_value.digits[0] === 4'hB ? 1 : 0;
  assign erro_teclado = digitos_valid && (digitos_value.digits[0] == 'hE);
  assign confirmar = digitos_valid && (digitos_value.digits[0] != 'hE && digitos_value.digits[0] != 'hF && digitos_value.digits[0] != 'hB );

  assign senha_correta = (senha_1 || senha_2 || senha_3 || senha_4) && buffer_senha != 80'hFFFFFFFFFFFFFFFFFFFF;

  assign senha_1 = (
    (((~((~buffer_senha)>>(0*4 )))|mask1)==data_setup_new.senha_1) |
    (((~((~buffer_senha)>>(1*4 )))|mask1)==data_setup_new.senha_1) |
    (((~((~buffer_senha)>>(2*4 )))|mask1)==data_setup_new.senha_1) |
    (((~((~buffer_senha)>>(3*4 )))|mask1)==data_setup_new.senha_1) |
    (((~((~buffer_senha)>>(4*4 )))|mask1)==data_setup_new.senha_1) |
    (((~((~buffer_senha)>>(5*4 )))|mask1)==data_setup_new.senha_1) |
    (((~((~buffer_senha)>>(6*4 )))|mask1)==data_setup_new.senha_1) |
    (((~((~buffer_senha)>>(7*4 )))|mask1)==data_setup_new.senha_1) |
    (((~((~buffer_senha)>>(8*4 )))|mask1)==data_setup_new.senha_1) |
    (((~((~buffer_senha)>>(9*4 )))|mask1)==data_setup_new.senha_1) |
    (((~((~buffer_senha)>>(10*4)))|mask1)==data_setup_new.senha_1) |
    (((~((~buffer_senha)>>(11*4)))|mask1)==data_setup_new.senha_1) |
    (((~((~buffer_senha)>>(12*4)))|mask1)==data_setup_new.senha_1) |
    (((~((~buffer_senha)>>(13*4)))|mask1)==data_setup_new.senha_1) |
    (((~((~buffer_senha)>>(14*4)))|mask1)==data_setup_new.senha_1) |
    (((~((~buffer_senha)>>(15*4)))|mask1)==data_setup_new.senha_1) |
    (((~((~buffer_senha)>>(16*4)))|mask1)==data_setup_new.senha_1)
  ) && mask1 != 80'hFFFFFFFFFFFFFFFFFFFF;

  assign senha_2 = (
    (((~((~buffer_senha)>>(0*4 )))|mask2)==data_setup_new.senha_2) |
    (((~((~buffer_senha)>>(1*4 )))|mask2)==data_setup_new.senha_2) |
    (((~((~buffer_senha)>>(2*4 )))|mask2)==data_setup_new.senha_2) |
    (((~((~buffer_senha)>>(3*4 )))|mask2)==data_setup_new.senha_2) |
    (((~((~buffer_senha)>>(4*4 )))|mask2)==data_setup_new.senha_2) |
    (((~((~buffer_senha)>>(5*4 )))|mask2)==data_setup_new.senha_2) |
    (((~((~buffer_senha)>>(6*4 )))|mask2)==data_setup_new.senha_2) |
    (((~((~buffer_senha)>>(7*4 )))|mask2)==data_setup_new.senha_2) |
    (((~((~buffer_senha)>>(8*4 )))|mask2)==data_setup_new.senha_2) |
    (((~((~buffer_senha)>>(9*4 )))|mask2)==data_setup_new.senha_2) |
    (((~((~buffer_senha)>>(10*4)))|mask2)==data_setup_new.senha_2) |
    (((~((~buffer_senha)>>(11*4)))|mask2)==data_setup_new.senha_2) |
    (((~((~buffer_senha)>>(12*4)))|mask2)==data_setup_new.senha_2) |
    (((~((~buffer_senha)>>(13*4)))|mask2)==data_setup_new.senha_2) |
    (((~((~buffer_senha)>>(14*4)))|mask2)==data_setup_new.senha_2) |
    (((~((~buffer_senha)>>(15*4)))|mask2)==data_setup_new.senha_2) |
    (((~((~buffer_senha)>>(16*4)))|mask2)==data_setup_new.senha_2)
  ) && mask2 != 80'hFFFFFFFFFFFFFFFFFFFF;

  assign senha_3 = (
    (((~((~buffer_senha)>>(0*4 )))|mask3)==data_setup_new.senha_3) |
    (((~((~buffer_senha)>>(1*4 )))|mask3)==data_setup_new.senha_3) |
    (((~((~buffer_senha)>>(2*4 )))|mask3)==data_setup_new.senha_3) |
    (((~((~buffer_senha)>>(3*4 )))|mask3)==data_setup_new.senha_3) |
    (((~((~buffer_senha)>>(4*4 )))|mask3)==data_setup_new.senha_3) |
    (((~((~buffer_senha)>>(5*4 )))|mask3)==data_setup_new.senha_3) |
    (((~((~buffer_senha)>>(6*4 )))|mask3)==data_setup_new.senha_3) |
    (((~((~buffer_senha)>>(7*4 )))|mask3)==data_setup_new.senha_3) |
    (((~((~buffer_senha)>>(8*4 )))|mask3)==data_setup_new.senha_3) |
    (((~((~buffer_senha)>>(9*4 )))|mask3)==data_setup_new.senha_3) |
    (((~((~buffer_senha)>>(10*4)))|mask3)==data_setup_new.senha_3) |
    (((~((~buffer_senha)>>(11*4)))|mask3)==data_setup_new.senha_3) |
    (((~((~buffer_senha)>>(12*4)))|mask3)==data_setup_new.senha_3) |
    (((~((~buffer_senha)>>(13*4)))|mask3)==data_setup_new.senha_3) |
    (((~((~buffer_senha)>>(14*4)))|mask3)==data_setup_new.senha_3) |
    (((~((~buffer_senha)>>(15*4)))|mask3)==data_setup_new.senha_3) |
    (((~((~buffer_senha)>>(16*4)))|mask3)==data_setup_new.senha_3)
  ) && mask3 != 80'hFFFFFFFFFFFFFFFFFFFF;

  assign senha_4 = (
    (((~((~buffer_senha)>>(0*4 )))|mask4)==data_setup_new.senha_4) |
    (((~((~buffer_senha)>>(1*4 )))|mask4)==data_setup_new.senha_4) |
    (((~((~buffer_senha)>>(2*4 )))|mask4)==data_setup_new.senha_4) |
    (((~((~buffer_senha)>>(3*4 )))|mask4)==data_setup_new.senha_4) |
    (((~((~buffer_senha)>>(4*4 )))|mask4)==data_setup_new.senha_4) |
    (((~((~buffer_senha)>>(5*4 )))|mask4)==data_setup_new.senha_4) |
    (((~((~buffer_senha)>>(6*4 )))|mask4)==data_setup_new.senha_4) |
    (((~((~buffer_senha)>>(7*4 )))|mask4)==data_setup_new.senha_4) |
    (((~((~buffer_senha)>>(8*4 )))|mask4)==data_setup_new.senha_4) |
    (((~((~buffer_senha)>>(9*4 )))|mask4)==data_setup_new.senha_4) |
    (((~((~buffer_senha)>>(10*4)))|mask4)==data_setup_new.senha_4) |
    (((~((~buffer_senha)>>(11*4)))|mask4)==data_setup_new.senha_4) |
    (((~((~buffer_senha)>>(12*4)))|mask4)==data_setup_new.senha_4) |
    (((~((~buffer_senha)>>(13*4)))|mask4)==data_setup_new.senha_4) |
    (((~((~buffer_senha)>>(14*4)))|mask4)==data_setup_new.senha_4) |
    (((~((~buffer_senha)>>(15*4)))|mask4)==data_setup_new.senha_4) |
    (((~((~buffer_senha)>>(16*4)))|mask4)==data_setup_new.senha_4)
  ) && mask4 != 80'hFFFFFFFFFFFFFFFFFFFF;

  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      estado <= reset;
      cont <= 0;
      tent <= 0;
      contFechado <= 0;
      mask1 <= 80'hFFFFFFFFFFFFFFFFFFFF;
      mask2 <= 80'hFFFFFFFFFFFFFFFFFFFF;
      mask3 <= 80'hFFFFFFFFFFFFFFFFFFFF;
      mask4 <= 80'hFFFFFFFFFFFFFFFFFFFF;
      mask_master <= 80'hFFFFFFFFFFFFFFFF0000;
      buffer_senha <= 80'hFFFFFFFFFFFFFFFFFFFF;
    end
    else begin
      case (estado)
        reset: begin
          cont <= 0;
          tent <= 0;
          contFechado <= 0;
			mask1 <= 80'hFFFFFFFFFFFFFFFFFFFF;
			mask2 <= 80'hFFFFFFFFFFFFFFFFFFFF;
			mask3 <= 80'hFFFFFFFFFFFFFFFFFFFF;
			mask4 <= 80'hFFFFFFFFFFFFFFFFFFFF;
			mask_master <= 80'hFFFFFFFFFFFFFFFF0000;
          buffer_senha <= 80'hFFFFFFFFFFFFFFFFFFFF;
          if (!sensor_contato) begin
            estado <= porta_trancada;
            tent <= 0;
          end
        end
        porta_trancada: begin
          if (erro_teclado) begin
            estado <= bipar_senha_incompleta;
            cont <= 0;
          end
          else if (botao_bloqueio) begin
            estado <= debounce_nao_pertube;
            cont <= 0;
          end
          else if (botao_interno) begin
            estado <= debounce_destrancar;
            cont <= 0;
          end
          else if (confirmar) begin
            buffer_senha <= digitos_value;
            estado <= validar_senha;
            tent <= tent + 1;
          end
        end
        porta_encostada: begin
          if (botao_interno) begin
            estado <= debounce_trancar;
            cont <= 0;
          end
          else if (sensor_contato) begin
            estado <= porta_aberta;
            cont <= 0;
          end
          else if (contFechado >= data_setup_new.tranca_aut_time*1000) begin
            estado <= porta_trancada;
				tent <= 0;
          end
          else begin
            contFechado <= contFechado + 1;
          end
        end
        porta_aberta: begin
          if (botao_config) begin
            estado <= leitura_senha_master;
          end
          else if (!sensor_contato) begin
            estado <= porta_encostada;
            contFechado <= 0;
          end
          else if (cont >= (data_setup_new.bip_time * 1000)) begin
            estado <= bipar_porta_aberta;
          end
          else begin
            cont <= cont + 1;
          end
        end
        setup: begin
          if (data_setup_ok) begin
            if      (data_setup_new.senha_1.digits[3] == 'hF)  mask1 <= 80'hFFFFFFFFFFFFFFFFFFFF;
            else if (data_setup_new.senha_1.digits[4] == 'hF)  mask1 <= 80'hFFFFFFFFFFFFFFFF0000;
            else if (data_setup_new.senha_1.digits[5] == 'hF)  mask1 <= 80'hFFFFFFFFFFFFFFF00000;
            else if (data_setup_new.senha_1.digits[6] == 'hF)  mask1 <= 80'hFFFFFFFFFFFFFF000000;
            else if (data_setup_new.senha_1.digits[7] == 'hF)  mask1 <= 80'hFFFFFFFFFFFFF0000000;
            else if (data_setup_new.senha_1.digits[8] == 'hF)  mask1 <= 80'hFFFFFFFFFFFF00000000;
            else if (data_setup_new.senha_1.digits[9] == 'hF)  mask1 <= 80'hFFFFFFFFFFF000000000;
            else if (data_setup_new.senha_1.digits[10] == 'hF)  mask1 <= 80'hFFFFFFFFFF0000000000;
            else if (data_setup_new.senha_1.digits[11] == 'hF)  mask1 <= 80'hFFFFFFFFF00000000000;
            else if (data_setup_new.senha_1.digits[12] == 'hF)  mask1 <= 80'hFFFFFFFF000000000000;
            else 	                                                    mask1 <= 80'hFFFFFFFFFFFFFFFFFFFF;

            if      (data_setup_new.senha_2.digits[3] == 'hF)  mask2 <= 80'hFFFFFFFFFFFFFFFFFFFF;
            else if (data_setup_new.senha_2.digits[4] == 'hF)  mask2 <= 80'hFFFFFFFFFFFFFFFF0000;
            else if (data_setup_new.senha_2.digits[5] == 'hF)  mask2 <= 80'hFFFFFFFFFFFFFFF00000;
            else if (data_setup_new.senha_2.digits[6] == 'hF)  mask2 <= 80'hFFFFFFFFFFFFFF000000;
            else if (data_setup_new.senha_2.digits[7] == 'hF)  mask2 <= 80'hFFFFFFFFFFFFF0000000;
            else if (data_setup_new.senha_2.digits[8] == 'hF)  mask2 <= 80'hFFFFFFFFFFFF00000000;
            else if (data_setup_new.senha_2.digits[9] == 'hF)  mask2 <= 80'hFFFFFFFFFFF000000000;
            else if (data_setup_new.senha_2.digits[10] == 'hF)  mask2 <= 80'hFFFFFFFFFF0000000000;
            else if (data_setup_new.senha_2.digits[11] == 'hF)  mask2 <= 80'hFFFFFFFFF00000000000;
            else if (data_setup_new.senha_2.digits[12] == 'hF)  mask2 <= 80'hFFFFFFFF000000000000;
            else 	                                                    mask2 <= 80'hFFFFFFFFFFFFFFFFFFFF;

            if      (data_setup_new.senha_3.digits[3] == 'hF)  mask3 <= 80'hFFFFFFFFFFFFFFFFFFFF;
            else if (data_setup_new.senha_3.digits[4] == 'hF)  mask3 <= 80'hFFFFFFFFFFFFFFFF0000;
            else if (data_setup_new.senha_3.digits[5] == 'hF)  mask3 <= 80'hFFFFFFFFFFFFFFF00000;
            else if (data_setup_new.senha_3.digits[6] == 'hF)  mask3 <= 80'hFFFFFFFFFFFFFF000000;
            else if (data_setup_new.senha_3.digits[7] == 'hF)  mask3 <= 80'hFFFFFFFFFFFFF0000000;
            else if (data_setup_new.senha_3.digits[8] == 'hF)  mask3 <= 80'hFFFFFFFFFFFF00000000;
            else if (data_setup_new.senha_3.digits[9] == 'hF)  mask3 <= 80'hFFFFFFFFFFF000000000;
            else if (data_setup_new.senha_3.digits[10] == 'hF)  mask3 <= 80'hFFFFFFFFFF0000000000;
            else if (data_setup_new.senha_3.digits[11] == 'hF)  mask3 <= 80'hFFFFFFFFF00000000000;
            else if (data_setup_new.senha_3.digits[12] == 'hF)  mask3 <= 80'hFFFFFFFF000000000000;
            else 	                                                    mask3 <= 80'hFFFFFFFFFFFFFFFFFFFF;

            if      (data_setup_new.senha_4.digits[3] == 'hF)  mask4 <= 80'hFFFFFFFFFFFFFFFFFFFF;
            else if (data_setup_new.senha_4.digits[4] == 'hF)  mask4 <= 80'hFFFFFFFFFFFFFFFF0000;
            else if (data_setup_new.senha_4.digits[5] == 'hF)  mask4 <= 80'hFFFFFFFFFFFFFFF00000;
            else if (data_setup_new.senha_4.digits[6] == 'hF)  mask4 <= 80'hFFFFFFFFFFFFFF000000;
            else if (data_setup_new.senha_4.digits[7] == 'hF)  mask4 <= 80'hFFFFFFFFFFFFF0000000;
            else if (data_setup_new.senha_4.digits[8] == 'hF)  mask4 <= 80'hFFFFFFFFFFFF00000000;
            else if (data_setup_new.senha_4.digits[9] == 'hF)  mask4 <= 80'hFFFFFFFFFFF000000000;
            else if (data_setup_new.senha_4.digits[10] == 'hF)  mask4 <= 80'hFFFFFFFFFF0000000000;
            else if (data_setup_new.senha_4.digits[11] == 'hF)  mask4 <= 80'hFFFFFFFFF00000000000;
            else if (data_setup_new.senha_4.digits[12] == 'hF)  mask4 <= 80'hFFFFFFFF000000000000;
            else 	                                                    mask4 <= 80'hFFFFFFFFFFFFFFFFFFFF;

            if      (data_setup_new.senha_master.digits[3] == 'hF) mask_master <= 80'hFFFFFFFFFFFFFFFFFFFF;
            else if (data_setup_new.senha_master.digits[4] == 'hF) mask_master <= 80'hFFFFFFFFFFFFFFFF0000;
            else if (data_setup_new.senha_master.digits[5] == 'hF) mask_master <= 80'hFFFFFFFFFFFFFFF00000;
            else if (data_setup_new.senha_master.digits[6] == 'hF) mask_master <= 80'hFFFFFFFFFFFFFF000000;
            else if (data_setup_new.senha_master.digits[7] == 'hF) mask_master <= 80'hFFFFFFFFFFFFF0000000;
            else if (data_setup_new.senha_master.digits[8] == 'hF) mask_master <= 80'hFFFFFFFFFFFF00000000;
            else if (data_setup_new.senha_master.digits[9] == 'hF) mask_master <= 80'hFFFFFFFFFFF000000000;
            else if (data_setup_new.senha_master.digits[10] == 'hF) mask_master <= 80'hFFFFFFFFFF0000000000;
            else if (data_setup_new.senha_master.digits[11] == 'hF) mask_master <= 80'hFFFFFFFFF00000000000;
            else if (data_setup_new.senha_master.digits[12] == 'hF) mask_master <= 80'hFFFFFFFF000000000000;
            else 	                                                        mask_master <= 80'hFFFFFFFFFFFFFFFFFFFF;
            estado <= porta_aberta;
          end
        end
        bloqueado: begin
          if (cont >= BLOQUEADO) begin
            cont <= 0;
            tent <= 0;
            estado <= porta_trancada;
          end
          else begin
            cont <= cont + 1;
          end
        end
        nao_pertube: begin
          if (botao_interno) begin
            estado <= debounce_sair_nao_pertube;
            cont <= 0;
          end
        end
        senha_errada: begin
          if (cont < SENHA_ERRADA) begin
            cont <= cont + 1;
          end
          else if (tent < 5) begin
            estado <= porta_trancada;
          end
          else if (tent >= 5) begin
            estado <= bloqueado;
            cont <= 0;
          end
        end
        validar_senha: begin
          if(senha_correta)begin
            estado <= porta_encostada;
            contFechado <= 0;
            buffer_senha <= 80'hFFFFFFFFFFFFFFFFFFFF;
          end
          else begin
            estado <= senha_errada;
            cont <= 0;
          end
        end
        bipar_senha_incompleta: begin
          if (cont < DURACAO) begin
            cont++;
          end
          else begin
            estado <= porta_trancada;
          end
        end
        bipar_porta_aberta: begin
          if (!sensor_contato) begin
            estado <= porta_encostada;
            contFechado <= 0;
          end
          else if(botao_config) begin
            estado <= leitura_senha_master;
          end
        end
        debounce_nao_pertube: begin
          if (cont >= 3000) begin
            estado <= nao_pertube;
          end
          else if (!botao_bloqueio) begin
            estado <= porta_trancada;
          end
          else begin
            cont <= cont + 1;
          end
        end
        debounce_sair_nao_pertube: begin
          if (cont >= DEBOUNCE && !botao_interno) begin
            estado <= porta_encostada;
            contFechado <= 0;
          end
          else if (!botao_interno) begin
            estado <= nao_pertube;
          end
          else begin
            cont <= cont + 1;
          end
        end
        debounce_trancar: begin
          if (cont >= DEBOUNCE && !botao_interno) begin
            estado <= porta_trancada;
				tent <= 0;
          end
          else if (!botao_interno) begin
            estado <= porta_encostada;
          end
          else begin
            cont <= cont +1;
          end
        end
        debounce_destrancar: begin
          if (cont >= DEBOUNCE && !botao_interno) begin
            estado <= porta_encostada;
            contFechado <= 0;
          end
          else if (!botao_interno) begin
            estado <= porta_trancada;
          end
          else begin
            cont <= cont + 1;
          end
        end
        leitura_senha_master: begin
          if(confirmar) begin
            buffer_senha <= digitos_value;
            estado <= validar_senha_master;
          end
          else if(digitos_value.digits[0] == 4'hB) begin
				cont <= 0;
            estado <= porta_aberta;
          end
        end
        validar_senha_master: begin
          if((
				 (((~((~buffer_senha)>>(0*4 )))|mask_master)==data_setup_new.senha_master) |
				 (((~((~buffer_senha)>>(1*4 )))|mask_master)==data_setup_new.senha_master) |
				 (((~((~buffer_senha)>>(2*4 )))|mask_master)==data_setup_new.senha_master) |
				 (((~((~buffer_senha)>>(3*4 )))|mask_master)==data_setup_new.senha_master) |
				 (((~((~buffer_senha)>>(4*4 )))|mask_master)==data_setup_new.senha_master) |
				 (((~((~buffer_senha)>>(5*4 )))|mask_master)==data_setup_new.senha_master) |
				 (((~((~buffer_senha)>>(6*4 )))|mask_master)==data_setup_new.senha_master) |
				 (((~((~buffer_senha)>>(7*4 )))|mask_master)==data_setup_new.senha_master) |
				 (((~((~buffer_senha)>>(8*4 )))|mask_master)==data_setup_new.senha_master) |
				 (((~((~buffer_senha)>>(9*4 )))|mask_master)==data_setup_new.senha_master) |
				 (((~((~buffer_senha)>>(10*4)))|mask_master)==data_setup_new.senha_master) |
				 (((~((~buffer_senha)>>(11*4)))|mask_master)==data_setup_new.senha_master) |
				 (((~((~buffer_senha)>>(12*4)))|mask_master)==data_setup_new.senha_master) |
				 (((~((~buffer_senha)>>(13*4)))|mask_master)==data_setup_new.senha_master) |
				 (((~((~buffer_senha)>>(14*4)))|mask_master)==data_setup_new.senha_master) |
				 (((~((~buffer_senha)>>(15*4)))|mask_master)==data_setup_new.senha_master) |
				 (((~((~buffer_senha)>>(16*4)))|mask_master)==data_setup_new.senha_master)
			  ) && mask_master != 80'hFFFFFFFFFFFFFFFFFFFF) begin
            estado <= setup;
				 buffer_senha <= 80'hFFFFFFFFFFFFFFFFFFFF;
          end
          else begin
            estado <= leitura_senha_master;
				buffer_senha <= 80'hFFFFFFFFFFFFFFFFFFFF;
			end
        end
        default: estado <= reset;
      endcase
    end
  end

  always_comb begin
    if(rst) begin
      bcd_pac = 'hBBBBBB;
      teclado_en = 0;
      display_en = 1;
      setup_on = 0;
      tranca = 0;
      bip = 0;
    end
    else begin
      case(estado)
        reset: begin
          bcd_pac = 'hBBBBBB;
          teclado_en = 0;
          display_en = 1;
          setup_on = 0;
          tranca = 0;
          bip = 0;
        end
        porta_trancada: begin
          bcd_pac = 'hBBBBBB;
          teclado_en = 1;
          display_en = 1;
          setup_on = 0;
          tranca = 1;
          bip = 0;
        end
        porta_encostada: begin
          bcd_pac = 'hBBBBBB;
          teclado_en = 0;
          display_en = 1;
          setup_on = 0;
          tranca = 0;
          bip = 0;
        end
        porta_aberta: begin
          bcd_pac = 'hBBBBBB;
          teclado_en = 0;
          display_en = 1;
          setup_on = 0;
          tranca = 0;
          bip = 0;
        end
        setup: begin
          bcd_pac = 'hBBBBBB;
          teclado_en = 1;
          display_en = 0;
          setup_on = 1;
          tranca = 0;
          bip = 0;
        end
        bloqueado: begin
          bcd_pac = 'hAAAAAA;
          teclado_en = 0;
          display_en = 1;
          setup_on = 0;
          tranca = 1;
          bip = 0;
        end
        nao_pertube: begin
          bcd_pac = 'hBBBBBB;
          teclado_en = 0;
          display_en = 0;
          setup_on = 0;
          tranca = 1;
          bip = 0;
        end
        senha_errada: begin
          case(tent)
            
            1: begin
              bcd_pac.BCD0 = 'hA;
              bcd_pac.BCD1 = 'hB;
              bcd_pac.BCD2 = 'hB;
              bcd_pac.BCD3 = 'hB;
              bcd_pac.BCD4 = 'hB;
              bcd_pac.BCD5 = 'hB;
            end
            
            2: begin
              bcd_pac.BCD0 = 'hA;
              bcd_pac.BCD1 = 'hA;
              bcd_pac.BCD2 = 'hB;
              bcd_pac.BCD3 = 'hB;
              bcd_pac.BCD4 = 'hB;
              bcd_pac.BCD5 = 'hB;
            end
            3: begin
              bcd_pac.BCD0 = 'hA;
              bcd_pac.BCD1 = 'hA;
              bcd_pac.BCD2 = 'hA;
              bcd_pac.BCD3 = 'hB;
              bcd_pac.BCD4 = 'hB;
              bcd_pac.BCD5 = 'hB;
            end
            4: begin
              bcd_pac.BCD0 = 'hA;
              bcd_pac.BCD1 = 'hA;
              bcd_pac.BCD2 = 'hA;
              bcd_pac.BCD3 = 'hA;
              bcd_pac.BCD4 = 'hB;
              bcd_pac.BCD5 = 'hB;
            end
            5: begin
              bcd_pac.BCD0 = 'hA;
              bcd_pac.BCD1 = 'hA;
              bcd_pac.BCD2 = 'hA;
              bcd_pac.BCD3 = 'hA;
              bcd_pac.BCD4 = 'hA;
              bcd_pac.BCD5 = 'hB;
            end
          endcase
          teclado_en = 0;
          display_en = 1;
          setup_on = 0;
          tranca = 1;
          bip = 0;
        end
        validar_senha: begin
          bcd_pac = 'hBBBBBB;
          teclado_en = 0;
          display_en = 1;
          setup_on = 0;
          tranca = 1;
          bip = 0;
        end
        bipar_senha_incompleta: begin
          bcd_pac = 'hBBBBBB;
          teclado_en = 0;
          display_en = 1;
          setup_on = 0;
          tranca = 1;
          bip = 1;
        end
        bipar_porta_aberta: begin
          bcd_pac = 'hBBBBBB;
          teclado_en = 0;
          display_en = 1;
          setup_on = 0;
          tranca = 0;
          bip = 1;
        end
        debounce_nao_pertube: begin
          bcd_pac = 'hBBBBBB;
          teclado_en = 0;
          display_en = 1;
          setup_on = 0;
          tranca = 1;
          bip = 0;
        end
        debounce_sair_nao_pertube: begin
          bcd_pac = 'hBBBBBB;
          teclado_en = 0;
          display_en = 1;
          setup_on = 0;
          tranca = 1;
          bip = 0;
        end
        debounce_trancar: begin
          bcd_pac = 'hBBBBBB;
          teclado_en = 0;
          display_en = 1;
          setup_on = 0;
          tranca = 0;
          bip = 0;
        end
        debounce_destrancar: begin
          bcd_pac = 'hBBBBBB;
          teclado_en = 0;
          display_en = 1;
          setup_on = 0;
          tranca = 1;
          bip = 0;
        end
        leitura_senha_master: begin
          bcd_pac.BCD0 = 'hB;
          bcd_pac.BCD1 = 'hB;
          bcd_pac.BCD2 = 'hB;
          bcd_pac.BCD3 = 'hB;
          bcd_pac.BCD4 = 'hB;
          bcd_pac.BCD5 = 'h0;
          teclado_en = 1;
          display_en = 1;
          setup_on = 0;
          tranca = 0;
          bip = 0;
        end
        validar_senha_master: begin
          bcd_pac.BCD0 = 'hB;
          bcd_pac.BCD1 = 'hB;
          bcd_pac.BCD2 = 'hB;
          bcd_pac.BCD3 = 'hB;
          bcd_pac.BCD4 = 'hB;
          bcd_pac.BCD5 = 'h0;
          teclado_en = 0;
          display_en = 1;
          setup_on = 0;
          tranca = 0;
          bip = 0;
        end
      endcase
    end
  end
endmodule


