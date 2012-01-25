/**************************************************************************
* PeaTiX QR Reader
* Copyright 2012 (c) Peatix Inc. (http://peatix.com) All rights reserved.
*
* This program is created based on LOGOSWARE ReaderQrCodeSample class
* that comes with QRCodeReader class package by SPARK project.
*
* This program is free software; you can redistribute it and/or modify it under
* the terms of the GNU General Public License as published by the Free Software
* Foundation; either version 2 of the License, or (at your option) any later version.
*
**************************************************************************/
/**************************************************************************
* LOGOSWARE Class Library.
*
* Copyright 2009 (c) LOGOSWARE (http://www.logosware.com) All rights reserved.
*
*
* This program is free software; you can redistribute it and/or modify it under
* the terms of the GNU General Public License as published by the Free Software
* Foundation; either version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License along with
* this program; if not, write to the Free Software Foundation, Inc., 59 Temple
* Place, Suite 330, Boston, MA 02111-1307 USA
*
**************************************************************************/
package com.peatix
{

    import mx.core.Application;
    import mx.core.UIComponent; 
    import mx.controls.Alert;
    import mx.events.FlexEvent;
    import mx.events.CloseEvent;

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.GradientType;
    import flash.display.SimpleButton;
    import flash.display.SpreadMethod;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.filters.BlurFilter;
    import flash.filters.DropShadowFilter;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.media.Camera;
    import flash.media.Video;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import spark.components.HGroup;
    import spark.components.TileGroup;
    import spark.components.RadioButton;
    import spark.components.RadioButtonGroup;
    import spark.components.Button;
    import flash.utils.Timer;

    import com.logosware.event.QRdecoderEvent;
    import com.logosware.event.QRreaderEvent;
    import com.logosware.utils.QRcode.QRdecode;
    import com.logosware.utils.QRcode.GetQRimage;

    /**
     * PeaTiX QR Reader
     * @author Fumiaki Yoshimatsu, Kenichi UENO (LOGOSWARE)
     */
    public class PeatixQRReader extends Application
    {
        private const SRC_SIZE:int = 320;
        private const STAGE_SIZE:int = 350;

        private var getQRimage:GetQRimage;
        private var qrDecode:QRdecode = new QRdecode();

        private var errorView:Sprite;
        private var errorText:TextField = new TextField();

        private var startView:Sprite;

        public var panelCamera:HGroup;
        /*
        public var tgStart:TileGroup;
        public var ratio:RadioButtonGroup;
        public var ratio11:RadioButton;
        public var ratio43:RadioButton;
        public var btnStart:Button;
        */
        public var btnStopStart:Button;

        private var isSquare:Boolean;

        private var cameraView:Sprite;
        private var camera:Camera;
        private var video:Video;
        private var freezeImage:Bitmap;
        private var blue:Sprite = new Sprite();
        private var red:Sprite = new Sprite();
        private var blurFilter:BlurFilter = new BlurFilter();

        private var resultView:Sprite;
        private var textArea:TextField = new TextField();
        private var cameraTimer:Timer = new Timer(2000);
        private var redTimer:Timer = new Timer(400, 1);

        private var textArray:Array = ["", "", ""];

        /**
         * Constructor
         */
        public function PeatixQRReader():void {
            super();
            this.addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
        }

        private function onCreationComplete(e:FlexEvent):void {
            this.removeEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);

            errorView = buildErrorView();

            cameraTimer.addEventListener(TimerEvent.TIMER, getCamera);
            cameraTimer.start();
            getCamera();

            //panelCamera.height = 0;
            btnStopStart.addEventListener(MouseEvent.CLICK, onButtonClick);
            startCamera();
        }
        /**
         * Check camera connection
         */
        private function getCamera(e:TimerEvent = null):void{
            camera = Camera.getCamera();
            this.graphics.clear();
            if ( camera == null ) {
                this.addChild( errorView );
            } else {
                cameraTimer.stop();
                if ( errorView.parent == this ) {
                    this.removeChild(errorView);
                }
            }
        }
        private function startCamera():void {
            isSquare = false;

            video = new Video();
            panelCamera.height = video.height;
            cameraView = buildCameraView();
            resultView = buildResultView();

            //tgStart.visible = false;
            var uic:UIComponent = new UIComponent();
            uic.addChild( cameraView );
            uic.addChild( resultView );
            panelCamera.addElementAt( uic, 0 );
            
            //this.removeChild( startView );
            resultView.visible = false;

            getQRimage = new GetQRimage(video);
            getQRimage.addEventListener(QRreaderEvent.QR_IMAGE_READ_COMPLETE, onQrImageReadComplete);
            qrDecode.addEventListener(QRdecoderEvent.QR_DECODE_COMPLETE, onQrDecodeComplete);
            redTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onRedTimer );
            this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
        /**
         * Pass images from camera and monitors QRcode detection
         */
        private function onStart(e:MouseEvent):void {
            // isSquare = ratio.selectedValue == '1';
            if ( isSquare ) {
                video = new Video( SRC_SIZE, SRC_SIZE );
                panelCamera.height = SRC_SIZE - 30;
            }
            else {
                video = new Video();
                panelCamera.height = video.height;
            }
            cameraView = buildCameraView();
            resultView = buildResultView();

            //tgStart.visible = false;
            var uic:UIComponent = new UIComponent();
            uic.addChild( cameraView );
            uic.addChild( resultView );
            panelCamera.addElementAt( uic, 0 );
            
            //this.removeChild( startView );
            resultView.visible = false;

            getQRimage = new GetQRimage(video);
            getQRimage.addEventListener(QRreaderEvent.QR_IMAGE_READ_COMPLETE, onQrImageReadComplete);
            qrDecode.addEventListener(QRdecoderEvent.QR_DECODE_COMPLETE, onQrDecodeComplete);
            redTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onRedTimer );
            this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
        /**
         * Error view
         */
        private function buildErrorView():Sprite {
            var sprite:Sprite = new Sprite();
            errorText.autoSize = TextFieldAutoSize.LEFT;
            errorText.text = "no camera detected.";
            errorText.x = 0.5 * (STAGE_SIZE - errorText.width);
            errorText.y = 0.5 * (STAGE_SIZE - errorText.height);
            errorText.border = true;
            errorText.background = true;
            sprite.graphics.lineStyle(0);
            sprite.graphics.drawPath(Vector.<int>([1, 2, 2, 2, 2, 2, 1, 2]), Vector.<Number>([5, 5, STAGE_SIZE-5, 5, STAGE_SIZE-5, STAGE_SIZE-5, 5, STAGE_SIZE-5, 5, 5, STAGE_SIZE-5, STAGE_SIZE-5, 5, STAGE_SIZE-5, STAGE_SIZE-5, 5]));
            sprite.addChild(errorText);
            return sprite;
        }
        /**
         * Create camera view
         */
        private function buildCameraView():Sprite {
            camera.setQuality(0, 100);
            //camera.setMode(SRC_SIZE, SRC_SIZE, 24, true );
            camera.setMode(video.width, video.height, 24, true );
            video.attachCamera( camera );

            var sprite:Sprite = new Sprite();
            //sprite.graphics.beginGradientFill(GradientType.LINEAR, [0xCCCCCC, 0x999999], [1.0, 1.0], [0, 255], new Matrix(0, 0.1, -0.1, 0, 0, 150));
            //sprite.graphics.drawRoundRect(0, 0, SRC_SIZE+30, SRC_SIZE+30, 20);
            //sprite.graphics.drawRoundRect(0, 0, video.width+30, video.height+90, 20);

            var videoHolder:Sprite = new Sprite();
            videoHolder.addChild( video );
            videoHolder.x = 15;

            freezeImage = new Bitmap(new BitmapData(video.width, video.height));
            videoHolder.addChild( freezeImage );
            freezeImage.visible = false;

            var commands:Vector.<int> = Vector.<int>([1,2,2,1,2,2,1,2,2,1,2,2]);
            var path:Vector.<Number>;
            if ( isSquare ) {
                path = Vector.<Number>([30,60,30,30,60,30,290,60,290,30,260,30,30,260,30,290,60,290,290,260,290,290,260,290]);
            }
            else {
                path = Vector.<Number>([50,40,50,10,80,10,240,10,270,10,270,40,50,200,50,230,80,230,240,230,270,230,270,200]);
            }
            red.graphics.lineStyle(10, 0xFF0000);
            red.alpha = 0.7;
            red.graphics.drawPath(commands, path );
            blue.graphics.lineStyle(10, 0x00FF00);
            blue.graphics.drawPath(commands, path);

            sprite.addChild( videoHolder );
            sprite.addChild( red );
            sprite.addChild( blue );
            blue.alpha = 0;
            red.x = blue.x = 15;

            return sprite;
        }
        /**
         * Resulting view
         */
        private function buildResultView():Sprite {
            var sprite:Sprite = new Sprite();
            sprite.graphics.beginGradientFill(GradientType.LINEAR, [0xDDDDEE, 0xBBBBCC], [0.9, 0.9], [0, 255], new Matrix(0, 0.1, -0.1, 0, 0, 150));
            sprite.graphics.drawRoundRect(0, 0, 280, 280, 20);

            sprite.addChild( textArea );
            textArea.width = 250;
            textArea.height = 200;
            textArea.wordWrap = true;
            textArea.multiline = true;
            textArea.border = true;
            textArea.background = true;
            textArea.backgroundColor = 0xFFFFFF;
            textArea.x = textArea.y = 15;

            var btnText:TextField = new TextField();
            btnText.autoSize = TextFieldAutoSize.LEFT;
            btnText.text = "CLOSE";
            btnText.selectable = false;
            var btnSprite:Sprite = new Sprite();
            btnSprite.addChild(btnText);
            btnSprite.graphics.lineStyle(1);
            btnSprite.graphics.beginGradientFill(GradientType.LINEAR, [0xEEEEEE, 0xCCCCCC], [0.9, 0.9], [0, 255], new Matrix(0, 0.01, -0.01, 0, 0, 10));
            btnSprite.graphics.drawRoundRect(0, 0, 80, 20, 8);
            btnText.x = 0.5 * (btnSprite.width - btnText.width);
            btnText.y = 0.5 * (btnSprite.height - btnText.height);
            btnSprite.x = 0.5 * ( 280 - 80 );
            btnSprite.y = 240;
            btnSprite.buttonMode = true;
            btnSprite.mouseChildren = false;
            btnSprite.addEventListener(MouseEvent.CLICK, onClose);

            sprite.addChild( btnSprite );
            sprite.addChild( textArea );

            sprite.x = sprite.y = 35;
            sprite.filters = [new DropShadowFilter(4.0,45,0,0.875)];

            return sprite;
        }
        /**
         * Process every frame
         */
        private function onEnterFrame(e: Event):void{
            if( camera.currentFPS > 0 ){
                getQRimage.process();
            }
        }
        /**
         * Decode image if it is a QRcode
         */
        private function onQrImageReadComplete(e: QRreaderEvent):void{
            qrDecode.setQR(e.data); // QRreaderEvent.data: QRcode in array
            qrDecode.startDecode(); // start decoding
        }
        /**
         * Show the result text of a QRcode processed
         */
        private function onQrDecodeComplete(e: QRdecoderEvent):void {
            blue.alpha = 1.0;
            redTimer.reset();
            redTimer.start();
            textArray.shift();
            textArray.push( e.data );  // QRdecoderEvent.data: QRcode in array
            if ( textArray[0] == textArray[1] && textArray[1] == textArray[2] ) {
                //textArea.htmlText = e.data;
                stopCamera();
                postCheckin( e.data );
            }
        }

        private function restartCamera():void {
            textArray = ["", "", ""];
            freezeImage.visible = false;
            redTimer.start();
            this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
            cameraView.filters = [];
        }
        private function stopCamera():void {
            //cameraView.filters = [blurFilter];
            redTimer.stop();
            freezeImage.bitmapData.draw(video);
            freezeImage.visible = true;
            this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
        private function onButtonClick(e: MouseEvent):void {
            if ( btnStopStart.label == "STOP" ) {
                stopCamera();
                btnStopStart.label = "START";
            }
            else {
                btnStopStart.label = "STOP";
                restartCamera();
            }
        }

        /**
         * Closing result view, removing result
         */
        private function onClose(e: MouseEvent):void {
            textArray = ["", "", ""];
            freezeImage.visible = false;
            redTimer.start();
            this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
            cameraView.filters = [];
            resultView.visible = false;
        }
        /**
         * Set the guide image back to red
         */
        private function onRedTimer(e:TimerEvent):void {
            blue.alpha = 0;
        }

        private function onAlertClose(event:CloseEvent):void {
            textArray = ["", "", ""];
            freezeImage.visible = false;
            redTimer.start();
            this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
            cameraView.filters = [];
        }

        private function postCheckin(hash:String):void {
            var checkin_url:String = this.parameters.checkin_url.toString();
            var form_token:String  = this.parameters.form_token.toString();

            var request:URLRequest = new URLRequest( checkin_url )
            var loader:URLLoader = new URLLoader();
            var params:URLVariables = new URLVariables();
            params.form_token = form_token;
            params.hash = hash;
            request.data = params;
            request.method = URLRequestMethod.POST;
            loader.addEventListener(Event.COMPLETE, checkinCompleteHandler);
            loader.addEventListener(IOErrorEvent.IO_ERROR, checkinIoErrorHandler);
            loader.load(request);
        }
        private function checkinCompleteHandler(event:Event):void {
            var message:String;
            var title:String;
            try {
                var jsonData:Object = JSON.parse(event.target.data);
                var attendee:Object = jsonData.json_data.attendee
                message = attendee.name + "\n" + attendee.quantity + " x " + attendee.ticket;
                title   = "Checked in!";
            }
            catch (error:Error) {
                message = event.target.data;
                title   = "Error";
            }
            Alert.show(message, title, Alert.OK, this, onAlertClose );
        }
        private function checkinIoErrorHandler(event:IOErrorEvent):void {
            Alert.show("Irrecoverable error. Try again", "Alert", Alert.OK, this, onAlertClose );
        }
    }

}
