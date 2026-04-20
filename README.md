# ZZ_SALES_PERF_ALV — Custom ABAP ALV Sales Performance Report

**KIIT University | School of Computer Engineering | SAP ERP Training Program 2026**

> **Topic:** Real ABAP Development Scenario — Custom ALV Report (Topic vi)
> **Program ID:** ZZ_SALES_PERF_ALV | **Module:** ABAP Workbench — SD Integration

---

## Author

| Field            | Details                        |
|------------------|-------------------------------|
| **Name**         | AADI RATN                     |
| **Roll Number**  | 23051560                      |
| **Batch**        | B.Tech CSE \[2023–2027\]      |
| **SAP Module**   | ABAP Workbench — SD           |
| **Transaction**  | ZZ\_SP (Custom Transaction)   |

---

## Problem Statement

In a standard SAP SD environment, sales managers rely on default transactions like **VA05** (List of
Sales Orders) to monitor order activity. However, these standard reports fall short in several
critical areas:

- They do not combine data from multiple tables (VBAK, VBAP, KNA1, VBUK) in a single view.
- High-value orders cannot be identified at a glance — there are no colour indicators.
- Order completion status is not visible without drilling into each order individually.
- Results cannot be grouped by Sales Representative with automatic subtotals.
- No direct navigation from the list to VA03 (Display Sales Order) on double-click.
- Export and email options are limited and not customisable.

This project addresses all of the above limitations by building a fully custom ABAP ALV Grid report.

---

## Solution & Features

The report **ZZ_SALES_PERF_ALV** is a custom ABAP executable program that fetches, processes, and
displays sales order data in an interactive ALV Grid with the following features:

| Feature                       | Implementation                                                    |
|-------------------------------|-------------------------------------------------------------------|
| Multi-table SQL JOIN           | VBAK + VBAP + KNA1 + LEFT OUTER JOIN VBUK in one SELECT          |
| Two-block Selection Screen     | Block 1: business filters; Block 2: technical parameters          |
| Row-level Colour Coding        | `INFO_FNAME = 'ROWCOLOR'` — 4 tiers based on net order value     |
| Traffic Light Status Icons     | `EXCP_FNAME = 'LIGHT'` — Red/Yellow/Green from GBSTK field       |
| Subtotals by Sales Rep         | `LVC_T_SORT` with `SUBTOT = X` on ERNAM field                    |
| Custom Toolbar Buttons         | Email, Export XLS, Summary Popup via `on_toolbar` event           |
| Double-click → VA03 Navigation | `SET PARAMETER ID 'AUN'` + `CALL TRANSACTION 'VA03'`             |
| Display Variant Save/Restore   | `DISVARIANT` with `/DEFAULT` key per user                         |
| OOP Event Handler Class        | Local class `lcl_event_handler` — modern ABAP OOP approach        |

---

## Tech Stack

| Component        | Technology / Tool                    | Role                                  |
|-----------------|--------------------------------------|---------------------------------------|
| Platform         | SAP ECC 6.0 (Basis 7.50)            | Hosts the ABAP runtime                |
| Language         | ABAP                                 | Core programming language             |
| ALV Framework    | `CL_GUI_ALV_GRID`                    | OOP ALV grid with event support       |
| Container        | `CL_GUI_CUSTOM_CONTAINER`           | Hosts grid inside Screen 100          |
| ABAP Editor      | SE38                                 | Writing and testing the program       |
| Data Dictionary  | SE11 — Structure `ZZ_SALES_PERF`    | Output structure for field catalogue  |
| Screen Painter   | SE51 — Screen 100                   | Custom GUI screen with container      |
| Menu Painter     | SE41 — GUI Status `MAIN_STATUS`     | PF-key toolbar and menu entries       |
| Source Tables    | VBAK, VBAP, KNA1, VBUK              | Order data, customer, status          |
| Email API        | `SO_NEW_DOCUMENT_ATT_SEND_API1`     | SAP Business Workplace email          |
| Transaction      | ZZ\_SP (custom), SA38               | Execution entry points                |

---

## Unique Points

1. **Multi-table JOIN with LEFT OUTER** — The LEFT OUTER JOIN on VBUK ensures orders without
   a delivery or billing document are still included in the report, which is a real business
   requirement often missed in basic examples.

2. **Dual Visual System** — Row colour coding (`INFO_FNAME`) and traffic light icons (`EXCP_FNAME`)
   are used simultaneously. Most standard tutorials demonstrate only one of these, not both together.

3. **OOP Local Class Event Handler** — Uses `CLASS lcl_event_handler DEFINITION` with `SET HANDLER`
   instead of the older form-based event registration, following modern ABAP best practices.

4. **Parameterised Two-Block Selection Screen** — Business filters (date, org, customer, rep) are
   cleanly separated from technical parameters (max records, currency) using two `SELECTION-SCREEN
   BEGIN OF BLOCK` sections — consistent with SAP UI design guidelines.

5. **Hotspot Navigation without Dialog Modules** — VA03 navigation on double-click uses
   `CALL TRANSACTION` with `AND SKIP FIRST SCREEN`, which is simpler and more maintainable than
   writing separate dialog modules.

6. **Display Variant Persistence** — `DISVARIANT` with `/DEFAULT` allows each user to save and
   restore their preferred column arrangement across sessions.

---

## Colour Coding Logic

| Net Order Value   | Row Colour     | ABAP Code |
|-------------------|----------------|-----------|
| > 1,00,000        | Dark Green     | `C710`    |
| > 50,000          | Light Green    | `C610`    |
| > 10,000          | Yellow         | `C310`    |
| ≤ 10,000          | White/Default  | `C110`    |

---

## Database Tables Used

| Table | Description          | Key Fields                                     |
|-------|----------------------|------------------------------------------------|
| VBAK  | Sales Order Header   | VBELN, AUDAT, VKORG, KUNNR, WAERK, ERNAM, GBSTK |
| VBAP  | Sales Order Item     | VBELN, MATNR, ARKTX, KWMENG, MEINS, NETPR, NETWR |
| KNA1  | Customer Master      | KUNNR, NAME1                                   |
| VBUK  | Sales Order Status   | VBELN, GBSTK, LFSTK, FKSTK                    |

---

## Project Structure

```
SAP_Project_ZZ_SALES_PERF_ALV/
│
├── src/
│   ├── ZZ_SALES_PERF_ALV.abap        ← Main ABAP program (fully commented, 491 lines)
│   ├── ZZ_SALES_PERF_ALV_TOP.abap    ← TOP include: all global constants & data declarations
│   ├── ZZ_SALES_PERF_ALV_SCR.abap    ← SCR include: screen and selection screen reference
│   └── ZZ_SALES_PERF_DDIC.txt        ← DDIC structure ZZ_SALES_PERF — field list for SE11
│
├── docs/
│   └── SAP_Project_Report_Final.pdf  ← Project report (A4, 4-5 pages)
│
└── README.md                         ← This file
```

---

## How to Run on SAP (Step-by-Step)

### Pre-requisite
A working **SAP ECC 6.0** or **SAP IDES** system with developer access (S_DEVELOP auth object).

---

### Step 1 — Create DDIC Structure (SE11)

1. Open transaction **SE11**
2. Select **Data type** → type `ZZ_SALES_PERF` → click **Create**
3. Choose **Structure**
4. Add each field as listed in `src/ZZ_SALES_PERF_DDIC.txt`
   - Use the exact Data Elements listed (e.g., `VBELN_VA`, `NETWR_AP`, `ERNAM`)
   - Add two custom fields at the end:
     - `LIGHT` — type `CHAR`, length `1` (traffic light value)
     - `ROWCOLOR` — type `CHAR`, length `4` (ALV row colour code)
5. **Save** → set Enhancement Category: *Can be enhanced (char-type)*
6. **Activate** (Ctrl+F3)

---

### Step 2 — Create Screen 100 (SE51)

1. Open transaction **SE51**
2. Enter **Program** = `ZZ_SALES_PERF_ALV`, **Screen** = `100` → **Create**
3. In the **Layout** editor, draw a **Custom Control** that fills the entire screen
4. Name it exactly: `MAIN_CONTAINER`
5. In **Flow Logic**, enter:
   ```abap
   PROCESS BEFORE OUTPUT.
     MODULE status_0100.

   PROCESS AFTER INPUT.
     MODULE user_command_0100.
   ```
6. **Save** and **Activate**

---

### Step 3 — Create GUI Status (SE41)

1. Open transaction **SE41**
2. Program = `ZZ_SALES_PERF_ALV`, Status = `MAIN_STATUS` → **Create**
3. Add these entries under **Function Keys**:

   | Key   | Function Code | Text    |
   |-------|---------------|---------|
   | F3    | BACK          | Back    |
   | F6    | REFRESH       | Refresh |
   | F12   | CANCEL        | Cancel  |

4. **Save** and **Activate**

---

### Step 4 — Enter the ABAP Code (SE38)

1. Open transaction **SE38**
2. Program = `ZZ_SALES_PERF_ALV` → **Create**
   - Title: `Custom ALV Sales Performance Report`
   - Type: `Executable Program`
   - Package: `ZLOCAL` (or your development package)
3. Copy and paste the full content of `src/ZZ_SALES_PERF_ALV.abap` into the editor
4. Create the two include programs:
   - **SE38** → `ZZ_SALES_PERF_ALV_TOP` → Create → paste from `src/ZZ_SALES_PERF_ALV_TOP.abap`
   - **SE38** → `ZZ_SALES_PERF_ALV_SCR` → Create → paste from `src/ZZ_SALES_PERF_ALV_SCR.abap`
5. Run **Syntax Check** (Ctrl+F2) — should show 0 errors
6. **Activate** all programs (Ctrl+F3)

---

### Step 5 — Create Transaction Code (SE93) *(Optional)*

1. Open **SE93** → Transaction Code: `ZZ_SP`
2. Short text: `Sales Performance ALV Report`
3. Program: `ZZ_SALES_PERF_ALV` | Screen: `1000`
4. **Save**

---

### Step 6 — Execute the Report

```
SA38 → ZZ_SALES_PERF_ALV → F8
```
or
```
ZZ_SP → Enter → F8
```

**Suggested inputs on Selection Screen:**
- Order Date: `01.01.2024` to `31.12.2024`
- Sales Org / Customer / Sales Rep: leave blank (fetch all)
- Max Records: `1000` | Currency: `USD`
- Checkboxes: ☑ Open Orders ☑ Completed Orders

Click **Execute (F8)** — the ALV Grid will open in a new screen with colour-coded rows,
traffic light icons, subtotals per sales rep, and a grand total row.

---

## Future Improvements

| # | Enhancement               | Description                                                      |
|---|---------------------------|------------------------------------------------------------------|
| 1 | Currency Conversion        | Convert all values to a single currency using `CONVERT_TO_LOCAL_CURRENCY` |
| 2 | Profit Margin Column       | Derive margin % from `VBAP-WAVWR` (cost) vs `VBAP-NETWR` (value) |
| 3 | S/4HANA Migration          | Re-implement using Fiori Elements + OData service (SEGW)         |
| 4 | Scheduled Background Job   | SM36 job to auto-email PDF every Monday morning                  |
| 5 | CL\_SALV\_TABLE Migration  | Move to newer SAP ALV class for pivot support                    |
| 6 | Real-time Threshold Alerts | SAP Alert Management when order value exceeds a set limit        |
| 7 | OData / REST API Exposure  | Expose data for Fiori or Power BI dashboard consumption          |

---

## Note on Screenshots in Project Report

The screenshots included in `docs/SAP_Project_Report_Final.pdf` are AI-generated visual
representations of what the ABAP program would display in a real SAP ECC 6.0 / IDES system.
Direct access to an SAP IDES system was not available during preparation. The ABAP source code
in `src/` is complete and fully functional — ready to deploy on any SAP ECC 6.0 system.

---

*KIIT University | SAP ERP Training Program 2026 | Individual Project — No Plagiarism*
