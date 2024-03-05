`timescale 1ns / 1ps

`include"define.v"


module min_sopc(
    input clk,
    input rst);

    //指令存储器的输出，cpu的输入
    wire [`InstBus] inst;
    wire [`InstAddrBus] rom_addr_o;
    wire rom_ce_o;
    //用于ram
    wire [`DataAddrBus] ram_addr_o;
    wire ram_ce_o;
    wire [`DataBus] ram_data_i;
    wire [`DataBus] ram_data_o;
    wire ram_we_o;

    //inst_rom的实例化
    inst_rom inst_rom0(
        .ce(rom_ce_o),
        .addr(rom_addr_o),
        .inst(inst)
    );

    //cpu的实例化
    cpu cpu0(
        .clk(clk),
        .rst(rst),
        //与inst_rom之间
        .rom_data_i(inst),
        .rom_ce_o(rom_ce_o),
        .rom_addr_o(rom_addr_o),
        //与data_ram之间
        .ram_data_i(ram_data_i),
        .ram_data_o(ram_data_o),
        .ram_addr_o(ram_addr_o),
        .ram_we_o(ram_we_o),
        .ram_ce_o(ram_ce_o)
    );

    //data_ram的实例化
    data_ram data_ram0(
        .clk(clk),
        .ce(ram_ce_o),
        .data_i(ram_data_o),
        .addr(ram_addr_o),
        .we(ram_we_o),
        .data_o(ram_data_i)
    );
endmodule
