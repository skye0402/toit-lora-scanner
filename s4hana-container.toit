import net
import encoding.json
import net.x509 as net
import .debuglib.http as http

import pubsub

import uart
import gpio

loopDone := false
host := "enter.your.host.here:8888"

sendToSerial serialPort/uart.Port productData/string:
  print "Writing '$productData' to LoRa module"
  serialPort.write productData
      --wait=true
  print "$productData.size bytes written."

readFromSerialOne serialPort/uart.Port connection/http.Connection:
  print "Serial data 1 listener started (LoRa)."

  task::
      while true:
          sleep --ms=50   
          sData := serialPort.read
          if not sData:
              break
          reqData := sData.to_string
          print "->$reqData"
          if reqData.size == 13:
            getProductDatafromS4 connection reqData serialPort
          else:
            print "Unexpected data received from LoRa module."

getProductDatafromS4 connection/http.Connection reqData/string serialPort/uart.Port:
  print "sending http request for $reqData."
  urlGtin13 := "/sap/opu/odata/sap/API_PRODUCT_SRV/A_ProductUnitsOfMeasureEAN?%24filter=ProductStandardID%20eq%20%27$reqData%27"
  request := connection.new_request "GET" urlGtin13
  request.headers.add "Accept" "application/json"
  response := request.send

  decoded := json.decode_stream response
  results /List? := null
  product /string := ""
  caught := catch --trace: // trace to make other exceptions visible
    results = decoded["d"]["results"]
    product = results[0]["Product"]
  if caught == "WRONG_OBJECT_TYPE":
    print "That didn't work."
  else:
    print "Read $decoded.size bytes from http://$host/ with status $response.status_message status code $response.status_code"
    // Get material description
    urlProdDesc := "/sap/opu/odata/sap/API_PRODUCT_SRV/A_ProductDescription(Product='$product',Language='EN')"
    request = connection.new_request "GET" urlProdDesc
    request.headers.add "Accept" "application/json"
    response = request.send
    decoded = json.decode_stream response

    prodDesc /string := ""
    caught = catch --trace: // trace to make other exceptions visible
      prodDesc = decoded["d"]["ProductDescription"]
      if caught == "WRONG_OBJECT_TYPE":
        print "That didn't work."
      else:
        print "Product code for GTIN-13 $reqData is #$product description '$prodDesc'."
        sendToSerial serialPort "$product/$prodDesc"

main:
  print "Initialize serial port 1 (LoRa-Module)"
  serialOne := uart.Port 
      --baud_rate=9600 
      --tx=gpio.Pin 17
      --rx=gpio.Pin 16

  // http socket preparation
  network_interface := net.open
  socket := network_interface.tcp_connect host 50000
  connection := http.Connection socket host     

  // Start listener
  task:: readFromSerialOne serialOne connection

  // currently endless
  while loopDone==false:
      sleep
          --ms=50

  connection.close
  serialOne.close
  print "Closed the ports"