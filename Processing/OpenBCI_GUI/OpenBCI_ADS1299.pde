
///////////////////////////////////////////////////////////////////////////////
//
// This class configures and manages the connection to the OpenBCI shield for
// the Arduino.  The connection is implemented via a Serial connection.
// The OpenBCI is configured using single letter text commands sent from the
// PC to the Arduino.  The EEG data streams back from the Arduino to the PC
// continuously (once started).  This class defaults to using binary transfer
// for normal operation.
//
// Created: Chip Audette, Oct 2013
// Modified: through April 2014
// Modified again: Conor Russomanno Sept-Oct 2014
//
// Note: this class now expects the data format produced by OpenBCI V3.
//
/////////////////////////////////////////////////////////////////////////////

//import processing.serial.*;
import java.io.OutputStream; //for logging raw bytes to an output file

final String command_stop = "s";
// final String command_startText = "x";
final String command_startBinary = "b";
final String command_startBinary_wAux = "n";  // already doing this with 'b' now
final String command_startBinary_4chan = "v";  // not necessary now
final String command_activateFilters = "f";  // swithed from 'F' to 'f'  ... but not necessary because taken out of hardware code
final String command_deactivateFilters = "g";  // not necessary anymore 

final String[] command_deactivate_channel = {"1", "2", "3", "4", "5", "6", "7", "8"};
final String[] command_activate_channel = {"!", "@", "#", "$", "%", "^", "&", "*"};

final String[] command_deactivate_channel_daisy = {"q", "w", "e", "r", "t", "y", "u", "i"};
final String[] command_activate_channel_daisy = {"Q", "W", "E", "R", "T", "Y", "U", "I"};

//everything below is now deprecated...
// final String[] command_activate_leadoffP_channel = {"!", "@", "#", "$", "%", "^", "&", "*"};  //shift + 1-8
// final String[] command_deactivate_leadoffP_channel = {"Q", "W", "E", "R", "T", "Y", "U", "I"};   //letters (plus shift) right below 1-8
// final String[] command_activate_leadoffN_channel = {"A", "S", "D", "F", "G", "H", "J", "K"}; //letters (plus shift) below the letters below 1-8
// final String[] command_deactivate_leadoffN_channel = {"Z", "X", "C", "V", "B", "N", "M", "<"};   //letters (plus shift) below the letters below the letters below 1-8
// final String command_biasAuto = "`";
// final String command_biasFixed = "~";

// ArrayList defaultChannelSettings;

class OpenBCI_ADS1299 {
  
  //final static int DATAMODE_TXT = 0;
  final static int DATAMODE_BIN = 2;
  final static int DATAMODE_BIN_WAUX = 1;  //switched to this value so that receiving Accel data is now the default
  //final static int DATAMODE_BIN_4CHAN = 4;
  
  final static int STATE_NOCOM = 0;
  final static int STATE_COMINIT = 1;
  final static int STATE_SYNCWITHHARDWARE = 2;
  final static int STATE_NORMAL = 3;
  final static int STATE_STOPPED = 4;
  final static int COM_INIT_MSEC = 3000; //you may need to vary this for your computer or your Arduino
  
  int[] measured_packet_length = {0,0,0,0,0};
  int measured_packet_length_ind = 0;
  int known_packet_length_bytes = 0;
  
  final static byte BYTE_START = (byte)0xA0;
  final static byte BYTE_END = (byte)0xC0;
  
  int prefered_datamode = DATAMODE_BIN_WAUX;
  
  int state = STATE_NOCOM;
  int dataMode = -1;
  int prevState_millis = 0;
  //byte[] serialBuff;
  //int curBuffIndex = 0;
  DataPacket_ADS1299 dataPacket;
  int nAuxValues;
  boolean isNewDataPacketAvailable = false;
  OutputStream output; //for debugging  WEA 2014-01-26
  int prevSampleIndex = 0;
  int serialErrorCounter = 0;
  
  final float fs_Hz = 250.0f;  //sample rate used by OpenBCI board...set by its Arduino code
  final float ADS1299_Vref = 4.5f;  //reference voltage for ADC in ADS1299.  set by its hardware
  float ADS1299_gain = 24;  //assumed gain setting for ADS1299.  set by its Arduino code
  float scale_fac_uVolts_per_count = ADS1299_Vref / (pow(2,23)-1) / ADS1299_gain  * 1000000.f; //ADS1299 datasheet Table 7, confirmed through experiment
  //float LIS3DH_full_scale_G = 4;  // +/- 4G, assumed full scale setting for the accelerometer
  //final float scale_fac_accel_G_per_count = 0.002;  //data sheet, 2 mg per "digit", which I assume is per "count"
  final float scale_fac_accel_G_per_count = 1.0;
  final float leadOffDrive_amps = 6.0e-9;  //6 nA, set by its Arduino code
  
  boolean isBiasAuto = true;

  final char[] EOT = {'$','$','$'};
  char[] prev3chars = {'#','#','#'};

  String defaultChannelSettings = "";
  String daisyOrNot = "";
  
  //constructors
  OpenBCI_ADS1299() {};  //only use this if you simply want access to some of the constants
  OpenBCI_ADS1299(PApplet applet, String comPort, int baud, int nEEGValuesPerPacket, boolean useAux, int nAuxValuesPerPacket) {
    nAuxValues=nAuxValuesPerPacket;
    
    //choose data mode
    println("OpenBCI_ADS1299: prefered_datamode = " + prefered_datamode + ", nValuesPerPacket = " + nEEGValuesPerPacket);
    if (prefered_datamode == DATAMODE_BIN_WAUX) {
      if (!useAux) {
        //must be requesting the aux data, so change the referred data mode
        prefered_datamode = DATAMODE_BIN;
        nAuxValues = 0;
        //println("OpenBCI_ADS1299: nAuxValuesPerPacket = " + nAuxValuesPerPacket + " so setting prefered_datamode to " + prefered_datamode);
      }
    }

    println(" a");

    dataMode = prefered_datamode;

    //allocate space for data packet
    dataPacket = new DataPacket_ADS1299(nEEGValuesPerPacket,nAuxValuesPerPacket);

    println(" b");

    //prepare the serial port  ... close if open
    println("port is open? ... " + portIsOpen);
    if(portIsOpen == true){
      closeSerialPort();
    }

    println(" i");
    openSerialPort(applet, comPort, baud);
    println(" j");
    
    //open file for raw bytes
    //output = createOutput("rawByteDumpFromProcessing.bin");  //for debugging  WEA 2014-01-26
  }
  
  // //manage the serial port  
  private int openSerialPort(PApplet applet, String comPort, int baud) {
    
    try {
      println("OpenBCI_ADS1299: attempting to open serial port " + openBCI_portName);
      serial_openBCI = new Serial(applet,comPort,baud); //open the com port
      serial_openBCI.clear(); // clear anything in the com port's buffer    
      portIsOpen = true;
      println("port is open (t)? ... " + portIsOpen);
      changeState(STATE_COMINIT);
      return 0;
    } 
    catch (RuntimeException e){
      if (e.getMessage().contains("<init>")) {
        System.out.println("port in use, trying again later...");
        portIsOpen = false;
      }
      return 0;
    }
  }

  public int changeState(int newState) {
    state = newState;
    prevState_millis = millis();
    return 0;
  }

  int finalizeCOMINIT() {
    // //wait specified time for COM/serial port to initialize
    // if (state == STATE_COMINIT) {
    //   // println("Initializing Serial: millis() = " + millis());
    //   if ((millis() - prevState_millis) > COM_INIT_MSEC) {
    //     //serial_openBCI.write(command_activates + "\n"); println("Processing: OpenBCI_ADS1299: activating filters");
    //     println("OpenBCI_ADS1299: State = NORMAL");
        changeState(STATE_NORMAL);
    //     // startRunning();
    //   }
    // }
    return 0;
  }    

  int closeSerialPort() {

    // if (serial_openBCI != null) {
    println(" d");
    portIsOpen = false;
    println(" e");
    serial_openBCI.clear();
    println(" e2");
    serial_openBCI.stop();
    println(" f");
    serial_openBCI = null;
    println(" g");
    state = STATE_NOCOM;
    println(" h");
    return 0;
  }
  
  //start the data transfer using the current mode
  // int startDataTransfer() {
  //   println("OpenBCI_ADS1299: startDataTransfer: using current dataMode..." + dataMode);
  //   return startDataTransfer(dataMode);
  // }
  
  // //start data trasnfer using the given mode
  // int startDataTransfer(int mode) {
  //   dataMode = mode;
  //   if (state == STATE_COMINIT) {
  //     println("OpenBCI_ADS1299: startDataTransfer: cannot start transfer...waiting for comms...");
  //     return -1;
  //   }
  //   // stopDataTransfer();
  //   // println("OpenBCI_ADS1299: startDataTransfer: received command for mode = " + mode);
  //   // switch (mode) {
  //   //   case DATAMODE_BIN:
  //   //     serial_openBCI.write(command_startBinary);// + "\n");
  //   //     // serial_openBCI.write(command_startBinary);
  //   //     println("OpenBCI_ADS1299: startDataTransfer: starting binary transfer");
  //   //     break;
  //   //   case DATAMODE_BIN_WAUX:
  //   //     serial_openBCI.write(command_startBinary_wAux);// + "\n");
  //   //     println("OpenBCI_ADS1299: startDataTransfer: starting binary transfer (with Aux)");
  //   //     break;
  //   // }

  //   return 0;
  // }

  void startDataTransfer(){
    if (serial_openBCI != null) {
      serial_openBCI.clear(); // clear anything in the com port's buffer
      // stopDataTransfer();
      openBCI.changeState(STATE_NORMAL);  // make sure it's now interpretting as binary
      println("writing \'" + command_startBinary + "\' to the serial port...");
      serial_openBCI.write(command_startBinary);
    }
  }
  
  void stopDataTransfer() {
    if (serial_openBCI != null) {
      serial_openBCI.clear(); // clear anything in the com port's buffer
      openBCI.changeState(STATE_STOPPED);  // make sure it's now interpretting as binary
      println("writing \'" + command_stop + "\' to the serial port...");
      serial_openBCI.write(command_stop);// + "\n");
    }
  }
  
  //read from the serial port
  int read() {  return read(false); }
  int read(boolean echoChar) {
    // print("State: " + state);
    //get the byte
    byte inByte = byte(serial_openBCI.read());

    //write the most recent char to the console
    if (echoChar){  //if not in interpret binary (NORMAL) mode
      // print(".");
      char inASCII = char(inByte); 
      if(isRunning == false && (millis() - timeSinceStopRunning) > 500){
        print(char(inByte));
      }

      //keep track of previous three chars coming from OpenBCI
      prev3chars[0] = prev3chars[1];
      prev3chars[1] = prev3chars[2];
      prev3chars[2] = inASCII;

      if(hardwareSyncStep == 1 && inASCII != '$'){
        daisyOrNot+=inASCII;
        //if hardware returns 8 because daisy is not attached, switch the GUI mode back to 8 channels
        // if(nchan == 16 && char(daisyOrNot.substring(daisyOrNot.length() - 1)) == '8'){
        if(nchan == 16 && daisyOrNot.charAt(daisyOrNot.length() - 1) == '8'){
          verbosePrint(" received from OpenBCI... Switching to nchan = 8 bc daisy is not present...");
          nchan = 8;
        }
      }

      if(hardwareSyncStep == 3 && inASCII != '$'){ //if we're retrieving channel settings from OpenBCI
        defaultChannelSettings+=inASCII;
      }

      //if the last three chars are $$$, it means we are moving on to the next stage of initialization
      if(prev3chars[0] == EOT[0] && prev3chars[1] == EOT[1] && prev3chars[2] == EOT[2]){
        verbosePrint(" > EOT detected...");
        // hardwareSyncStep++;
        prev3chars[2] = '#';
        if(hardwareSyncStep == 3){
          println("x");
          println(defaultChannelSettings);
          println("y");
          gui.cc.loadDefaultChannelSettings();
          println("z");
        }
        readyToSend = true; 
        // println(hardwareSyncStep);
        // syncWithHardware(); //haha, I'm getting very verbose with my naming... it's late...
      }  
    }
    
    //write raw unprocessed bytes to a binary data dump file
    if (output != null) {
      try {
       output.write(inByte);   //for debugging  WEA 2014-01-26
      } catch (IOException e) {
        System.err.println("OpenBCI_ADS1299: Caught IOException: " + e.getMessage());
        //do nothing
      }
    }
    
    interpretBinaryStream(inByte);  //new 2014-02-02 WEA
    return int(inByte);
  }

  /* **** Borrowed from Chris Viegl from his OpenBCI parser for BrainBay
  Modified by Joel Murphy and Conor Russomanno to read OpenBCI data
  Packet Parser for OpenBCI (1-N channel binary format):
  3-byte data values are stored in 'little endian' formant in AVRs
  so this protocol parser expects the lower bytes first.
  Start Indicator: 0xA0
  EXPECTING STANDARD PACKET LENGTH DON'T NEED: Packet_length  : 1 byte  (length = 4 bytes framenumber + 4 bytes per active channel + (optional) 4 bytes for 1 Aux value)
  Framenumber     : 1 byte (Sequential counter of packets)
  Channel 1 data  : 3 bytes 
  ...
  Channel 8 data  : 3 bytes
  Aux Values      : UP TO 6 bytes
  End Indcator    : 0xC0
  TOTAL OF 33 bytes ALL DAY
  ********************************************************************* */
  int nDataValuesInPacket = 0;
  int localByteCounter=0;
  int localChannelCounter=0;
  int PACKET_readstate = 0;
  // byte[] localByteBuffer = {0,0,0,0};
  byte[] localAdsByteBuffer = {0,0,0};
  byte[] localAccelByteBuffer = {0,0};

  void interpretBinaryStream(byte actbyte)
  { 
    //println("OpenBCI_ADS1299: interpretBinaryStream: PACKET_readstate " + PACKET_readstate);
    switch (PACKET_readstate) {
      case 0:  
         //look for header byte  
         if (actbyte == byte(0xA0)) {          // look for start indicator
          // println("OpenBCI_ADS1299: interpretBinaryStream: found 0xA0");
          PACKET_readstate++;
         } 
         break;
      case 1: 
        //check the packet counter
        // println("case 1");
        byte inByte = actbyte;
        dataPacket.sampleIndex = int(inByte); //changed by JAM
        if ((dataPacket.sampleIndex-prevSampleIndex) != 1) {
          if(dataPacket.sampleIndex != 0){  // if we rolled over, don't count as error
            serialErrorCounter++;
            println("OpenBCI_ADS1299: apparent sampleIndex jump from Serial data: " + prevSampleIndex + " to  " + dataPacket.sampleIndex + ".  Keeping packet. (" + serialErrorCounter + ")");
          }
        }
        prevSampleIndex = dataPacket.sampleIndex;
        localByteCounter=0;//prepare for next usage of localByteCounter
        localChannelCounter=0; //prepare for next usage of localChannelCounter
        PACKET_readstate++;
        break;
      case 2: 
        // get ADS channel values 
        // println("case 2");
        localAdsByteBuffer[localByteCounter] = actbyte;
        localByteCounter++;
        if (localByteCounter==3) {
          dataPacket.values[localChannelCounter] = interpret24bitAsInt32(localAdsByteBuffer);
          localChannelCounter++;
          if (localChannelCounter==8) { //nDataValuesInPacket) {  
            // all ADS channels arrived !
            //println("OpenBCI_ADS1299: interpretBinaryStream: localChannelCounter = " + localChannelCounter);
            PACKET_readstate++;
            if (prefered_datamode != DATAMODE_BIN_WAUX) PACKET_readstate++;  //if not using AUX, skip over the next readstate
            localByteCounter = 0;
            localChannelCounter = 0;
            //isNewDataPacketAvailable = true;  //tell the rest of the code that the data packet is complete
          } else { 
            //prepare for next data channel
            localByteCounter=0; //prepare for next usage of localByteCounter
          }
        }
        break;
      case 3:
        // get LIS3DH channel values 2 bytes times 3 axes
        // println("case 3");
        localAccelByteBuffer[localByteCounter] = actbyte;
        localByteCounter++;
        if (localByteCounter==2) {
          dataPacket.auxValues[localChannelCounter]  = interpret16bitAsInt32(localAccelByteBuffer);
          localChannelCounter++;
          if (localChannelCounter==nAuxValues) { //number of accelerometer axis) {  
            // all Accelerometer channels arrived !
            //println("OpenBCI_ADS1299: interpretBinaryStream: Accel Data: " + dataPacket.auxValues[0] + ", " + dataPacket.auxValues[1] + ", " + dataPacket.auxValues[2]);
            PACKET_readstate++;
            localByteCounter = 0;
            //isNewDataPacketAvailable = true;  //tell the rest of the code that the data packet is complete
          } else { 
            //prepare for next data channel
            localByteCounter=0; //prepare for next usage of localByteCounter
          }
        }
        break;
      case 4:
        //look for end byte
        // println("case 4");
        if (actbyte == byte(0xC0)) {    // if correct end delimiter found:
          // println("... 0xC0 found");
          //println("OpenBCI_ADS1299: interpretBinaryStream: found end byte. Setting isNewDataPacketAvailable to TRUE");
          isNewDataPacketAvailable = true; //original place for this.  but why not put it in the previous case block
        } else {
          serialErrorCounter++;
          println("Actbyte = " + actbyte);
          println("OpenBCI_ADS1299: interpretBinaryStream: expecteding end-of-packet byte is missing.  Discarding packet. (" + serialErrorCounter + ")");
        }
        PACKET_readstate=0;  // either way, look for next packet
        break;
      default: 
          //println("OpenBCI_ADS1299: Unknown byte: " + actbyte + " .  Continuing...");
          println("OpenBCI_ADS1299: interpretBinaryStream: Unknown byte.  Continuing...");
          PACKET_readstate=0;  // look for next packet
    }
  } // end of interpretBinaryStream


  //activate or deactivate an EEG channel...channel counting is zero through nchan-1
  public void changeChannelState(int Ichan,boolean activate) {
    if (serial_openBCI != null) {
      // if ((Ichan >= 0) && (Ichan < command_activate_channel.length)) {
      if ((Ichan >= 0)) {
        if (activate) {
          // serial_openBCI.write(command_activate_channel[Ichan]);
          gui.cc.powerUpChannel(Ichan);
        } else {
          // serial_openBCI.write(command_deactivate_channel[Ichan]);
          gui.cc.powerDownChannel(Ichan);
        }
      }
    }
  }
  
  //deactivate an EEG channel...channel counting is zero through nchan-1
  public void deactivateChannel(int Ichan) {
    if (serial_openBCI != null) {
      if ((Ichan >= 0) && (Ichan < command_activate_channel.length)) {
        serial_openBCI.write(command_activate_channel[Ichan]);
      }
    }
  }

  //return the state
  boolean isStateNormal() { 
    if (state == STATE_NORMAL) { 
      return true;
    } else {
      return false;
    }
  }
  
  // ---- DEPRECATED ---- 
  // public void changeImpedanceState(int Ichan,boolean activate,int code_P_N_Both) {
  //   //println("OpenBCI_ADS1299: changeImpedanceState: Ichan " + Ichan + ", activate " + activate + ", code_P_N_Both " + code_P_N_Both);
  //   if (serial_openBCI != null) {
  //     if ((Ichan >= 0) && (Ichan < command_activate_leadoffP_channel.length)) {
  //       if (activate) {
  //         if ((code_P_N_Both == 0) || (code_P_N_Both == 2)) {
  //           //activate the P channel
  //           serial_openBCI.write(command_activate_leadoffP_channel[Ichan]);
  //         } else if ((code_P_N_Both == 1) || (code_P_N_Both == 2)) {
  //           //activate the N channel
  //           serial_openBCI.write(command_activate_leadoffN_channel[Ichan]);
  //         }
  //       } else {
  //         if ((code_P_N_Both == 0) || (code_P_N_Both == 2)) {
  //           //deactivate the P channel
  //           serial_openBCI.write(command_deactivate_leadoffP_channel[Ichan]);
  //         } else if ((code_P_N_Both == 1) || (code_P_N_Both == 2)) {
  //           //deactivate the N channel
  //           serial_openBCI.write(command_deactivate_leadoffN_channel[Ichan]);
  //         }          
  //       }
  //     }
  //   }
  // }
  
  // public void setBiasAutoState(boolean isAuto) {
  //   if (serial_openBCI != null) {
  //     if (isAuto) {
  //       println("OpenBCI_ADS1299: setBiasAutoState: setting bias to AUTO");
  //       serial_openBCI.write(command_biasAuto);
  //     } else {
  //       println("OpenBCI_ADS1299: setBiasAutoState: setting bias to REF ONLY");
  //       serial_openBCI.write(command_biasFixed);
  //     }
  //   }
  // }
  
  private int interpret24bitAsInt32(byte[] byteArray) {     
    //little endian
    int newInt = ( 
      ((0xFF & byteArray[0]) << 16) |
      ((0xFF & byteArray[1]) << 8) | 
      (0xFF & byteArray[2])
      );
    if ((newInt & 0x00800000) > 0) {
      newInt |= 0xFF000000;
    } else {
      newInt &= 0x00FFFFFF;
    }
    return newInt;
  }
  
  private int interpret16bitAsInt32(byte[] byteArray) {
    int newInt = (
      ((0xFF & byteArray[0]) << 8) |
       (0xFF & byteArray[1])
      );
    if ((newInt & 0x00008000) > 0) {
      newInt |= 0xFFFF0000;
    } else {
      newInt &= 0x0000FFFF;
    }
    return newInt;
  }
  
  public int copyDataPacketTo(DataPacket_ADS1299 target) {
    isNewDataPacketAvailable = false;
    dataPacket.copyTo(target);
    return 0;
  }
};
  
//  int measurePacketLength() {
//    
//    //assume curBuffIndex has already been incremented to the next open spot
//    int startInd = curBuffIndex-1;
//    int endInd = curBuffIndex-1;
//
//    //roll backwards to find the start of the packet
//    while ((startInd >= 0) && (serialBuff[startInd] != BYTE_START)) {
//      startInd--;
//    }
//    if (startInd < 0) {
//      //didn't find the start byte..so ignore this data packet
//      return 0;
//    } else if ((endInd - startInd + 1) < 3) {
//      //data packet isn't long enough to hold any data...so ignore this data packet
//      return 0;
//    } else {
//      //int n_bytes = int(serialBuff[startInd + 1]); //this is the number of bytes in the payload
//      //println("OpenBCI_ADS1299: measurePacketLength = " + (endInd-startInd+1));
//      return endInd-startInd+1;
//    }