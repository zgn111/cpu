`timescale 1ns / 1ps

`include"define.v"

// id_ex模块连接了译码阶段和执行阶段，将译码阶段的输出传递给执行阶段

module id_ex(
    input clk,
    input rst,

// id阶段的输出
    input [`AluSelBus] id_alusel,                               //运算类型
    input [`AluOpBus] id_aluop,                                 //运算操作
    input id_wreg,                                              //是否写寄存器
    input [`RegAddrBus] id_waddr,                               //写寄存器地址
    input [`RegBus] id_reg1,                                    //寄存器1的值
    input [`RegBus] id_reg2,                                    //寄存器2的值


    input [5:0] stall,                                          //流水线暂停
    input id_is_in_delayslot,                                   //是否延迟
    input next_inst_in_delayslot_i,                             //下一条指令是否延迟
    input [`InstAddrBus] id_link_address,                       //跳转地址
    input [`InstBus] id_inst,                                   //id阶段传来指令

    // ex阶段的输入
    output reg [`AluSelBus] ex_alusel,                          //运算类型
    output reg [`AluOpBus] ex_aluop,                            //运算操作
    output reg ex_wreg,                                         //是否写寄存器
    output reg [`RegAddrBus] ex_waddr,                          //写寄存器地址
    output reg [`RegBus] ex_reg1,                               //寄存器1的值
    output reg [`RegBus] ex_reg2,                               //寄存器2的值


    output reg ex_is_in_delayslot,                              //ex模块是否延迟
    output reg is_in_delayslot_o,                               //是否延迟
    output reg [`InstAddrBus] ex_link_address,                  //跳转地址
    output reg [`InstBus] ex_inst                               //传到ex模块的指令
    );




    always @(posedge clk)
    begin
        if(rst == `RstEna)//复位有效
            begin
                ex_alusel <= `EXE_RES_NOP;
                ex_aluop <= `EXE_NOP_OP;
                ex_wreg <= `WriteDisa;
                ex_waddr <= `NOPRegAddr;
                ex_reg1 <= `ZeroWord;
                ex_reg2 <= `ZeroWord;
                ex_is_in_delayslot <= 1'b0;
                is_in_delayslot_o <= 1'b0;
                ex_link_address <= `ZeroWord;
                ex_inst <= `ZeroWord;
            end
        else if(stall[2] == `Stop && stall[3] == `NoStop)//译码阶段暂停，执行阶段不暂停
            begin
                ex_alusel <= `EXE_RES_NOP;
                ex_aluop <= `EXE_NOP_OP;
                ex_wreg <= `WriteDisa;
                ex_waddr <= `NOPRegAddr;
                ex_reg1 <= `ZeroWord;
                ex_reg2 <= `ZeroWord;
                ex_is_in_delayslot <= 1'b0;
                is_in_delayslot_o <= 1'b0;
                ex_link_address <= `ZeroWord;
                ex_inst <= `ZeroWord;
            end
        else if(stall[2] == `NoStop)//译码阶段不暂停,执行阶段不暂停,正常传递
            begin
                ex_alusel <= id_alusel;
                ex_aluop <= id_aluop;
                ex_wreg <= id_wreg;
                ex_waddr <= id_waddr;
                ex_reg1 <= id_reg1;
                ex_reg2 <= id_reg2;
                ex_is_in_delayslot <= id_is_in_delayslot;
                is_in_delayslot_o <= next_inst_in_delayslot_i;
                ex_link_address <= id_link_address;
                ex_inst <= id_inst;
            end
        else 
            begin
            end
    end
endmodule
