*&---------------------------------------------------------------------*
*& Include         : ZZ_SALES_PERF_ALV_SCR
*& Description     : Screen and Selection Screen elements
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* SCREEN 100 — Main ALV Container Screen
* This screen hosts the ALV Grid (Custom Container)
* Module pool: ZZ_SALES_PERF_ALV
*----------------------------------------------------------------------*
*
* Screen Painter Definition (normally done in SE51):
*
*  - Subscreen area named: MAIN_CONTAINER
*  - Size: full screen (80x24 minimum)
*  - Custom Control painted on screen with name: MAIN_CONTAINER
*
*----------------------------------------------------------------------*
* PF-STATUS: MAIN_STATUS
* Buttons defined in Menu Painter (SE41):
*   BACK   = Back
*   EXIT   = Exit
*   CANCEL = Cancel
*   REFRESH = Refresh Data
*----------------------------------------------------------------------*

*----------------------------------------------------------------------*
* FUNCTION KEY TEXT TABLE: ZZ_SALES_FUNC
*----------------------------------------------------------------------*
* F4  = Input Help (standard)
* F5  = Detail display
* F6  = Refresh
* F8  = Execute
* F12 = Back/Cancel
*----------------------------------------------------------------------*
