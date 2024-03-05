`timescale 1ns / 1ps

`include"define.v"


module cpu(
    input clk,
    input rst,
    //rom输入的接口
    input [`InstBus] rom_data_i,        //存储器传输进来的指令
    //ram输入的接口
    input [`RegBus] ram_data_i,         

    // 输出到rom的接口
    output rom_ce_o,                    //通过控制pc，从而控制整个处理器
    output [`InstAddrBus] rom_addr_o,   //指令存储器的输入地址

    // 输出到ram的接口
    output [`RegBus] ram_addr_o,        //要访问的地址
    output [`RegBus] ram_data_o,        //加载存储的数据
    output ram_we_o,                    //控制加载或存储
    output ram_ce_o                    //控制是否能读
    );

    // 连接IF_ID模块和ID模块的变量

    //pc的输出以及if_id的输入
    wire [`InstAddrBus] pc;      //通向if_id
    //if_id的输出与id的输入
    wire [`InstAddrBus] id_pc_i;        //pc
    wire [`InstBus] id_inst_i;          //指令

    //id的输出与regfile的输入
    wire [`RegAddrBus] reg1_addr;       //第一个读取的寄存器地址
    wire reg1_read;                     //第一个读使能信号
    wire [`RegAddrBus] reg2_addr;       //第二个读取的寄存器地址
    wire reg2_read;                     //第二个读使能信号
    //转移
    wire branch_flag;
    wire [`InstAddrBus] branch_address;

    //regfile的输出与id的输入
    wire [`RegBus] reg1_data;           //第一个寄存器数据
    wire [`RegBus] reg2_data;           //第二个寄存器数据

    //id的输出与id_ex的输入
    wire [`AluOpBus] id_aluop_o;        //alu控制
    wire [`AluSelBus] id_alusel_o;      //alu运算类型
    wire [`RegBus] id_reg1_o;           //源操作数1
    wire [`RegBus] id_reg2_o;           //源操作数2
    wire [`RegAddrBus] id_waddr_o;      //写入的寄存器地址
    wire id_wreg_o;                     //写使能信号


    wire next_is_delay;             //下一条指令为延迟指令，最后返回id
    wire is_delay;                  //最后流向ex的延迟指令信号（感觉没啥用
    wire [`InstAddrBus] link_addr;   //流向ex的返回地址
    wire [`InstBus] inst_id;      //在ex用来获取地址

    //id_ex的输出与ex的输入
    wire [`AluOpBus] ex_aluop_i;      //alu控制
    wire [`AluSelBus] ex_alusel_i;    //alu运算类型
    wire [`RegBus] ex_reg1_i;         //源操作数1
    wire [`RegBus] ex_reg2_i;         //源操作数2
    wire [`RegAddrBus] reg_addr_ex; //写入的寄存器地址
    wire ex_wreg_i;                   //写使能信号
    wire is_delay_ex;
    wire [`InstAddrBus] link_addr_ex;
    wire [`InstBus] inst_ex;                   //指令

    //向id的输出
    wire is_delay_inst;             //告诉id，为延迟指令

    //ex的输出与ex_mem的输入
    wire [`RegBus] ex_wdata_o;        //写入的数据
    wire [`RegAddrBus] ex_waddr_o;    //写入的寄存器地址
    wire ex_wreg_o;               //写使能信号



    wire [`AluOpBus] aluop_ex_mem;  //指令类型
    wire [`RegBus] reg2_ex_mem;     //rt的数据
    wire [`RegBus] mem_addr_ex_mem; //控制ram的地址
   

    //ex_mem的输出与mem的输入
    wire [`RegBus] mem_wdata_i;        //写入的数据
    wire [`RegAddrBus] mem_waddr_i;    //写入的寄存器地址
    wire mem_wreg_i;                   //写使能信号


    wire [`AluOpBus] aluop_mem;     //指令类型
    wire [`RegBus] reg2_mem;        //rt的数据
    wire [`RegBus] mem_addr_mem;    //控制ram的地址

    //mem的输出与mem_wb的输入
    wire [`RegBus] mem_wdata_o;    //写入的数据
    wire [`RegAddrBus] mem_waddr_o;//写入的寄存器地址
    wire mem_wreg_o;               //写使能信号
   

    //mem_wb的输出与regfile的输入
    wire [`RegBus] wb_wdata_i;        //写入的数据
    wire [`RegAddrBus] wb_waddr_i;    //写入的寄存器地址
    wire wb_wreg_i;                   //写使能信号
    

    //ctrl的输入与输出，同时也是各个中间件的输入
    wire stallreq_from_id;
    wire [5:0] stall;


    //regfile的实例化
    regfile regfile0(
        .clk(clk),
        .rst(rst),
        .we(wb_wreg_i),
        .waddr(wb_waddr_i),
        .wdata(wb_wdata_i),
        .re1(reg1_read),
        .re2(reg2_read),
        .raddr1(reg1_addr),
        .raddr2(reg2_addr),

        .rdata1(reg1_data),
        .rdata2(reg2_data)
    );

    //pc的实例化
    pc_reg pc_reg0(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .branch_flag_i(branch_flag),
        .branch_target_address_i(branch_address),
        .pc(pc),
        .ce(rom_ce_o)
    );

    assign rom_addr_o = pc; //指令存储器的输入地址

    //if_id的实例化
    if_id if_id0(
        .clk(clk),
        .rst(rst),
        .if_pc(pc),
        .if_inst(rom_data_i), //指令存储器的值
        .stall(stall),
        .id_pc(id_pc_i),
        .id_inst(id_inst_i)
    );

    //id的实例化
    id id0(
        .rst(rst),
        .pc_i(id_pc_i),
        .inst_i(id_inst_i),
        // regfile的输入
        .reg1_data_i(reg1_data),
        .reg2_data_i(reg2_data),


        .ex_wdata_i(ex_wdata_o),
        .ex_waddr_i(ex_waddr_o),
        .ex_wreg_i(ex_wreg_o),

        .ex_aluop_i(aluop_ex_mem),  //从ex将aluop旁路回id
        .mem_wdata_i(mem_wdata_o),
        .mem_waddr_i(mem_waddr_o),
        .mem_wreg_i(mem_wreg_o),

        //id_ex的输入
        .is_in_delayslot_i(is_delay_inst),

        //向regfile输出
        .reg1_read_o(reg1_read),
        .reg2_read_o(reg2_read),
        .reg1_addr_o(reg1_addr),
        .reg2_addr_o(reg2_addr),
        //向pc_reg输出
        .branch_flag_o(branch_flag),
        .branch_target_address_o(branch_address),

        //向id_ex输出
        .wreg_o(id_wreg_o),
        .waddr_o(id_waddr_o),
        .reg1_o(id_reg1_o),
        .reg2_o(id_reg2_o),
        .aluop_o(id_aluop_o),
        .alusel_o(id_alusel_o),

        .stallreq(stallreq_from_id),
        .next_inst_in_delayslot_o(next_is_delay),
        .is_in_delayslot_o(is_delay),
        .link_addr_o(link_addr),
        .inst_o(inst_id)
    );

    //id_ex的实例化
    id_ex id_ex0(
        .clk(clk),
        .rst(rst),
        //从id接收的输入
        .id_alusel(id_alusel_o),
        .id_aluop(id_aluop_o),
        .id_wreg(id_wreg_o),
        .id_waddr(id_waddr_o),
        .id_reg1(id_reg1_o),
        .id_reg2(id_reg2_o),


        .stall(stall),
        .next_inst_in_delayslot_i(next_is_delay),
        .id_is_in_delayslot(is_delay),
        .id_link_address(link_addr),
        .id_inst(inst_id),

        // 向ex的输出
        .ex_alusel(ex_alusel_i),
        .ex_aluop(ex_aluop_i),
        .ex_wreg(ex_wreg_i),
        .ex_waddr(reg_addr_ex),
        .ex_reg1(ex_reg1_i),
        .ex_reg2(ex_reg2_i),

    
        .ex_is_in_delayslot(is_delay_ex),
        .ex_link_address(link_addr_ex),
        .ex_inst(inst_ex),
        //向id的输出
        .is_in_delayslot_o(is_delay_inst)
    );

    //ex的实例化
    ex ex0(
        .rst(rst),
        // 译码阶段的输出
        .alusel_i(ex_alusel_i),
        .aluop_i(ex_aluop_i),
        .reg1_i(ex_reg1_i),
        .reg2_i(ex_reg2_i),
        .wreg_i(ex_wreg_i),
        .waddr_i(reg_addr_ex),

        //转移指令相关
        .is_in_delayslot_i(is_delay_ex),
        .link_address_i(link_addr_ex),
        .inst_i(inst_ex),
        
      
      
        // 执行阶段的输出
        .wreg_o(ex_wreg_o),
        .waddr_o(ex_waddr_o),
        .wdata_o(ex_wdata_o),
            
        //  传输到mem阶段进行处理，为加载存储指令做准备
        .reg2_o(reg2_ex_mem),
        .aluop_o(aluop_ex_mem),
        .mem_addr_o(mem_addr_ex_mem)
    );

    //ex_mem的实例化
    ex_mem ex_me0(
        .clk(clk),
        .rst(rst),
        // 从ex接收的输入
        .ex_waddr(ex_waddr_o),
        .ex_wdata(ex_wdata_o),
        .ex_wreg(ex_wreg_o),
        // 暂停信号
        .stall(stall),
        
        // 来自ex的输入
        .ex_aluop(aluop_ex_mem),
        .ex_mem_addr(mem_addr_ex_mem),
        .ex_reg2(reg2_ex_mem),
        
        // 送到mem的接口
        .mem_waddr(mem_waddr_i),
        .mem_wdata(mem_wdata_i),
        .mem_wreg(mem_wreg_i),
      
        // 输出到mem的接口
        .mem_aluop(aluop_mem),
        .mem_mem_addr(mem_addr_mem),
        .mem_reg2(reg2_mem)
    );

    //mem的实例化
    mem mem0(
        .rst(rst),
        // 执行阶段的输出
        .wreg_i(mem_wreg_i),
        .waddr_i(mem_waddr_i),
        .wdata_i(mem_wdata_i),
        
        .aluop_i(aluop_mem),
        .mem_addr_i(mem_addr_mem),
        .reg2_i(reg2_mem),
        // 来自ram的输入
        .mem_data_i(ram_data_i),

        // 访存阶段的输出
        .wreg_o(mem_wreg_o),
        .waddr_o(mem_waddr_o),
        .wdata_o(mem_wdata_o),
        
        // 送到ram的接口
        .mem_data_o(ram_data_o),
        .mem_addr_o(ram_addr_o),
        .mem_we_o(ram_we_o),
        .mem_ce_o(ram_ce_o)
    );

    //mem_wb的实例化
    mem_wb mem_wb0(
        .clk(clk),
        .rst(rst),
        // 访存阶段的输出
        .mem_reg(mem_wreg_o),
        .mem_waddr(mem_waddr_o),
        .mem_wdata(mem_wdata_o),
        
        // 暂停信号
        .stall(stall),
        
        // 送到回写阶段
        .wb_reg(wb_wreg_i),
        .wb_waddr(wb_waddr_i),
        .wb_wdata(wb_wdata_i)       
    );

    //ctrl的实例化
    ctrl ctrl0(
        .rst(rst),
        .stallreq_from_id(stallreq_from_id),
        .stall(stall)
    );

    
endmodule
