`timescale 1ns / 1ps

`include"define.v"

module data_ram(
    input clk,
    input ce,                                       //用于控制是否可读
    input [`DataBus] data_i,                        //要写入的数据
    input [`DataAddrBus] addr,                      //要访问的地址
    input we,                                       //用于控制操作方式（加载或存储）
    output reg [`DataBus] data_o                    //读出的数据
    );



    // 定义一个32位存储器，只需要支持sw，lw指令
    reg [`DataBus] data_mem [0:`DataMemNum-1];        //存储器


//**********写操作****************将输入的数据写入到data_mem中
    always @(posedge clk)
    begin
        if(ce == `ChipDisa)
            begin
                data_o <= `ZeroWord;    
            end
        else if(we == `IsWrite)
            begin    
                
                data_mem[addr[`DataMemNumLog2-1:0]] <= data_i;
            
            end
    end

//*********读操作*****************将data_mem中的数据输出到mem中
    always @(*)
    begin
        if(ce == `ChipDisa)
            begin
                data_o <= `ZeroWord;
            end
        else if(we == `IsRead) 
            begin    
                data_o <= data_mem[addr[`DataMemNumLog2-1:0]];
            end
        else 
            begin
                data_o <= `ZeroWord;
            end
    end
endmodule
