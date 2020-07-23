//  Package: rat_pkg
//
package rat_pkg;
    import common::*;
    //  Group: Parameters
    parameter READ_PORTS = MACHINE_WIDTH * 3;
    parameter WRITE_PORTS = MACHINE_WIDTH;
    parameter TABLE_LEN = AREG_NUM;
    //  Group: Typedefs
    typedef struct packed {
        preg_addr_t preg_id;
        rob_pkg::rob_addr_t rob_addr;
    } entry_t;
    typedef entry_t [TABLE_LEN-1:0] table_t; 
    typedef struct packed {
        areg_addr_t id;
        // preg_addr_t preg_id;
    } w_req_t;
    typedef struct packed {
        areg_addr_t id;
    } r_req_t;
    typedef struct packed {
        preg_addr_t id;
    } r_resp_t;
endpackage: rat_pkg