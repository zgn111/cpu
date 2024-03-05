//*********** 全局的宏定义 **********************
`define RstEna      1'b1                //复位信号有效
`define RstDisa     1'b0                //复位信号无效
`define ZeroWord    32'h00000000        //32位的数值0
`define WriteEna    1'b1                //使能写
`define WriteDisa   1'b0                //禁止写
`define ReadEna     1'b1                //使能读
`define ReadDisa    1'b0                //禁止读
`define AluOpBus    7:0                 //译码阶段的输出 aluop_o的宽度
`define AluSelBus   2:0                 //译码阶段的输出 alusel_o的宽度
`define InstValid   1'b1                //指令有效
`define InstInvalid 1'b0                //指令无效
`define True_v      1'b1                //逻辑“真”
`define False_v     1'b0                //逻辑“假”
`define ChipEna     1'b1                //芯片使能
`define ChipDisa    1'b0                //芯片禁止
`define Stop        1'b1                //流水暂停
`define NoStop      1'b0                //流水继续
`define InDelaySlot 1'b1                //延迟槽
`define NotInDelaySlot 1'b0             //非延迟槽


//*********** 与具体指令有关的宏定义 **********************

// R型指令 格式：op rs rt rd shamt funct
// I型指令 格式：op rs rt imm
// J型指令 格式：op target

// R型指令 add sub subu slt sltu
// I型指令 addiu ori lw  sw beq
// J型指令 j  

// R型指令的func字段 instruction[5:0]

`define EXE_ADD             6'b100000           //add的功能码
`define EXE_SUB             6'b100010           //sub的功能码
`define EXE_SUBU            6'b100011           //subu的功能码
`define EXE_SLT             6'b101010           //slt的功能码
`define EXE_SLTU            6'b101011           //sltu的功能码


// I型指令的op字段 instruction[31:26]

`define EXE_ADDIU           6'b001001           //addiu的指令码
`define EXE_ORI             6'b001101           //ori的指令码
`define EXE_LW              6'b100011           //lw的指令码
`define EXE_SW              6'b101011           //sw的指令码
`define EXE_BEQ             6'b000100           //beq的指令码

// J型指令的op字段 instruction[31:26]
`define EXE_J               6'b000010           //j的指令码

`define EXE_NOP             6'b000000           //nop的指令码
`define EXE_SPECIAL_INST    6'b000000           //SPECIAL类的指令码,用于在op为0的时候


///////////////////////////////////////////////////////////////////////////////////////////

// aluop
// 定义aluop的宏,本次实验只实现11条指令 即add sub subu slt sltu addiu ori lw sw beq j
// 
`define EXE_AND_OP      8'b00000001     //AND控制信号
`define EXE_OR_OP       8'b00000010     //这个是在ALU单元运用的，每一个指令有不同的ALUop，单独进行设置的，书上的控制信号是两位的，也就是只有两种情况
`define EXE_XOR_OP      8'b00000011     //XOR
`define EXE_NOR_OP      8'b00000100     //NOR


`define EXE_ADD_OP      8'b00000101     //这类运算指令都是对rs以及rt进行计算，结果存入rd中
`define EXE_SUB_OP      8'b00000110
`define EXE_SUBU_OP     8'b00000111
`define EXE_SLT_OP      8'b00001000
`define EXE_SLTU_OP     8'b00001001

    //转移分支指令
`define EXE_J_OP        8'b00001010     //j target;
`define EXE_BEQ_OP      8'b00001011     //beq rs,rt,offset; 相等则转移

    //加载存储指令
`define EXE_LW_OP       8'b00001100     //读取一个字
`define EXE_SW_OP       8'b00001101     //直接将rt放进去就行了
`define EXE_ADDIU_OP    8'b00001110     //addiu rt,rs,immediate; 无符号扩展的立即数加法
`define EXE_NOP_OP      8'b00000000     //这个就是流水线中的气泡



//AluSel: 用来选择ALU的操作
`define EXE_RES_LOGIC       3'b001      //逻辑运算
`define EXE_RES_ARITH       3'b100      //算术运算
`define EXE_RES_JUMP_BRANCH 3'b110      //跳转分支
`define EXE_RES_LOAD_STORE  3'b111      //加载存储
`define EXE_RES_NOP         3'b000      //空指令





//*********** 与指令存储器ROM有关的宏定义 **********************
`define InstAddrBus     31:0        //ROM的地址总线宽度
`define InstBus         31:0        //ROM的数据总线宽度
`define InstMemNum      1024      //ROM的实际大小1KB
`define InstMemNumLog2  10          //ROM实际使用的地址线宽度

//*********** 与通用寄存器Regfile有关的宏定义 **********************
`define RegAddrBus      4:0         //Regfile模块的地址线宽度
`define RegBus          31:0        //Regfile模块的数据线宽度
`define RegWidth        32          //通用寄存器的宽度
`define DoubleRegBus    63:0        //两倍的通用寄存器的数据线宽度
`define DoubleRegWidth  64          //两倍的通用寄存器的宽度
`define RegNum          32          //通用寄存器的数量
`define RegNumLog2      5           //寻址通用寄存器使用的地址位数
`define NOPRegAddr      5'b00000



//************ 加载存储的宏定义 **********************************
`define IsWrite         1'b1
`define IsRead          1'b0
`define DataAddrBus     31:0        //地址总线宽度
`define DataBus         31:0        //数据总线宽度
`define DataMemNum       1024       //存储器的实际大小1KB     
`define DataMemNumLog2    10        //实际使用的地址线宽度
     

