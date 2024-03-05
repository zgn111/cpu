`timescale 1ns / 1ps

`include"define.v"

module ex(
    input rst,
    // 译码阶段的输出
    input [`AluSelBus] alusel_i,                    //运算类型
    input [`AluOpBus] aluop_i,                      //运算操作
    input [`RegBus] reg1_i,                         //寄存器1的值
    input [`RegBus] reg2_i,                         //寄存器2的值
    input wreg_i,                                   //是否写寄存器
    input [`RegAddrBus] waddr_i,                    //写寄存器地址
   
    //转移指令相关
    input is_in_delayslot_i,                         //当前处于执行阶段的指令是否延迟
    input [`InstAddrBus] link_address_i,             //处于执行阶段的指令要保存的返回地址   
    input [`InstBus] inst_i,                         //当前处于执行阶段的指令

    // 执行阶段的输出
    output reg wreg_o,                              //是否写寄存器
    output reg [`RegAddrBus] waddr_o,               //写寄存器地址
    output reg [`RegBus] wdata_o,                   //写寄存器数据


    //传输到mem阶段进行处理，为加载存储指令做准备
    output [`RegBus] reg2_o,                        //寄存器2的值
    output [`AluOpBus] aluop_o,                     //运算操作
    output [`RegBus] mem_addr_o                    //加载存储指令的地址
    );



//    保存的数据
    reg[`RegBus] logicout;                          //逻辑运算的结果
    reg[`RegBus] arithout;                          //简单算术运算的结果

    wire ov_sum;                                    //溢出
    wire reg1_eq_reg2;                              //相等
    wire reg1_lt_reg2;                              //1小于2
    wire [`RegBus] reg2_i_mux;                      //reg2的补码
    wire [`RegBus] reg1_i_not;                      //reg1的反码
    wire [`RegBus] result_sum;                      //加法的结果

    
    //对比id.v以及ex.v,可以发现：对于输出的数据，一般是在另一个块里面进行操作的
    //我觉得 alusel 存在的意义在于使不同之类的指令并行化，不然每次只有一个结果，那么输出一个结果就可以了，何必多此一举进行选择

    //逻辑运算
    always @(*)
    begin
        if(rst == `RstEna)
            begin
                logicout <= `ZeroWord;
            end
        else 
            begin
                case(aluop_i)
                    `EXE_AND_OP:
                        begin
                            logicout <= reg1_i & reg2_i;
                        end
                    `EXE_OR_OP:
                        begin
                            logicout <= reg1_i | reg2_i;
                        end
                    `EXE_XOR_OP:
                        begin
                            logicout <= reg1_i ^ reg2_i;
                        end
                    `EXE_NOR_OP:
                        begin
                            logicout <= ~(reg1_i | reg2_i);
                        end
                    default:
                        logicout <= `ZeroWord;
                endcase
            end
    end

   
    //简单算术运算

    // 一、如果是减法运算，那么就是取反加一，否则就是原来的值
    assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) ||
                        (aluop_i == `EXE_SUBU_OP) ||
                        (aluop_i == `EXE_SLT_OP)) ?(~reg2_i+1):reg2_i;
    

    //二、运算结果
    assign result_sum = reg1_i + reg2_i_mux;


    //三、判断是否溢出
    // 1.两个正数相加，结果为负数
    // 2.两个负数相加，结果为正数
    assign ov_sum = (reg1_i[`RegWidth-1]==reg2_i[`RegWidth-1]&&result_sum[`RegWidth-1]!=reg1_i[`RegWidth-1])?1:0;


    //四、判断操作数1是否小于操作数2
    // (1).SLT指令：
    //      1.两个数符号相同，直接比较大小,result_sum<0,则reg1<reg2
    //      2.reg1<0,reg2>0,则reg1<reg2
    // (2).无符号比较指令，直接比较大小
    assign reg1_lt_reg2 = (aluop_i == `EXE_SLT_OP)?
    ((reg1_i[`RegWidth-1]&&!reg2_i[`RegWidth-1])||
    (!reg1_i[`RegWidth-1]&&!reg2_i[`RegWidth-1]&&result_sum[`RegWidth-1])||
    (reg1_i[`RegWidth-1]&&reg2_i[`RegWidth-1]&&result_sum[`RegWidth-1]))
    :(reg1_i<reg2_i);


    // 五、对操作数1取反
    assign reg1_i_not = ~reg1_i;


    // 给arithout赋值
    always @(*)
    begin
        if(rst == `RstEna)
            begin
                arithout <= `ZeroWord;
            end
        else 
            begin
                case(aluop_i)
                    //运算的结果都是存放到regfile里面的，所以用一个相同的输出就行了
                    
                    `EXE_ADD_OP,`EXE_ADDIU_OP:    
                        begin
                            arithout <= result_sum;
                        end
                    //减法运算
                    `EXE_SUB_OP,`EXE_SUBU_OP:  
                        begin
                            arithout <= result_sum;
                        end
                    //比较运算
                    `EXE_SLT_OP,`EXE_SLTU_OP:  
                        begin
                            arithout <= reg1_lt_reg2;
                        end
                default:
                        begin
                            arithout <= `ZeroWord;
                        end
                endcase
            end
    end

    

    //加载存储指令，在这里没有对写入regfile相关的进行处理，留到mem阶段进行处理了
    assign reg2_o = reg2_i;
    assign aluop_o = aluop_i;
    assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};   //base + 符号扩展后的offset






    //根据 alusel 选择输出结果,写入regfile
    always @(*)
    begin
        waddr_o <= waddr_i;     //写入的寄存器地址

        if(((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_SUB_OP))&&(ov_sum == `True_v))//add或者sub指令溢出
            begin
                wreg_o <= `WriteDisa;//不写入
            end
        else 
            begin
                wreg_o <= wreg_i;//允许写入
            end
            // 选择输出结果
        case (alusel_i)
            `EXE_RES_LOGIC:
                begin
                    wdata_o <= logicout;                            //逻辑运算的结果
                end
            `EXE_RES_ARITH:
                begin
                    wdata_o <= arithout;                            //简单算术运算的结果
                end
            `EXE_RES_JUMP_BRANCH:
                begin
                    wdata_o <= link_address_i;                      //转移指令的返回地址
                end
            default: 
                begin
                    wdata_o <= `ZeroWord;                           //默认为0
                end
        endcase
    end

endmodule
