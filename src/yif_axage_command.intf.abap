INTERFACE yif_axage_command
  PUBLIC .
  TYPES tv_category TYPE string.
  CONSTANTS:
    c_open TYPE tv_category VALUE 'TAKE_FROM_BOX',
    c_spell TYPE tv_category VALUE 'CAST_SPELL'.

  DATA category TYPE string.
  METHODS execute
    IMPORTING engine TYPE REF TO ycl_axage_engine
              log TYPE REF TO ycl_axage_log.

ENDINTERFACE.
