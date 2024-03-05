`timescale 1ns / 1ps

`include "define.v"


module pc_reg(
    input clk,
    input rst,
    input [5:0] stall,                      //暂停信号
    input branch_flag_i,                    //分支标志
    input [`InstAddrBus] branch_target_address_i,  //分支地址

    output reg[`InstAddrBus] pc,            //PC
    output reg ce                           //指令存储器使能
    );

    // 更新ce，将ce的更新和使用分开，避免冲突
    always @(posedge clk)
    begin
        if(rst==`RstEna)
            begin
                ce<=`ChipDisa; //复位的时候指令存储器禁用
            end
        else 
            begin
                ce<=`ChipEna;//复位结束后，指令存储器使能，一个过程中只能有一个操作
            end
    end



    // 更新pc
    always @(posedge clk)
    begin
        if(ce==`ChipDisa)
            begin
                pc<=32'h00000000;//指令存储器禁用的时候，PC为0
            end
        else if(stall[0] == `NoStop)   
            begin //不暂停才赋值，暂停则保持不变
                if(branch_flag_i == 1'b1)
                    begin
                        pc <= branch_target_address_i;//分支的时候，直接跳转到分支地址
                    end
                else 
                    begin
                        pc<=pc+4'h4; //直接就在这里自动完成了加4的功能
                    end
            end
        else 
            begin
            end
    end
endmodule
