`timescale 1ns / 1ps

`include"define.v"

module ex_mem(
    input clk,
    input rst,

    // 执行阶段的输出
    input [`RegAddrBus] ex_waddr,                           //写寄存器地址
    input [`RegBus] ex_wdata,                               //写寄存器数据
    input ex_wreg,                                          //是否写寄存器
    input [5:0] stall,                                      //流水线阻塞
    // 来自ex阶段的数据
    input [`AluOpBus] ex_aluop,                             //运算操作
    input [`RegBus] ex_mem_addr,                            //存储器地址
    input [`RegBus] ex_reg2,                                //要存储的数据
    
    // 送到访存阶段的数据
    output reg [`RegAddrBus] mem_waddr,                     //写寄存器地址
    output reg [`RegBus] mem_wdata,                         //写寄存器数据
    output reg mem_wreg,                                    //是否写寄存器
   
    // 送到访存阶段的数据 
    output reg [`AluOpBus] mem_aluop,                       //运算操作
    output reg [`RegBus] mem_mem_addr,                      //存储器地址
    output reg [`RegBus] mem_reg2                          //要存储的数据
    );



    always @(posedge clk)
    begin
        if(rst == `RstEna)
            begin
                mem_waddr <= `NOPRegAddr;           //写寄存器地址默认为0
                mem_wdata <= `ZeroWord;             //写寄存器数据默认为0
                mem_wreg <= `WriteDisa;             //是否写寄存器默认为禁止
                mem_aluop <= `EXE_NOP_OP;           //运算操作默认为nop
                mem_mem_addr <= `ZeroWord;          //存储器地址默认为0
                mem_reg2 <= `ZeroWord;              //要存储的数据默认为0
            end
        else if(stall[3] == `Stop && stall[4] == `NoStop)//执行阶段暂停，访存阶段不暂停
            begin
                mem_waddr <= `NOPRegAddr;           //写寄存器地址默认为0
                mem_wdata <= `ZeroWord;             //写寄存器数据默认为0
                mem_wreg <= `WriteDisa;             //是否写寄存器默认为禁止      
                mem_aluop <= `EXE_NOP_OP;           //运算操作默认为nop
                mem_mem_addr <= `ZeroWord;          //存储器地址默认为0
                mem_reg2 <= `ZeroWord;              //要存储的数据默认为0
            end
        else if(stall[3] == `NoStop)//执行阶段不暂停
            begin   
                mem_waddr <= ex_waddr;              //写寄存器地址
                mem_wdata <= ex_wdata;              //写寄存器数据
                mem_wreg <= ex_wreg;                //是否写寄存器 
                mem_aluop <= ex_aluop;              //运算操作
                mem_mem_addr <= ex_mem_addr;        //存储器地址
                mem_reg2 <= ex_reg2;                //要存储的数据
            end
        else 
            begin
               
            end
    end
endmodule
