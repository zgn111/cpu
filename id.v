`timescale 1ns / 1ps
`include"define.v"

module id(
    input rst,
    input [`InstAddrBus] pc_i,              //从pc传输来的指令地址
    input [`InstBus] inst_i,                //从指令存储器中读取的指令

    //读取的Regfile的值
    input [`RegBus] reg1_data_i,            //从regfile获取第一个读输入
    input [`RegBus] reg2_data_i,            //从regfile获取的第二个读输入


    //来自ex阶段的旁路数据，当相邻指令发生数据冲突时
    input [`RegBus] ex_wdata_i,
    input [`RegAddrBus] ex_waddr_i,
    input ex_wreg_i,


    input [`AluOpBus] ex_aluop_i,                                       //alu控制信号

    //来自mem阶段的旁路数据，当间隔一条指令发生数据发生数据冲突时
    input [`RegBus] mem_wdata_i,
    input [`RegAddrBus] mem_waddr_i,
    input mem_wreg_i,

    //来自id_ex的输入，判断指令是否为延迟指令
    input is_in_delayslot_i,                                            //取id_ex绕了一个周期后返回，用来判断是否为延迟指令

    //输出到regfile的信息
    output reg reg1_read_o,                                             //第一个读使能信号
    output reg reg2_read_o,                                             //第二个读使能信号
    output reg [`RegAddrBus] reg1_addr_o,                               //第一个读地址
    output reg [`RegAddrBus] reg2_addr_o,                               //第二个读地址

    //送到执行阶段的信息
    output reg wreg_o,                                                  //写使能信号
    output reg [`RegAddrBus] waddr_o,                                   //写入寄存器地址(目的寄存器rd)
    output reg [`RegBus] reg1_o,                                        //译码阶段的源操作数1
    output reg [`RegBus] reg2_o,                                        //源操作数2
    output reg [`AluOpBus] aluop_o,                                     //alu控制信号
    output reg [`AluSelBus] alusel_o,                                   //运算类型

    //用于判断是否为延迟指令，j指令和beq指令
    output reg is_in_delayslot_o,                                       //当前指令是否为延迟槽中的指令
    output reg [`InstAddrBus] link_addr_o,                              //转移指令要保存的返回地址
    output [`InstBus] inst_o,                                           //指令,用于加载存储指令的判断
    output reg stallreq,                                                //暂停信号

    //送回pc的数据
    output reg branch_flag_o,                                            //是否转移
    output reg [`InstAddrBus] branch_target_address_o,                   //转移目标地址

    output reg next_inst_in_delayslot_o                                  //取id_ex绕了一个周期后返回，用来判断是否为延迟指令
    );

    //对inst_o进行赋值
    assign inst_o = inst_i;


    //op字段,op3为func字段，op2为shamt字段
    wire[5:0] op = inst_i[31:26];
    wire[4:0] op2 = inst_i[10:6];
    wire[5:0] op3 = inst_i[5:0];
    




    //立即数，等待后面扩展为32位之后再赋值
    reg [`RegBus] imm;
    wire [`RegBus] pc_plus_4;       //用来暂时存储下一条指令的地址，pc_i + 4;
    wire [`RegBus] pc_plus_8;       //用来存储返回地址

    //指示指令是否有效，没考虑到这个，实际上暂时没用到，后面异常处理可能会用上
    reg instvalid;


    //判断上一条指令是否为load指令以及判断是否需要阻塞
    reg stallreq_for_reg1;
    reg stallreq_for_reg2;
    wire inst_is_load;

    assign pc_plus_4 = (pc_i + 4);//保存下一条指令的地址
    assign pc_plus_8 = (pc_i + 8);//保存当前译码阶段指令后面第2条指令的地址
   
    //判断是否为lw指令
    assign inst_is_load = (ex_aluop_i == `EXE_LW_OP )?1'b1:1'b0;




/**********************一、对指令进行译码*****************************/

    always @(*)
    begin
        if(rst == `RstEna)//复位有效
            begin
                reg1_read_o <= `ReadDisa;
                reg2_read_o <= `ReadDisa;
                reg1_addr_o <= `RegNumLog2'b0;
                reg2_addr_o <= `RegNumLog2'b0;
                wreg_o <= `WriteDisa;
                waddr_o <= `NOPRegAddr;        //宏定义：默认地址为空时
                aluop_o <= `EXE_NOP_OP;
                alusel_o <= `EXE_RES_NOP;
                imm <= 32'h0;
                instvalid <= `InstValid;
                branch_flag_o <= 1'b0;
                link_addr_o <= `ZeroWord;
                next_inst_in_delayslot_o <= 1'b0;
                branch_target_address_o <= `ZeroWord;
            end
        else 
            begin
                aluop_o <= `EXE_NOP_OP;         //先初始化为气泡
                alusel_o <= `EXE_RES_NOP;       
                waddr_o <= inst_i[15:11];       //默认为rd寄存器
                wreg_o <= `WriteDisa;
                instvalid <= `InstInvalid;
                reg1_read_o <= `ReadDisa;
                reg2_read_o <= `ReadDisa;
                reg1_addr_o <= inst_i[25:21];   //rs寄存器
                reg2_addr_o <= inst_i[20:16];   //rt寄存器
                imm <= `ZeroWord;               //立即数初始化为0
                branch_flag_o <= 1'b0;          //默认不转移
                link_addr_o <= `ZeroWord;       //默认返回地址为0
                next_inst_in_delayslot_o <= 1'b0;   //默认不是延迟槽指令
                branch_target_address_o <= `ZeroWord;//默认转移地址为0

                // 根据不同的指令类型进行译码
                // I型指令，直接比较op字段 ori addi lw sw beq
                case(op)
                    `EXE_ORI: 
                    // ORI 操作 rs | imm -> rt
                        begin
                            aluop_o <= `EXE_OR_OP;          //或操作
                            alusel_o <= `EXE_RES_LOGIC;     //逻辑运算
                            reg1_read_o <= `ReadEna;        //ori操作只需要rs
                            reg2_read_o <= `ReadDisa;       //rt寄存器不需要读取
                            imm <= {16'b0,inst_i[15:0]};    //立即数
                            wreg_o <= `WriteEna;            //允许写
                            waddr_o <= inst_i[20:16];       //rt寄存器
                            instvalid <= `InstValid;        //指令有效
                        end
                    `EXE_ADDIU:
                    // ADDIU 操作 rs + imm -> rt
                        begin
                            aluop_o <= `EXE_ADDIU_OP;          //加法操作
                            alusel_o <= `EXE_RES_ARITH;      //算术运算
                            reg1_read_o <= `ReadEna;         //addi操作只需要rs
                            reg2_read_o <= `ReadDisa;       //rt寄存器不需要读取
                            imm <= {{16{inst_i[15]}},inst_i[15:0]};    //立即数
                            wreg_o <= `WriteEna;            //允许写
                            waddr_o <= inst_i[20:16];       //rt寄存器
                            instvalid <= `InstValid;        //指令有效
                        end
                    `EXE_LW:
                    // LW 操作 rs + imm -> rt
                        begin
                            aluop_o <= `EXE_LW_OP;              //加载操作
                            alusel_o <= `EXE_RES_LOAD_STORE;    //加载存储
                            reg1_read_o <= `ReadEna;            //lw操作需要rs
                            reg2_read_o <= `ReadDisa;           //rt寄存器不需要读取
                            wreg_o <= `WriteEna;                //允许写
                            waddr_o <= inst_i[20:16];           //rt寄存器
                            instvalid <= `InstValid;            //指令有效
                        end
                    `EXE_SW:
                    // SW 操作 rs + imm -> rt
                        begin
                            aluop_o <= `EXE_SW_OP;              //存储操作
                            alusel_o <= `EXE_RES_LOAD_STORE;    //加载存储
                            reg1_read_o <= `ReadEna;            //sw操作需要rs
                            reg2_read_o <= `ReadEna;            //sw操作需要rt
                            wreg_o <= `WriteDisa;               //禁止写
                            instvalid <= `InstValid;            //指令有效
                        end
                    `EXE_BEQ:
                    // BEQ 操作 rs - rt -> imm
                        begin
                            aluop_o <= `EXE_BEQ_OP;              //比较操作
                            alusel_o <= `EXE_RES_JUMP_BRANCH;    //跳转分支
                            reg1_read_o <= `ReadEna;            //beq操作需要rs
                            reg2_read_o <= `ReadEna;            //beq操作需要rt
                            wreg_o <= `WriteDisa;               //禁止写
                            instvalid <= `InstValid;            //指令有效
                            if(reg1_o == reg2_o)
                                begin//相等时转移
                                    branch_flag_o <= 1'b1;          //转移标志
                                    next_inst_in_delayslot_o <= `InDelaySlot;   //下一条指令是延迟槽指令
                                    branch_target_address_o <=pc_plus_4+{{14{inst_i[15]}},inst_i[15:0],2'b00};    //左移两位后符号扩展为32位，再与延迟槽指令地址相加
                                end
                        end
                    `EXE_J:
                    // J 操作 target -> pc
                        begin
                            aluop_o <= `EXE_J_OP;               //跳转操作
                            alusel_o <= `EXE_RES_JUMP_BRANCH;   //跳转分支
                            reg1_read_o <= `ReadDisa;           //不需要读取
                            reg2_read_o <= `ReadDisa;           //不需要读取
                            wreg_o <= `WriteDisa;               //禁止写
                            instvalid <= `InstValid;            //指令有效
                            branch_flag_o <= 1'b1;              //转移标志
                            next_inst_in_delayslot_o <= `InDelaySlot;       //下一条指令是延迟槽指令
                            branch_target_address_o <= {pc_plus_4[31:28],inst_i[25:0],2'b00};//左移两位后与延迟槽指令地址相加
                        end
                    // R型指令,比较func字段
                    `EXE_SPECIAL_INST:
                        begin
                            case(op2)
                                5'b00000:
                                    begin
                                        case(op3)
                                        `EXE_ADD:
                                        // ADD 操作 rs + rt -> rd
                                            begin
                                                aluop_o <= `EXE_ADD_OP;          //加法操作
                                                alusel_o <= `EXE_RES_ARITH;      //算术运算
                                                reg1_read_o <= `ReadEna;         //add操作需要rs
                                                reg2_read_o <= `ReadEna;         //add操作需要rt
                                                wreg_o <= `WriteEna;             //允许写
                                                instvalid <= `InstValid;          //指令有效
                                            end 
                                        `EXE_SUB:
                                        // SUB 操作 rs - rt -> rd
                                            begin
                                                aluop_o <= `EXE_SUB_OP;          //减法操作
                                                alusel_o <= `EXE_RES_ARITH;      //算术运算
                                                reg1_read_o <= `ReadEna;         //sub操作需要rs
                                                reg2_read_o <= `ReadEna;         //sub操作需要rt
                                                wreg_o <= `WriteEna;             //允许写
                                                instvalid <= `InstValid;          //指令有效
                                            end
                                        `EXE_SUBU:
                                        // SUBU 操作 rs - rt -> rd
                                            begin
                                                aluop_o <= `EXE_SUBU_OP;         //减法操作
                                                alusel_o <= `EXE_RES_ARITH;      //算术运算
                                                reg1_read_o <= `ReadEna;         //subu操作需要rs
                                                reg2_read_o <= `ReadEna;         //subu操作需要rt
                                                wreg_o <= `WriteEna;             //允许写
                                                instvalid <= `InstValid;          //指令有效
                                            end
                                        `EXE_SLT:
                                        // SLT 操作 rs < rt -> rd
                                            begin
                                                aluop_o <= `EXE_SLT_OP;          //比较操作
                                                alusel_o <= `EXE_RES_ARITH;      //算术运算
                                                reg1_read_o <= `ReadEna;         //slt操作需要rs
                                                reg2_read_o <= `ReadEna;         //slt操作需要rt
                                                wreg_o <= `WriteEna;             //允许写
                                                instvalid <= `InstValid;          //指令有效
                                            end
                                        `EXE_SLTU:
                                        // SLTU 操作 rs < rt -> rd
                                            begin
                                                aluop_o <= `EXE_SLTU_OP;         //比较操作
                                                alusel_o <= `EXE_RES_ARITH;      //算术运算
                                                reg1_read_o <= `ReadEna;         //sltu操作需要rs
                                                reg2_read_o <= `ReadEna;         //sltu操作需要rt
                                                wreg_o <= `WriteEna;             //允许写
                                                instvalid <= `InstValid;          //指令有效
                                            end
                                            default: 
                                                ;
                                        endcase
                                    end
                                default: 
                                        ;
                            endcase
                        end
                    default: 
                            ;
                endcase
            end
    end

                               
        
                    
/**********************二、读取源操作数1*****************************/

    always @(*)
    begin
        if(rst == `RstEna)//复位有效
            begin
                reg1_o <= `ZeroWord;
            end
        else if(reg1_read_o == `ReadEna)//允许读
            begin
            //当读地址与写地址相同，并且写使能为真时，说明发生了数据相关，这是需要旁路
                if((reg1_addr_o==ex_waddr_i)&&(ex_wreg_i==`WriteEna))//ex阶段的旁路
                    begin
                        reg1_o <= ex_wdata_i;
                    end
                else if((reg1_addr_o==mem_waddr_i)&&(mem_wreg_i==`WriteEna))//mem阶段的旁路
                    begin
                        reg1_o <= mem_wdata_i;
                    end
            //当没有发生旁路时，则从regfile中读取数据
                else 
                    begin
                        reg1_o <= reg1_data_i;  //regfile 读端口1的值
                    end
            end
        else if(reg1_read_o == `ReadDisa)//禁止读
            begin
                reg1_o <= imm;         //立即数
            end
        else 
            begin
                reg1_o <= `ZeroWord;
            end
    end

/**********************三、读取源操作数2*****************************/

    always @(*)
    begin
        if(rst == `RstEna)//复位有效
            begin
                reg2_o <= `ZeroWord;
            end
        else if(reg2_read_o == `ReadEna)//允许读
            begin
            //当读地址与写地址相同，并且写使能为真时，说明发生了数据相关，这时需要旁路
                if((reg2_addr_o==ex_waddr_i)&&(ex_wreg_i==`WriteEna))//ex阶段的旁路
                    begin
                        reg2_o <= ex_wdata_i;
                    end
                else if((reg2_addr_o==mem_waddr_i)&&(mem_wreg_i==`WriteEna))//mem阶段的旁路
                    begin
                        reg2_o <= mem_wdata_i;
                    end
            //当没有发生旁路时，则从regfile中读取数据
                else 
                    begin
                        reg2_o <= reg2_data_i;  //regfile 读端口2的值
                    end
            end
        else if(reg2_read_o == `ReadDisa)//禁止读
            begin
                reg2_o <= imm;//立即数
            end
        else 
            begin
                reg2_o <= `ZeroWord;
            end
    end

    //为is_in_delayslot_o进行赋值操作，放在外面是因为没必要因为这一个而执行某个always块中的所有部分
    always @(*) 
    begin
        if(rst == `RstEna)//复位有效
            begin
                is_in_delayslot_o <=`NotInDelaySlot;    //默认不是延迟槽指令
            end
        else 
            begin
                is_in_delayslot_o <= is_in_delayslot_i;//取id_ex绕了一个周期后返回，用来判断是否为延迟指令
            end
    end

    //处理加载存储指令与转移指令之间的数据冲突，主要是两者相邻时进行阻塞操作，对reg1进行判断
    always @(*)
    begin
        stallreq_for_reg1 <= `NoStop;//默认不阻塞
        if(rst == `RstEna)//复位有效
            begin
                stallreq_for_reg1 <= `NoStop;//默认不阻塞
            end
        else 
            begin
                if(inst_is_load == 1'b1 && reg1_read_o == `ReadEna && reg1_addr_o == ex_waddr_i)//当是load指令并且需要读取rs寄存器时
                    begin
                        stallreq_for_reg1 <= `Stop;//阻塞
                    end
            end
    end



    //对reg2进行判断，不放在一起是因为这两个是并行的操作
    always @(*)
    begin
        stallreq_for_reg2 <= `NoStop;
        if(rst == `RstEna)
            begin
                stallreq_for_reg2 <= `NoStop;
            end
        else 
            begin
                if(inst_is_load == 1'b1 && reg2_read_o == `ReadEna && reg2_addr_o == ex_waddr_i)
                    begin
                        stallreq_for_reg2 <= `Stop;
                    end
            end
    end



    //对阻塞进行赋值
    always @(*)
    begin
        if(rst == `RstEna)
            begin
                stallreq <= `NoStop;
            end
        else 
            begin
                stallreq <= stallreq_for_reg1 | stallreq_for_reg2;//只要有一个需要阻塞，就阻塞
            end
    end
endmodule
