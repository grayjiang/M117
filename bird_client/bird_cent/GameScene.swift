//
//  GameScene.swift
//  bird_cent
//
//  Created by gray on 2018/8/12.
//  Copyright © 2018年 gray. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreBluetooth

class GameScene: SKScene,SKPhysicsContactDelegate, CBCentralManagerDelegate, CBPeripheralDelegate{
    
    var pipes: SKNode!
    var birdA: SKSpriteNode!
    var birdB: SKSpriteNode!
    var ground: SKNode!
    var sky: SKNode!
    var canRest = false
    var ready = false
    var overInfo = SKLabelNode(fontNamed: "MarkerFelt-Wide")
    var blank = SKAction()
    var startInfo = SKLabelNode(fontNamed: "MarkerFelt-Wide")
    var shine = SKAction()
    var creatPipeSet = SKAction()
    var count = TimeInterval()
    
    //------------------------central端(scan)-----------------------
    let centralQueue = DispatchQueue.global()
    var centralManager: CBCentralManager!
    var connectedPeripheral:CBPeripheral!
    var centralDictionary = [String:CBCharacteristic]()
    var connected = false
    
    //------------------------central端(scan)-------------------------
    func ispaired() -> Bool{
        let user = UserDefaults.standard
        if let uuidString = user.string(forKey: "KEY_PERIPHERAL_UUID"){
            let uuid = UUID(uuidString: uuidString)
            let list = centralManager.retrievePeripherals(withIdentifiers: [uuid!])
            if list.count > 0{
                connectedPeripheral = list.first!
                connectedPeripheral.delegate = self
                return false
            }
        }
        return false
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else{
            return
        }
        if ispaired(){
            centralManager.connect(connectedPeripheral, options: nil)
        }else {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    //central端
    //------------------------central端(scan)进行扫描-------------------
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard peripheral.name != nil else{
            return
        }
        guard peripheral.name == "Gray的 iPad" else{
            return
        }
        //找到设备然后停止扫描
        central.stopScan()
        
        //记录扫描到的uuid，重连使用
        let user = UserDefaults.standard
        user.set(peripheral.identifier.uuidString, forKey:"KEY_PERIPHERAL_UUID")
        user.synchronize()
        
        connectedPeripheral = peripheral
        connectedPeripheral.delegate = self
        
        //执行3
        centralManager.connect(connectedPeripheral, options: nil)
    }
    
    //------------------------central端(scan)连线前的准备工作-------------
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        centralDictionary = [:] //清空
        //对发现的设备，扫描所有service
        peripheral.discoverServices(nil)
    }
    
    //------------------------central端(scan)扫描所有service-------------
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else{
            print("error:\(#file, #function)")
            return
        }
        
        for service in peripheral.services! {
            connectedPeripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    //------------------------central端(scan)检查service-------------
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else{
            print("Error:\(#file, #function)")
            return
        }
        
        for characteristic in service.characteristics!{
            let uuidString = characteristic.uuid.uuidString
            centralDictionary[uuidString] = characteristic
            
            if String(uuidString) == "C001"{
                connectedPeripheral.setNotifyValue(true, for:centralDictionary["C001"]!)
                begin()
                connected = true
            }
        }
    }
    
    func sendDate(_ data:Data, uuidString:String){
        //-------------central端(Scan)发到periphral端(AD)的资料------------
        let characteristic = centralDictionary[uuidString]
        connectedPeripheral.writeValue(data, for: characteristic!, type: .withoutResponse)
    }
    
    //-------------central端(Scan)收到periphral端(AD)的资料------------
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else{
            print("Error:\(#file, #function)")
            return
        }
        
        if characteristic.uuid.uuidString == "C001" {
            let data = characteristic.value!
            let string = String(data:data as Data, encoding: .utf8)!
            DispatchQueue.main.async {
                switch string {
                case "pop":
                    self.birdB.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                    self.birdB.physicsBody?.applyImpulse(CGVector(dx: 0, dy:force))
                case "ready":
                    self.ready = true
                default:
                    return
                }
            }
        }
    }
    
    func createNode(image:SKTexture)->SKSpriteNode{
        let texture = image
        texture.filteringMode = SKTextureFilteringMode.nearest
        let item = SKSpriteNode(texture: texture)
        item.anchorPoint = CGPoint(x:0,y:0)
        item.position = CGPoint(x:-halfWide, y:-halfHigh)
        return item
    }
    
    func preparework(){
        //physical world
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
        self.physicsWorld.contactDelegate = self
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
    
    func addsharp(){
        let item = createNode(image: sharpTexture)
        item.position.x = CGFloat(-halfWide)
        item.physicsBody = SKPhysicsBody(edgeLoopFrom:CGRect(x: 0, y: 0, width: Int(item.size.width-15), height: Int(high)))
        item.physicsBody?.isDynamic = false
        item.physicsBody?.categoryBitMask = sharpC
        item.physicsBody?.contactTestBitMask = birdC
        item.zPosition = 5
        addChild(item)
    }
    
    func creatbird(which:Bool) ->SKSpriteNode{
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
        
        //set physical body
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height/3.5)
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.categoryBitMask = birdC
        bird.physicsBody?.collisionBitMask = worldC
        return bird
    }
    
    func CreatPipe(texture:SKTexture)->SKSpriteNode{
        let pipe = createNode(image: texture)
        pipe.position.x = halfWide
        pipe.setScale(2.0)
        pipe.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: pipe.size.width, height: pipe.size.height))
        pipe.physicsBody?.isDynamic = false
        pipe.physicsBody?.categoryBitMask = worldC
        
        let distance = wide + pipe.size.width*2
        let movePipeAction = SKAction.moveBy(x:-distance, y:0, duration: TimeInterval(0.01 * distance))
        let delate = SKAction.removeFromParent()
        let action = SKAction.repeatForever(SKAction.sequence([movePipeAction,delate]))
        pipe.run(SKAction.repeatForever(action))
        
        return pipe
    }
    func addPipePair(){
        let upPipe = CreatPipe(texture: pipeUp)
        let downPipe = CreatPipe(texture: pipeDown)
    
        let between = CGFloat(arc4random()%UInt32(high/4))
        let send = "high:"+String(Double(between))
        sendDate(send.data(using: .utf8)!, uuidString: "C001")
        upPipe.position.y = CGFloat(-halfHigh)-between
        downPipe.position.y = upPipe.position.y + upPipe.size.height + high/8
        
        pipes.addChild(downPipe)
        pipes.addChild(upPipe)
    }
    func addedge(){
        let topEdge = SKNode()
        topEdge.position = CGPoint(x:-halfWide, y:halfHigh+1)
        topEdge.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: wide, height: 1))
        topEdge.physicsBody?.categoryBitMask = worldC
        topEdge.physicsBody?.isDynamic = false
        
        let realGround = SKNode()
        realGround.position = CGPoint(x:-halfWide, y:-halfHigh)
        realGround.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: wide, height: 217))
        realGround.physicsBody?.categoryBitMask = sharpC
        realGround.physicsBody?.contactTestBitMask = birdC
        realGround.physicsBody?.isDynamic = false
        
        addChild(realGround)
        addChild(topEdge)
    }
    override func didMove(to view: SKView) {
   
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
        preparework()
        ground = creatMoveBackground(image: groundTexture, speed: 0.01)
        ground.zPosition = 6
        addChild(ground)
        sky = creatMoveBackground(image: skyTexture, speed: 0.1)
        sky.zPosition = 1
        addChild(sky)
        
        addsharp()
        addedge()

        // set pipes
        pipes = SKNode()
        pipes.zPosition = 4
        let PipeSet = SKAction.run({() in self.addPipePair()})
        let delay = SKAction.wait(forDuration:TimeInterval(3.0))
        let creatPipeSet =    SKAction.repeatForever(SKAction.sequence([delay,PipeSet]))
        pipes.run(creatPipeSet)
        addChild(pipes)
        
        //set bird
        birdA = creatbird(which: true)
        addChild(birdA)
        birdB = creatbird(which: false)
        addChild(birdB)
        stopworld()
    }
    func reset(){
       
        pipes.removeAllChildren()
        birdA.position = CGPoint(x:wide/4, y:high/4 )
        birdA.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        birdA.physicsBody?.categoryBitMask = birdC
        
        birdB.position = CGPoint(x:wide/4, y:high/4 + birdB.size.height)
        birdB.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        birdB.physicsBody?.categoryBitMask = birdC

        overInfo.isHidden = true
        canRest = false
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
        birdA.speed = 1
        birdB.speed = 1
        ground.speed = 1
        pipes.speed = 1
        sky.speed = 1
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
        pipes.removeAllChildren()
    }
    func begin(){
        sendDate("seset".data(using: .utf8)!, uuidString: "C001")
        let wait = SKAction.wait(forDuration: TimeInterval(3))
        let again = SKAction.run ({self.startworld()})
        self.run(SKAction.sequence([wait,again]))
        startInfo.isHidden = false
        startInfo.run(shine)
    }
    
    func endsGame(){
        sendDate("end".data(using: .utf8)!, uuidString: "C001")
        ready = false
        stopworld()
        overInfo.isHidden = false
        overInfo.run(SKAction.repeat(blank, count: 3))
        birdA.physicsBody?.categoryBitMask = worldC
        birdB.physicsBody?.categoryBitMask = worldC
        let wait = SKAction.wait(forDuration: TimeInterval(0.6))
        let reset = SKAction.run ({self.canRest = true})
        self.run(SKAction.sequence([wait,reset]))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard connected else {
            return
        }
        
        if ground.speed>0 {
            for _ in touches{
                birdA.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                birdA.physicsBody?.applyImpulse(CGVector(dx: 0, dy: force))
                break
            }
        }else{
            if ready {
                if canRest{
                    self.reset()
                }
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if ground.speed > 0{
            if (contact.bodyA.categoryBitMask & scoreC) == scoreC || (contact.bodyB.categoryBitMask & scoreC) == scoreC{
            }else{
                endsGame()
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if connected{
                let birdAX = Double(birdA.position.x)
                let birdAY = Double(birdA.position.y)
                let birdBX = Double(birdB.position.x)
                let birdBY = Double(birdB.position.y)
                let info = String(birdAX) + "/" + String(birdAY) + "/" + String(birdBX) + "/" + String(birdBY)
                sendDate(info.data(using: .utf8)!, uuidString: "C001")
            }
    }
}
