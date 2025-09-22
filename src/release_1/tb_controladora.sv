`timescale 1ns/1ns

module tb_controladora;
  // Sinais principais
  logic clk = 0, rst = 1;
  logic push_button = 0;
  logic infravermelho = 0;
  logic led, saida;

  // Clock de período 4ns (freq ~250 MHz)
  always #2 clk = ~clk;

  // Contador de 13 bits
  logic [12:0] cont;

  // Incrementa contador a cada clock, com reset
  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      cont <= 13'd0;
    else if (push_button)begin
      cont <= cont + 1;
      if (cont % 10 == 0)
        $display("  %0t     | %b   | %b     |     %b      | %s", 
             $time, led, saida, push_button, dut.sub_1.state.name());
    end
  end

  // Instância do DUT
  controladora dut (
    .clk          (clk),
    .rst          (rst),
    .push_button  (push_button),
    .infravermelho(infravermelho),
    .led          (led),
    .saida        (saida)
  );

  // Reset inicial
  initial begin
    rst = 1;
    repeat (3) @(posedge clk);
    rst = 0;
  end
  
  // Estímulos e critério de parada
  initial begin
    @(negedge rst);           // espera reset sair
    #10 push_button = 1;      // começa a contar
    wait (cont > 5301);       // espera até contador ultrapassar 5301
    push_button = 0;          // solta o botão
    $display("Time(ns)=%0t | Led=%b | Saida=%b | cont=%d | push_button=%b | Estado=%s",
             $time, led, saida, cont, push_button, dut.sub_1.state.name());
    #10 $finish;              // encerra simulação
  end

  // Monitor
  initial begin
    $display("Time(ns) | Led | Saida | push_button | Estado");
    
  end

endmodule
