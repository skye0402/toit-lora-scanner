# Toit: Proof of concept - Connecting to SAP S/4HANA
This app connects to SAP S/4HANA OData services to resolve a GTIN-13 code into a product number and description.
For that we use 2 ESP32 with LoRa and one barcode reader connected to UART

## Process
Scan a GTIN-13 barcodes, then transmit it via LoRa to SAP S/4HANA and back with data. Display on OLED screen.
