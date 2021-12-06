import pubsub

import gpio
import i2c

import ssd1306 show *
import pixel_display show *
import pixel_display.texture show *
import pixel_display.two_color show *
import font show *

loopDone := false

// PubSub Topics
topicBarcodeRead ::= "device:readBarcode" // Barcode read from scanner
topicDataReceive ::= "device:dataFromSAP" // Received EAN data from SAP System
topicDisplayShow ::= "device:showOnDispl" // Information to be shown on I2C Display


get_display -> TwoColorPixelDisplay:
    scl := gpio.Pin 22 // On Wemos D1 R32
    sda := gpio.Pin 21 // On Wemos D1 R32
    bus := i2c.Bus
        --sda=sda
        --scl=scl
        --frequency=800_000
    devices := bus.scan
    if not devices.contains SSD1306_ID: throw "No SSD1306 display found"
    driver := SSD1306 (bus.device 0x3c)
    return TwoColorPixelDisplay driver

main:
    print "Aquiring font and initialize display."
    sans ::= Font.get "sans10"
    display ::= get_display
    print display
    context := display.context --landscape --color=BLACK --font=sans
    display.remove_all
    display.text context 1 12 "Scan EAN-Code!"
    display.draw

    pubsub.subscribe topicDisplayShow: | msg/pubsub.Message |
        print "Received message '$msg.payload.to_string'"
        display.remove_all
        i := 1
        lineHeight := 12
        msg.payload.to_string.split "/":
            print it
            y := i * lineHeight + i
            display.text context 1 y "$it"
            i++
        display.draw