`timescale 1ns / 1ps

`include "define.v"

module if_id(
    input clk,
    input rst,
    input [`InstAddrBus] if_pc,             //取指阶段的地址
    input [`InstBus] if_inst,               //取指阶段的指令
    input [5:0] stall,                      //暂停信号
    output reg[`InstAddrBus] id_pc,         //译码阶段的地址
    output reg[`InstBus] id_inst            //译码阶段的指令
    );

    // 根据取指阶段获取的指令和地址，更新译码阶段的指令和地址
    // 当stall[1]==`Stop && stall[2]==`NoStop时，表示取指阶段暂停，译码阶段继续，使用空指令作为下一周期的译码阶段的指令
    // 当stall[1]==`NoStop时，表示取指阶段继续，译码阶段继续，使用取指阶段的指令作为下一周期的译码阶段的指令
    // 其余情况下，译码阶段的指令和地址保持不变
    always @(posedge clk)
    begin
        if(rst==`RstEna)
            begin
                id_pc <= `ZeroWord;
                id_inst <= `ZeroWord;
            end
        else if(stall[1] == `Stop && stall[2] == `NoStop)
            begin
                id_pc <= `ZeroWord;
                id_inst <= `ZeroWord;
            end
        else if(stall[1] == `NoStop)
            begin
                id_pc <= if_pc;
                id_inst <= if_inst;
            end
    end
endmodule
