//
//  GameScene.swift
//  flappy bird
//
//  Created by gray on 2018/7/22.
//  Copyright © 2018年 gray. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreBluetooth


class GameScene: SKScene,SKPhysicsContactDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate{
    
    var pipes: SKNode!
    var birdA: SKSpriteNode!
    var birdB: SKSpriteNode!
    var ground: SKNode!
    var sky: SKNode!
    var overInfo = SKLabelNode(fontNamed: "MarkerFelt-Wide")
    var blank = SKAction()
    var startInfo = SKLabelNode(fontNamed: "MarkerFelt-Wide")
    var shine = SKAction()
    var creatPipeSet = SKAction()
    
    //------------------------peripheral端(AD)----------------------
    let peripheralQueue = DispatchQueue.global()
    let UUID_SERVICE = "A001"
    let UUID_CHARACTERISTIC = "C001"
    var peripheralManager: CBPeripheralManager!
    var peripheralDictionary = [String:CBMutableCharacteristic]()
    var connected = false
    
    // check power
    //------------------------peripheral端(AD)------------------------
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else{
            return
        }
        
        var service: CBMutableService
        var characteristic: CBMutableCharacteristic
        var charArray = [CBCharacteristic]()
        
        service = CBMutableService(type: CBUUID(string: UUID_SERVICE), primary: true)
        
        characteristic = CBMutableCharacteristic(type: CBUUID(string: UUID_CHARACTERISTIC), properties: [.notifyEncryptionRequired, .writeWithoutResponse], value: nil, permissions: .writeable)
        
        charArray.append(characteristic)
        peripheralDictionary[UUID_CHARACTERISTIC] = characteristic
        service.characteristics = charArray
        peripheralManager.add(service)
    }
    
    //periphral端
    //------------------------periphral端(AD)设置广播参数-------------------
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil else{
            print("error:\(#file, #function)")
            print(error!.localizedDescription)
            return
        }
        let deviceName = "my device"
        //广播参数
        peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[service.uuid],CBAdvertisementDataLocalNameKey:deviceName])
    }
    
    //------------------------periphral端(AD)开始广播----------------------
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        
    }
    
    //------------------------periphral端(AD)被订阅-----------------------
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        
        if peripheral.isAdvertising{
            peripheral.stopAdvertising()
            connected = true
        }
        if characteristic.uuid.uuidString == UUID_CHARACTERISTIC{
            
        }
    }
    
    //IOS上
    //发送资料
    func sendDate(_ data:Data, uuidString:String){
            //-------------periphral端(AD)发到central端(Scan)的资料------------
            let characteristic = peripheralDictionary[uuidString]
            peripheralManager.updateValue(data, for: characteristic!, onSubscribedCentrals: nil)
    }
    
    //-------------periphral端(AD)收到central端(Scan)的资料------------
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        guard let at = requests.first else{
    
            return
        }
        guard let data = at.value else{

            return
        }
        
        let string = String(data:data, encoding: .utf8)!
        DispatchQueue.main.async {
            if string.starts(with: "high:"){
                var piece:Array = string.split(separator: ":")
                let height = Double(piece[1])!
                self.addPipePair(between: CGFloat(height))
                return
            }
            
            switch string {
            case "seset":
                self.reset()
            case "end":
                self.endsGame()
            default:
               self.setposition(info:string)
            }
        }
    }
    
    //////////////////////////////////////////////////////////////////
   
    func createNode(image:SKTexture)->SKSpriteNode{
        let texture = image
        texture.filteringMode = SKTextureFilteringMode.nearest
        let item = SKSpriteNode(texture: texture)
        item.anchorPoint = CGPoint(x:0,y:0)
        item.position = CGPoint(x:-halfWide, y:-halfHigh)
        return item
    }
    
    func preparework(){

        //Set gameover
        overInfo.position = CGPoint(x: 0, y: high/4)
        overInfo.text = String("GameOver")
        overInfo.zPosition = 20
        overInfo.fontSize = 100
        overInfo.isHidden = true
        overInfo.color = SKColor.white
        self.addChild(overInfo)
        //Set gamestart
        startInfo.position = CGPoint(x: 0, y: high/4)
        startInfo.text = String("3...")
        startInfo.zPosition = 20
        startInfo.fontSize = 100
        startInfo.isHidden = false
        startInfo.color = SKColor.white
        self.addChild(startInfo)
        
        //init action
        let beRed = SKAction.run({self.overInfo.fontColor = SKColor.red})
        let beWhite = SKAction.run({self.overInfo.fontColor = SKColor.white})
        let wait = SKAction.wait(forDuration: TimeInterval(0.1))
        blank = SKAction.sequence([beRed,wait,beWhite,wait])
        
        let bebig = SKAction.scale(to: 1, duration: 0.0)
        let besmall = SKAction.scale(to: 0.1, duration: 1.0)
        let beThree = SKAction.run {self.startInfo.text = "3..."}
        let beTwo = SKAction.run {self.startInfo.text = "2..."}
        let beOne = SKAction.run {self.startInfo.text = "1..."}
        shine = SKAction.sequence([beThree,besmall,bebig,beTwo,besmall,bebig,beOne,besmall,bebig ])
    }
    
    func creatMoveBackground(image:SKTexture, speed:CGFloat)->SKSpriteNode{
        let item = createNode(image: image)
        item.setScale(2.0)
        let distance = CGFloat(item.size.width-wide)
        let moveGroundAction = SKAction.moveBy(x:-distance, y:0, duration: TimeInterval(speed * distance))
        let reset = SKAction.run {
            item.position = CGPoint(x:-halfWide, y:-halfHigh)
        }
        let action = SKAction.repeatForever(SKAction.sequence([moveGroundAction,reset]))
        item.run(action)
        return item
    }
    
    func addsharpImage(){
        let item = createNode(image: sharpTexture)
        item.position.x = CGFloat(-halfWide)
        item.zPosition = 5
        addChild(item)
    }
    
    func creatbirdImage(which:Bool) ->SKSpriteNode{
        var BirdTexture = [SKTexture]()
        if which {
            BirdTexture.append(birdATexture1)
            BirdTexture.append(birdATexture2)
            BirdTexture.append(birdATexture3)
        }else{
            BirdTexture.append(birdBTexture1)
            BirdTexture.append(birdBTexture2)
            BirdTexture.append(birdBTexture3)
        }
        BirdTexture.forEach(){$0.filteringMode = SKTextureFilteringMode.nearest}
        let fly = SKAction.animate(with: BirdTexture, timePerFrame: 0.2)
        
        // make it fly
        let bird = SKSpriteNode(texture: BirdTexture[0])
        bird.zPosition = 7
        bird.setScale(2.0)
        if which {
            bird.position = CGPoint(x:wide/4, y:high/4)
        }else{
            bird.position = CGPoint(x:wide/4, y:high/4 + bird.size.height )
        }
        bird.run(SKAction.repeatForever(fly))
        
        return bird
    }
    
    func CreatPipe(texture:SKTexture)->SKSpriteNode{
        let pipe = createNode(image: texture)
        pipe.position.x = halfWide
        pipe.setScale(2.0)
        
        let distance = wide + pipe.size.width*2
        let movePipeAction = SKAction.moveBy(x:-distance, y:0, duration: TimeInterval(0.01 * distance))
        let delate = SKAction.removeFromParent()
        let action = SKAction.repeatForever(SKAction.sequence([movePipeAction,delate]))
        pipe.run(SKAction.repeatForever(action))
        
        return pipe
    }
    func addPipePair(between: CGFloat){
        let upPipe = CreatPipe(texture: pipeUp)
        let downPipe = CreatPipe(texture: pipeDown)
        
        upPipe.position.y = CGFloat(-halfHigh)-between
        downPipe.position.y = upPipe.position.y + upPipe.size.height + high/8
        
        pipes.addChild(downPipe)
        pipes.addChild(upPipe)
    }
    
    override func didMove(to view: SKView) {
        peripheralManager = CBPeripheralManager(delegate: self, queue: peripheralQueue)
        
        preparework()
        
        ground = creatMoveBackground(image: groundTexture, speed: 0.01)
        ground.zPosition = 6
        addChild(ground)
        sky = creatMoveBackground(image: skyTexture, speed: 0.1)
        sky.zPosition = 1
        addChild(sky)
        
        addsharpImage()
        
        // set pipes
        pipes = SKNode()
        pipes.zPosition = 4
        addChild(pipes)
        
        //set bird
        birdA = creatbirdImage(which: true)
        addChild(birdA)
        birdB = creatbirdImage(which: false)
        addChild(birdB)
        stopworld()
    }
    
    func reset(){
        pipes.removeAllChildren()
        birdA.position = CGPoint(x:wide/4, y:high/4 )
        birdB.position = CGPoint(x:wide/4, y:high/4 + birdB.size.height)
        overInfo.isHidden = true
        begin()
    }
    func stopworld(){
        birdA.speed = 0
        birdB.speed = 0
        ground.speed = 0
        pipes.speed = 0
        sky.speed = 0
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
    }
    
    func startworld(){
        startInfo.isHidden = true
        overInfo.isHidden = true
        ground.speed = 1
        pipes.speed = 1
        sky.speed = 1
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
        pipes.removeAllChildren()
    }
    func begin(){
        let wait = SKAction.wait(forDuration: TimeInterval(3))
        let again = SKAction.run ({self.startworld()})
        self.run(SKAction.sequence([wait,again]))
        startInfo.isHidden = false
        startInfo.run(shine)
    }
    
    func endsGame(){
        stopworld()
        overInfo.isHidden = false
        overInfo.run(SKAction.repeat(blank, count: 3))
        self.run(SKAction.wait(forDuration: TimeInterval(0.6)))
    }
    
    func setposition(info: String){
        print("pos")
        var piece:Array = info.split(separator: "/")
        let birdAX = Double(piece[0])
        let birdAY = Double(piece[1])
        let birdBX = Double(piece[2])
        let birdBY = Double(piece[3])
        birdA.position.x = CGFloat(birdAX!)
        birdA.position.y = CGFloat(birdAY!)
        birdB.position.x = CGFloat(birdBX!)
        birdB.position.y = CGFloat(birdBY!)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if ground.speed>0 {
            for _ in touches{
                sendDate("pop".data(using: .utf8)!, uuidString: "C001")
                break
            }
        }else{
            if connected {
                sendDate("ready".data(using: .utf8)!, uuidString: "C001")
            }
        }
    }
    
}
