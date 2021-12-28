import pubsub

import uart
import gpio

loopDone := false

// PubSub Topics
topicBarcodeRead ::= "device:readBarcode" // Barcode read from scanner
topicDisplayShow ::= "device:showOnDispl" // Information to be shown on I2C Display

sendToSerial serialPort/uart.Port barcodeData/string:
    print "Writing '$barcodeData' to LoRa module"
    serialPort.write barcodeData
        --wait=true
    print "$barcodeData.size bytes written."

readFromSerialOne serialPort/uart.Port:
    print "Serial data 1 listener started."

    task::
        while true:
            sleep --ms=50   
            sData := serialPort.read
            if not sData:
                break
            sapData := sData.to_string
            print "->$sapData"
            if sapData.size > 10:
                print "Calling display."
                // Split string and notify display container
                pubsub.publish topicDisplayShow "#$sapData"

readFromSerialTwo serialPort/uart.Port loraPort/uart.Port:
    print "Serial data 2 listener started."

    task::
        while true:
            sleep 
                --ms=50   
            sData := serialPort.read
            if not sData:
                break
            // Data received check for right length
            print "->$sData.to_string"
            if sData.to_string.size == 14:
                print "Valid EAN - Inform Display and LoRa Container"
                pubsub.publish topicDisplayShow "Requesting EAN/$sData.to_string[..13]" //remove 0x0D, comes with scanner
                sendToSerial loraPort sData.to_string[..13]

main:
    print "Initialize serial port 1 (LoRa-Module)"
    serialOne := uart.Port 
        --baud_rate=9600 
        --tx=gpio.Pin 17
        --rx=gpio.Pin 16

    print "Initialize serial port 2 (Barcode Reader)"
    serialTwo := uart.Port
        --baud_rate=9600
        --tx=gpio.Pin 2
        --rx=gpio.Pin 4

    // Start listener
    task:: readFromSerialOne serialOne
    task:: readFromSerialTwo serialTwo serialOne

    // currently endless
    while loopDone==false:
        sleep
            --ms=50

    serialOne.close
    serialTwo.close
    print "Closed the ports"