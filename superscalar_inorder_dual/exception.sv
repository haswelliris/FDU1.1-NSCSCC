`include "mips.svh"

module exception(
        input logic reset,
        input logic [5: 0] ext_int,
        input exception_pipeline_t pipe,
        //input interrupt_info_t interrupt_info,
        //to pipeline commit
        output logic exception_valid,
        output word_t pcexception,
        //fetch control
        output exception_t exception,
        input cp0_status_t cp0_status
        //cp0
        //input cp0_status_t cp0_status,
        //input cp0_cause_t cp0_cause
        //exception
    );

    // input logic reset,
    exc_code_t exc_code;
    word_t vaddr;
    logic in_delay_slot;
    word_t pc;
    exception_info_t exc_info;
    // interrupt
    interrupt_info_t interrupt_info;
    assign interrupt_info = pipe.interrupt_info;
    logic interrupt_valid;
    assign interrupt_valid = (interrupt_info != 0) // request
                           & (cp0_status.IE)
                        //    & (~cp0.debug.DM)
                           & (~cp0_status.EXL)
                           & (~cp0_status.ERL);
    always_comb begin
        priority case (1'b1)
            interrupt_valid : exc_code = `CODE_INT;
            exc_info.instr : exc_code = `CODE_ADEL;
            exc_info.instr_tlb : exc_code = `CODE_TLBL;
            exc_info.cpu: exc_code = `CODE_CPU;
            exc_info.ri: exc_code = `CODE_RI;
            exc_info.of: exc_code = `CODE_OF;
            exc_info.bp: exc_code = `CODE_BP;
            exc_info.sys: exc_code = `CODE_SYS;
            exc_info.tr: exc_code = `CODE_TR;
            exc_info.load: exc_code = `CODE_ADEL;
            exc_info.save: exc_code = `CODE_ADES;
            exc_info.load_tlb: exc_code = `CODE_TLBL;
            exc_info.save_tlb: exc_code = `CODE_TLBS;
            exc_info.mod: exc_code = `CODE_MOD;
            default: begin
                exc_code = '0;
            end
        endcase
    end
        assign exc_info = pipe.exc_info;

    assign exception_valid = ((|exc_info) | interrupt_valid) & reset;
    assign exception.location = `EXC_ENTRY;
    assign exception.valid = (exception_valid);
    assign exception.code = (interrupt_valid) ? (`CODE_INT) : (exc_code);
    assign exception.pc = pc;
    assign exception.in_delay_slot = in_delay_slot;
    assign exception.badvaddr = vaddr;

    // assign exception_instr = pipe.exception_instr;
    // assign exception_ri = pipe.exception_ri;
    // assign exception_of = pipe.exception_of;
    // assign exception_load =  pipe.exception_load;
    // assign exception_bp = pipe.exception_bp;
    // assign exception_sys = pipe.exception_sys;
    // assign exception_save = pipe.exception_save;
    assign vaddr = pipe.vaddr;
    assign pc = pipe.pc;
    assign in_delay_slot = pipe.in_delay_slot;
    
    assign pcexception = `EXC_ENTRY;
    
endmodule