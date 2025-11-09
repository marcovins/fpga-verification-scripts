module controladora #(
  parameter DEBOUNCE_P = 300,
  parameter SWITCH_MODE_MIN_T = 5000,
  parameter AUTO_SHUTDOWN_T = 30000
)(
  input  wire clk, rst,
  input  logic infravermelho, push_button,
  output logic led, saida
);

  // Sinais intermediários entre módulos
  logic A, B, C, D;

  // Instanciação do submodulo_2 (debounce e controle de modo manual/automático)
  submodulo_2 #(
    .DEBOUNCE_P(DEBOUNCE_P),
    .SWITCH_MODE_MIN_T(SWITCH_MODE_MIN_T)
  ) debouncer (
    .clk(clk),
    .rst(rst),
    .PB(push_button),
    .A(A),
    .B(B)
  );

  // Instanciação do submodulo_3 (sensor IR e desligamento automático)
  submodulo_3 #(
    .AUTO_SHUTDOWN_T(AUTO_SHUTDOWN_T)
  ) sensor_IR (
    .clk(clk),
    .rst(rst),
    .infravermelho(infravermelho),
    .C(C)
  );

  // D é o próprio sinal do sensor infravermelho (enquanto ativo, movimento)
  assign D = infravermelho;

  // Instanciação do submodulo_1
  submodulo_1 maquina_principal (
    .clk(clk),
    .rst(rst),
    .a(A),
    .b(B),
    .c(C),
    .d(D),
    .led(led),
    .saida(saida)
  );

  // Log para controle de estado
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      $display("Controladora: RESET - A: %b, B: %b, C: %b, D: %b", A, B, C, D);
    end
  end

endmodule


module submodulo_1(
  input  logic clk, rst, a, b, c, d,
  output logic led, saida
);

  typedef enum logic [1:0] {
    lampada_lig_auto,
    lampada_des_auto,
    lampada_lig_man,
    lampada_des_man
  } estado_t;

  estado_t estado;

  // Lógica sequencial
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      estado <= lampada_des_auto;
    end
    
    else begin
      case (estado)
        lampada_des_auto: begin
          if (a) begin
            estado <= lampada_des_man;
          end
          else begin
            estado <= lampada_lig_auto;
          end
        end
        
        lampada_lig_auto: begin
          if (a) begin
            estado <= lampada_des_man;
          end

          else if (c) begin
            estado <= lampada_des_auto;
          end
        end
        
        lampada_des_man: begin
          if (a) begin
            estado <= lampada_lig_auto;
          end
          
          else begin
          	estado <= lampada_lig_man;
          end
        end
        
        lampada_lig_man: begin
          if (a) begin
            estado <= lampada_lig_auto;
          end
          
          else begin
            estado <= lampada_des_man;
          end
        end
      endcase
    end
  end

  // Lógica combinacional
  always_comb begin
    case (estado)
      lampada_lig_auto: begin
        led = 0;
        saida = 1;
      end

      lampada_des_auto: begin
      	led = 0;
        saida = 0;
        end

      lampada_lig_man: begin
        led = 1;
        saida = 1;
      end

      lampada_des_man: begin
        led = 1;
        saida = 0;
      end

      default: begin
        led = 0;
        saida  = 0;
      end
    endcase
  end
endmodule


module submodulo_2 #(
  parameter DEBOUNCE_P = 300,
  parameter SWITCH_MODE_MIN_T = 5000
)(
  input  wire clk, rst,
  input  logic PB,
  output logic A, B
);

  typedef enum logic [2:0] {inicial, db, a, b, temp} estado_t;
  estado_t estado;
  
  int tp;

  // Bloco sequencial
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      estado <= inicial;
    end
    
    else begin
      case (estado)
        inicial: begin
          if (PB) begin
            estado <= db;
          end
          
    end
  end

  // Bloco combinacional
  always_comb begin
    case (estado)
      inicial: begin
        a = 0;
        b = 0;
        tp = 0;
      end
      
      db: begin
        
    endcase
  end
endmodule

module submodulo_3 #(
  parameter AUTO_SHUTDOWN_T = 30000
)(
  input  wire clk, rst,
  input  logic infravermelho,
  output logic C
);

  typedef enum logic [1:0] {inicial, contando} estado_t;
  estado_t estado;

  int TC;

  // Bloco sequencial: controla o estado e as variáveis
  always_ff @(posedge clk or posedge rst) begin
  if (rst) begin
      estado <= inicial;
      TC     <= 0;
      C      <= 0;
  end else begin
      case (estado)
      inicial: begin
          if (!infravermelho) begin
          estado <= contando;
          end
      end

      contando: begin
          if (!infravermelho) begin
          if (TC < AUTO_SHUTDOWN_T) begin
              TC <= TC + 1;
          end
          if (TC == AUTO_SHUTDOWN_T - 1) begin
              estado <= temp;
          end
          end else begin
          // Sensor ativado novamente: volta ao início
          estado <= inicial;
          end
      end

      temp:begin
          estado <= inicial;
      end

      default: begin
          estado <= inicial;
      end
      endcase
  end
  end

  // Bloco combinacional: define os próximos valores
  always_comb begin

      case (estado)
      inicial: begin
          C = 0;
          TC = 0;
      end

      contando: begin
          if (!infravermelho)
              C = 0;
      end

      temp: begin
          C = 1;
          TC = 0;
      end

      default: begin
          C = 0;
          TC = 0;
      end
      endcase
  end

endmodule
