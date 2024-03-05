`timescale 1ns / 1ps

`include"define.v"

module mem(
    input rst,
    // 执行阶段的输出
    input wreg_i,                       //是否写寄存器
    input [`RegAddrBus] waddr_i,        //写寄存器地址
    input [`RegBus] wdata_i,            //写寄存器数据


    input [`AluOpBus] aluop_i,           //运算操作   
    input [`RegBus] mem_addr_i,         //存储器地址
    input [`RegBus] reg2_i,             //要存储的数据

    // 来自RAM的数据
    input [`RegBus] mem_data_i,         //从存储器读取的数据

    // 返回到id阶段的数据
    output reg wreg_o,                  //是否写寄存器
    output reg [`RegAddrBus] waddr_o,   //写寄存器地址
    output reg [`RegBus] wdata_o,       //写寄存器数据
    
    
    //输出到数据存储器的数据
    output reg [`RegBus] mem_data_o,    //写入存储器的数据
    output reg [`RegBus] mem_addr_o,    //存放的地址
    output reg mem_we_o,                //指定是加载还是存储操作
    output reg mem_ce_o                 //存储器使能信号
    );

    
    always @(*)
    begin
        if(rst == `RstEna)
            begin
                wreg_o <= `WriteDisa;           //默认不写
                waddr_o <= `NOPRegAddr;         //默认写0
                wdata_o <= `ZeroWord;           //默认写0
                mem_data_o <= `ZeroWord;        //默认写0
                mem_addr_o <= `ZeroWord;        //默认写0
                mem_we_o <= `IsRead;            //默认为读操作
                mem_ce_o <= `ChipDisa;          //默认不可操作
            end
        else 
        begin
            case(aluop_i)      
                `EXE_LW_OP: 
                    begin
                        mem_data_o <= `ZeroWord;    //默认写0
                        mem_addr_o <= mem_addr_i;   //存放的地址  
                        mem_we_o <= `IsRead;        //读操作
                        mem_ce_o <= `ChipEna;       //使能
                        wreg_o <= `WriteEna;        //写使能
                        wdata_o <= mem_data_i;      //写入的数据
                        waddr_o <= waddr_i;         //写入的地址
                    end
                `EXE_SW_OP: 
                    begin
                        wdata_o <= `ZeroWord;
                        wreg_o <= `WriteDisa;
                        mem_addr_o <= mem_addr_i;
                        mem_we_o <= `IsWrite;
                        mem_ce_o <= `ChipEna;
                        mem_data_o <= reg2_i;
                    end
                default:    
                    begin  //当不是加载存储指令时
                        wreg_o <= wreg_i;       //是否写寄存器
                        waddr_o <= waddr_i;     //写寄存器地址
                        wdata_o <= wdata_i;     //写寄存器数据
                        mem_we_o <= `WriteDisa; //默认为读操作
                        mem_addr_o <= `ZeroWord; //默认写0
                        mem_ce_o <= 1'b0;       //默认不可操作
                    end
            endcase
        end
    end
endmodule
