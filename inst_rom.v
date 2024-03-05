`timescale 1ns / 1ps

`include"define.v"

// 用于存放指令的ROM

module inst_rom(
    input ce,                       //使能信号
    input [`InstAddrBus] addr,       //地址
    output reg [`InstBus] inst      //输出的指令
    );

    reg [`InstBus] inst_mem[0:`InstMemNum-1];
    // 使用文件初始化ROM
    initial $readmemh("F:/ModelSim/examples/work/inst_rom.data",inst_mem);

    always @(*)
    begin
        if(ce == `ChipDisa)
            begin
                inst <= `ZeroWord;
            end
        else 
            begin
                inst <= inst_mem[addr[`InstMemNumLog2+1:2]];
            end
    end
endmodule
