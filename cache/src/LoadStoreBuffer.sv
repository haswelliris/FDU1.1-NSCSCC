`include "defs.svh"
`include "sramx.svh"

module LoadStoreBuffer #(
`ifdef IN_SIMULATION
    parameter int BUFFER_LENGTH = 4,
`else
    parameter int BUFFER_LENGTH = 16,
`endif

    localparam int INDEX_BITS = $clog2(BUFFER_LENGTH),

    localparam type record_t = struct packed {
        logic avail;
    },

    localparam type req_t   = sramx_req_t,
    localparam type index_t = logic    [INDEX_BITS    - 1:0],
    localparam type meta_t  = record_t [BUFFER_LENGTH - 1:0],
    localparam type fifo_t  = req_t    [BUFFER_LENGTH - 1:0]
) (
    input logic clk, resetn,

    input  sramx_req_t  m_req,
    output sramx_resp_t m_resp,
    output sramx_req_t  s_req,
    input  sramx_resp_t s_resp
);
    /**
     * states & storages
     */
    index_t head, tail;
    meta_t  meta;
    fifo_t  fifo;

    /**
     * FIFO signals
     */
    req_t tail_elem;
    logic fifo_avail;
    logic fifo_empty;
    logic fifo_push;
    logic fifo_pop;

    assign tail_elem  = fifo[tail];
    assign fifo_avail = meta[head].avail;
    assign fifo_empty = ~meta[tail].avail;
    assign fifo_push  = fifo_avail && m_req.req && !(fifo_empty && s_resp.data_ok);
    assign fifo_pop   = /*!fifo_empty &&*/ s_resp.data_ok;

    /**
     * state updates
     */
    always_ff @(posedge clk)
    if (resetn) begin
        for (int i = 0; i < BUFFER_LENGTH; i++) begin
            /*unique*/ if (fifo_push && head == index_t'(i))
                meta[i].avail <= 0;
            else if (fifo_pop && tail == index_t'(i))
                meta[i].avail <= 1;
            else
                meta[i].avail <= meta[i].avail;
        end

        for (int i = 0; i < BUFFER_LENGTH; i++) begin
            /*unique*/ if (fifo_push && head == index_t'(i))
                fifo[i] <= m_req;
            else if (tail == index_t'(i) && s_resp.addr_ok) begin
                fifo[i]     <= fifo[i];
                fifo[i].req <= 0;
            end else
                fifo[i] <= fifo[i];
        end

        if (fifo_push)
            head <= index_t'(head + 1);
        if (fifo_pop)
            tail <= index_t'(tail + 1);
    end else begin
        {head, tail} <= 0;
        meta <= '1;  // fill all ones
    end

    /**
     * driver for master
     */
    assign m_resp.rdata = s_resp.rdata;

    always_comb begin
        if (fifo_empty) begin
            s_req = m_req;

            m_resp.addr_ok = 1;
            m_resp.data_ok = m_req.wr || s_resp.data_ok;
        end else begin
            s_req = tail_elem;

            m_resp.addr_ok = fifo_push;
            m_resp.data_ok = !tail_elem.wr && s_resp.data_ok;
        end
    end
endmodule