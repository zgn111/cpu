`timescale 1ns / 1ps

`include"define.v"

module mem_wb(
    input clk,
    input rst,
    // 访存阶段的输出
    input mem_reg,                              //访存阶段是否有要写入的目的寄存器
    input [`RegAddrBus] mem_waddr,              //写寄存器地址
    input [`RegBus] mem_wdata,                  //写寄存器数据
    
    input [5:0] stall,                          //流水线阻塞
    
    // 送到回写阶段
    output reg wb_reg,                          //回写阶段是否有要写入的目的寄存器
    output reg [`RegAddrBus] wb_waddr,          //写寄存器地址
    output reg [`RegBus] wb_wdata              //写寄存器数据
    );



    always @(posedge clk)
    begin
        if(rst == `RstEna)
            begin
                wb_reg <= `WriteDisa;       //默认不写
                wb_waddr <= `NOPRegAddr;    //默认写0
                wb_wdata <= `ZeroWord;      //默认写0
            end
        else if(stall[4] == `Stop && stall[5] == `NoStop)//访存阶段暂停，回写阶段不暂停
            begin
                wb_reg <= `WriteDisa;
                wb_waddr <= `NOPRegAddr;
                wb_wdata <= `ZeroWord;
            end
        else if(stall[4] == `NoStop)    //访存阶段不暂停，回写阶段不暂停，才能进行回写
            begin
                wb_reg <= mem_reg;
                wb_waddr <= mem_waddr;
                wb_wdata <= mem_wdata; 
        end
    end
endmodule
