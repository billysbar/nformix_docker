database test;
--drop table cs_client_config ;
create table cs_client_config (
        ccc_bill_numm INTEGER NOT NULL PRIMARY KEY ,
        ccc_bank_sort CHAR(8)  NOT NULL,
        ccc_bank_acc CHAR(8)  NOT NULL,
        ccc_bank_name CHAR(18) NOT NULL,
        ccc_net_settle CHAR(1) NOT NULL,
        ccc_settle_freq CHAR(13) NOT NULL,
        ccc_settle_method CHAR(1) NOT NULL,
        ccc_bacs_delay SMALLINT  NOT NULL,
        ccc_last_run INTEGER  NOT NULL,
        ccc_proc VARCHAR(100) NOT NULL,
        ccc_inv_report INTEGER,
        ccc_name VARCHAR(100) NOT NULL,
        ccc_add1 VARCHAR(100) NOT NULL,
        ccc_add2 VARCHAR(100) NOT NULL,
        ccc_add3 VARCHAR(100),
        ccc_add4 VARCHAR(100),
        ccc_add5 VARCHAR(100),
        ccc_add6 VARCHAR(100),
        ccc_post_code VARCHAR(8,0),
        ccc_phone_no  VARCHAR(11,0),
        ccc_contact_name VARCHAR(100) NOT NULL,
        ccc_vat_no VARCHAR(15) NOT NULL,
        ccc_active VARCHAR(1,0) NOT NULL
);

--drop table cs_client_comm;
create table cs_client_comm
(
ccm_bill_numm    integer not null,
ccm_valid        char(1) not null,
ccm_line_type    integer not null,
ccm_basis_type   integer not null,
ccm_calc_order   smallint not null,
ccm_report_order smallint not null,
ccm_fava         char(1) not null,
ccm_arat         decimal(7,4) not null,
ccm_vat          char(1) not null,
ccm_line_desc    varchar(20),
ccm_basis_desc   varchar(20),
ccm_desc         varchar(200) not null
);

--drop index idx_ccm1;
create index idx_ccm_1 on cs_client_comm (ccm_bill_numm);

-- cs_inv_line_type
-- This table is used to store the various different types of invoice lines
--drop table cs_inv_line_type ;
create table cs_inv_line_type (
        clt_seri SERIAL NOT NULL PRIMARY KEY,
        clt_short_desc VARCHAR(20) NOT NULL,
        clt_desc VARCHAR(200) NOT NULL
 );

-- populate this table with the initial values
insert into cs_inv_line_type
values (1,"SALES","Sale totals for a DTF date" );
insert into cs_inv_line_type
values (2,"REFUNDS","Refund totals for a DTF date" );
insert into cs_inv_line_type
values (3,"PAYZONE COMMISSION","Payzone Commission Payment for a DTF date" );
insert into cs_inv_line_type
values (4,"PS COMMISSION","Payment Services Commission Payment for a DTF date" );
insert into cs_inv_line_type values (5,"VAT","VAT" );
