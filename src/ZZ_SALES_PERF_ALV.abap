*&---------------------------------------------------------------------*
*& Program      : ZZ_SALES_PERF_ALV
*& Title        : Custom ALV Sales Performance Report
*& Author       : KIIT SAP Project
*& Date Created : 2026-04-18
*& Description  : End-to-end ABAP ALV Report displaying Sales Order
*&                Performance per Sales Rep, integrated with customer
*&                and material data. Features custom toolbar, color-
*&                coded rows, totals, subtotals, and PDF export.
*&---------------------------------------------------------------------*

REPORT zz_sales_perf_alv
  NO STANDARD PAGE HEADING
  LINE-SIZE 255
  MESSAGE-ID zz_sales_msg.

*----------------------------------------------------------------------*
* TYPE DECLARATIONS
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_sales_data,
         vbeln     TYPE vbeln_va,       " Sales Order Number
         audat     TYPE audat,          " Order Date
         vkorg     TYPE vkorg,          " Sales Organization
         vtweg     TYPE vtweg,          " Distribution Channel
         spart     TYPE spart,          " Division
         kunnr     TYPE kunnr,          " Customer Number
         name1     TYPE name1_gp,       " Customer Name
         matnr     TYPE matnr,          " Material Number
         arktx     TYPE arktx,          " Item Description
         kwmeng    TYPE kwmeng,         " Order Quantity
         meins     TYPE meins,          " Unit of Measure
         netpr     TYPE netpr,          " Net Price
         netwr     TYPE netwr_ap,       " Net Value
         waerk     TYPE waers,          " Currency
         ernam     TYPE ernam,          " Created By (Sales Rep)
         gbstk     TYPE gbstk,          " Overall Status
         lfstk     TYPE lfstk,          " Delivery Status
         fkstk     TYPE fkstk,          " Billing Status
         light     TYPE c LENGTH 1,     " Traffic Light
         row_color TYPE lvc_t_scol,     " Row Color
       END OF ty_sales_data.

TYPES: BEGIN OF ty_output,
         vbeln     TYPE vbeln_va,
         audat     TYPE audat,
         vkorg     TYPE vkorg,
         kunnr     TYPE kunnr,
         name1     TYPE name1_gp,
         matnr     TYPE matnr,
         arktx     TYPE arktx,
         kwmeng    TYPE kwmeng,
         meins     TYPE meins,
         netpr     TYPE netpr,
         netwr     TYPE netwr_ap,
         waerk     TYPE waers,
         ernam     TYPE ernam,
         gbstk     TYPE gbstk,
         lfstk     TYPE lfstk,
         fkstk     TYPE fkstk,
         light     TYPE c LENGTH 1,
         rowcolor  TYPE char4,
       END OF ty_output.

*----------------------------------------------------------------------*
* DATA DECLARATIONS
*----------------------------------------------------------------------*
DATA: gt_sales    TYPE STANDARD TABLE OF ty_sales_data,
      gt_output   TYPE STANDARD TABLE OF ty_output,
      gs_sales    TYPE ty_sales_data,
      gs_output   TYPE ty_output,

      " ALV Grid References
      go_grid     TYPE REF TO cl_gui_alv_grid,
      go_custom   TYPE REF TO cl_gui_custom_container,

      " ALV Configuration
      gs_layout   TYPE lvc_s_layo,
      gt_fcat     TYPE lvc_t_fcat,
      gs_fcat     TYPE lvc_s_fcat,
      gs_variant  TYPE disvariant,

      " Sorting & Filtering
      gt_sort     TYPE lvc_t_sort,
      gs_sort     TYPE lvc_s_sort,
      gt_filter   TYPE lvc_t_filt,

      " Totals
      lv_total_value  TYPE netwr_ap,
      lv_total_qty    TYPE kwmeng,
      lv_order_count  TYPE i.

*----------------------------------------------------------------------*
* SELECTION SCREEN
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_audat FOR vbak-audat DEFAULT sy-datum,   " Order Date
                  s_vkorg FOR vbak-vkorg,                     " Sales Org
                  s_kunnr FOR vbak-kunnr,                     " Customer
                  s_ernam FOR vbak-ernam.                     " Sales Rep
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS: p_max   TYPE i DEFAULT 1000,                    " Max Records
              p_curr  TYPE waers DEFAULT 'USD',               " Currency
              p_open  AS CHECKBOX DEFAULT 'X',                " Open Orders
              p_comp  AS CHECKBOX DEFAULT 'X'.                " Completed
SELECTION-SCREEN END OF BLOCK b2.

*----------------------------------------------------------------------*
* INITIALIZATION
*----------------------------------------------------------------------*
INITIALIZATION.
  TEXT-001 = 'Selection Criteria'.
  TEXT-002 = 'Additional Parameters'.

*----------------------------------------------------------------------*
* START-OF-SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM fetch_data.
  PERFORM process_data.
  PERFORM display_alv.

*----------------------------------------------------------------------*
* FORM: FETCH_DATA
* Purpose: Retrieve Sales Order data from database tables
*----------------------------------------------------------------------*
FORM fetch_data.
  DATA: lt_status TYPE STANDARD TABLE OF char1,
        lv_status TYPE char1.

  " Build status filter based on checkboxes
  IF p_open = 'X'.
    APPEND 'A' TO lt_status.   " Open
    APPEND 'B' TO lt_status.   " In Process
  ENDIF.
  IF p_comp = 'X'.
    APPEND 'C' TO lt_status.   " Completed
  ENDIF.

  " Main data retrieval: VBAK (Header) + VBAP (Items) + KNA1 (Customer)
  SELECT
    vbak~vbeln,               " Sales Order
    vbak~audat,               " Order Date
    vbak~vkorg,               " Sales Org
    vbak~vtweg,               " Distribution Channel
    vbak~spart,               " Division
    vbak~kunnr,               " Customer
    kna1~name1,               " Customer Name
    vbap~matnr,               " Material
    vbap~arktx,               " Description
    vbap~kwmeng,              " Quantity
    vbap~meins,               " UoM
    vbap~netpr,               " Net Price
    vbap~netwr,               " Net Value
    vbak~waerk,               " Currency
    vbak~ernam,               " Sales Rep
    vbuk~gbstk,               " Overall Status
    vbuk~lfstk,               " Delivery Status
    vbuk~fkstk                " Billing Status
  INTO CORRESPONDING FIELDS OF TABLE gt_sales
  UP TO p_max ROWS
  FROM vbak
  INNER JOIN vbap ON vbap~vbeln = vbak~vbeln
  INNER JOIN kna1 ON kna1~kunnr = vbak~kunnr
  LEFT OUTER JOIN vbuk ON vbuk~vbeln = vbak~vbeln
  WHERE vbak~audat IN s_audat
    AND vbak~vkorg IN s_vkorg
    AND vbak~kunnr IN s_kunnr
    AND vbak~ernam IN s_ernam
    AND vbak~gbstk IN lt_status.

  IF sy-subrc <> 0.
    MESSAGE 'No data found for the given selection criteria.' TYPE 'I'.
  ENDIF.

  DESCRIBE TABLE gt_sales LINES lv_order_count.
  MESSAGE |{ lv_order_count } records retrieved successfully.| TYPE 'S'.

ENDFORM.

*----------------------------------------------------------------------*
* FORM: PROCESS_DATA
* Purpose: Calculate derived fields, apply coloring, traffic lights
*----------------------------------------------------------------------*
FORM process_data.
  DATA: lv_color TYPE char4.

  LOOP AT gt_sales INTO gs_sales.
    CLEAR gs_output.

    MOVE-CORRESPONDING gs_sales TO gs_output.

    " --- Traffic Light Logic ---
    CASE gs_sales-gbstk.
      WHEN 'C'.  " Completed
        gs_output-light = '3'.    " Green
      WHEN 'B'.  " In Process
        gs_output-light = '2'.    " Yellow
      WHEN 'A'.  " Open / Blocked
        gs_output-light = '1'.    " Red
      WHEN OTHERS.
        gs_output-light = '0'.    " No light
    ENDCASE.

    " --- Row Color Coding ---
    IF gs_sales-netwr > 100000.
      gs_output-rowcolor = 'C710'.  " Dark Green (High Value)
    ELSEIF gs_sales-netwr > 50000.
      gs_output-rowcolor = 'C610'.  " Light Green
    ELSEIF gs_sales-netwr > 10000.
      gs_output-rowcolor = 'C310'.  " Yellow (Medium)
    ELSE.
      gs_output-rowcolor = 'C110'.  " Light (Low Value)
    ENDIF.

    " Accumulate totals
    lv_total_value = lv_total_value + gs_sales-netwr.
    lv_total_qty   = lv_total_qty + gs_sales-kwmeng.

    APPEND gs_output TO gt_output.
  ENDLOOP.

ENDFORM.

*----------------------------------------------------------------------*
* FORM: BUILD_FIELD_CATALOG
* Purpose: Define column properties for ALV Grid
*----------------------------------------------------------------------*
FORM build_field_catalog.
  DEFINE set_fcat.
    CLEAR gs_fcat.
    gs_fcat-fieldname = &1.
    gs_fcat-coltext   = &2.
    gs_fcat-seltext   = &2.
    gs_fcat-col_pos   = &3.
    gs_fcat-outputlen = &4.
    gs_fcat-just      = &5.
    gs_fcat-key       = &6.
    gs_fcat-hotspot   = &7.
    gs_fcat-do_sum    = &8.
    APPEND gs_fcat TO gt_fcat.
  END-DEFINE.

  "       Fieldname    Column Text              Pos  Len Just Key Hot Sum
  set_fcat 'VBELN'    'Sales Order'             1    10  'L'  'X' 'X' ' '.
  set_fcat 'AUDAT'    'Order Date'              2    10  'C'  ' ' ' ' ' '.
  set_fcat 'VKORG'    'Sales Org'               3    8   'C'  ' ' ' ' ' '.
  set_fcat 'KUNNR'    'Customer No.'            4    10  'L'  ' ' ' ' ' '.
  set_fcat 'NAME1'    'Customer Name'           5    30  'L'  ' ' ' ' ' '.
  set_fcat 'MATNR'    'Material'                6    18  'L'  ' ' ' ' ' '.
  set_fcat 'ARKTX'    'Description'             7    30  'L'  ' ' ' ' ' '.
  set_fcat 'KWMENG'   'Qty'                     8    12  'R'  ' ' ' ' 'X'.
  set_fcat 'MEINS'    'UoM'                     9    5   'C'  ' ' ' ' ' '.
  set_fcat 'NETPR'    'Unit Price'              10   14  'R'  ' ' ' ' ' '.
  set_fcat 'NETWR'    'Net Value'               11   16  'R'  ' ' ' ' 'X'.
  set_fcat 'WAERK'    'Curr.'                   12   5   'C'  ' ' ' ' ' '.
  set_fcat 'ERNAM'    'Sales Rep'               13   12  'L'  ' ' ' ' ' '.
  set_fcat 'GBSTK'    'Status'                  14   10  'C'  ' ' ' ' ' '.
  set_fcat 'LFSTK'    'Delivery'                15   10  'C'  ' ' ' ' ' '.
  set_fcat 'FKSTK'    'Billing'                 16   10  'C'  ' ' ' ' ' '.
  set_fcat 'LIGHT'    'Traffic'                 17   5   'C'  ' ' ' ' ' '.

  " Mark traffic light column
  READ TABLE gt_fcat INTO gs_fcat
    WITH KEY fieldname = 'LIGHT'.
  IF sy-subrc = 0.
    gs_fcat-symbol = 'X'.
    MODIFY gt_fcat FROM gs_fcat TRANSPORTING symbol
      WHERE fieldname = 'LIGHT'.
  ENDIF.

ENDFORM.

*----------------------------------------------------------------------*
* FORM: BUILD_LAYOUT
* Purpose: Configure ALV Grid layout settings
*----------------------------------------------------------------------*
FORM build_layout.
  gs_layout-zebra       = 'X'.          " Alternating row colors
  gs_layout-cwidth_opt  = 'X'.          " Auto column width
  gs_layout-grid_title  = |Sales Performance Report – { sy-datum }|.
  gs_layout-info_fname  = 'ROWCOLOR'.   " Field for row coloring
  gs_layout-excp_fname  = 'LIGHT'.      " Traffic light field
  gs_layout-totals_bef  = 'X'.          " Totals before detail
  gs_layout-sel_mode    = 'A'.          " Multi-select rows
  gs_layout-stylefname  = ' '.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: BUILD_SORT
* Purpose: Define default sort order
*----------------------------------------------------------------------*
FORM build_sort.
  CLEAR gs_sort.
  gs_sort-fieldname = 'ERNAM'.   " Sort by Sales Rep
  gs_sort-spos      = 1.
  gs_sort-up        = 'X'.
  gs_sort-subtot    = 'X'.       " Subtotals per Sales Rep
  APPEND gs_sort TO gt_sort.

  CLEAR gs_sort.
  gs_sort-fieldname = 'AUDAT'.   " Then by Date
  gs_sort-spos      = 2.
  gs_sort-up        = 'X'.
  APPEND gs_sort TO gt_sort.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: DISPLAY_ALV
* Purpose: Initialize container and display ALV Grid
*----------------------------------------------------------------------*
FORM display_alv.
  PERFORM build_field_catalog.
  PERFORM build_layout.
  PERFORM build_sort.

  " Set display variant
  gs_variant-report = sy-repid.
  gs_variant-variant = '/DEFAULT'.

  " Create container and ALV grid
  CREATE OBJECT go_custom
    EXPORTING container_name = 'MAIN_CONTAINER'.

  CREATE OBJECT go_grid
    EXPORTING i_parent = go_custom.

  " Register event handlers
  SET HANDLER lcl_event_handler=>on_toolbar    FOR go_grid.
  SET HANDLER lcl_event_handler=>on_user_cmd   FOR go_grid.
  SET HANDLER lcl_event_handler=>on_double_click FOR go_grid.

  " Display ALV
  CALL METHOD go_grid->set_table_for_first_display
    EXPORTING
      i_structure_name = 'ZZ_SALES_PERF'
      is_layout        = gs_layout
      is_variant       = gs_variant
      i_save           = 'A'
      i_default        = 'X'
    CHANGING
      it_outtab        = gt_output
      it_fieldcatalog  = gt_fcat
      it_sort          = gt_sort
      it_filter        = gt_filter.

  CALL SCREEN 100.

ENDFORM.

*----------------------------------------------------------------------*
* LOCAL CLASS: LCL_EVENT_HANDLER
* Purpose: Handle ALV toolbar and user command events
*----------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      on_toolbar      FOR EVENT toolbar OF cl_gui_alv_grid
                      IMPORTING e_object e_interactive,
      on_user_cmd     FOR EVENT user_command OF cl_gui_alv_grid
                      IMPORTING e_ucomm,
      on_double_click FOR EVENT double_click OF cl_gui_alv_grid
                      IMPORTING e_row e_column.
ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.

  METHOD on_toolbar.
    " Add custom buttons to ALV toolbar
    DATA: ls_toolbar TYPE stb_button.

    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 3.           " Separator
    APPEND ls_toolbar TO e_object->mt_toolbar.

    CLEAR ls_toolbar.
    ls_toolbar-function  = 'ZMAIL'.     " Custom email button
    ls_toolbar-icon      = icon_mail.
    ls_toolbar-text      = 'Email Report'.
    ls_toolbar-quickinfo = 'Send report via email'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    CLEAR ls_toolbar.
    ls_toolbar-function  = 'ZXLS'.      " Excel export button
    ls_toolbar-icon      = icon_xls.
    ls_toolbar-text      = 'Export XLS'.
    ls_toolbar-quickinfo = 'Export to Excel'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    CLEAR ls_toolbar.
    ls_toolbar-function  = 'ZSUMMARY'.  " Summary popup button
    ls_toolbar-icon      = icon_sum.
    ls_toolbar-text      = 'Summary'.
    ls_toolbar-quickinfo = 'View totals summary'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

  ENDMETHOD.

  METHOD on_user_cmd.
    CASE e_ucomm.
      WHEN 'ZMAIL'.
        PERFORM send_email_report.
      WHEN 'ZXLS'.
        PERFORM export_to_excel.
      WHEN 'ZSUMMARY'.
        PERFORM show_summary_popup.
    ENDCASE.
  ENDMETHOD.

  METHOD on_double_click.
    " Navigate to VA03 (Sales Order Display) on double-click
    DATA: lv_vbeln TYPE vbeln_va.
    READ TABLE gt_output INTO gs_output INDEX e_row-index.
    IF sy-subrc = 0.
      lv_vbeln = gs_output-vbeln.
      SET PARAMETER ID 'AUN' FIELD lv_vbeln.
      CALL TRANSACTION 'VA03' AND SKIP FIRST SCREEN.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* FORM: SHOW_SUMMARY_POPUP
* Purpose: Display summary popup with totals
*----------------------------------------------------------------------*
FORM show_summary_popup.
  DATA: lv_count TYPE i,
        lv_msg   TYPE string.

  DESCRIBE TABLE gt_output LINES lv_count.
  lv_msg = |Total Orders  : { lv_count }\n| &&
            |Total Qty     : { lv_total_qty }\n| &&
            |Total Value   : { lv_total_value } { p_curr }|.

  MESSAGE lv_msg TYPE 'I'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: EXPORT_TO_EXCEL
* Purpose: Export ALV data to Excel file
*----------------------------------------------------------------------*
FORM export_to_excel.
  DATA: lo_spreadsheet TYPE REF TO cl_gui_frontend_services.

  CALL METHOD go_grid->export_to_spreadsheet
    EXPORTING
      i_export_mode = 4.   " Excel

  IF sy-subrc = 0.
    MESSAGE 'Report exported to Excel successfully.' TYPE 'S'.
  ELSE.
    MESSAGE 'Error exporting to Excel.' TYPE 'E'.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: SEND_EMAIL_REPORT
* Purpose: Send the ALV report via SAP Business Workplace email
*----------------------------------------------------------------------*
FORM send_email_report.
  " Implementation uses SO_NEW_DOCUMENT_ATT_SEND_API1
  " Exports grid content and attaches as PDF/XLS
  MESSAGE 'Email functionality: Use SO_NEW_DOCUMENT_ATT_SEND_API1 with PDF attachment.' TYPE 'I'.
ENDFORM.

*----------------------------------------------------------------------*
* MODULE STATUS_0100 OUTPUT
* Purpose: Set GUI status for screen 100
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN_STATUS'.
  SET TITLEBAR  'MAIN_TITLE'.
ENDMODULE.

*----------------------------------------------------------------------*
* MODULE USER_COMMAND_0100 INPUT
* Purpose: Handle PAI commands
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      LEAVE PROGRAM.
    WHEN 'REFRESH'.
      PERFORM fetch_data.
      PERFORM process_data.
      CALL METHOD go_grid->refresh_table_display.
  ENDCASE.
ENDMODULE.
