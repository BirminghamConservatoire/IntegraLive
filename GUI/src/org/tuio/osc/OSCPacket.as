﻿package org.tuio.osc {
	
	import flash.utils.ByteArray;
	import flash.errors.EOFError;

	/**
	 * An OSCPacket
	 * This is a basic class for OSCBundles and OSCMessages that basically wraps a ByteArray
	 * and offers some additional functions for reading the binary data for extending classes.
	 * 
	 * @author Immanuel Bauer
	 */
	public class OSCPacket {
		
		internal var bytes:ByteArray;
		
		public function OSCPacket(bytes:ByteArray = null) {
			if (bytes != null) this.bytes = bytes;
			else this.bytes = new ByteArray();
		}
		
		public function getPacketInfo():String {
			return "packet";
		}
		
		public function getBytes():ByteArray {
			return this.bytes;
		}
		
		protected function skipNullString():void {
			var char:String = new String();
			while(this.bytes.bytesAvailable > 0){
				char = this.bytes.readUTFBytes(1);
				if(char != ""){
					this.bytes.position -= 1;
					break;
				}
			}
		}
		
		protected function readString():String {
			var out:String = new String();
			var char:String = new String();
			while(this.bytes.bytesAvailable > 0){
				char = this.bytes.readUTFBytes(4);
				out += char;
				if(char.length < 4) break;
			}
			return out;
		}
		
		protected function readTimetag():OSCTimetag {
			var seconds:uint = this.bytes.readUnsignedInt();
			var picoseconds:uint = this.bytes.readUnsignedInt();
			
			return new OSCTimetag(seconds, picoseconds);
		}
		
		protected function readBlob():ByteArray {
			var length:int = this.bytes.readInt();
			var blob:ByteArray = new ByteArray();
			this.bytes.readBytes(blob, 0, length);
			
			var bits:int = (length + 1) * 8;
			while((bits % 32) != 0){
				this.bytes.position += 1;
				bits += 8;
			}
			
			return blob;
		}
		
		protected function read64BInt():ByteArray {
			var bigInt:ByteArray = new ByteArray();
			
			this.bytes.readBytes(bigInt, 0, 8);
			
			return bigInt;
		}
		
		protected function writeString(str:String, byteArray:ByteArray = null):void {
			var nulls:int = 4 - (str.length % 4);
			if (!byteArray) byteArray = this.bytes;
			byteArray.writeUTFBytes(str);
			//add zero padding so the length of the string is a multiple of 4
			for (var c:int = 0; c < nulls; c++ ){
				byteArray.writeByte(0);
			}
		}
		
		protected function writeTimetag(ott:OSCTimetag, byteArray:ByteArray = null):void {
			if (!byteArray) byteArray = this.bytes;
			byteArray.writeUnsignedInt(ott.seconds);
			byteArray.writeUnsignedInt(ott.picoseconds);
		}
		
		protected function writeBlob(blob:ByteArray):void {
			var length:int = blob.length;
			blob.position = 0;
			blob.readBytes(this.bytes, this.bytes.position, length);
			
			var nulls:int = length % 4;
			for (var c:int = 0; c < nulls; c++){
				this.bytes.writeByte(0);
			}
		}
		
		protected function write64BInt(bigInt:ByteArray):void {
			bigInt.position = 0;
			bigInt.readBytes(this.bytes, this.bytes.position, 8);
		}
		
	}
	
}
