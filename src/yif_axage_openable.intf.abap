INTERFACE yif_axage_openable
  PUBLIC.

  METHODS get_content
    RETURNING VALUE(content) TYPE REF TO ycl_axage_thing.

  METHODS open
    IMPORTING things TYPE REF TO ycl_axage_thing
              !log   TYPE REF TO ycl_axage_log.

  METHODS details
    IMPORTING location TYPE REF TO ycl_axage_thing.

  METHODS is_open
    RETURNING VALUE(result) TYPE abap_bool.

ENDINTERFACE.
