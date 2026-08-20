*&---------------------------------------------------------------------*
*& Report  ZSD_REV_LIFECYCLE_EXTRACT
*&
*& ECC SD/FI audit extraction for long-running sales orders.
*&
*& Design goals
*&   - seed the population from audit-period orders, billings or FI docs;
*&   - expand the population through VBFA in both directions;
*&   - retain every SD document event instead of netting invoices in SAP;
*&   - extract linked FI headers/lines for billing and accrual accounts;
*&   - write raw, line-grain UTF-8 files for controlled downstream analysis.
*&
*& This is a standalone extraction template. Customer-specific revenue
*& recognition / acceptance Z tables must be added in FORM
*& CUSTOMER_EXTENSION after their schema is confirmed.
*&---------------------------------------------------------------------*
REPORT zsd_rev_lifecycle_extract NO STANDARD PAGE HEADING.

TABLES: vbak, vbap, likp, lips, vbfa, vbrk, vbrp,
        bkpf, bseg.

CONSTANTS c_sep TYPE c LENGTH 3 VALUE '#|#'.
CONSTANTS c_max_flow_rounds TYPE i VALUE 20.
CONSTANTS c_doc_chunk TYPE i VALUE 1000.

TYPES: BEGIN OF ty_doc_key,
         vbeln TYPE vbeln_va,
       END OF ty_doc_key.
TYPES ty_t_doc_key TYPE SORTED TABLE OF ty_doc_key WITH UNIQUE KEY vbeln.
TYPES ty_t_doc_range TYPE RANGE OF vbeln_va.

TYPES: BEGIN OF ty_fi_key,
         bukrs TYPE bukrs,
         belnr TYPE belnr_d,
         gjahr TYPE gjahr,
       END OF ty_fi_key.
TYPES ty_t_fi_key TYPE SORTED TABLE OF ty_fi_key
                  WITH UNIQUE KEY bukrs belnr gjahr.

TYPES: BEGIN OF ty_bill_seed,
         vbeln TYPE vbrk-vbeln,
         bukrs TYPE vbrk-bukrs,
         vkorg TYPE vbrk-vkorg,
         kunag TYPE vbrk-kunag,
         fkdat TYPE vbrk-fkdat,
       END OF ty_bill_seed.

TYPES: BEGIN OF ty_order_out,
         MANDT TYPE vbak-mandt,
         VBELN TYPE vbak-vbeln,
         POSNR TYPE vbap-posnr,
         AUART TYPE vbak-auart,
         AUDAT TYPE vbak-audat,
         ERDAT TYPE vbak-erdat,
         AEDAT TYPE vbak-aedat,
         VKORG TYPE vbak-vkorg,
         VTWEG TYPE vbak-vtweg,
         SPART TYPE vbak-spart,
         KUNNR TYPE vbak-kunnr,
         BSTNK TYPE vbak-bstnk,
         KTEXT TYPE vbak-ktext,
         NETWR TYPE vbap-netwr,
         WAERK TYPE vbap-waerk,
         MATNR TYPE vbap-matnr,
         ARKTX TYPE vbap-arktx,
         WERKS TYPE vbap-werks,
         KWMENG TYPE vbap-kwmeng,
         VRKME TYPE vbap-vrkme,
         LFREL TYPE vbap-lfrel,
         FKREL TYPE vbap-fkrel,
         ABGRU TYPE vbap-abgru,
         ERLRE TYPE vbap-erlre,
         VGBEL TYPE vbap-vgbel,
         VGPOS TYPE vbap-vgpos,
       END OF ty_order_out.

TYPES: BEGIN OF ty_delivery_out,
         MANDT TYPE likp-mandt,
         VBELN TYPE likp-vbeln,
         POSNR TYPE lips-posnr,
         ERDAT TYPE likp-erdat,
         LFDAT TYPE likp-lfdat,
         WADAT TYPE likp-wadat,
         WADAT_IST TYPE likp-wadat_ist,
         VKORG TYPE likp-vkorg,
         KUNAG TYPE likp-kunag,
         LFART TYPE likp-lfart,
         VBTYP TYPE likp-vbtyp,
         MATNR TYPE lips-matnr,
         WERKS TYPE lips-werks,
         LFIMG TYPE lips-lfimg,
         VRKME TYPE lips-vrkme,
         SHKZG TYPE lips-shkzg,
         BWART TYPE lips-bwart,
         NETWR TYPE lips-netwr,
         VBELV TYPE lips-vbelv,
         POSNV TYPE lips-posnv,
         VGBEL TYPE lips-vgbel,
         VGPOS TYPE lips-vgpos,
       END OF ty_delivery_out.

TYPES: BEGIN OF ty_billing_out,
         MANDT TYPE vbrk-mandt,
         VBELN TYPE vbrk-vbeln,
         POSNR TYPE vbrp-posnr,
         FKART TYPE vbrk-fkart,
         VBTYP TYPE vbrk-vbtyp,
         FKDAT TYPE vbrk-fkdat,
         BUKRS TYPE vbrk-bukrs,
         VKORG TYPE vbrk-vkorg,
         KUNAG TYPE vbrk-kunag,
         WAERK TYPE vbrk-waerk,
         NETWR TYPE vbrp-netwr,
         MWSBP TYPE vbrp-mwsbp,
         BELNR TYPE vbrk-belnr,
         GJAHR TYPE vbrk-gjahr,
         FKSTO TYPE vbrk-fksto,
         SFAKN TYPE vbrk-sfakn,
         XBLNR TYPE vbrk-xblnr,
         ZUONR TYPE vbrk-zuonr,
         FKIMG TYPE vbrp-fkimg,
         FKLMG TYPE vbrp-fklmg,
         SHKZG TYPE vbrp-shkzg,
         MATNR TYPE vbrp-matnr,
         FBUDA TYPE vbrp-fbuda,
         PRSDT TYPE vbrp-prsdt,
         AUBEL TYPE vbrp-aubel,
         AUPOS TYPE vbrp-aupos,
         VBELV TYPE vbrp-vbelv,
         POSNV TYPE vbrp-posnv,
         VGBEL TYPE vbrp-vgbel,
         VGPOS TYPE vbrp-vgpos,
       END OF ty_billing_out.

TYPES: BEGIN OF ty_flow_out,
         MANDT TYPE vbfa-mandt,
         VBELV TYPE vbfa-vbelv,
         POSNV TYPE vbfa-posnv,
         VBELN TYPE vbfa-vbeln,
         POSNN TYPE vbfa-posnn,
         VBTYP_V TYPE vbfa-vbtyp_v,
         VBTYP_N TYPE vbfa-vbtyp_n,
         RFMNG TYPE vbfa-rfmng,
         MEINS TYPE vbfa-meins,
         RFWRT TYPE vbfa-rfwrt,
         WAERS TYPE vbfa-waers,
         PLMIN TYPE vbfa-plmin,
         ERDAT TYPE vbfa-erdat,
         AEDAT TYPE vbfa-aedat,
         MATNR TYPE vbfa-matnr,
         BWART TYPE vbfa-bwart,
         STUFE TYPE vbfa-stufe,
         FPLNR TYPE vbfa-fplnr,
         FPLTR TYPE vbfa-fpltr,
         MJAHR TYPE vbfa-mjahr,
       END OF ty_flow_out.

TYPES: BEGIN OF ty_bkpf_out,
         SOURCE_SCOPE TYPE char20,
         MANDT TYPE bkpf-mandt,
         BUKRS TYPE bkpf-bukrs,
         BELNR TYPE bkpf-belnr,
         GJAHR TYPE bkpf-gjahr,
         BLART TYPE bkpf-blart,
         BLDAT TYPE bkpf-bldat,
         BUDAT TYPE bkpf-budat,
         CPUDT TYPE bkpf-cpudt,
         CPUTM TYPE bkpf-cputm,
         USNAM TYPE bkpf-usnam,
         TCODE TYPE bkpf-tcode,
         XBLNR TYPE bkpf-xblnr,
         STBLG TYPE bkpf-stblg,
         STJAH TYPE bkpf-stjah,
         BKTXT TYPE bkpf-bktxt,
         WAERS TYPE bkpf-waers,
         BSTAT TYPE bkpf-bstat,
         AWTYP TYPE bkpf-awtyp,
         AWKEY TYPE bkpf-awkey,
         STODT TYPE bkpf-stodt,
       END OF ty_bkpf_out.

TYPES: BEGIN OF ty_bseg_raw,
         MANDT TYPE bseg-mandt,
         BUKRS TYPE bseg-bukrs,
         BELNR TYPE bseg-belnr,
         GJAHR TYPE bseg-gjahr,
         BUZEI TYPE bseg-buzei,
         UMSKS TYPE bseg-umsks,
         ZUMSK TYPE bseg-zumsk,
         SHKZG TYPE bseg-shkzg,
         DMBTR TYPE bseg-dmbtr,
         WRBTR TYPE bseg-wrbtr,
         ZUONR TYPE bseg-zuonr,
         SGTXT TYPE bseg-sgtxt,
         HKONT TYPE bseg-hkont,
         KUNNR TYPE bseg-kunnr,
         VBELN TYPE bseg-vbeln,
         VBEL2 TYPE bseg-vbel2,
         POSN2 TYPE bseg-posn2,
         REBZG TYPE bseg-rebzg,
         REBZJ TYPE bseg-rebzj,
         REBZZ TYPE bseg-rebzz,
         AUGBL TYPE bseg-augbl,
         AUGGJ TYPE bseg-auggj,
         XREF1 TYPE bseg-xref1,
         XREF2 TYPE bseg-xref2,
         XREF3 TYPE bseg-xref3,
         PRCTR TYPE bseg-prctr,
         MATNR TYPE bseg-matnr,
         WERKS TYPE bseg-werks,
       END OF ty_bseg_raw.

TYPES: BEGIN OF ty_fi_line_out,
         SOURCE_SCOPE TYPE char20,
         BUKRS TYPE bseg-bukrs,
         BELNR TYPE bseg-belnr,
         GJAHR TYPE bseg-gjahr,
         BUZEI TYPE bseg-buzei,
         BUDAT TYPE bkpf-budat,
         BLART TYPE bkpf-blart,
         WAERS TYPE bkpf-waers,
         HKONT TYPE bseg-hkont,
         SHKZG TYPE bseg-shkzg,
         DMBTR TYPE bseg-dmbtr,
         WRBTR TYPE bseg-wrbtr,
         ZUONR TYPE bseg-zuonr,
         SGTXT TYPE bseg-sgtxt,
         VBELN TYPE bseg-vbeln,
         VBEL2 TYPE bseg-vbel2,
         POSN2 TYPE bseg-posn2,
         REBZG TYPE bseg-rebzg,
         REBZJ TYPE bseg-rebzj,
         REBZZ TYPE bseg-rebzz,
         AUGBL TYPE bseg-augbl,
         AUGGJ TYPE bseg-auggj,
         XREF1 TYPE bseg-xref1,
         XREF2 TYPE bseg-xref2,
         XREF3 TYPE bseg-xref3,
         PRCTR TYPE bseg-prctr,
         MATNR TYPE bseg-matnr,
         WERKS TYPE bseg-werks,
       END OF ty_fi_line_out.

TYPES: BEGIN OF ty_control_out,
         RUN_TIMESTAMP TYPE char14,
         REPORT_NAME TYPE char40,
         DATASET TYPE char30,
         ROW_COUNT TYPE i,
         CONTROL_NOTE TYPE char120,
       END OF ty_control_out.

DATA: gt_seed_orders TYPE ty_t_doc_key,
      gt_seed_docs TYPE ty_t_doc_key,
      gt_order_keys TYPE ty_t_doc_key,
      gt_seen_docs TYPE ty_t_doc_key,
      gt_fi_keys TYPE ty_t_fi_key,
      gt_bill_fi_keys TYPE ty_t_fi_key,
      gt_orders TYPE STANDARD TABLE OF ty_order_out,
      gt_deliveries TYPE STANDARD TABLE OF ty_delivery_out,
      gt_billings TYPE STANDARD TABLE OF ty_billing_out,
      gt_flow TYPE STANDARD TABLE OF ty_flow_out,
      gt_bkpf TYPE STANDARD TABLE OF ty_bkpf_out,
      gt_bseg_raw TYPE STANDARD TABLE OF ty_bseg_raw,
      gt_fi_lines TYPE STANDARD TABLE OF ty_fi_line_out,
      gt_control TYPE STANDARD TABLE OF ty_control_out.

DATA gv_run_timestamp TYPE char14.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.
PARAMETERS: p_inv RADIOBUTTON GROUP seed DEFAULT 'X',
            p_ord RADIOBUTTON GROUP seed,
            p_fi  RADIOBUTTON GROUP seed.
SELECT-OPTIONS: s_order FOR vbak-vbeln,
                s_bill  FOR vbrk-vbeln,
                s_bukrs FOR vbrk-bukrs OBLIGATORY,
                s_vkorg FOR vbak-vkorg,
                s_kunag FOR vbrk-kunag,
                s_odat  FOR vbak-audat,
                s_fdat  FOR vbrk-fkdat,
                s_budat FOR bkpf-budat,
                s_hkont FOR bseg-hkont.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME.
PARAMETERS: p_fiall AS CHECKBOX DEFAULT 'X',
            p_path TYPE c LENGTH 255 LOWER CASE OBLIGATORY,
            p_pref TYPE char20 DEFAULT 'REV_LIFE'.
SELECTION-SCREEN END OF BLOCK b2.

START-OF-SELECTION.
  PERFORM validate_selection.
  PERFORM get_seed_population.
  PERFORM validate_seed_population.
  PERFORM expand_document_flow.
  PERFORM load_sd_documents.
  PERFORM load_fi_documents.
  PERFORM customer_extension.
  PERFORM write_outputs.
  MESSAGE 'Revenue lifecycle extraction completed' TYPE 'S'.

FORM validate_selection.
  IF p_inv = 'X' AND s_bill[] IS INITIAL AND s_fdat[] IS INITIAL.
    MESSAGE 'Invoice seed requires billing number or billing date range' TYPE 'E'.
  ENDIF.
  IF p_ord = 'X' AND s_order[] IS INITIAL AND s_odat[] IS INITIAL.
    MESSAGE 'Order seed requires order number or order date range' TYPE 'E'.
  ENDIF.
  IF p_fi = 'X' AND s_budat[] IS INITIAL AND s_fdat[] IS INITIAL.
    MESSAGE 'FI seed requires posting date range or billing date range' TYPE 'E'.
  ENDIF.
  IF p_fi = 'X' AND s_budat[] IS INITIAL AND s_fdat[] IS NOT INITIAL.
    s_budat[] = s_fdat[].
  ENDIF.
ENDFORM.

FORM validate_seed_population.
  IF gt_seed_docs[] IS INITIAL
     AND gt_seed_orders[] IS INITIAL
     AND gt_fi_keys[] IS INITIAL.
    MESSAGE 'No seed documents found for the selected scope' TYPE 'E'.
  ENDIF.
ENDFORM.

FORM append_doc USING p_vbeln TYPE vbeln_va
               CHANGING ct_docs TYPE ty_t_doc_key.
  DATA ls_doc TYPE ty_doc_key.
  IF p_vbeln IS INITIAL.
    RETURN.
  ENDIF.
  ls_doc-vbeln = p_vbeln.
  INSERT ls_doc INTO TABLE ct_docs.
ENDFORM.

FORM append_fi_key USING p_bukrs TYPE bukrs
                         p_belnr TYPE belnr_d
                         p_gjahr TYPE gjahr
                  CHANGING ct_keys TYPE ty_t_fi_key.
  DATA ls_key TYPE ty_fi_key.
  IF p_bukrs IS INITIAL OR p_belnr IS INITIAL OR p_gjahr IS INITIAL.
    RETURN.
  ENDIF.
  ls_key-bukrs = p_bukrs.
  ls_key-belnr = p_belnr.
  ls_key-gjahr = p_gjahr.
  INSERT ls_key INTO TABLE ct_keys.
ENDFORM.

FORM get_seed_population.
  DATA: lt_bill_seed TYPE STANDARD TABLE OF ty_bill_seed,
        ls_bill_seed TYPE ty_bill_seed,
        lt_vbrp_seed TYPE STANDARD TABLE OF ty_billing_out,
        ls_vbrp_seed TYPE ty_billing_out,
        lt_bkpf_seed TYPE STANDARD TABLE OF ty_bkpf_out,
        ls_bkpf_seed TYPE ty_bkpf_out,
        ls_doc TYPE ty_doc_key.
  FIELD-SYMBOLS <ls_seed_bseg> TYPE ty_bseg_raw.

  IF p_ord = 'X'.
    IF s_order[] IS NOT INITIAL.
      IF s_vkorg[] IS INITIAL.
        SELECT vbeln FROM vbak INTO TABLE gt_seed_orders
          WHERE vbeln IN s_order.
      ELSE.
        SELECT vbeln FROM vbak INTO TABLE gt_seed_orders
          WHERE vbeln IN s_order AND vkorg IN s_vkorg.
      ENDIF.
    ELSEIF s_vkorg[] IS INITIAL.
      SELECT vbeln FROM vbak INTO TABLE gt_seed_orders
        WHERE audat IN s_odat.
    ELSE.
      SELECT vbeln FROM vbak INTO TABLE gt_seed_orders
        WHERE audat IN s_odat AND vkorg IN s_vkorg.
    ENDIF.
    LOOP AT gt_seed_orders INTO ls_doc.
      INSERT ls_doc INTO TABLE gt_seed_docs.
    ENDLOOP.
  ENDIF.

  IF p_inv = 'X'.
    IF s_bill[] IS NOT INITIAL.
      SELECT vbeln bukrs vkorg kunag fkdat
        FROM vbrk INTO TABLE lt_bill_seed
        WHERE vbeln IN s_bill AND bukrs IN s_bukrs.
    ELSE.
      SELECT vbeln bukrs vkorg kunag fkdat
        FROM vbrk INTO TABLE lt_bill_seed
        WHERE fkdat IN s_fdat AND bukrs IN s_bukrs.
    ENDIF.
    LOOP AT lt_bill_seed INTO ls_bill_seed.
      IF s_vkorg[] IS NOT INITIAL.
        IF NOT ls_bill_seed-vkorg IN s_vkorg.
          CONTINUE.
        ENDIF.
      ENDIF.
      IF s_kunag[] IS NOT INITIAL.
        IF NOT ls_bill_seed-kunag IN s_kunag.
          CONTINUE.
        ENDIF.
      ENDIF.
      PERFORM append_doc USING ls_bill_seed-vbeln CHANGING gt_seed_docs.
    ENDLOOP.
    IF gt_seed_docs[] IS NOT INITIAL.
      SELECT vbeln posnr aubel aupos vbelv posnv
        FROM vbrp INTO CORRESPONDING FIELDS OF TABLE lt_vbrp_seed
        FOR ALL ENTRIES IN gt_seed_docs
        WHERE vbeln = gt_seed_docs-vbeln.
      LOOP AT lt_vbrp_seed INTO ls_vbrp_seed.
        PERFORM append_doc USING ls_vbrp_seed-aubel CHANGING gt_seed_orders.
        PERFORM append_doc USING ls_vbrp_seed-aubel CHANGING gt_seed_docs.
        IF ls_vbrp_seed-aubel IS INITIAL.
          PERFORM append_doc USING ls_vbrp_seed-vbelv CHANGING gt_seed_docs.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF p_fi = 'X'.
    SELECT mandt bukrs belnr gjahr blart bldat budat cpudt cputm usnam
           tcode xblnr stblg stjah bktxt waers bstat awtyp awkey stodt
      FROM bkpf INTO CORRESPONDING FIELDS OF TABLE lt_bkpf_seed
      WHERE bukrs IN s_bukrs AND budat IN s_budat.
    APPEND LINES OF lt_bkpf_seed TO gt_bkpf.
    LOOP AT lt_bkpf_seed INTO ls_bkpf_seed.
      PERFORM append_fi_key USING ls_bkpf_seed-bukrs
                                  ls_bkpf_seed-belnr
                                  ls_bkpf_seed-gjahr
                           CHANGING gt_fi_keys.
      IF ls_bkpf_seed-awtyp = 'VBRK'.
        PERFORM append_doc USING ls_bkpf_seed-awkey+0(10)
                          CHANGING gt_seed_docs.
      ENDIF.
    ENDLOOP.
    PERFORM load_bseg_for_keys USING gt_fi_keys.
    LOOP AT gt_bseg_raw ASSIGNING <ls_seed_bseg>.
      PERFORM append_doc USING <ls_seed_bseg>-vbeln CHANGING gt_seed_docs.
      PERFORM append_doc USING <ls_seed_bseg>-vbel2 CHANGING gt_seed_docs.
      PERFORM append_doc USING <ls_seed_bseg>-vbel2 CHANGING gt_seed_orders.
    ENDLOOP.
  ENDIF.

  LOOP AT gt_seed_orders INTO ls_doc.
    INSERT ls_doc INTO TABLE gt_order_keys.
  ENDLOOP.
ENDFORM.

FORM expand_document_flow.
  DATA: lt_frontier TYPE ty_t_doc_key,
        lt_next TYPE ty_t_doc_key,
        lt_range TYPE ty_t_doc_range,
        lt_round TYPE STANDARD TABLE OF ty_flow_out,
        ls_doc TYPE ty_doc_key,
        ls_range LIKE LINE OF lt_range,
        ls_flow TYPE ty_flow_out,
        lv_new TYPE i,
        lv_round TYPE i,
        lv_chunk_count TYPE i.

  lt_frontier = gt_seed_docs.
  LOOP AT lt_frontier INTO ls_doc.
    INSERT ls_doc INTO TABLE gt_seen_docs.
  ENDLOOP.

  DO c_max_flow_rounds TIMES.
    lv_round = sy-index.
    CLEAR lt_range.
    LOOP AT lt_frontier INTO ls_doc.
      CLEAR ls_range.
      ls_range-sign = 'I'.
      ls_range-option = 'EQ'.
      ls_range-low = ls_doc-vbeln.
      APPEND ls_range TO lt_range.
    ENDLOOP.
    IF lt_range[] IS INITIAL.
      EXIT.
    ENDIF.

    CLEAR lt_round.
    CLEAR lt_range.
    lv_chunk_count = 0.
    LOOP AT lt_frontier INTO ls_doc.
      CLEAR ls_range.
      ls_range-sign = 'I'.
      ls_range-option = 'EQ'.
      ls_range-low = ls_doc-vbeln.
      APPEND ls_range TO lt_range.
      lv_chunk_count = lv_chunk_count + 1.
      IF lv_chunk_count >= c_doc_chunk.
        PERFORM select_flow_chunk USING lt_range CHANGING lt_round.
        CLEAR lt_range.
        lv_chunk_count = 0.
      ENDIF.
    ENDLOOP.
    IF lt_range[] IS NOT INITIAL.
      PERFORM select_flow_chunk USING lt_range CHANGING lt_round.
    ENDIF.
    IF lt_round[] IS INITIAL.
      EXIT.
    ENDIF.

    CLEAR lt_next.
    lv_new = 0.
    LOOP AT lt_round INTO ls_flow.
      APPEND ls_flow TO gt_flow.
      IF ls_flow-vbtyp_v = 'C'.
        PERFORM append_doc USING ls_flow-vbelv CHANGING gt_order_keys.
      ENDIF.
      IF ls_flow-vbtyp_n = 'C'.
        PERFORM append_doc USING ls_flow-vbeln CHANGING gt_order_keys.
      ENDIF.
      READ TABLE gt_seen_docs WITH TABLE KEY vbeln = ls_flow-vbelv
        TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        ls_doc-vbeln = ls_flow-vbelv.
        INSERT ls_doc INTO TABLE gt_seen_docs.
        INSERT ls_doc INTO TABLE lt_next.
        lv_new = lv_new + 1.
      ENDIF.
      READ TABLE gt_seen_docs WITH TABLE KEY vbeln = ls_flow-vbeln
        TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        ls_doc-vbeln = ls_flow-vbeln.
        INSERT ls_doc INTO TABLE gt_seen_docs.
        INSERT ls_doc INTO TABLE lt_next.
        lv_new = lv_new + 1.
      ENDIF.
    ENDLOOP.
    lt_frontier = lt_next.
    IF lv_new = 0.
      EXIT.
    ENDIF.
  ENDDO.

  SORT gt_flow BY vbelv posnv vbeln posnn vbtyp_v vbtyp_n erdat.
  DELETE ADJACENT DUPLICATES FROM gt_flow
    COMPARING vbelv posnv vbeln posnn vbtyp_v vbtyp_n erdat.

  IF lv_round = c_max_flow_rounds.
    MESSAGE 'VBFA expansion reached the maximum rounds; review flow completeness' TYPE 'W'.
  ENDIF.
ENDFORM.

FORM select_flow_chunk USING it_range TYPE ty_t_doc_range
                      CHANGING ct_flow TYPE STANDARD TABLE.
  DATA lt_flow_chunk TYPE STANDARD TABLE OF ty_flow_out.
  IF it_range[] IS INITIAL.
    RETURN.
  ENDIF.
  SELECT mandt vbelv posnv vbeln posnn vbtyp_v vbtyp_n rfmng meins
         rfwrt waers plmin erdat aedat matnr bwart stufe fplnr fpltr mjahr
    FROM vbfa INTO TABLE lt_flow_chunk
    WHERE vbelv IN it_range OR vbeln IN it_range.
  APPEND LINES OF lt_flow_chunk TO ct_flow.
ENDFORM.

FORM load_sd_documents.
  DATA: lt_range TYPE RANGE OF vbeln_va,
        ls_range LIKE LINE OF lt_range,
        ls_doc TYPE ty_doc_key,
        ls_bill TYPE ty_billing_out.

  LOOP AT gt_seen_docs INTO ls_doc.
    CLEAR ls_range.
    ls_range-sign = 'I'.
    ls_range-option = 'EQ'.
    ls_range-low = ls_doc-vbeln.
    APPEND ls_range TO lt_range.
  ENDLOOP.

  IF lt_range[] IS NOT INITIAL.
    SELECT a~mandt a~vbeln b~posnr a~erdat a~lfdat a~wadat a~wadat_ist
           a~vkorg a~kunag a~lfart a~vbtyp b~matnr b~werks b~lfimg
           b~vrkme b~shkzg b~bwart b~netwr b~vbelv b~posnv b~vgbel b~vgpos
      FROM likp AS a INNER JOIN lips AS b
        ON b~mandt = a~mandt AND b~vbeln = a~vbeln
      INTO CORRESPONDING FIELDS OF TABLE gt_deliveries
      WHERE a~vbeln IN lt_range.

    SELECT a~mandt a~vbeln b~posnr a~fkart a~vbtyp a~fkdat a~bukrs a~vkorg
           a~kunag a~waerk b~netwr b~mwsbp a~belnr a~gjahr a~fksto a~sfakn
           a~xblnr a~zuonr b~fkimg b~fklmg b~shkzg b~matnr b~fbuda b~prsdt
           b~aubel b~aupos b~vbelv b~posnv b~vgbel b~vgpos
      FROM vbrk AS a INNER JOIN vbrp AS b
        ON b~mandt = a~mandt AND b~vbeln = a~vbeln
      INTO CORRESPONDING FIELDS OF TABLE gt_billings
      WHERE a~vbeln IN lt_range.
  ENDIF.

  LOOP AT gt_billings INTO ls_bill.
    PERFORM append_doc USING ls_bill-aubel CHANGING gt_order_keys.
    PERFORM append_fi_key USING ls_bill-bukrs ls_bill-belnr ls_bill-gjahr
                         CHANGING gt_bill_fi_keys.
  ENDLOOP.

  "AUBEL/AUPOS is the direct order reference. Add any late or custom flow
  "rows found in VBRP before reloading the order population.
  LOOP AT gt_billings INTO ls_bill.
    IF ls_bill-aubel IS NOT INITIAL.
      PERFORM append_doc USING ls_bill-aubel CHANGING gt_order_keys.
    ENDIF.
  ENDLOOP.

  IF gt_order_keys[] IS NOT INITIAL.
    CLEAR gt_orders.
    SELECT a~mandt a~vbeln b~posnr a~auart a~audat a~erdat a~aedat
           a~vkorg a~vtweg a~spart a~kunnr a~bstnk a~ktext
           b~netwr b~waerk b~matnr b~arktx b~werks b~kwmeng b~vrkme
           b~lfrel b~fkrel b~abgru b~erlre b~vgbel b~vgpos
      FROM vbak AS a INNER JOIN vbap AS b
        ON b~mandt = a~mandt AND b~vbeln = a~vbeln
      INTO CORRESPONDING FIELDS OF TABLE gt_orders
      FOR ALL ENTRIES IN gt_order_keys
      WHERE a~vbeln = gt_order_keys-vbeln.
  ENDIF.

  SORT gt_orders BY vbeln posnr.
  DELETE ADJACENT DUPLICATES FROM gt_orders COMPARING vbeln posnr.
  SORT gt_billings BY vbeln posnr.
  DELETE ADJACENT DUPLICATES FROM gt_billings COMPARING vbeln posnr.
ENDFORM.

FORM load_bseg_for_keys USING it_keys TYPE ty_t_fi_key.
  DATA lt_bseg TYPE STANDARD TABLE OF ty_bseg_raw.
  IF it_keys[] IS INITIAL.
    RETURN.
  ENDIF.
  IF s_hkont[] IS INITIAL.
    SELECT mandt bukrs belnr gjahr buzei umsks zumsk shkzg dmbtr wrbtr
           zuonr sgtxt hkont kunnr vbeln vbel2 posn2 rebzg rebzj rebzz
           augbl auggj xref1 xref2 xref3 prctr matnr werks
      FROM bseg INTO TABLE lt_bseg
      FOR ALL ENTRIES IN it_keys
      WHERE bukrs = it_keys-bukrs
        AND belnr = it_keys-belnr
        AND gjahr = it_keys-gjahr.
  ELSE.
    SELECT mandt bukrs belnr gjahr buzei umsks zumsk shkzg dmbtr wrbtr
           zuonr sgtxt hkont kunnr vbeln vbel2 posn2 rebzg rebzj rebzz
           augbl auggj xref1 xref2 xref3 prctr matnr werks
      FROM bseg INTO TABLE lt_bseg
      FOR ALL ENTRIES IN it_keys
      WHERE bukrs = it_keys-bukrs
        AND belnr = it_keys-belnr
        AND gjahr = it_keys-gjahr
        AND hkont IN s_hkont.
  ENDIF.
  APPEND LINES OF lt_bseg TO gt_bseg_raw.
ENDFORM.

FORM load_fi_documents.
  DATA: lt_bkpf_period TYPE STANDARD TABLE OF ty_bkpf_out,
        lt_bkpf_bill TYPE STANDARD TABLE OF ty_bkpf_out,
        ls_bkpf TYPE ty_bkpf_out,
        ls_bill_key TYPE ty_fi_key,
        ls_bseg TYPE ty_bseg_raw,
        ls_line TYPE ty_fi_line_out,
        ls_key TYPE ty_fi_key.

  LOOP AT gt_bill_fi_keys INTO ls_bill_key.
    INSERT ls_bill_key INTO TABLE gt_fi_keys.
  ENDLOOP.

  IF gt_bill_fi_keys[] IS NOT INITIAL.
    SELECT mandt bukrs belnr gjahr blart bldat budat cpudt cputm usnam
           tcode xblnr stblg stjah bktxt waers bstat awtyp awkey stodt
      FROM bkpf INTO CORRESPONDING FIELDS OF TABLE lt_bkpf_bill
      FOR ALL ENTRIES IN gt_bill_fi_keys
      WHERE bukrs = gt_bill_fi_keys-bukrs
        AND belnr = gt_bill_fi_keys-belnr
        AND gjahr = gt_bill_fi_keys-gjahr.
    APPEND LINES OF lt_bkpf_bill TO gt_bkpf.
  ENDIF.

  IF p_fiall = 'X' AND s_budat[] IS NOT INITIAL.
    SELECT mandt bukrs belnr gjahr blart bldat budat cpudt cputm usnam
           tcode xblnr stblg stjah bktxt waers bstat awtyp awkey stodt
      FROM bkpf INTO CORRESPONDING FIELDS OF TABLE lt_bkpf_period
      WHERE bukrs IN s_bukrs AND budat IN s_budat.
    APPEND LINES OF lt_bkpf_period TO gt_bkpf.
    LOOP AT lt_bkpf_period INTO ls_bkpf.
      PERFORM append_fi_key USING ls_bkpf-bukrs ls_bkpf-belnr ls_bkpf-gjahr
                           CHANGING gt_fi_keys.
    ENDLOOP.
  ENDIF.

  SORT gt_bkpf BY bukrs belnr gjahr.
  DELETE ADJACENT DUPLICATES FROM gt_bkpf COMPARING bukrs belnr gjahr.

  CLEAR gt_bseg_raw.
  IF gt_fi_keys[] IS NOT INITIAL.
    PERFORM load_bseg_for_keys USING gt_fi_keys.
  ENDIF.

  SORT gt_bkpf BY bukrs belnr gjahr.
  LOOP AT gt_bseg_raw INTO ls_bseg.
    CLEAR ls_line.
    MOVE-CORRESPONDING ls_bseg TO ls_line.
    READ TABLE gt_bkpf INTO ls_bkpf
      WITH KEY bukrs = ls_bseg-bukrs belnr = ls_bseg-belnr
               gjahr = ls_bseg-gjahr BINARY SEARCH.
    IF sy-subrc = 0.
      ls_line-budat = ls_bkpf-budat.
      ls_line-blart = ls_bkpf-blart.
      ls_line-waers = ls_bkpf-waers.
      READ TABLE gt_bill_fi_keys INTO ls_key
        WITH TABLE KEY bukrs = ls_bseg-bukrs belnr = ls_bseg-belnr
                      gjahr = ls_bseg-gjahr.
      IF sy-subrc = 0.
        ls_line-source_scope = 'SD_BILLING'.
      ELSE.
        ls_line-source_scope = 'FI_PERIOD'.
      ENDIF.
    ENDIF.
    APPEND ls_line TO gt_fi_lines.
  ENDLOOP.
  SORT gt_fi_lines BY bukrs belnr gjahr buzei.
  DELETE ADJACENT DUPLICATES FROM gt_fi_lines
    COMPARING bukrs belnr gjahr buzei hkont.
ENDFORM.

FORM customer_extension.
  "Reserved for the customer's acceptance / revenue-recognition Z table.
  "Do not activate guessed table names. Once the customer confirms the
  "table and key, append one event-grain output file here with source table,
  "document number, order/item, recognition date, amount and reversal key.
ENDFORM.

FORM struct_to_csv USING p_data TYPE any
                  CHANGING p_line TYPE string.
  DATA: lo_descr TYPE REF TO cl_abap_structdescr,
        lt_comp TYPE cl_abap_structdescr=>component_table,
        ls_comp LIKE LINE OF lt_comp,
        lv_value TYPE string,
        lv_first TYPE c LENGTH 1.
  FIELD-SYMBOLS <value> TYPE any.

  CLEAR p_line.
  lv_first = 'X'.
  lo_descr ?= cl_abap_typedescr=>describe_by_data( p_data ).
  lt_comp = lo_descr->get_components( ).
  LOOP AT lt_comp INTO ls_comp.
    ASSIGN COMPONENT ls_comp-name OF STRUCTURE p_data TO <value>.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.
    CLEAR lv_value.
    WRITE <value> TO lv_value NO-GROUPING.
    REPLACE ALL OCCURRENCES OF '"' IN lv_value WITH '""'.
    IF lv_value CS c_sep OR lv_value CS '"' OR lv_value CS cl_abap_char_utilities=>cr_lf.
      CONCATENATE '"' lv_value '"' INTO lv_value.
    ENDIF.
    IF lv_first = 'X'.
      p_line = lv_value.
      lv_first = space.
    ELSE.
      CONCATENATE p_line c_sep lv_value INTO p_line.
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM write_header USING p_file TYPE string p_data TYPE any.
  DATA lv_line TYPE string.
  PERFORM struct_to_csv USING p_data CHANGING lv_line.
  TRANSFER lv_line TO p_file.
ENDFORM.

FORM write_outputs.
  DATA: lv_file TYPE string,
        lv_stamp TYPE char14,
        ls_order TYPE ty_order_out,
        ls_delivery TYPE ty_delivery_out,
        ls_bill TYPE ty_billing_out,
        ls_flow TYPE ty_flow_out,
        ls_bkpf TYPE ty_bkpf_out,
        ls_fi TYPE ty_fi_line_out,
        ls_control TYPE ty_control_out,
        lv_line TYPE string.

  CONCATENATE sy-datum sy-uzeit INTO lv_stamp.
  gv_run_timestamp = lv_stamp.

  CONCATENATE p_path '/' p_pref '_' lv_stamp '_order_item.csv' INTO lv_file.
  OPEN DATASET lv_file FOR OUTPUT IN TEXT MODE ENCODING UTF-8 WITH SMART LINEFEED.
  IF sy-subrc <> 0. MESSAGE 'Cannot open order output file' TYPE 'E'. ENDIF.
  READ TABLE gt_orders INTO ls_order INDEX 1.
  PERFORM write_header USING lv_file ls_order.
  LOOP AT gt_orders INTO ls_order.
    PERFORM struct_to_csv USING ls_order CHANGING lv_line.
    TRANSFER lv_line TO lv_file.
  ENDLOOP.
  CLOSE DATASET lv_file.

  CONCATENATE p_path '/' p_pref '_' lv_stamp '_delivery_item.csv' INTO lv_file.
  OPEN DATASET lv_file FOR OUTPUT IN TEXT MODE ENCODING UTF-8 WITH SMART LINEFEED.
  IF sy-subrc <> 0. MESSAGE 'Cannot open delivery output file' TYPE 'E'. ENDIF.
  READ TABLE gt_deliveries INTO ls_delivery INDEX 1.
  PERFORM write_header USING lv_file ls_delivery.
  LOOP AT gt_deliveries INTO ls_delivery.
    PERFORM struct_to_csv USING ls_delivery CHANGING lv_line.
    TRANSFER lv_line TO lv_file.
  ENDLOOP.
  CLOSE DATASET lv_file.

  CONCATENATE p_path '/' p_pref '_' lv_stamp '_billing_event.csv' INTO lv_file.
  OPEN DATASET lv_file FOR OUTPUT IN TEXT MODE ENCODING UTF-8 WITH SMART LINEFEED.
  IF sy-subrc <> 0. MESSAGE 'Cannot open billing output file' TYPE 'E'. ENDIF.
  READ TABLE gt_billings INTO ls_bill INDEX 1.
  PERFORM write_header USING lv_file ls_bill.
  LOOP AT gt_billings INTO ls_bill.
    PERFORM struct_to_csv USING ls_bill CHANGING lv_line.
    TRANSFER lv_line TO lv_file.
  ENDLOOP.
  CLOSE DATASET lv_file.

  CONCATENATE p_path '/' p_pref '_' lv_stamp '_document_flow.csv' INTO lv_file.
  OPEN DATASET lv_file FOR OUTPUT IN TEXT MODE ENCODING UTF-8 WITH SMART LINEFEED.
  IF sy-subrc <> 0. MESSAGE 'Cannot open flow output file' TYPE 'E'. ENDIF.
  READ TABLE gt_flow INTO ls_flow INDEX 1.
  PERFORM write_header USING lv_file ls_flow.
  LOOP AT gt_flow INTO ls_flow.
    PERFORM struct_to_csv USING ls_flow CHANGING lv_line.
    TRANSFER lv_line TO lv_file.
  ENDLOOP.
  CLOSE DATASET lv_file.

  CONCATENATE p_path '/' p_pref '_' lv_stamp '_fi_header.csv' INTO lv_file.
  OPEN DATASET lv_file FOR OUTPUT IN TEXT MODE ENCODING UTF-8 WITH SMART LINEFEED.
  IF sy-subrc <> 0. MESSAGE 'Cannot open FI header output file' TYPE 'E'. ENDIF.
  READ TABLE gt_bkpf INTO ls_bkpf INDEX 1.
  PERFORM write_header USING lv_file ls_bkpf.
  LOOP AT gt_bkpf INTO ls_bkpf.
    PERFORM struct_to_csv USING ls_bkpf CHANGING lv_line.
    TRANSFER lv_line TO lv_file.
  ENDLOOP.
  CLOSE DATASET lv_file.

  CONCATENATE p_path '/' p_pref '_' lv_stamp '_fi_line.csv' INTO lv_file.
  OPEN DATASET lv_file FOR OUTPUT IN TEXT MODE ENCODING UTF-8 WITH SMART LINEFEED.
  IF sy-subrc <> 0. MESSAGE 'Cannot open FI line output file' TYPE 'E'. ENDIF.
  READ TABLE gt_fi_lines INTO ls_fi INDEX 1.
  PERFORM write_header USING lv_file ls_fi.
  LOOP AT gt_fi_lines INTO ls_fi.
    PERFORM struct_to_csv USING ls_fi CHANGING lv_line.
    TRANSFER lv_line TO lv_file.
  ENDLOOP.
  CLOSE DATASET lv_file.

  CLEAR ls_control.
  ls_control-run_timestamp = lv_stamp.
  ls_control-report_name = 'ZSD_REV_LIFECYCLE_EXTRACT'.
  ls_control-dataset = 'ORDER_ITEM'.
  ls_control-row_count = lines( gt_orders ).
  ls_control-control_note = 'Raw order/item rows; reconcile by currency and company'.
  APPEND ls_control TO gt_control.
  ls_control-dataset = 'DELIVERY_ITEM'.
  ls_control-row_count = lines( gt_deliveries ).
  ls_control-control_note = 'Raw delivery/item rows; preserve SHKZG and quantities'.
  APPEND ls_control TO gt_control.
  ls_control-dataset = 'BILLING_EVENT'.
  ls_control-row_count = lines( gt_billings ).
  ls_control-control_note = 'Each billing item retained; do not net in SAP'.
  APPEND ls_control TO gt_control.
  ls_control-dataset = 'DOCUMENT_FLOW'.
  ls_control-row_count = lines( gt_flow ).
  ls_control-control_note = 'VBFA closure; review maximum-round warning'.
  APPEND ls_control TO gt_control.
  ls_control-dataset = 'FI_HEADER'.
  ls_control-row_count = lines( gt_bkpf ).
  ls_control-control_note = 'Billing-linked plus optional FI-period headers'.
  APPEND ls_control TO gt_control.
  ls_control-dataset = 'FI_LINE'.
  ls_control-row_count = lines( gt_fi_lines ).
  ls_control-control_note = 'BSEG lines; account/currency controls required downstream'.
  APPEND ls_control TO gt_control.

  CONCATENATE p_path '/' p_pref '_' lv_stamp '_control.csv' INTO lv_file.
  OPEN DATASET lv_file FOR OUTPUT IN TEXT MODE ENCODING UTF-8 WITH SMART LINEFEED.
  IF sy-subrc <> 0. MESSAGE 'Cannot open control output file' TYPE 'E'. ENDIF.
  READ TABLE gt_control INTO ls_control INDEX 1.
  PERFORM write_header USING lv_file ls_control.
  LOOP AT gt_control INTO ls_control.
    PERFORM struct_to_csv USING ls_control CHANGING lv_line.
    TRANSFER lv_line TO lv_file.
  ENDLOOP.
  CLOSE DATASET lv_file.
ENDFORM.
