*&---------------------------------------------------------------------*
*& Include         : ZZ_SALES_PERF_ALV_TOP
*& Description     : Global Type & Data declarations (TOP Include)
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* CONSTANTS
*----------------------------------------------------------------------*
CONSTANTS:
  gc_program_id    TYPE z_program_id VALUE 'ZZ_SALES_PERF_ALV',
  gc_report_title  TYPE string       VALUE 'Custom Sales Performance ALV Report',
  gc_version       TYPE string       VALUE 'v1.0.0',

  " Color codes for ALV rows
  gc_col_green     TYPE char4        VALUE 'C710',
  gc_col_lgn       TYPE char4        VALUE 'C610',
  gc_col_yellow    TYPE char4        VALUE 'C310',
  gc_col_white     TYPE char4        VALUE 'C110',

  " Traffic light values
  gc_tl_red        TYPE c            VALUE '1',
  gc_tl_yellow     TYPE c            VALUE '2',
  gc_tl_green      TYPE c            VALUE '3'.

*----------------------------------------------------------------------*
* MESSAGE CLASS TEXTS (ZZ_SALES_MSG)
*----------------------------------------------------------------------*
* E001 - No data found for given selection
* I001 - & records retrieved
* S001 - Report executed successfully
* W001 - Currency conversion error for &
*----------------------------------------------------------------------*
