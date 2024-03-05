`timescale 1ns / 1ps

`include"define.v"


module regfile(
    input clk,
    input rst,

    // 写端口
    input we,                       //写使能
    input [`RegAddrBus] waddr,      //写地址
    input [`RegBus] wdata,          //写数据

    // 读端口1
    input re1,                      //读使能
    input [`RegAddrBus] raddr1,     //读地址
    output reg [`RegBus] rdata1,    //读数据

    // 读端口2
    input re2,                      //读使能
    input [`RegAddrBus] raddr2,     //读地址
    output reg [`RegBus] rdata2     //读数据
    );


reg [`RegBus] regs[0:`RegNum-1];
//***********初始化寄存器********
integer i;
initial
begin
    for(i=0;i<`RegNum;i=i+1)
        regs[i]=`ZeroWord;
end



//******************写操作****************
// 写操作为时序逻辑电路，发生在时钟上升沿
    always @(posedge clk)
    begin
        if(rst==`RstDisa)
            begin
                if((we==`WriteEna)&&(waddr!=`RegNumLog2'h0))//写使能有效，且不是写0号寄存器，因为MIPS的0号寄存器是恒为0的
                begin
                    regs[waddr] <= wdata;
                end
            end
    end

//*****************读操作1****************
// 读操作为组合逻辑电路，根据读使能信号和读地址信号来决定读数据
    always @(*) 
    begin          
        if(rst==`RstEna)//复位时，读数据为0
            begin   
                rdata1<=`ZeroWord;
            end
        else if(raddr1== `RegNumLog2'h0)//读0号寄存器时，读数据为0
            begin
                rdata1<=`ZeroWord;
            end
        else if((raddr1==waddr)&&(we==`WriteEna)&&(re1==`ReadEna))//当同时发生读写时，直接将写的值传送给读.
            begin
                rdata1<=wdata;//当同时发生读写时，直接将写的值传送给读,因为是异步的，所以可能发生冲突
            end
        else if(re1==`ReadEna)//正常读操作
            begin
                rdata1 <= regs[raddr1];
            end
        else //其他情况，读数据为0
            begin
                rdata1 <= `ZeroWord;
            end
    end

//******************读操作2****************

    always @(*) 
    begin
        if(rst==`RstEna)
            begin
                rdata2<=`ZeroWord;
            end
        else if(raddr2== `RegNumLog2'h0)
            begin
                rdata2<=`ZeroWord;
            end
        else if((raddr2==waddr)&&(we==`WriteEna)&&(re2==`ReadEna))
            begin
                rdata2<=wdata;
            end
        else if(re2==`ReadEna)
            begin
                rdata2 <= regs[raddr2];
            end
        else 
            begin
                rdata2 <= `ZeroWord;
            end
    end
endmodule
