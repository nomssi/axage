INTERFACE zif_axage_openable
  PUBLIC.

  METHODS get_content
    RETURNING VALUE(content) TYPE REF TO zcl_axage_thing_list.

  METHODS open
    IMPORTING things        TYPE REF TO zcl_axage_thing_list
    RETURNING VALUE(result) TYPE REF TO zcl_axage_result.

  METHODS is_open
    RETURNING VALUE(result) TYPE abap_bool.

ENDINTERFACE.
