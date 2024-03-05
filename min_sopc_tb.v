`timescale 1ns / 1ps

module min_sopc_tb();

    // 时钟信号
    reg clk;
    // 复位信号
    reg rst;

   //每隔10ns,clk翻转一次
   initial begin
         clk = 0;
         forever #10 clk = ~clk;
   end

   initial begin
         rst = 1;
         #200 rst = 0;
         #1000 $stop;
   end

   min_sopc min_sopc0(
       .clk(clk),
       .rst(rst)
   );

endmodule
